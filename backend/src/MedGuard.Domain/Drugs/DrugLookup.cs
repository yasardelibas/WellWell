namespace MedGuard.Domain.Drugs;

/// <summary>
/// Outcome of a lookup against an external drug data provider.
/// <see cref="Unavailable"/> must never be treated as a successful verification.
/// </summary>
public enum DrugLookupStatus
{
    Matched = 0,
    NoMatch = 1,
    Unavailable = 2,
    NotConfigured = 3
}

public sealed record DrugSearchRequest(
    string? BrandName,
    string? GenericName,
    IReadOnlyCollection<string> IngredientNames,
    string? Strength,
    string? DosageForm)
{
    public string CacheKey =>
        string.Join('|',
            BrandName?.ToLowerInvariant() ?? "-",
            GenericName?.ToLowerInvariant() ?? "-",
            string.Join(',', IngredientNames.Select(i => i.ToLowerInvariant()).OrderBy(i => i, StringComparer.Ordinal)),
            Strength?.ToLowerInvariant() ?? "-",
            DosageForm?.ToLowerInvariant() ?? "-");
}

/// <summary>
/// A candidate match. <paramref name="MatchScore"/> is a 0..1 provider confidence, never a safety judgement.
/// </summary>
public sealed record DrugCandidate(DrugIdentity Identity, double MatchScore);

public sealed record DrugSearchResult(
    DrugLookupStatus Status,
    IReadOnlyCollection<DrugCandidate> Candidates)
{
    public static DrugSearchResult Unavailable() => new(DrugLookupStatus.Unavailable, Array.Empty<DrugCandidate>());

    public static DrugSearchResult NoMatch() => new(DrugLookupStatus.NoMatch, Array.Empty<DrugCandidate>());

    public static DrugSearchResult NotConfigured() => new(DrugLookupStatus.NotConfigured, Array.Empty<DrugCandidate>());

    public static DrugSearchResult Matched(IReadOnlyCollection<DrugCandidate> candidates) =>
        candidates.Count == 0 ? NoMatch() : new DrugSearchResult(DrugLookupStatus.Matched, candidates);

    public DrugCandidate? BestMatch => Candidates.OrderByDescending(c => c.MatchScore).FirstOrDefault();
}

public sealed record DrugDetails(DrugIdentity Identity, string? LabelText);
