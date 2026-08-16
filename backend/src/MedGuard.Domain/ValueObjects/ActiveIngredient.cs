namespace MedGuard.Domain.ValueObjects;

/// <summary>
/// An active ingredient as understood after normalization. Both the original label
/// wording and the normalized name are preserved so the user can always see what was read.
/// </summary>
public sealed record ActiveIngredient(
    string NormalizedName,
    string OriginalName,
    decimal? Strength,
    string? Unit,
    string? RxCui)
{
    /// <summary>
    /// Canonical comparison key. RxNorm concept identifiers are preferred over text equality.
    /// </summary>
    public string ComparisonKey => string.IsNullOrWhiteSpace(RxCui)
        ? $"name:{NormalizedName}"
        : $"rxcui:{RxCui}";

    public bool HasCanonicalIdentifier => !string.IsNullOrWhiteSpace(RxCui);
}
