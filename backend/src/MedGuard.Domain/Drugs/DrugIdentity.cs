using MedGuard.Domain.ValueObjects;

namespace MedGuard.Domain.Drugs;

/// <summary>
/// Provider-neutral representation of a medication returned by an external drug data source.
/// The domain never depends on a specific provider's payload shape.
/// </summary>
public sealed record DrugIdentity(
    string? RxCui,
    string BrandName,
    string GenericName,
    IReadOnlyCollection<ActiveIngredient> Ingredients,
    string? DosageForm,
    string? Strength,
    string? Manufacturer,
    DataProvenance Provenance);
