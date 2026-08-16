using System.Globalization;
using System.Net;
using System.Text;
using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Contracts.Common;
using MedGuard.Contracts.Emergency;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Emergency;

public static class EmergencyEndpoints
{
    private const string Disclaimer =
        "This card shows only the information its owner chose to share. It is not a medical record and may not be complete.";

    public static IEndpointRouteBuilder MapEmergencyEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/emergency-card").WithTags("Emergency").RequireAuthorization();

        group.MapGet("/", GetAsync);
        group.MapPut("/", UpdateAsync).WithValidation<UpdateEmergencyCardRequest>();
        group.MapPost("/regenerate", RegenerateAsync);

        // Public, unauthenticated read path used by the QR code.
        app.MapGet("/e/{token}", ViewPublicAsync)
            .WithTags("Emergency")
            .AllowAnonymous()
            .RequireRateLimiting("public-emergency");

        return app;
    }

    private static async Task<IResult> GetAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IOptions<EmergencyCardOptions> options,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var card = await EnsureCardAsync(dbContext, userId, clock, options.Value, cancellationToken);

        return Results.Ok(ToResponse(card, options.Value));
    }

    private static async Task<IResult> UpdateAsync(
        UpdateEmergencyCardRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        IOptions<EmergencyCardOptions> options,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var card = await EnsureCardAsync(dbContext, userId, clock, options.Value, cancellationToken);

        card.Update(
            request.IsEnabled,
            request.ShareName,
            request.ShareAllergies,
            request.ShareMedications,
            request.ShareEmergencyContact,
            request.ShareNotes,
            request.DisplayName,
            request.Allergies,
            request.EmergencyContactName,
            request.EmergencyContactPhone,
            request.Notes,
            clock.UtcNow);

        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.EmergencyCardUpdated, userId, card.Id, cancellationToken: cancellationToken);

        return Results.Ok(ToResponse(card, options.Value));
    }

    /// <summary>Issues a new token, which immediately invalidates every previously shared QR code.</summary>
    private static async Task<IResult> RegenerateAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        IOptions<EmergencyCardOptions> options,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var card = await EnsureCardAsync(dbContext, userId, clock, options.Value, cancellationToken);

        var rawToken = TokenGenerator.CreateToken();
        card.RegenerateToken(rawToken, TokenGenerator.Hash(rawToken), clock.UtcNow, TokenLifetime(options.Value));

        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(
            AuditEventType.EmergencyCardTokenRegenerated,
            userId,
            card.Id,
            cancellationToken: cancellationToken);

        return Results.Ok(ToResponse(card, options.Value));
    }

    private static async Task<IResult> ViewPublicAsync(
        string token,
        HttpContext httpContext,
        MedGuardDbContext dbContext,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        // The QR code is scanned with a phone camera, so browsers (Accept: text/html) get a
        // readable card while programmatic clients that ask for JSON keep the JSON contract.
        var wantsJson = WantsJson(httpContext.Request.Headers.Accept.ToString());

        var hash = TokenGenerator.Hash(token);
        var fingerprint = TokenGenerator.Fingerprint(httpContext.Request.Headers.UserAgent.ToString());

        var card = await dbContext.EmergencyCards
            .FirstOrDefaultAsync(item => item.TokenHash == hash, cancellationToken);

        if (card is null || !card.IsTokenUsable(clock.UtcNow))
        {
            dbContext.EmergencyCardAccessLogs.Add(
                EmergencyCardAccessLog.Record(card?.Id, card is null ? "not-found" : "expired", fingerprint, clock.UtcNow));
            await dbContext.SaveChangesAsync(cancellationToken);

            return wantsJson
                ? Results.NotFound(new ApiError("card_not_available", "This emergency card is not available."))
                : Results.Content(BuildNotFoundHtml(), "text/html; charset=utf-8", statusCode: StatusCodes.Status404NotFound);
        }

        var medications = card.ShareMedications
            ? await dbContext.Medications
                .Where(medication => medication.UserId == card.UserId && !medication.IsArchived)
                .OrderBy(medication => medication.BrandName)
                .Select(medication => new PublicEmergencyMedication(
                    medication.BrandName == string.Empty ? medication.GenericName : medication.BrandName,
                    medication.Strength,
                    medication.LabelDirections))
                .ToListAsync(cancellationToken)
            : new List<PublicEmergencyMedication>();

        dbContext.EmergencyCardAccessLogs.Add(
            EmergencyCardAccessLog.Record(card.Id, "viewed", fingerprint, clock.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);

        // Only the fields the owner explicitly enabled leave the server.
        var response = new PublicEmergencyCardResponse(
            card.ShareName ? card.DisplayName : null,
            card.ShareAllergies ? card.Allergies : null,
            medications,
            card.ShareEmergencyContact ? card.EmergencyContactName : null,
            card.ShareEmergencyContact ? card.EmergencyContactPhone : null,
            card.ShareNotes ? card.Notes : null,
            card.UpdatedAt,
            Disclaimer);

        return wantsJson
            ? Results.Ok(response)
            : Results.Content(BuildCardHtml(response), "text/html; charset=utf-8");
    }

    /// <summary>Prefer HTML for browsers; only serve JSON when the client explicitly asks for it.</summary>
    private static bool WantsJson(string accept) =>
        accept.Contains("application/json", StringComparison.OrdinalIgnoreCase)
        && !accept.Contains("text/html", StringComparison.OrdinalIgnoreCase);

    private static string Enc(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);

    private static string BuildCardHtml(PublicEmergencyCardResponse card)
    {
        var title = string.IsNullOrWhiteSpace(card.Name) ? "Emergency information" : card.Name!;
        var lastUpdated = card.LastUpdated.UtcDateTime.ToString("dd MMM yyyy, HH:mm", CultureInfo.InvariantCulture) + " UTC";
        var body = new StringBuilder();

        if (!string.IsNullOrWhiteSpace(card.Allergies))
        {
            body.Append($"""
                <section class="block alert">
                    <div class="label">Allergies</div>
                    <div class="value">{Enc(card.Allergies)}</div>
                </section>
                """);
        }

        if (card.Medications.Count > 0)
        {
            var rows = new StringBuilder();
            foreach (var med in card.Medications)
            {
                var detail = new StringBuilder();
                if (!string.IsNullOrWhiteSpace(med.StrengthText))
                {
                    detail.Append($"<span class=\"pill\">{Enc(med.StrengthText)}</span>");
                }

                if (!string.IsNullOrWhiteSpace(med.Directions))
                {
                    detail.Append($"<div class=\"muted\">{Enc(med.Directions)}</div>");
                }

                rows.Append($"""
                    <li>
                        <div class="med-name">{Enc(med.Name)}</div>
                        {detail}
                    </li>
                    """);
            }

            body.Append($"""
                <section class="block">
                    <div class="label">Medications</div>
                    <ul class="meds">{rows}</ul>
                </section>
                """);
        }

        if (!string.IsNullOrWhiteSpace(card.EmergencyContactName) || !string.IsNullOrWhiteSpace(card.EmergencyContactPhone))
        {
            var phone = card.EmergencyContactPhone;
            var phoneHtml = string.IsNullOrWhiteSpace(phone)
                ? string.Empty
                : $"<a class=\"phone\" href=\"tel:{Enc(SanitizePhone(phone))}\">{Enc(phone)}</a>";

            body.Append($"""
                <section class="block">
                    <div class="label">Emergency contact</div>
                    <div class="value">{Enc(card.EmergencyContactName)}</div>
                    {phoneHtml}
                </section>
                """);
        }

        if (!string.IsNullOrWhiteSpace(card.Notes))
        {
            body.Append($"""
                <section class="block">
                    <div class="label">Notes</div>
                    <div class="value">{Enc(card.Notes)}</div>
                </section>
                """);
        }

        return $$"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>Emergency Card</title>
                <style>
                    :root { color-scheme: light; }
                    * { box-sizing: border-box; }
                    body { margin: 0; background: #F3F4F6; color: #1F2937;
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                        padding: 20px; display: flex; justify-content: center; }
                    .card { width: 100%; max-width: 560px; background: #fff; border-radius: 20px;
                        box-shadow: 0 10px 30px rgba(0,0,0,.08); overflow: hidden; }
                    .header { display: flex; align-items: center; gap: 14px; padding: 22px 22px;
                        background: linear-gradient(135deg, #DC2626, #B91C1C); color: #fff; }
                    .header .icon { width: 46px; height: 46px; border-radius: 14px; background: rgba(255,255,255,.2);
                        display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: 700; }
                    .kicker { font-size: 11px; letter-spacing: 2px; opacity: .85; }
                    .header h1 { margin: 2px 0 0; font-size: 22px; line-height: 1.2; }
                    .body { padding: 8px 22px 4px; }
                    .block { padding: 16px 0; border-bottom: 1px solid #E5E7EB; }
                    .block:last-child { border-bottom: 0; }
                    .label { font-size: 12px; letter-spacing: 1px; text-transform: uppercase; color: #6B7280; margin-bottom: 6px; }
                    .value { font-size: 16px; line-height: 1.45; white-space: pre-wrap; }
                    .alert { background: #FEF2F2; margin: 12px -22px 0; padding: 16px 22px; border: 0; }
                    .alert .label { color: #B91C1C; }
                    .alert .value { color: #B91C1C; font-weight: 600; }
                    ul.meds { list-style: none; margin: 0; padding: 0; }
                    ul.meds li { padding: 10px 0; border-bottom: 1px dashed #E5E7EB; }
                    ul.meds li:last-child { border-bottom: 0; }
                    .med-name { font-weight: 600; font-size: 16px; }
                    .pill { display: inline-block; margin-top: 4px; padding: 2px 10px; border-radius: 999px;
                        background: #EBF1FF; color: #1E4ED8; font-size: 13px; font-weight: 600; }
                    .muted { color: #6B7280; font-size: 14px; margin-top: 4px; }
                    .phone { display: inline-block; margin-top: 6px; font-size: 18px; font-weight: 700; color: #2E63EB; text-decoration: none; }
                    .footer { padding: 16px 22px 22px; }
                    .meta { font-size: 12px; color: #9CA3AF; }
                    .disclaimer { margin-top: 8px; font-size: 12px; color: #9CA3AF; line-height: 1.5; }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="header">
                        <div class="icon">✚</div>
                        <div>
                            <div class="kicker">MEDGUARD · EMERGENCY CARD</div>
                            <h1>{{Enc(title)}}</h1>
                        </div>
                    </div>
                    <div class="body">{{body}}</div>
                    <div class="footer">
                        <div class="meta">Last updated {{Enc(lastUpdated)}}</div>
                        <div class="disclaimer">{{Enc(card.Disclaimer)}}</div>
                    </div>
                </div>
            </body>
            </html>
            """;
    }

    private static string BuildNotFoundHtml() => """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Emergency Card</title>
            <style>
                body { margin: 0; min-height: 100vh; background: #F3F4F6; color: #1F2937;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex; align-items: center; justify-content: center; padding: 24px; }
                .box { background: #fff; border-radius: 20px; padding: 32px; max-width: 420px; text-align: center;
                    box-shadow: 0 10px 30px rgba(0,0,0,.08); }
                h1 { font-size: 20px; margin: 0 0 8px; }
                p { color: #6B7280; line-height: 1.5; margin: 0; }
            </style>
        </head>
        <body>
            <div class="box">
                <h1>This emergency card is not available</h1>
                <p>The link may have expired or been replaced by its owner. Please ask them for an up-to-date card.</p>
            </div>
        </body>
        </html>
        """;

    private static string SanitizePhone(string phone)
    {
        var builder = new StringBuilder(phone.Length);
        foreach (var ch in phone)
        {
            if (char.IsDigit(ch) || ch == '+')
            {
                builder.Append(ch);
            }
        }

        return builder.ToString();
    }

    private static async Task<EmergencyCard> EnsureCardAsync(
        MedGuardDbContext dbContext,
        Guid userId,
        IDateTimeProvider clock,
        EmergencyCardOptions options,
        CancellationToken cancellationToken)
    {
        var card = await dbContext.EmergencyCards
            .FirstOrDefaultAsync(item => item.UserId == userId, cancellationToken);

        if (card is not null)
        {
            return card;
        }

        var rawToken = TokenGenerator.CreateToken();
        card = EmergencyCard.Create(userId, rawToken, TokenGenerator.Hash(rawToken), clock.UtcNow, TokenLifetime(options));

        dbContext.EmergencyCards.Add(card);
        await dbContext.SaveChangesAsync(cancellationToken);

        return card;
    }

    private static TimeSpan? TokenLifetime(EmergencyCardOptions options) =>
        options.TokenLifetimeDays.HasValue ? TimeSpan.FromDays(options.TokenLifetimeDays.Value) : null;

    private static EmergencyCardResponse ToResponse(EmergencyCard card, EmergencyCardOptions options) => new(
        card.IsEnabled,
        card.ShareName,
        card.ShareAllergies,
        card.ShareMedications,
        card.ShareEmergencyContact,
        card.ShareNotes,
        card.DisplayName,
        card.Allergies,
        card.EmergencyContactName,
        card.EmergencyContactPhone,
        card.Notes,
        string.IsNullOrWhiteSpace(card.Token) ? string.Empty : $"{options.PublicBaseUrl.TrimEnd('/')}/e/{card.Token}",
        card.TokenIssuedAt,
        card.TokenExpiresAt,
        card.UpdatedAt);
}
