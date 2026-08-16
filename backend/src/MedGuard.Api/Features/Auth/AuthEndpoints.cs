using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Contracts.Auth;
using MedGuard.Contracts.Common;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Auth;

public static class AuthEndpoints
{
    private static readonly TimeSpan PasswordResetLifetime = TimeSpan.FromMinutes(30);

    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth").RequireRateLimiting("auth");

        group.MapPost("/register", RegisterAsync).WithValidation<RegisterRequest>().AllowAnonymous();
        group.MapPost("/login", LoginAsync).WithValidation<LoginRequest>().AllowAnonymous();
        group.MapPost("/refresh", RefreshAsync).WithValidation<RefreshTokenRequest>().AllowAnonymous();
        group.MapPost("/logout", LogoutAsync).AllowAnonymous();
        group.MapPost("/forgot-password", ForgotPasswordAsync).WithValidation<ForgotPasswordRequest>().AllowAnonymous();
        group.MapPost("/reset-password", ResetPasswordAsync).WithValidation<ResetPasswordRequest>().AllowAnonymous();

        var me = app.MapGroup("/api/me").WithTags("Profile").RequireAuthorization();
        me.MapGet("/", GetProfileAsync);
        me.MapPut("/", UpdateProfileAsync).WithValidation<UpdateProfileRequest>();
        me.MapPost("/acknowledge-safety-notice", AcknowledgeSafetyNoticeAsync);
        me.MapPost("/verify-email", VerifyEmailAsync).WithValidation<VerifyEmailRequest>().RequireRateLimiting("auth");
        me.MapPost("/resend-verification-code", ResendVerificationCodeAsync).RequireRateLimiting("auth");

        return app;
    }

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        MedGuardDbContext dbContext,
        IPasswordHasher passwordHasher,
        IDateTimeProvider clock,
        AuthTokenIssuer tokenIssuer,
        INotificationSender notificationSender,
        IOptions<EmailOptions> emailOptions,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = User.NormalizeEmail(request.Email);

        if (await dbContext.Users.AnyAsync(user => user.NormalizedEmail == normalizedEmail, cancellationToken))
        {
            return Results.Conflict(new ApiError("email_in_use", "An account with this email already exists."));
        }

        var user = User.Create(
            request.Email,
            passwordHasher.Hash(request.Password),
            request.DisplayName,
            clock.UtcNow,
            request.TimeZoneId ?? "UTC");

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);

        var response = await tokenIssuer.IssueAsync(user, familyId: null, cancellationToken);
        await auditLogger.LogAsync(AuditEventType.UserRegistered, user.Id, cancellationToken: cancellationToken);

        // A brand new, non-demo account gets a verification code in the same request. Delivery
        // failure must never block registration, so this never throws back into the response.
        if (!user.EmailVerified)
        {
            await IssueAndSendVerificationCodeAsync(
                dbContext, clock, notificationSender, emailOptions.Value, auditLogger, user, cancellationToken);
        }

        return Results.Created($"/api/me", response);
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        MedGuardDbContext dbContext,
        IPasswordHasher passwordHasher,
        AuthTokenIssuer tokenIssuer,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = User.NormalizeEmail(request.Email);
        var user = await dbContext.Users
            .FirstOrDefaultAsync(candidate => candidate.NormalizedEmail == normalizedEmail, cancellationToken);

        // The same response shape for unknown accounts and wrong passwords avoids account enumeration.
        if (user is null || !passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            return Results.Json(
                new ApiError("invalid_credentials", "Email or password is incorrect."),
                statusCode: StatusCodes.Status401Unauthorized);
        }

        var response = await tokenIssuer.IssueAsync(user, familyId: null, cancellationToken);
        await auditLogger.LogAsync(AuditEventType.UserSignedIn, user.Id, cancellationToken: cancellationToken);

        return Results.Ok(response);
    }

    private static async Task<IResult> RefreshAsync(
        RefreshTokenRequest request,
        MedGuardDbContext dbContext,
        AuthTokenIssuer tokenIssuer,
        CancellationToken cancellationToken)
    {
        var (token, reuseDetected) = await tokenIssuer.ResolveAsync(request.RefreshToken, cancellationToken);

        if (token is null)
        {
            return Results.Json(
                new ApiError(
                    reuseDetected ? "refresh_token_reused" : "invalid_refresh_token",
                    "Please sign in again."),
                statusCode: StatusCodes.Status401Unauthorized);
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(candidate => candidate.Id == token.UserId, cancellationToken);
        if (user is null)
        {
            return Results.Json(
                new ApiError("invalid_refresh_token", "Please sign in again."),
                statusCode: StatusCodes.Status401Unauthorized);
        }

        await tokenIssuer.RevokeAsync(token, "rotated", cancellationToken);
        var response = await tokenIssuer.IssueAsync(user, token.FamilyId, cancellationToken);

        return Results.Ok(response);
    }

    private static async Task<IResult> LogoutAsync(
        LogoutRequest? request,
        AuthTokenIssuer tokenIssuer,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(request?.RefreshToken))
        {
            var (token, _) = await tokenIssuer.ResolveAsync(request.RefreshToken, cancellationToken);
            if (token is not null)
            {
                await tokenIssuer.RevokeAsync(token, "logout", cancellationToken);
            }
        }
        else if (currentUser.UserId is { } userId)
        {
            await tokenIssuer.RevokeAllForUserAsync(userId, "logout", cancellationToken);
        }

        if (currentUser.UserId is { } signedOutUserId)
        {
            await auditLogger.LogAsync(AuditEventType.UserSignedOut, signedOutUserId, cancellationToken: cancellationToken);
        }

        return Results.NoContent();
    }

    private static async Task<IResult> ForgotPasswordAsync(
        ForgotPasswordRequest request,
        MedGuardDbContext dbContext,
        IDateTimeProvider clock,
        INotificationSender notificationSender,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = User.NormalizeEmail(request.Email);
        var user = await dbContext.Users
            .FirstOrDefaultAsync(candidate => candidate.NormalizedEmail == normalizedEmail, cancellationToken);

        if (user is not null)
        {
            var rawToken = TokenGenerator.CreateToken();
            dbContext.PasswordResetTokens.Add(
                PasswordResetToken.Issue(user.Id, TokenGenerator.Hash(rawToken), clock.UtcNow, PasswordResetLifetime));

            await dbContext.SaveChangesAsync(cancellationToken);
            await notificationSender.SendPasswordResetAsync(user.Email, rawToken, user.PreferredLanguage, cancellationToken);
            await auditLogger.LogAsync(AuditEventType.PasswordResetRequested, user.Id, cancellationToken: cancellationToken);
        }

        // Always the same answer so the endpoint cannot be used to discover registered emails.
        return Results.Accepted(value: new { message = "If an account exists for this email, a reset link has been sent." });
    }

    private static async Task<IResult> ResetPasswordAsync(
        ResetPasswordRequest request,
        MedGuardDbContext dbContext,
        IPasswordHasher passwordHasher,
        IDateTimeProvider clock,
        AuthTokenIssuer tokenIssuer,
        CancellationToken cancellationToken)
    {
        var hash = TokenGenerator.Hash(request.Token);
        var resetToken = await dbContext.PasswordResetTokens
            .FirstOrDefaultAsync(token => token.TokenHash == hash, cancellationToken);

        if (resetToken is null || !resetToken.IsUsable(clock.UtcNow))
        {
            return Results.BadRequest(new ApiError("invalid_reset_token", "This reset link is no longer valid."));
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(candidate => candidate.Id == resetToken.UserId, cancellationToken);
        if (user is null)
        {
            return Results.BadRequest(new ApiError("invalid_reset_token", "This reset link is no longer valid."));
        }

        user.ChangePassword(passwordHasher.Hash(request.NewPassword), clock.UtcNow);
        resetToken.MarkUsed(clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        // Every existing session ends when the password changes.
        await tokenIssuer.RevokeAllForUserAsync(user.Id, "password-reset", cancellationToken);

        return Results.NoContent();
    }

    private static async Task<IResult> GetProfileAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FirstOrDefaultAsync(
            candidate => candidate.Id == currentUser.RequireUserId(),
            cancellationToken);

        return user is null ? Results.NotFound() : Results.Ok(user.ToResponse());
    }

    private static async Task<IResult> UpdateProfileAsync(
        UpdateProfileRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FirstOrDefaultAsync(
            candidate => candidate.Id == currentUser.RequireUserId(),
            cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        user.UpdatePreferences(
            request.DisplayName,
            request.TimeZoneId,
            request.PrivacyNotificationsEnabled,
            request.BiometricLockEnabled,
            clock.UtcNow,
            request.PreferredLanguage);

        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(user.ToResponse());
    }

    private static async Task<IResult> AcknowledgeSafetyNoticeAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FirstOrDefaultAsync(
            candidate => candidate.Id == currentUser.RequireUserId(),
            cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        user.AcknowledgeSafetyNotice(clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(user.ToResponse());
    }

    private static async Task<IResult> VerifyEmailAsync(
        VerifyEmailRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FirstOrDefaultAsync(
            candidate => candidate.Id == currentUser.RequireUserId(),
            cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        if (user.EmailVerified)
        {
            return Results.Ok(user.ToResponse());
        }

        var codeHash = TokenGenerator.Hash(request.Code);
        var pendingCode = await dbContext.EmailVerificationCodes
            .Where(code => code.UserId == user.Id && code.ConsumedAt == null)
            .OrderByDescending(code => code.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (pendingCode is null || !pendingCode.IsUsable(clock.UtcNow))
        {
            return Results.BadRequest(new ApiError("invalid_or_expired_code", "Request a new code and try again."));
        }

        if (pendingCode.CodeHash != codeHash)
        {
            pendingCode.RecordFailedAttempt();
            await dbContext.SaveChangesAsync(cancellationToken);
            return Results.BadRequest(new ApiError("incorrect_code", "That code is not correct."));
        }

        pendingCode.MarkConsumed(clock.UtcNow);
        user.MarkEmailVerified(clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.EmailVerified, user.Id, cancellationToken: cancellationToken);

        return Results.Ok(user.ToResponse());
    }

    private static async Task<IResult> ResendVerificationCodeAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        INotificationSender notificationSender,
        IOptions<EmailOptions> emailOptions,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FirstOrDefaultAsync(
            candidate => candidate.Id == currentUser.RequireUserId(),
            cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        if (user.EmailVerified)
        {
            return Results.Ok(user.ToResponse());
        }

        await IssueAndSendVerificationCodeAsync(
            dbContext, clock, notificationSender, emailOptions.Value, auditLogger, user, cancellationToken);

        return Results.Accepted(value: new { message = "A new verification code has been sent." });
    }

    private static async Task IssueAndSendVerificationCodeAsync(
        MedGuardDbContext dbContext,
        IDateTimeProvider clock,
        INotificationSender notificationSender,
        EmailOptions emailOptions,
        IAuditLogger auditLogger,
        User user,
        CancellationToken cancellationToken)
    {
        var rawCode = TokenGenerator.CreateNumericCode();
        var lifetime = TimeSpan.FromMinutes(Math.Clamp(emailOptions.VerificationCodeLifetimeMinutes, 5, 60));

        dbContext.EmailVerificationCodes.Add(
            EmailVerificationCode.Issue(user.Id, TokenGenerator.Hash(rawCode), clock.UtcNow, lifetime));

        await dbContext.SaveChangesAsync(cancellationToken);
        await notificationSender.SendEmailVerificationAsync(user.Email, rawCode, user.PreferredLanguage, cancellationToken);
        await auditLogger.LogAsync(AuditEventType.EmailVerificationRequested, user.Id, cancellationToken: cancellationToken);
    }
}
