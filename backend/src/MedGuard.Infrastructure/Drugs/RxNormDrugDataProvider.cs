using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.ValueObjects;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Drugs;

/// <summary>
/// RxNorm (RxNav) lookup. Transport and parsing failures are reported as
/// <see cref="DrugLookupStatus.Unavailable"/> so they can never be read as a match.
/// </summary>
public sealed class RxNormDrugDataProvider : IDrugDataProvider
{
    public const string ProviderName = "rxnorm";

    private static readonly Regex BracketedBrand = new(@"\[(?<brand>[^\]]+)\]", RegexOptions.Compiled);
    private static readonly string[] InterestingTermTypes = { "SBD", "SCD", "BPCK", "GPCK" };

    private readonly HttpClient _httpClient;
    private readonly IIngredientNormalizer _normalizer;
    private readonly IDateTimeProvider _clock;
    private readonly ILogger<RxNormDrugDataProvider> _logger;

    public RxNormDrugDataProvider(
        HttpClient httpClient,
        IIngredientNormalizer normalizer,
        IDateTimeProvider clock,
        ILogger<RxNormDrugDataProvider> logger)
    {
        _httpClient = httpClient;
        _normalizer = normalizer;
        _clock = clock;
        _logger = logger;
    }

    public string Name => ProviderName;

    public async Task<DrugSearchResult?> SearchAsync(DrugSearchRequest request, CancellationToken cancellationToken)
    {
        var term = FirstUsableTerm(request);
        if (term is null)
        {
            return DrugSearchResult.NoMatch();
        }

        try
        {
            using var response = await _httpClient
                .GetAsync($"drugs.json?name={Uri.EscapeDataString(term)}", cancellationToken)
                .ConfigureAwait(false);

            if (response.StatusCode == HttpStatusCode.NotFound)
            {
                return DrugSearchResult.NoMatch();
            }

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("RxNorm responded with {StatusCode}.", (int)response.StatusCode);
                return DrugSearchResult.Unavailable();
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var candidates = ParseCandidates(document, request);
            return candidates.Count == 0 ? DrugSearchResult.NoMatch() : DrugSearchResult.Matched(candidates);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "RxNorm lookup failed.");
            return DrugSearchResult.Unavailable();
        }
    }

    public async Task<DrugDetails?> GetDrugAsync(string externalId, CancellationToken cancellationToken)
    {
        try
        {
            using var response = await _httpClient
                .GetAsync($"rxcui/{Uri.EscapeDataString(externalId)}/properties.json", cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            if (!document.RootElement.TryGetProperty("properties", out var properties))
            {
                return null;
            }

            var name = properties.TryGetProperty("name", out var nameElement) ? nameElement.GetString() ?? string.Empty : string.Empty;
            return new DrugDetails(BuildIdentity(externalId, name), name);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "RxNorm property lookup failed.");
            return null;
        }
    }

    private List<DrugCandidate> ParseCandidates(JsonDocument document, DrugSearchRequest request)
    {
        var candidates = new List<DrugCandidate>();

        if (!document.RootElement.TryGetProperty("drugGroup", out var drugGroup) ||
            !drugGroup.TryGetProperty("conceptGroup", out var conceptGroups) ||
            conceptGroups.ValueKind != JsonValueKind.Array)
        {
            return candidates;
        }

        foreach (var group in conceptGroups.EnumerateArray())
        {
            var termType = group.TryGetProperty("tty", out var ttyElement) ? ttyElement.GetString() : null;
            if (termType is null || !InterestingTermTypes.Contains(termType))
            {
                continue;
            }

            if (!group.TryGetProperty("conceptProperties", out var concepts) || concepts.ValueKind != JsonValueKind.Array)
            {
                continue;
            }

            foreach (var concept in concepts.EnumerateArray().Take(10))
            {
                var rxCui = concept.TryGetProperty("rxcui", out var rxcuiElement) ? rxcuiElement.GetString() : null;
                var name = concept.TryGetProperty("name", out var nameElement) ? nameElement.GetString() : null;

                if (string.IsNullOrWhiteSpace(rxCui) || string.IsNullOrWhiteSpace(name))
                {
                    continue;
                }

                var identity = BuildIdentity(rxCui, name);
                var score = MatchScoring.Score(
                    request,
                    identity.BrandName,
                    identity.GenericName,
                    identity.Ingredients.Select(i => i.OriginalName));

                if (score > 0.2)
                {
                    candidates.Add(new DrugCandidate(identity, score));
                }
            }
        }

        return candidates
            .GroupBy(candidate => candidate.Identity.RxCui)
            .Select(group => group.OrderByDescending(candidate => candidate.MatchScore).First())
            .OrderByDescending(candidate => candidate.MatchScore)
            .Take(5)
            .ToList();
    }

    /// <summary>
    /// RxNorm concept names follow "ingredient strength form [Brand]"; the brand section is
    /// optional. Parsing is deliberately conservative: unparsed text stays in the original name.
    /// </summary>
    private DrugIdentity BuildIdentity(string rxCui, string conceptName)
    {
        var brandMatch = BracketedBrand.Match(conceptName);
        var brandName = brandMatch.Success ? brandMatch.Groups["brand"].Value.Trim() : string.Empty;
        var withoutBrand = BracketedBrand.Replace(conceptName, string.Empty).Trim();

        var dosageForm = DetectDosageForm(withoutBrand);
        var ingredientText = withoutBrand;

        var ingredients = IngredientTextParser
            .SplitIngredientList(ingredientText.Replace(" / ", ", "))
            .Select(IngredientTextParser.Parse)
            .Where(parsed => !string.IsNullOrWhiteSpace(parsed.Name))
            .Select(parsed => _normalizer.Normalize(parsed.Name, parsed.Strength, parsed.Unit, null))
            .ToList();

        var genericName = ingredients.Count > 0
            ? string.Join(" / ", ingredients.Select(i => _normalizer.ToDisplayName(i.NormalizedName)))
            : withoutBrand;

        var strength = ingredients.Count == 1 && ingredients[0].Strength is not null
            ? $"{ingredients[0].Strength} {ingredients[0].Unit}".Trim()
            : null;

        return new DrugIdentity(
            rxCui,
            string.IsNullOrWhiteSpace(brandName) ? genericName : brandName,
            genericName,
            ingredients,
            dosageForm,
            strength,
            null,
            new DataProvenance(ProviderName, rxCui, _clock.UtcNow, "rxnav-current"));
    }

    private static string? DetectDosageForm(string conceptName)
    {
        foreach (var form in new[]
                 {
                     "Oral Tablet", "Oral Capsule", "Chewable Tablet", "Oral Solution", "Oral Suspension",
                     "Injectable Solution", "Topical Cream", "Topical Gel", "Ophthalmic Solution", "Tablet", "Capsule"
                 })
        {
            if (conceptName.Contains(form, StringComparison.OrdinalIgnoreCase))
            {
                return form;
            }
        }

        return null;
    }

    private static string? FirstUsableTerm(DrugSearchRequest request)
    {
        if (!string.IsNullOrWhiteSpace(request.BrandName))
        {
            return request.BrandName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.GenericName))
        {
            return request.GenericName.Trim();
        }

        return request.IngredientNames.FirstOrDefault(name => !string.IsNullOrWhiteSpace(name))?.Trim();
    }
}
