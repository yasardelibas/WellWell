namespace MedGuard.Domain.ValueObjects;

/// <summary>
/// Where a medication fact or safety finding came from. Surfaced to the user as
/// "Source" and "Last verified" so a warning can always be traced back to its origin.
/// </summary>
public sealed record DataProvenance(
    string Provider,
    string? ExternalIdentifier,
    DateTimeOffset RetrievedAt,
    string? DatasetVersion)
{
    public static DataProvenance UserEntered(DateTimeOffset at) =>
        new("user-entered", null, at, null);
}
