using System.Security.Cryptography;
using System.Text;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Education;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Ai;

/// <summary>
/// Cache-aside layer in front of the education service. A medication's general "what is this
/// used for" text is identical for every user who takes the same drug, so once it has been
/// generated it is served from the shared cache (Redis when configured, otherwise the
/// distributed in-memory store) instead of calling the model again. Only successful,
/// AI-generated answers are cached; deterministic fallbacks (model disabled, rate limited,
/// out of credits, guard rejection) are never cached so the richer answer is produced as soon
/// as the model is reachable again.
/// </summary>
public sealed class CachingMedicationEducationService : IMedicationEducationService
{
    // Education is stable per drug, so a long TTL keeps us off the model for known medications.
    private static readonly TimeSpan CacheTtl = TimeSpan.FromDays(30);

    private readonly IMedicationEducationService _inner;
    private readonly ICacheStore _cache;
    private readonly ILogger<CachingMedicationEducationService> _logger;

    public CachingMedicationEducationService(
        IMedicationEducationService inner,
        ICacheStore cache,
        ILogger<CachingMedicationEducationService> logger)
    {
        _inner = inner;
        _cache = cache;
        _logger = logger;
    }

    public async Task<MedicationEducation> ExplainAsync(
        MedicationEducationInput input,
        string? language,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);

        var key = BuildKey(input, language);

        var cached = await _cache.GetAsync<MedicationEducation>(key, cancellationToken).ConfigureAwait(false);
        if (cached is not null)
        {
            _logger.LogDebug("Education cache hit for {Key}.", key);
            return cached;
        }

        var result = await _inner.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);

        // Only persist real model output; keep degraded fallbacks out of the cache.
        if (result.IsAvailable && result.GeneratedByAi)
        {
            await _cache.SetAsync(key, result, CacheTtl, cancellationToken).ConfigureAwait(false);
        }

        return result;
    }

    /// <summary>
    /// Key on the anonymous drug identity (generic name or display name + active ingredients)
    /// and the response language, so the same medication in the same language reuses one entry
    /// regardless of which user requests it.
    /// </summary>
    private static string BuildKey(MedicationEducationInput input, string? language)
    {
        var lang = string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase) ? "tr" : "en";
        var drug = string.IsNullOrWhiteSpace(input.GenericName) ? input.DisplayName : input.GenericName!;

        var ingredients = input.Ingredients is { Count: > 0 }
            ? string.Join(
                ",",
                input.Ingredients
                    .Where(name => !string.IsNullOrWhiteSpace(name))
                    .Select(name => name.Trim().ToLowerInvariant())
                    .OrderBy(name => name, StringComparer.Ordinal))
            : string.Empty;

        var raw = $"{drug.Trim().ToLowerInvariant()}|{ingredients}|{lang}";
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(raw)))[..32].ToLowerInvariant();
        return $"med-education:{hash}";
    }
}
