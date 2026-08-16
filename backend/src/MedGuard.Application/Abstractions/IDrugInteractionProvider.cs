using MedGuard.Domain.Drugs;

namespace MedGuard.Application.Abstractions;

/// <summary>
/// Extension point for drug-drug interaction data. MedGuard ships without a configured
/// provider; in that case the UI states that interaction checking is unavailable.
/// Fabricated interaction results are never produced.
/// </summary>
public interface IDrugInteractionProvider
{
    string Name { get; }

    bool IsConfigured { get; }

    Task<DrugInteractionResult> GetInteractionsAsync(
        IEnumerable<string> medicationIdentifiers,
        CancellationToken cancellationToken);
}
