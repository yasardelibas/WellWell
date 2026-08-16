using System.Net.Http.Json;
using System.Text.Json;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Ai;
using MedGuard.Application.Telemetry;
using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Ai;

/// <summary>
/// Explanation layer. It receives a finding the deterministic engine already produced,
/// asks the model to rephrase it, and rejects any output that drifts into clinical advice.
/// Every failure path degrades to the deterministic template, so explanations can never
/// block or alter a safety result.
/// </summary>
public sealed class OpenAiExplanationService : IMedicationExplanationService
{
    private readonly HttpClient _httpClient;
    private readonly AiOptions _options;
    private readonly TemplateExplanationService _fallback;
    private readonly ILogger<OpenAiExplanationService> _logger;

    public OpenAiExplanationService(
        HttpClient httpClient,
        IOptions<AiOptions> options,
        TemplateExplanationService fallback,
        ILogger<OpenAiExplanationService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _fallback = fallback;
        _logger = logger;
    }

    public async Task<MedicationExplanation> ExplainAsync(SafetyFinding finding, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(finding);

        if (!_options.ExplanationsEnabled || string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            return await FallbackAsync(finding, language, "not-configured", cancellationToken).ConfigureAwait(false);
        }

        try
        {
            var payload = new
            {
                model = _options.ExplanationModel,
                temperature = 0.2,
                max_tokens = 300,
                messages = new object[]
                {
                    new { role = "system", content = ExplanationPrompt.SystemPrompt },
                    new { role = "user", content = ExplanationPrompt.BuildUserMessage(finding, language) }
                }
            };

            using var response = await _httpClient
                .PostAsJsonAsync("chat/completions", payload, cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Explanation model returned {StatusCode}.", (int)response.StatusCode);
                return await FallbackAsync(finding, language, "provider-error", cancellationToken).ConfigureAwait(false);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var text = document.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString()
                ?.Trim();

            var guard = ExplanationGuard.Inspect(text);
            if (!guard.IsAllowed)
            {
                _logger.LogWarning("Generated explanation rejected by output guard: {Rule}.", guard.ViolatedRule);
                return await FallbackAsync(finding, language, "guard-rejected", cancellationToken).ConfigureAwait(false);
            }

            MedGuardTelemetry.ExplanationRequests.Add(1, new KeyValuePair<string, object?>("source", "model"));

            return new MedicationExplanation(text!, GeneratedByAi: true, $"model:{_options.ExplanationModel}");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "Explanation model call failed.");
            return await FallbackAsync(finding, language, "provider-unreachable", cancellationToken).ConfigureAwait(false);
        }
    }

    private async Task<MedicationExplanation> FallbackAsync(SafetyFinding finding, string? language, string reason, CancellationToken cancellationToken)
    {
        MedGuardTelemetry.ExplanationRequests.Add(
            1,
            new KeyValuePair<string, object?>("source", "template"),
            new KeyValuePair<string, object?>("reason", reason));

        return await _fallback.ExplainAsync(finding, language, cancellationToken).ConfigureAwait(false);
    }
}
