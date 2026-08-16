using System.Text.Json;
using MedGuard.Application.Abstractions;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Drugs;

/// <summary>
/// RxClass (RxNav) classification lookup. It resolves the conditions a drug "may treat"
/// (MED-RT) and its ATC therapeutic class. Transport and parsing failures degrade to
/// <see cref="DrugClassification.Empty"/> so a failure can never look like authoritative
/// "no uses". This is deterministic, cited data — never AI output.
/// </summary>
public sealed class RxClassDrugClassificationProvider : IDrugClassificationProvider
{
    private const int MaxUses = 5;

    private readonly HttpClient _httpClient;
    private readonly ILogger<RxClassDrugClassificationProvider> _logger;

    public RxClassDrugClassificationProvider(
        HttpClient httpClient,
        ILogger<RxClassDrugClassificationProvider> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<DrugClassification> GetByRxCuiAsync(string rxCui, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(rxCui))
        {
            return DrugClassification.Empty;
        }

        var uses = await FetchMayTreatAsync(rxCui, cancellationToken).ConfigureAwait(false);
        var pharmacologicClass = await FetchAtcClassAsync(rxCui, cancellationToken).ConfigureAwait(false);

        return new DrugClassification(uses, pharmacologicClass);
    }

    private async Task<IReadOnlyList<string>> FetchMayTreatAsync(string rxCui, CancellationToken cancellationToken)
    {
        var document = await GetAsync(
            $"class/byRxcui.json?rxcui={Uri.EscapeDataString(rxCui)}&relaSource=MEDRT&rela=may_treat",
            cancellationToken).ConfigureAwait(false);

        if (document is null)
        {
            return Array.Empty<string>();
        }

        using (document)
        {
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var uses = new List<string>();

            // The server-side rela filter is unreliable and mixes in other relationships
            // (ci_with, may_prevent), ingredient names and class names. Showing those as
            // "used for" would be misleading or unsafe, so we keep ONLY genuine may_treat
            // diseases and drop everything else.
            foreach (var entry in EnumerateEntries(document))
            {
                if (!string.Equals(entry.Rela, "may_treat", StringComparison.OrdinalIgnoreCase) ||
                    !string.Equals(entry.ClassType, "DISEASE", StringComparison.OrdinalIgnoreCase) ||
                    string.IsNullOrWhiteSpace(entry.ClassName) ||
                    !seen.Add(entry.ClassName))
                {
                    continue;
                }

                uses.Add(TitleCase(entry.ClassName));
                if (uses.Count >= MaxUses)
                {
                    break;
                }
            }

            return uses;
        }
    }

    private async Task<string?> FetchAtcClassAsync(string rxCui, CancellationToken cancellationToken)
    {
        var document = await GetAsync(
            $"class/byRxcui.json?rxcui={Uri.EscapeDataString(rxCui)}&relaSource=ATC",
            cancellationToken).ConfigureAwait(false);

        if (document is null)
        {
            return null;
        }

        using (document)
        {
            // ATC is a hierarchy; the deepest level (longest class id) is the most specific,
            // consumer-meaningful therapeutic class, e.g. "Selective serotonin (5HT1) agonists".
            string? bestName = null;
            var bestDepth = -1;

            foreach (var entry in EnumerateEntries(document))
            {
                if (string.IsNullOrWhiteSpace(entry.ClassName) ||
                    entry.ClassType is null ||
                    !entry.ClassType.StartsWith("ATC", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var depth = entry.ClassId?.Length ?? 0;
                if (depth > bestDepth)
                {
                    bestDepth = depth;
                    bestName = entry.ClassName.Trim();
                }
            }

            return TitleCaseIfUpper(bestName);
        }
    }

    private async Task<JsonDocument?> GetAsync(string requestUri, CancellationToken cancellationToken)
    {
        try
        {
            using var response = await _httpClient.GetAsync(requestUri, cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("RxClass responded with {StatusCode}.", (int)response.StatusCode);
                return null;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            return await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "RxClass lookup failed.");
            return null;
        }
    }

    private static IEnumerable<(string? Rela, string? ClassType, string? ClassName, string? ClassId)> EnumerateEntries(JsonDocument document)
    {
        if (!document.RootElement.TryGetProperty("rxclassDrugInfoList", out var list) ||
            !list.TryGetProperty("rxclassDrugInfo", out var infos) ||
            infos.ValueKind != JsonValueKind.Array)
        {
            yield break;
        }

        foreach (var info in infos.EnumerateArray())
        {
            var rela = info.TryGetProperty("rela", out var relaElement) ? relaElement.GetString() : null;

            if (!info.TryGetProperty("rxclassMinConceptItem", out var item) || item.ValueKind != JsonValueKind.Object)
            {
                continue;
            }

            var className = item.TryGetProperty("className", out var nameElement) ? nameElement.GetString() : null;
            var classType = item.TryGetProperty("classType", out var typeElement) ? typeElement.GetString() : null;
            var classId = item.TryGetProperty("classId", out var idElement) ? idElement.GetString() : null;

            yield return (rela, classType, className, classId);
        }
    }

    private static string TitleCase(string value) => TitleCaseIfUpper(value) ?? value;

    /// <summary>ATC names arrive in ALL CAPS; normalise those to Title Case for display.</summary>
    private static string? TitleCaseIfUpper(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        var trimmed = value.Trim();
        if (trimmed.Any(char.IsLower))
        {
            return trimmed;
        }

        return string.Join(
            ' ',
            trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Select(word => word.Length <= 1
                    ? word.ToUpperInvariant()
                    : char.ToUpperInvariant(word[0]) + word[1..].ToLowerInvariant()));
    }
}
