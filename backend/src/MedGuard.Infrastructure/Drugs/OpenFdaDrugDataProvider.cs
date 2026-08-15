using System.Net;
using System.Text.Json;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.ValueObjects;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Drugs;

/// <summary>
/// openFDA drug label lookup. openFDA answers "no result" with HTTP 404, which is a
/// legitimate no-match; anything else is treated as an outage.
/// </summary>
public sealed class OpenFdaDrugDataProvider : IDrugDataProvider
{
    public const string ProviderName = "openfda";

    private readonly HttpClient _httpClient;
    private readonly IIngredientNormalizer _normalizer;
    private readonly IDateTimeProvider _clock;
    private readonly DrugDataOptions _options;
    private readonly ILogger<OpenFdaDrugDataProvider> _logger;

    public OpenFdaDrugDataProvider(
        HttpClient httpClient,
        IIngredientNormalizer normalizer,
        IDateTimeProvider clock,
        IOptions<DrugDataOptions> options,
        ILogger<OpenFdaDrugDataProvider> logger)
    {
        _httpClient = httpClient;
        _normalizer = normalizer;
        _clock = clock;
        _options = options.Value;
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

        var escaped = Uri.EscapeDataString($"(openfda.brand_name:\"{term}\" OR openfda.generic_name:\"{term}\")");
        var url = $"drug/label.json?search={escaped}&limit=5";

        if (!string.IsNullOrWhiteSpace(_options.OpenFdaApiKey))
        {
            url += $"&api_key={Uri.EscapeDataString(_options.OpenFdaApiKey)}";
        }

        try
        {
            using var response = await _httpClient.GetAsync(url, cancellationToken).ConfigureAwait(false);

            if (response.StatusCode == HttpStatusCode.NotFound)
            {
                return DrugSearchResult.NoMatch();
            }

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("openFDA responded with {StatusCode}.", (int)response.StatusCode);
                return DrugSearchResult.Unavailable();
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var candidates = ParseCandidates(document, request);
            return candidates.Count == 0 ? DrugSearchResult.NoMatch() : DrugSearchResult.Matched(candidates);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "openFDA lookup failed.");
            return DrugSearchResult.Unavailable();
        }
    }

    public Task<DrugDetails?> GetDrugAsync(string externalId, CancellationToken cancellationToken) =>
        Task.FromResult<DrugDetails?>(null);

    private List<DrugCandidate> ParseCandidates(JsonDocument document, DrugSearchRequest request)
    {
        var candidates = new List<DrugCandidate>();

        if (!document.RootElement.TryGetProperty("results", out var results) || results.ValueKind != JsonValueKind.Array)
        {
            return candidates;
        }

        foreach (var result in results.EnumerateArray())
        {
            var openFda = result.TryGetProperty("openfda", out var openFdaElement) ? openFdaElement : default;

            var brandName = FirstString(openFda, "brand_name");
            var genericName = FirstString(openFda, "generic_name");
            var manufacturer = FirstString(openFda, "manufacturer_name");
            var rxCui = FirstString(openFda, "rxcui");
            var externalId = FirstString(openFda, "spl_set_id") ?? FirstString(openFda, "product_ndc");
            var dosageForm = FirstString(openFda, "dosage_form") ?? FirstString(openFda, "route");

            var ingredientPhrases = ReadStringArray(result, "active_ingredient")
                .SelectMany(IngredientTextParser.SplitIngredientList)
                .Select(IngredientTextParser.Parse)
                .Where(parsed => !string.IsNullOrWhiteSpace(parsed.Name))
                .ToList();

            if (string.IsNullOrWhiteSpace(brandName) && string.IsNullOrWhiteSpace(genericName))
            {
                continue;
            }

            var ingredients = ingredientPhrases
                .Select(parsed => _normalizer.Normalize(parsed.Name, parsed.Strength, parsed.Unit, null))
                .ToList();

            var identity = new DrugIdentity(
                rxCui,
                brandName ?? genericName ?? string.Empty,
                genericName ?? brandName ?? string.Empty,
                ingredients,
                dosageForm,
                ingredients.Count == 1 && ingredients[0].Strength is not null
                    ? $"{ingredients[0].Strength} {ingredients[0].Unit}".Trim()
                    : null,
                manufacturer,
                new DataProvenance(ProviderName, externalId, _clock.UtcNow, "openfda-drug-label"));

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

        return candidates.OrderByDescending(candidate => candidate.MatchScore).Take(5).ToList();
    }

    private static string? FirstString(JsonElement element, string propertyName)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(propertyName, out var property))
        {
            return null;
        }

        return property.ValueKind switch
        {
            JsonValueKind.String => property.GetString(),
            JsonValueKind.Array => property.EnumerateArray().FirstOrDefault().GetString(),
            _ => null
        };
    }

    private static IEnumerable<string> ReadStringArray(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var property) || property.ValueKind != JsonValueKind.Array)
        {
            yield break;
        }

        foreach (var item in property.EnumerateArray())
        {
            var value = item.GetString();
            if (!string.IsNullOrWhiteSpace(value))
            {
                yield return value;
            }
        }
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
