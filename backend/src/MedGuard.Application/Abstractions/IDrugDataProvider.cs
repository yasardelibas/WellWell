using MedGuard.Domain.Drugs;

namespace MedGuard.Application.Abstractions;

/// <summary>
/// Abstraction over external medication databases (RxNorm, openFDA, ...).
/// Implementations must never throw for transport failures; they return
/// <see cref="DrugLookupStatus.Unavailable"/> so callers cannot mistake a failure for a match.
/// </summary>
public interface IDrugDataProvider
{
    string Name { get; }

    Task<DrugSearchResult?> SearchAsync(
        DrugSearchRequest request,
        CancellationToken cancellationToken);

    Task<DrugDetails?> GetDrugAsync(
        string externalId,
        CancellationToken cancellationToken);
}
