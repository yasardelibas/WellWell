using MedGuard.Application.Abstractions;
using MedGuard.Domain.Drugs;

namespace MedGuard.Infrastructure.Drugs;

/// <summary>
/// Default interaction provider: none. It deliberately returns
/// <see cref="DrugLookupStatus.NotConfigured"/> rather than an empty "no interactions"
/// answer, because MedGuard must never imply an interaction check that did not happen.
/// </summary>
public sealed class UnavailableDrugInteractionProvider : IDrugInteractionProvider
{
    public string Name => "none";

    public bool IsConfigured => false;

    public Task<DrugInteractionResult> GetInteractionsAsync(
        IEnumerable<string> medicationIdentifiers,
        CancellationToken cancellationToken) =>
        Task.FromResult(DrugInteractionResult.NotConfigured());
}
