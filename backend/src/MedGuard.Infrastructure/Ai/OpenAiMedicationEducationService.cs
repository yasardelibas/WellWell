using System.Net.Http.Json;
using System.Text.Json;
using MedGuard.Application.Ai;
using MedGuard.Application.Education;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Ai;

/// <summary>
/// Education layer. It asks the model for a short, general description of what a medication
/// is commonly used for, and rejects any output that drifts into clinical advice via the
/// shared output guard. Every failure path (disabled, unreachable, unknown drug, guard
/// rejection) degrades to the deterministic template, so education can never turn into
/// personal medical instruction.
/// </summary>
public sealed class OpenAiMedicationEducationService : IMedicationEducationService
{
    private const int MaxTokens = 220;

    private readonly HttpClient _httpClient;
    private readonly AiOptions _options;
    private readonly TemplateMedicationEducationService _fallback;
    private readonly ILogger<OpenAiMedicationEducationService> _logger;

    public OpenAiMedicationEducationService(
        HttpClient httpClient,
        IOptions<AiOptions> options,
        TemplateMedicationEducationService fallback,
        ILogger<OpenAiMedicationEducationService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _fallback = fallback;
        _logger = logger;
    }

    public async Task<MedicationEducation> ExplainAsync(MedicationEducationInput input, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);

        if (!_options.ExplanationsEnabled || string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            return await _fallback.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);
        }

        try
        {
            var payload = new
            {
                model = _options.ExplanationModel,
                temperature = 0.3,
                max_tokens = MaxTokens,
                messages = new object[]
                {
                    new { role = "system", content = MedicationEducationPrompt.SystemPrompt },
                    new { role = "user", content = MedicationEducationPrompt.BuildUserMessage(input, language) },
                },
            };

            using var response = await _httpClient
                .PostAsJsonAsync("chat/completions", payload, cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Education model returned {StatusCode}.", (int)response.StatusCode);
                return await _fallback.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var text = document.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString()
                ?.Trim();

            // The model returns a sentinel when it does not recognise the drug; never guess.
            if (string.IsNullOrWhiteSpace(text) ||
                text.Contains(MedicationEducationPrompt.UnknownMarker, StringComparison.OrdinalIgnoreCase))
            {
                return await _fallback.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);
            }

            // Education text is subject to the same clinical-advice guard as explanations.
            var guard = ExplanationGuard.Inspect(text);
            if (!guard.IsAllowed)
            {
                _logger.LogWarning("Generated education rejected by output guard: {Rule}.", guard.ViolatedRule);
                return await _fallback.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);
            }

            return new MedicationEducation(text!, GeneratedByAi: true, IsAvailable: true, $"model:{_options.ExplanationModel}");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "Education model call failed.");
            return await _fallback.ExplainAsync(input, language, cancellationToken).ConfigureAwait(false);
        }
    }
}
