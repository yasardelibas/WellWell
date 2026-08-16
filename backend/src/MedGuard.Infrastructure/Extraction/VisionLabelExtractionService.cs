using System.Net.Http.Json;
using System.Text.Json;
using MedGuard.Application.Abstractions;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Extraction;

/// <summary>
/// Multimodal label reading. The model is used strictly as an OCR/structuring step: it is
/// told to transcribe, never to interpret, and its output still goes through database
/// verification and explicit user confirmation before anything is saved.
/// </summary>
public sealed class VisionLabelExtractionService : ILabelExtractionService
{
    public const string SourceName = "vision";

    /// <summary>Self-reported model confidence is capped: a model cannot certify its own reading.</summary>
    private const double MaxConfidence = 0.9d;

    private const string SystemPrompt = """
        You transcribe medication labels for a medication safety application.

        Return only what is printed on the label. Never infer, translate, correct or complete a
        value that is not visible. Never add medical advice, warnings or interpretation.

        Respond with a single JSON object of exactly this shape:
        {
          "brandName": {"value": string|null, "confidence": number},
          "genericName": {"value": string|null, "confidence": number},
          "activeIngredients": [
            {"name": string, "strength": string|null, "unit": string|null, "confidence": number}
          ],
          "dosageForm": {"value": string|null, "confidence": number},
          "route": {"value": string|null, "confidence": number},
          "directions": {"value": string|null, "confidence": number},
          "manufacturer": {"value": string|null, "confidence": number},
          "expirationDate": {"value": string|null, "confidence": number}
        }

        confidence is your reading certainty between 0 and 1. Use a low confidence when the text
        is blurred, cropped or ambiguous. Use null when a field is not visible on the label.
        """;

    private readonly HttpClient _httpClient;
    private readonly AiOptions _options;
    private readonly ILabelExtractionService _textFallback;
    private readonly ILogger<VisionLabelExtractionService> _logger;

    public VisionLabelExtractionService(
        HttpClient httpClient,
        IOptions<AiOptions> options,
        TextLabelExtractionService textFallback,
        ILogger<VisionLabelExtractionService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _textFallback = textFallback;
        _logger = logger;
    }

    public string Name => SourceName;

    public async Task<LabelExtraction> ExtractAsync(LabelExtractionInput input, CancellationToken cancellationToken)
    {
        if (!_options.VisionEnabled || string.IsNullOrWhiteSpace(_options.ApiKey) || input.ImageBytes is null)
        {
            return await _textFallback.ExtractAsync(input, cancellationToken).ConfigureAwait(false);
        }

        try
        {
            var dataUri = $"data:{input.MimeType ?? "image/jpeg"};base64,{Convert.ToBase64String(input.ImageBytes)}";

            var payload = new
            {
                model = _options.VisionModel,
                temperature = 0,
                response_format = new { type = "json_object" },
                messages = new object[]
                {
                    new { role = "system", content = SystemPrompt },
                    new
                    {
                        role = "user",
                        content = new object[]
                        {
                            new { type = "text", text = "Transcribe this medication label." },
                            new { type = "image_url", image_url = new { url = dataUri } }
                        }
                    }
                }
            };

            using var response = await _httpClient
                .PostAsJsonAsync("chat/completions", payload, cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Vision extraction returned {StatusCode}; falling back to text extraction.", (int)response.StatusCode);
                return await FallbackAsync(input, cancellationToken).ConfigureAwait(false);
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var content = document.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            if (string.IsNullOrWhiteSpace(content))
            {
                return await FallbackAsync(input, cancellationToken).ConfigureAwait(false);
            }

            return Parse(content);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "Vision extraction failed; falling back to text extraction.");
            return await FallbackAsync(input, cancellationToken).ConfigureAwait(false);
        }
    }

    private async Task<LabelExtraction> FallbackAsync(LabelExtractionInput input, CancellationToken cancellationToken)
    {
        var fallback = await _textFallback.ExtractAsync(input, cancellationToken).ConfigureAwait(false);

        return fallback.Succeeded
            ? fallback
            : LabelExtraction.Failed(SourceName, "We couldn't read the label clearly.");
    }

    private static LabelExtraction Parse(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;

        var ingredients = new List<ExtractedIngredientValue>();
        if (root.TryGetProperty("activeIngredients", out var ingredientArray) &&
            ingredientArray.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in ingredientArray.EnumerateArray())
            {
                var name = ReadString(item, "name");
                if (string.IsNullOrWhiteSpace(name))
                {
                    continue;
                }

                var confidence = ReadConfidence(item);

                ingredients.Add(new ExtractedIngredientValue(
                    new ExtractedValue(name, confidence, SourceName),
                    Wrap(ReadString(item, "strength"), confidence),
                    Wrap(ReadString(item, "unit"), confidence)));
            }
        }

        var extraction = new LabelExtraction(
            ReadField(root, "brandName"),
            ReadField(root, "genericName"),
            ingredients,
            ReadField(root, "dosageForm"),
            ReadField(root, "route"),
            ReadField(root, "directions"),
            ReadField(root, "manufacturer"),
            ReadField(root, "expirationDate"),
            SourceName,
            Succeeded: true,
            FailureReason: null);

        var hasAnything = extraction.BrandName.HasValue || extraction.GenericName.HasValue || ingredients.Count > 0;

        return hasAnything
            ? extraction
            : LabelExtraction.Failed(SourceName, "We couldn't read the label clearly.");
    }

    private static ExtractedValue ReadField(JsonElement root, string propertyName)
    {
        if (!root.TryGetProperty(propertyName, out var element) || element.ValueKind != JsonValueKind.Object)
        {
            return ExtractedValue.Empty(SourceName);
        }

        var value = ReadString(element, "value");
        return string.IsNullOrWhiteSpace(value)
            ? ExtractedValue.Empty(SourceName)
            : new ExtractedValue(value, ReadConfidence(element), SourceName);
    }

    private static ExtractedValue? Wrap(string? value, double confidence) =>
        string.IsNullOrWhiteSpace(value) ? null : new ExtractedValue(value, confidence, SourceName);

    private static string? ReadString(JsonElement element, string propertyName) =>
        element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString()
            : null;

    private static double ReadConfidence(JsonElement element)
    {
        if (!element.TryGetProperty("confidence", out var property) ||
            property.ValueKind != JsonValueKind.Number ||
            !property.TryGetDouble(out var confidence))
        {
            return 0.5d;
        }

        return Math.Clamp(confidence, 0d, MaxConfidence);
    }
}
