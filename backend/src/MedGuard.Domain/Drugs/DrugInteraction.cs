using MedGuard.Domain.ValueObjects;

namespace MedGuard.Domain.Drugs;

public sealed record DrugInteraction(
    string Description,
    string SeverityLabel,
    IReadOnlyCollection<string> MedicationIdentifiers,
    DataProvenance Provenance);

/// <summary>
/// Result wrapper that keeps "no interaction provider configured" distinguishable from
/// "provider says there is nothing". MedGuard never renders the two states identically.
/// </summary>
public sealed record DrugInteractionResult(
    DrugLookupStatus Status,
    IReadOnlyCollection<DrugInteraction> Interactions)
{
    public static DrugInteractionResult NotConfigured() =>
        new(DrugLookupStatus.NotConfigured, Array.Empty<DrugInteraction>());

    public static DrugInteractionResult Unavailable() =>
        new(DrugLookupStatus.Unavailable, Array.Empty<DrugInteraction>());
}
