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
        var hash = TokenGenerator.Hash(token);
        var fingerprint = TokenGenerator.Fingerprint(httpContext.Request.Headers.UserAgent.ToString());

        var card = await dbContext.EmergencyCards
            .FirstOrDefaultAsync(item => item.TokenHash == hash, cancellationToken);

        if (card is null || !card.IsTokenUsable(clock.UtcNow))
        {
            dbContext.EmergencyCardAccessLogs.Add(
                EmergencyCardAccessLog.Record(card?.Id, card is null ? "not-found" : "expired", fingerprint, clock.UtcNow));
            await dbContext.SaveChangesAsync(cancellationToken);

            return Results.NotFound(new ApiError("card_not_available", "This emergency card is not available."));
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
        return Results.Ok(new PublicEmergencyCardResponse(
            card.ShareName ? card.DisplayName : null,
            card.ShareAllergies ? card.Allergies : null,
            medications,
            card.ShareEmergencyContact ? card.EmergencyContactName : null,
            card.ShareEmergencyContact ? card.EmergencyContactPhone : null,
            card.ShareNotes ? card.Notes : null,
            card.UpdatedAt,
            Disclaimer));
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
