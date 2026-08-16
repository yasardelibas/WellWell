using System.Globalization;
using System.Text.RegularExpressions;

namespace MedGuard.Application.Medications;

public sealed record ParsedIngredientText(string Name, decimal? Strength, string? Unit);

/// <summary>
/// Parses ingredient phrases such as "Acetaminophen 500 mg" or "PARACETAMOL 500MG"
/// into a name plus an optional strength. Used by both label reading and provider
/// normalization so the two paths agree.
/// </summary>
public static class IngredientTextParser
{
    private static readonly Regex StrengthPattern = new(
        @"(?<value>\d+(?:[.,]\d+)?)\s*(?<unit>mg|mcg|µg|ug|g|ml|iu|units?|%)",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly Regex DosageFormNoise = new(
        @"\b(oral|tablet|tablets|capsule|capsules|film[- ]coated|extended[- ]release|suspension|syrup|solution|injection|per|each|in|of)\b",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly Regex Whitespace = new(@"\s+", RegexOptions.Compiled);

    public static ParsedIngredientText Parse(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return new ParsedIngredientText(string.Empty, null, null);
        }

        var match = StrengthPattern.Match(text);
        decimal? strength = null;
        string? unit = null;

        if (match.Success)
        {
            var raw = match.Groups["value"].Value.Replace(',', '.');
            if (decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed))
            {
                strength = parsed;
            }

            unit = match.Groups["unit"].Value.ToLowerInvariant() switch
            {
                "µg" or "ug" => "mcg",
                "unit" or "units" => "IU",
                "iu" => "IU",
                var other => other
            };
        }

        var name = StrengthPattern.Replace(text, " ");
        name = DosageFormNoise.Replace(name, " ");
        name = Whitespace.Replace(name, " ").Trim(' ', '-', ',', ';', '.', '/');

        return new ParsedIngredientText(name, strength, unit);
    }

    /// <summary>
    /// Splits a label ingredient block into individual ingredient phrases.
    /// </summary>
    public static IReadOnlyList<string> SplitIngredientList(string text) =>
        text.Split(new[] { ',', ';', '+', '\n', '\r', '|' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(part => part.Trim())
            .Where(part => part.Length > 1)
            .ToList();
}
