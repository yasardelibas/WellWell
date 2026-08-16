namespace MedGuard.Application.Abstractions;

/// <summary>A single value read from a label, always carrying confidence metadata.</summary>
public sealed record ExtractedValue(string? Value, double Confidence, string Source)
{
    public static ExtractedValue Empty(string source) => new(null, 0d, source);

    public bool HasValue => !string.IsNullOrWhiteSpace(Value);
}

public sealed record ExtractedIngredientValue(
    ExtractedValue Name,
    ExtractedValue? Strength,
    ExtractedValue? Unit);

public sealed record LabelExtractionInput(
    byte[]? ImageBytes,
    string? MimeType,
    string? OcrText);

public sealed record LabelExtraction(
    ExtractedValue BrandName,
    ExtractedValue GenericName,
    IReadOnlyCollection<ExtractedIngredientValue> ActiveIngredients,
    ExtractedValue DosageForm,
    ExtractedValue Route,
    ExtractedValue Directions,
    ExtractedValue Manufacturer,
    ExtractedValue ExpirationDate,
    string Source,
    bool Succeeded,
    string? FailureReason)
{
    public static LabelExtraction Failed(string source, string reason) => new(
        ExtractedValue.Empty(source),
        ExtractedValue.Empty(source),
        Array.Empty<ExtractedIngredientValue>(),
        ExtractedValue.Empty(source),
        ExtractedValue.Empty(source),
        ExtractedValue.Empty(source),
        ExtractedValue.Empty(source),
        ExtractedValue.Empty(source),
        source,
        Succeeded: false,
        FailureReason: reason);

    /// <summary>
    /// Overall confidence: the weakest identifying signal wins, so a single shaky
    /// ingredient reading still forces manual review.
    /// </summary>
    public double OverallConfidence
    {
        get
        {
            if (!Succeeded)
            {
                return 0d;
            }

            var signals = new List<double>();
            if (BrandName.HasValue)
            {
                signals.Add(BrandName.Confidence);
            }

            if (GenericName.HasValue)
            {
                signals.Add(GenericName.Confidence);
            }

            signals.AddRange(ActiveIngredients.Where(i => i.Name.HasValue).Select(i => i.Name.Confidence));

            return signals.Count == 0 ? 0d : Math.Round(signals.Min(), 2);
        }
    }
}

public interface ILabelExtractionService
{
    string Name { get; }

    Task<LabelExtraction> ExtractAsync(LabelExtractionInput input, CancellationToken cancellationToken);
}
