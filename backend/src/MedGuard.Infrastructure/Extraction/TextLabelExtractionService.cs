using System.Text.RegularExpressions;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;

namespace MedGuard.Infrastructure.Extraction;

/// <summary>
/// Deterministic extraction from OCR text produced on the device. This is the offline path:
/// it never needs a model, and every value it returns carries a confidence that reflects
/// whether the value was explicitly labelled or merely inferred.
/// </summary>
public sealed class TextLabelExtractionService : ILabelExtractionService
{
    public const string SourceName = "ocr-text";

    private static readonly Regex StrengthLine = new(
        @"\d+(?:[.,]\d+)?\s*(mg|mcg|µg|ug|g|ml|iu|units?|%)",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly Regex ExpirationPattern = new(
        @"(?:exp(?:iry|ires|iration)?|use before|son kullanma)\D{0,12}(?<date>(\d{1,2}[./-])?\d{1,2}[./-]\d{2,4})",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly string[] DosageForms =
    {
        "film-coated tablet", "effervescent tablet", "chewable tablet", "extended release tablet",
        "tablet", "capsule", "caplet", "softgel", "syrup", "suspension", "solution", "drops",
        "cream", "ointment", "gel", "patch", "inhaler", "spray", "suppository", "injection", "sachet"
    };

    private static readonly string[] RouteKeywords =
    {
        "oral", "topical", "intravenous", "intramuscular", "subcutaneous", "nasal",
        "ophthalmic", "otic", "rectal", "inhalation", "sublingual"
    };

    /// <summary>Matches a labelled ingredient section and the separator that follows it.</summary>
    private static readonly Regex IngredientSectionMarker = new(
        @"(active\s+ingredients?|etkin\s+madde(ler)?|principio\s+activo|wirkstoffe?|composition|contains)\s*[:\-–]?\s*",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly string[] DirectionMarkers =
    {
        "take ", "directions", "dosage", "dose:", "use:", "recommended", "swallow", "apply",
        "times a day", "times daily", "twice", "once daily", "every "
    };

    private static readonly string[] ManufacturerMarkers =
    {
        "manufactured by", "manufacturer", "mfg by", "marketed by", "distributed by", "üretici"
    };

    private readonly IIngredientNormalizer _normalizer;

    public TextLabelExtractionService(IIngredientNormalizer normalizer) => _normalizer = normalizer;

    public string Name => SourceName;

    public Task<LabelExtraction> ExtractAsync(LabelExtractionInput input, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(input.OcrText))
        {
            return Task.FromResult(LabelExtraction.Failed(
                SourceName,
                "No readable text was provided for this label."));
        }

        var lines = input.OcrText
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Trim())
            .Where(line => line.Length > 1)
            .ToList();

        if (lines.Count == 0)
        {
            return Task.FromResult(LabelExtraction.Failed(SourceName, "We couldn't read the label clearly."));
        }

        var ingredients = ReadIngredients(lines);
        var brand = ReadBrandName(lines);
        var generic = ReadGenericName(ingredients);
        var dosageForm = ReadKeyword(lines, DosageForms, 0.8);
        var route = ReadKeyword(lines, RouteKeywords, 0.7);
        var directions = ReadDirections(lines);
        var manufacturer = ReadManufacturer(lines);
        var expiration = ReadExpiration(input.OcrText);

        var succeeded = brand.HasValue || generic.HasValue || ingredients.Count > 0;

        var extraction = new LabelExtraction(
            brand,
            generic,
            ingredients,
            dosageForm,
            route,
            directions,
            manufacturer,
            expiration,
            SourceName,
            succeeded,
            succeeded ? null : "We couldn't read the label clearly.");

        return Task.FromResult(extraction);
    }

    private List<ExtractedIngredientValue> ReadIngredients(IReadOnlyList<string> lines)
    {
        var results = new List<ExtractedIngredientValue>();

        for (var index = 0; index < lines.Count; index++)
        {
            var line = lines[index];
            var marker = IngredientSectionMarker.Match(line);

            if (!marker.Success)
            {
                continue;
            }

            var payload = line[(marker.Index + marker.Length)..];

            if (payload.Length < 3 && index + 1 < lines.Count)
            {
                payload = lines[index + 1];
            }

            // Explicitly labelled ingredient sections are the strongest signal on a label.
            results.AddRange(ParsePhrases(payload, 0.92));
        }

        if (results.Count > 0)
        {
            return Deduplicate(results);
        }

        foreach (var line in lines.Where(line => StrengthLine.IsMatch(line)))
        {
            results.AddRange(ParsePhrases(line, 0.68));
        }

        return Deduplicate(results);
    }

    private IEnumerable<ExtractedIngredientValue> ParsePhrases(string payload, double confidence) =>
        IngredientTextParser
            .SplitIngredientList(payload)
            .Select(IngredientTextParser.Parse)
            .Where(parsed => !string.IsNullOrWhiteSpace(parsed.Name) && parsed.Name.Length > 2)
            .Where(parsed => !string.IsNullOrWhiteSpace(_normalizer.Normalize(parsed.Name)))
            .Select(parsed => new ExtractedIngredientValue(
                new ExtractedValue(parsed.Name, confidence, SourceName),
                parsed.Strength is null ? null : new ExtractedValue(parsed.Strength.Value.ToString("0.##"), confidence, SourceName),
                parsed.Unit is null ? null : new ExtractedValue(parsed.Unit, confidence, SourceName)));

    private static List<ExtractedIngredientValue> Deduplicate(IEnumerable<ExtractedIngredientValue> ingredients) =>
        ingredients
            .GroupBy(ingredient => ingredient.Name.Value?.ToLowerInvariant() ?? string.Empty)
            .Select(group => group.OrderByDescending(item => item.Name.Confidence).First())
            .Take(6)
            .ToList();

    private static ExtractedValue ReadBrandName(IReadOnlyList<string> lines)
    {
        var trademarked = lines.FirstOrDefault(line => line.Contains('®') || line.Contains('™'));
        if (trademarked is not null)
        {
            return new ExtractedValue(trademarked.Trim('®', '™', ' '), 0.88, SourceName);
        }

        var candidate = lines.FirstOrDefault(line =>
            line.Length is > 2 and < 40 &&
            line.Count(char.IsLetter) >= 3 &&
            !StrengthLine.IsMatch(line) &&
            line.Count(char.IsUpper) >= line.Count(char.IsLetter) / 2);

        return candidate is null
            ? ExtractedValue.Empty(SourceName)
            : new ExtractedValue(Capitalize(candidate), 0.55, SourceName);
    }

    private ExtractedValue ReadGenericName(IReadOnlyCollection<ExtractedIngredientValue> ingredients)
    {
        if (ingredients.Count == 0)
        {
            return ExtractedValue.Empty(SourceName);
        }

        var names = ingredients
            .Select(ingredient => _normalizer.ToDisplayName(_normalizer.Normalize(ingredient.Name.Value ?? string.Empty)))
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .ToList();

        return names.Count == 0
            ? ExtractedValue.Empty(SourceName)
            : new ExtractedValue(string.Join(" / ", names), ingredients.Min(i => i.Name.Confidence), SourceName);
    }

    private static ExtractedValue ReadKeyword(IReadOnlyList<string> lines, IReadOnlyList<string> keywords, double confidence)
    {
        foreach (var keyword in keywords)
        {
            if (lines.Any(line => line.Contains(keyword, StringComparison.OrdinalIgnoreCase)))
            {
                return new ExtractedValue(Capitalize(keyword), confidence, SourceName);
            }
        }

        return ExtractedValue.Empty(SourceName);
    }

    private static ExtractedValue ReadDirections(IReadOnlyList<string> lines)
    {
        var line = lines.FirstOrDefault(candidate =>
            DirectionMarkers.Any(marker => candidate.Contains(marker, StringComparison.OrdinalIgnoreCase)));

        return line is null
            ? ExtractedValue.Empty(SourceName)
            : new ExtractedValue(CleanDirections(line), 0.85, SourceName);
    }

    private static ExtractedValue ReadManufacturer(IReadOnlyList<string> lines)
    {
        foreach (var marker in ManufacturerMarkers)
        {
            var line = lines.FirstOrDefault(candidate => candidate.Contains(marker, StringComparison.OrdinalIgnoreCase));
            if (line is null)
            {
                continue;
            }

            var index = line.IndexOf(marker, StringComparison.OrdinalIgnoreCase) + marker.Length;
            var value = line[index..].Trim(':', '-', ' ', '.');

            if (value.Length > 1)
            {
                return new ExtractedValue(value, 0.7, SourceName);
            }
        }

        return ExtractedValue.Empty(SourceName);
    }

    private static ExtractedValue ReadExpiration(string text)
    {
        var match = ExpirationPattern.Match(text);
        return match.Success
            ? new ExtractedValue(match.Groups["date"].Value, 0.75, SourceName)
            : ExtractedValue.Empty(SourceName);
    }

    private static string CleanDirections(string line)
    {
        var cleaned = line.Trim();
        foreach (var prefix in new[] { "Directions:", "Dosage:", "Dose:", "Use:" })
        {
            if (cleaned.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                cleaned = cleaned[prefix.Length..].Trim();
            }
        }

        return cleaned;
    }

    private static string Capitalize(string value) =>
        value.Length <= 1 ? value.ToUpperInvariant() : char.ToUpperInvariant(value[0]) + value[1..].ToLowerInvariant();
}
