using System.Net.Http.Json;
using System.Text.Json;
using MedGuard.Application.Ai;
using MedGuard.Application.Insights;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Ai;

/// <summary>
/// Encouragement layer for adherence. It receives deterministic counts, asks the model to
/// rephrase them into one warm sentence, and rejects any output that drifts into clinical
/// advice. Every failure path degrades to the deterministic template, so the insight can
/// never block a screen or turn into medical instruction.
/// </summary>
public sealed class OpenAiAdherenceInsightService : IAdherenceInsightService
{
    private const int MaxTokens = 120;

    private readonly HttpClient _httpClient;
    private readonly AiOptions _options;
    private readonly TemplateAdherenceInsightService _fallback;
    private readonly ILogger<OpenAiAdherenceInsightService> _logger;

    public OpenAiAdherenceInsightService(
        HttpClient httpClient,
        IOptions<AiOptions> options,
        TemplateAdherenceInsightService fallback,
        ILogger<OpenAiAdherenceInsightService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _fallback = fallback;
        _logger = logger;
    }

    public Task<AdherenceInsight> SummarizeWeekAsync(AdherenceStats stats, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return GenerateAsync(
            AdherenceInsightPrompt.BuildWeeklyMessage(stats),
            () => TemplateAdherenceInsightService.BuildWeekly(stats),
            cancellationToken);
    }

    public Task<AdherenceInsight> DailyNudgeAsync(DailyAdherenceStats stats, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return GenerateAsync(
            AdherenceInsightPrompt.BuildDailyMessage(stats),
            () => TemplateAdherenceInsightService.BuildDaily(stats),
            cancellationToken);
    }

    public Task<AdherenceInsight> SummarizeInsightsAsync(AdherenceInsightsInput input, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        return GenerateAsync(
            AdherenceInsightPrompt.BuildInsightsMessage(input),
            () => TemplateAdherenceInsightService.BuildInsights(input),
            cancellationToken);
    }

    private async Task<AdherenceInsight> GenerateAsync(
        string userMessage,
        Func<string> fallbackText,
        CancellationToken cancellationToken)
    {
        if (!_options.ExplanationsEnabled || string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            return Fallback(fallbackText);
        }

        try
        {
            var payload = new
            {
                model = _options.ExplanationModel,
                temperature = 0.5,
                max_tokens = MaxTokens,
                messages = new object[]
                {
                    new { role = "system", content = AdherenceInsightPrompt.SystemPrompt },
                    new { role = "user", content = userMessage },
                },
            };

            using var response = await _httpClient
                .PostAsJsonAsync("chat/completions", payload, cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Adherence insight model returned {StatusCode}.", (int)response.StatusCode);
                return Fallback(fallbackText);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var text = document.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString()
                ?.Trim();

            // The insight text is subject to the same clinical-advice guard as explanations.
            var guard = ExplanationGuard.Inspect(text);
            if (!guard.IsAllowed)
            {
                _logger.LogWarning("Generated adherence insight rejected by output guard: {Rule}.", guard.ViolatedRule);
                return Fallback(fallbackText);
            }

            return new AdherenceInsight(text!, GeneratedByAi: true, $"model:{_options.ExplanationModel}");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "Adherence insight model call failed.");
            return Fallback(fallbackText);
        }
    }

    private AdherenceInsight Fallback(Func<string> fallbackText) =>
        new(fallbackText(), GeneratedByAi: false, TemplateAdherenceInsightService.SourceName);
}
