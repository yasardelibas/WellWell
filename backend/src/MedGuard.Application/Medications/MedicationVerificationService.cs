using System.Diagnostics;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Telemetry;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;
using Microsoft.Extensions.Logging;

namespace MedGuard.Application.Medications;

public sealed record MedicationVerificationOutcome(
    MedicationVerificationStatus Status,
    DrugIdentity? BestMatch,
    IReadOnlyCollection<DrugCandidate> Candidates,
    string Detail)
{
    public DataProvenance? Provenance =>
        Status == MedicationVerificationStatus.Verified ? BestMatch?.Provenance : null;
}

/// <summary>
/// Turns raw label information into a verification decision.
/// Domain Rule 1: only a confident match against a configured trusted provider yields
/// <see cref="MedicationVerificationStatus.Verified"/>; transport failures degrade to
/// <see cref="MedicationVerificationStatus.VerificationUnavailable"/>.
/// </summary>
public sealed class MedicationVerificationService
{
    /// <summary>Below this provider match score the user must confirm the medication manually.</summary>
    public const double ConfidentMatchThreshold = 0.75d;

    private readonly IReadOnlyList<IDrugDataProvider> _providers;
    private readonly ICacheStore _cache;
    private readonly ILogger<MedicationVerificationService> _logger;

    public MedicationVerificationService(
        IEnumerable<IDrugDataProvider> providers,
        ICacheStore cache,
        ILogger<MedicationVerificationService> logger)
    {
        _providers = providers.ToList();
        _cache = cache;
        _logger = logger;
    }

    public async Task<MedicationVerificationOutcome> VerifyAsync(
        DrugSearchRequest request,
        CancellationToken cancellationToken)
    {
        if (_providers.Count == 0)
        {
            return new MedicationVerificationOutcome(
                MedicationVerificationStatus.VerificationUnavailable,
                null,
                Array.Empty<DrugCandidate>(),
                "No trusted medication database is configured, so this medication could not be verified.");
        }

        var allCandidates = new List<DrugCandidate>();
        var anyUnavailable = false;
        var anyResponded = false;

        foreach (var provider in _providers)
        {
            var result = await SearchWithTelemetryAsync(provider, request, cancellationToken).ConfigureAwait(false);

            switch (result.Status)
            {
                case DrugLookupStatus.Matched:
                    anyResponded = true;
                    allCandidates.AddRange(result.Candidates);
                    break;
                case DrugLookupStatus.NoMatch:
                    anyResponded = true;
                    break;
                case DrugLookupStatus.Unavailable:
                    anyUnavailable = true;
                    break;
                case DrugLookupStatus.NotConfigured:
                default:
                    break;
            }

            var confident = allCandidates.OrderByDescending(c => c.MatchScore).FirstOrDefault();
            if (confident is not null && confident.MatchScore >= ConfidentMatchThreshold)
            {
                return new MedicationVerificationOutcome(
                    MedicationVerificationStatus.Verified,
                    confident.Identity,
                    Deduplicate(allCandidates),
                    $"Verified against {confident.Identity.Provenance.Provider}.");
            }
        }

        var ordered = Deduplicate(allCandidates);
        var best = ordered.FirstOrDefault();

        if (anyUnavailable && best is null)
        {
            return new MedicationVerificationOutcome(
                MedicationVerificationStatus.VerificationUnavailable,
                null,
                ordered,
                "We couldn't verify this medication right now. The medication database did not respond.");
        }

        if (best is not null)
        {
            return new MedicationVerificationOutcome(
                MedicationVerificationStatus.NoConfidentMatch,
                best.Identity,
                ordered,
                "We couldn't confidently match this medication with our current data source. Please review the details.");
        }

        return new MedicationVerificationOutcome(
            anyResponded ? MedicationVerificationStatus.NoConfidentMatch : MedicationVerificationStatus.VerificationUnavailable,
            null,
            ordered,
            anyResponded
                ? "We couldn't confidently match this medication with our current data source."
                : "We couldn't verify this medication right now.");
    }

    private async Task<DrugSearchResult> SearchWithTelemetryAsync(
        IDrugDataProvider provider,
        DrugSearchRequest request,
        CancellationToken cancellationToken)
    {
        var cacheKey = $"drug-search:{provider.Name}:{request.CacheKey}";
        var cached = await _cache.GetAsync<CachedSearchResult>(cacheKey, cancellationToken).ConfigureAwait(false);
        if (cached is not null)
        {
            MedGuardTelemetry.DrugProviderCalls.Add(
                1,
                new KeyValuePair<string, object?>("provider", provider.Name),
                new KeyValuePair<string, object?>("outcome", "cache-hit"));

            return cached.ToResult();
        }

        var stopwatch = Stopwatch.StartNew();
        DrugSearchResult result;

        try
        {
            result = await provider.SearchAsync(request, cancellationToken).ConfigureAwait(false)
                     ?? DrugSearchResult.NoMatch();
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // Never convert a provider failure into a successful verification.
            _logger.LogWarning(exception, "Drug data provider {Provider} failed.", provider.Name);
            result = DrugSearchResult.Unavailable();
        }
        finally
        {
            stopwatch.Stop();
            MedGuardTelemetry.DrugProviderLatency.Record(
                stopwatch.Elapsed.TotalMilliseconds,
                new KeyValuePair<string, object?>("provider", provider.Name));
        }

        MedGuardTelemetry.DrugProviderCalls.Add(
            1,
            new KeyValuePair<string, object?>("provider", provider.Name),
            new KeyValuePair<string, object?>("outcome", result.Status.ToString()));

        if (result.Status is DrugLookupStatus.Matched or DrugLookupStatus.NoMatch)
        {
            await _cache
                .SetAsync(cacheKey, CachedSearchResult.From(result), TimeSpan.FromHours(12), cancellationToken)
                .ConfigureAwait(false);
        }

        return result;
    }

    private static IReadOnlyCollection<DrugCandidate> Deduplicate(IEnumerable<DrugCandidate> candidates) =>
        candidates
            .GroupBy(c => c.Identity.RxCui ?? $"{c.Identity.BrandName}|{c.Identity.GenericName}", StringComparer.OrdinalIgnoreCase)
            .Select(group => group.OrderByDescending(c => c.MatchScore).First())
            .OrderByDescending(c => c.MatchScore)
            .Take(5)
            .ToList();

    /// <summary>Serializable cache shape; records with interfaces do not round-trip through JSON.</summary>
    public sealed class CachedSearchResult
    {
        public DrugLookupStatus Status { get; set; }

        public List<CachedCandidate> Candidates { get; set; } = new();

        public static CachedSearchResult From(DrugSearchResult result) => new()
        {
            Status = result.Status,
            Candidates = result.Candidates.Select(CachedCandidate.From).ToList()
        };

        public DrugSearchResult ToResult() => new(Status, Candidates.Select(c => c.ToCandidate()).ToList());
    }

    public sealed class CachedCandidate
    {
        public string? RxCui { get; set; }

        public string BrandName { get; set; } = string.Empty;

        public string GenericName { get; set; } = string.Empty;

        public string? DosageForm { get; set; }

        public string? Strength { get; set; }

        public string? Manufacturer { get; set; }

        public double MatchScore { get; set; }

        public string Provider { get; set; } = string.Empty;

        public string? ExternalIdentifier { get; set; }

        public DateTimeOffset RetrievedAt { get; set; }

        public string? DatasetVersion { get; set; }

        public List<CachedIngredient> Ingredients { get; set; } = new();

        public static CachedCandidate From(DrugCandidate candidate) => new()
        {
            RxCui = candidate.Identity.RxCui,
            BrandName = candidate.Identity.BrandName,
            GenericName = candidate.Identity.GenericName,
            DosageForm = candidate.Identity.DosageForm,
            Strength = candidate.Identity.Strength,
            Manufacturer = candidate.Identity.Manufacturer,
            MatchScore = candidate.MatchScore,
            Provider = candidate.Identity.Provenance.Provider,
            ExternalIdentifier = candidate.Identity.Provenance.ExternalIdentifier,
            RetrievedAt = candidate.Identity.Provenance.RetrievedAt,
            DatasetVersion = candidate.Identity.Provenance.DatasetVersion,
            Ingredients = candidate.Identity.Ingredients.Select(CachedIngredient.From).ToList()
        };

        public DrugCandidate ToCandidate() => new(
            new DrugIdentity(
                RxCui,
                BrandName,
                GenericName,
                Ingredients.Select(i => i.ToIngredient()).ToList(),
                DosageForm,
                Strength,
                Manufacturer,
                new DataProvenance(Provider, ExternalIdentifier, RetrievedAt, DatasetVersion)),
            MatchScore);
    }

    public sealed class CachedIngredient
    {
        public string NormalizedName { get; set; } = string.Empty;

        public string OriginalName { get; set; } = string.Empty;

        public decimal? Strength { get; set; }

        public string? Unit { get; set; }

        public string? RxCui { get; set; }

        public static CachedIngredient From(ActiveIngredient ingredient) => new()
        {
            NormalizedName = ingredient.NormalizedName,
            OriginalName = ingredient.OriginalName,
            Strength = ingredient.Strength,
            Unit = ingredient.Unit,
            RxCui = ingredient.RxCui
        };

        public ActiveIngredient ToIngredient() => new(NormalizedName, OriginalName, Strength, Unit, RxCui);
    }
}
