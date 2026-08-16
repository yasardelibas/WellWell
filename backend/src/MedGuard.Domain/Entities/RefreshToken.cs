namespace MedGuard.Domain.Entities;

/// <summary>
/// Refresh tokens are stored hashed. The raw token only ever exists in the response body
/// and in the client's secure storage.
/// </summary>
public sealed class RefreshToken
{
    private RefreshToken()
    {
        TokenHash = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    /// <summary>Groups a rotation chain so that reuse can revoke the whole family.</summary>
    public Guid FamilyId { get; private set; }

    public string TokenHash { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset ExpiresAt { get; private set; }

    public DateTimeOffset? RevokedAt { get; private set; }

    public string? RevokedReason { get; private set; }

    public Guid? ReplacedByTokenId { get; private set; }

    public bool IsActive(DateTimeOffset now) => RevokedAt is null && ExpiresAt > now;

    public static RefreshToken Issue(Guid userId, string tokenHash, DateTimeOffset now, TimeSpan lifetime, Guid? familyId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            FamilyId = familyId ?? Guid.NewGuid(),
            TokenHash = tokenHash,
            CreatedAt = now,
            ExpiresAt = now.Add(lifetime)
        };

    public void Revoke(DateTimeOffset now, string reason, Guid? replacedByTokenId = null)
    {
        if (RevokedAt is not null)
        {
            return;
        }

        RevokedAt = now;
        RevokedReason = reason;
        ReplacedByTokenId = replacedByTokenId;
    }
}
