using MedGuard.Domain.Enums;

namespace MedGuard.Domain.Entities;

/// <summary>
/// A caregiver link. The patient always remains the data owner and grants each capability
/// explicitly; nothing is granted by default and access can be revoked immediately.
/// </summary>
public sealed class CaregiverRelationship
{
    private readonly List<CaregiverPermissionGrant> _permissions = new();

    private CaregiverRelationship()
    {
        CaregiverEmail = string.Empty;
        InvitationTokenHash = string.Empty;
    }

    public Guid Id { get; private set; }

    /// <summary>The patient who owns the data.</summary>
    public Guid OwnerUserId { get; private set; }

    /// <summary>Set once the invited caregiver has an account and accepts.</summary>
    public Guid? CaregiverUserId { get; private set; }

    public string CaregiverEmail { get; private set; }

    public string? CaregiverDisplayName { get; private set; }

    public CaregiverRelationshipStatus Status { get; private set; } = CaregiverRelationshipStatus.Invited;

    public string InvitationTokenHash { get; private set; }

    public DateTimeOffset InvitationExpiresAt { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public DateTimeOffset? AcceptedAt { get; private set; }

    public DateTimeOffset? RevokedAt { get; private set; }

    public IReadOnlyCollection<CaregiverPermissionGrant> Permissions => _permissions.AsReadOnly();

    public static CaregiverRelationship Invite(
        Guid ownerUserId,
        string caregiverEmail,
        string invitationTokenHash,
        DateTimeOffset now,
        TimeSpan invitationLifetime,
        IEnumerable<CaregiverPermission> requestedPermissions)
    {
        var relationship = new CaregiverRelationship
        {
            Id = Guid.NewGuid(),
            OwnerUserId = ownerUserId,
            CaregiverEmail = User.NormalizeEmail(caregiverEmail),
            InvitationTokenHash = invitationTokenHash,
            InvitationExpiresAt = now.Add(invitationLifetime),
            Status = CaregiverRelationshipStatus.Invited,
            CreatedAt = now,
            UpdatedAt = now
        };

        relationship.SetPermissions(requestedPermissions, now, approved: false);
        return relationship;
    }

    public void Accept(Guid caregiverUserId, string? displayName, DateTimeOffset now)
    {
        CaregiverUserId = caregiverUserId;
        CaregiverDisplayName = displayName;
        Status = CaregiverRelationshipStatus.Accepted;
        AcceptedAt = now;
        UpdatedAt = now;
    }

    /// <summary>
    /// The owner approves the permission set after acceptance; only then does access begin.
    /// </summary>
    public void ApprovePermissions(IEnumerable<CaregiverPermission> permissions, DateTimeOffset now)
    {
        SetPermissions(permissions, now, approved: true);
        Status = CaregiverRelationshipStatus.Active;
        UpdatedAt = now;
    }

    public void Revoke(DateTimeOffset now)
    {
        Status = CaregiverRelationshipStatus.Revoked;
        RevokedAt = now;
        UpdatedAt = now;
        _permissions.Clear();
    }

    public bool HasPermission(CaregiverPermission permission, DateTimeOffset now) =>
        Status == CaregiverRelationshipStatus.Active &&
        RevokedAt is null &&
        _permissions.Any(p => p.Permission == permission && p.Approved);

    private void SetPermissions(IEnumerable<CaregiverPermission> permissions, DateTimeOffset now, bool approved)
    {
        _permissions.Clear();
        foreach (var permission in permissions.Distinct())
        {
            _permissions.Add(CaregiverPermissionGrant.Create(permission, approved, now));
        }
    }
}

public sealed class CaregiverPermissionGrant
{
    private CaregiverPermissionGrant()
    {
    }

    public Guid Id { get; private set; }

    public Guid CaregiverRelationshipId { get; private set; }

    public CaregiverPermission Permission { get; private set; }

    public bool Approved { get; private set; }

    public DateTimeOffset GrantedAt { get; private set; }

    public static CaregiverPermissionGrant Create(CaregiverPermission permission, bool approved, DateTimeOffset now) =>
        new()
        {
            Id = Guid.NewGuid(),
            Permission = permission,
            Approved = approved,
            GrantedAt = now
        };
}
