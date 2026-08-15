using MedGuard.Domain.Enums;

namespace MedGuard.Application.Abstractions;

public interface IDateTimeProvider
{
    DateTimeOffset UtcNow { get; }
}

/// <summary>Small cache facade so Redis stays optional.</summary>
public interface ICacheStore
{
    Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken) where T : class;

    Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken) where T : class;
}

public interface IAuditLogger
{
    Task LogAsync(
        AuditEventType type,
        Guid? userId,
        Guid? subjectId = null,
        string? outcome = null,
        CancellationToken cancellationToken = default);
}

/// <summary>Outbound notifications for invitations, password resets and email verification.</summary>
public interface INotificationSender
{
    Task SendCaregiverInvitationAsync(string email, string token, CancellationToken cancellationToken);

    Task SendPasswordResetAsync(string email, string token, CancellationToken cancellationToken);

    Task SendEmailVerificationAsync(string email, string code, CancellationToken cancellationToken);
}
