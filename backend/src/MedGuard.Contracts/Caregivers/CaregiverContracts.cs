namespace MedGuard.Contracts.Caregivers;

public sealed record InviteCaregiverRequest(string Email, IReadOnlyCollection<string> Permissions);

public sealed record AcceptCaregiverInvitationRequest(string Token);

public sealed record UpdateCaregiverPermissionsRequest(IReadOnlyCollection<string> Permissions);

public sealed record CaregiverResponse(
    Guid Id,
    string Email,
    string? DisplayName,
    string Status,
    IReadOnlyCollection<string> Permissions,
    DateTimeOffset CreatedAt,
    DateTimeOffset? AcceptedAt);

/// <summary>
/// Returned only for local/demo environments so the invitation link can be shown in the UI
/// without an outbound email provider.
/// </summary>
public sealed record CaregiverInvitationResponse(CaregiverResponse Caregiver, string? InvitationToken);

/// <summary>
/// A relationship as seen by the caregiver, not the owner — carries the owner's identity
/// instead of the caregiver's own, which <see cref="CaregiverResponse"/> carries for every
/// owner-perspective endpoint.
/// </summary>
public sealed record SharedWithMeResponse(
    Guid Id,
    string OwnerEmail,
    string? OwnerDisplayName,
    string Status,
    IReadOnlyCollection<string> Permissions,
    DateTimeOffset CreatedAt,
    DateTimeOffset? AcceptedAt);
