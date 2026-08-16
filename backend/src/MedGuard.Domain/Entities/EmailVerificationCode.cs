namespace MedGuard.Domain.Entities;

/// <summary>
/// A short-lived numeric code sent to a user's inbox to confirm they own the address they
/// registered with. Only the hash is persisted. Unlike <see cref="PasswordResetToken"/>, a
/// numeric code is short enough to guess, so attempts are capped as well as time-boxed.
/// </summary>
public sealed class EmailVerificationCode
{
    public const int MaxAttempts = 5;

    private EmailVerificationCode()
    {
        CodeHash = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string CodeHash { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset ExpiresAt { get; private set; }

    public DateTimeOffset? ConsumedAt { get; private set; }

    public int AttemptCount { get; private set; }

    public bool IsUsable(DateTimeOffset now) =>
        ConsumedAt is null && ExpiresAt > now && AttemptCount < MaxAttempts;

    public static EmailVerificationCode Issue(Guid userId, string codeHash, DateTimeOffset now, TimeSpan lifetime) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CodeHash = codeHash,
            CreatedAt = now,
            ExpiresAt = now.Add(lifetime)
        };

    public void RecordFailedAttempt() => AttemptCount++;

    public void MarkConsumed(DateTimeOffset now) => ConsumedAt = now;
}
