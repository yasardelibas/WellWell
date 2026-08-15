using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using MedGuard.Application.Abstractions;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.Application.Safety;

/// <summary>
/// Deterministic ingredient name normalization. Text matching is only ever a fallback:
/// where an RxNorm concept identifier exists it takes precedence in comparisons.
/// </summary>
public sealed class IngredientNormalizer : IIngredientNormalizer
{
    private static readonly Regex ParentheticalPattern = new(@"\([^)]*\)", RegexOptions.Compiled);
    private static readonly Regex StrengthPattern = new(
        @"\b\d+(\.\d+)?\s*(mg|mcg|g|ml|iu|units?|%)\b",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex NonAlphaPattern = new(@"[^a-z0-9 ]", RegexOptions.Compiled);
    private static readonly Regex WhitespacePattern = new(@"\s+", RegexOptions.Compiled);

    /// <summary>Salt, hydrate and ester forms that do not change the active moiety for duplicate detection.</summary>
    private static readonly string[] SaltAndHydrateForms =
    {
        "hydrochloride", "hydrobromide", "hydrochlorid", "hcl", "hbr",
        "sodium", "potassium", "calcium", "magnesium", "aluminium", "aluminum",
        "sulfate", "sulphate", "phosphate", "nitrate", "acetate", "citrate", "tartrate",
        "bitartrate", "maleate", "fumarate", "succinate", "besylate", "besilate",
        "mesylate", "mesilate", "tosylate", "oxalate", "gluconate", "lactate",
        "carbonate", "bicarbonate", "chloride", "bromide", "iodide",
        "monohydrate", "dihydrate", "trihydrate", "hemihydrate", "anhydrous",
        "micronized", "micronised", "usp", "bp", "ph eur", "ep"
    };

    /// <summary>
    /// Cross-market synonyms mapped onto a single canonical active moiety.
    /// Paracetamol and acetaminophen are the same molecule under different naming conventions.
    /// </summary>
    private static readonly Dictionary<string, string> Synonyms = new(StringComparer.OrdinalIgnoreCase)
    {
        ["paracetamol"] = "acetaminophen",
        ["para acetyl amino phenol"] = "acetaminophen",
        ["apap"] = "acetaminophen",
        ["n acetyl p aminophenol"] = "acetaminophen",
        ["acetylsalicylic acid"] = "aspirin",
        ["acetyl salicylic acid"] = "aspirin",
        ["asa"] = "aspirin",
        ["salicylic acid acetate"] = "aspirin",
        ["ibuprofene"] = "ibuprofen",
        ["ibuprofeno"] = "ibuprofen",
        ["metformine"] = "metformin",
        ["metformina"] = "metformin",
        ["ascorbic acid"] = "vitamin c",
        ["colecalciferol"] = "cholecalciferol",
        ["vitamin d3"] = "cholecalciferol",
        ["salbutamol"] = "albuterol",
        ["adrenaline"] = "epinephrine",
        ["noradrenaline"] = "norepinephrine",
        ["acetaminofen"] = "acetaminophen",
        ["diphenhydramin"] = "diphenhydramine",
        ["pseudoephedrin"] = "pseudoephedrine",
        ["dextromethorphan hydrobromide"] = "dextromethorphan"
    };

    private static readonly Dictionary<string, string> DisplayOverrides = new(StringComparer.OrdinalIgnoreCase)
    {
        ["acetaminophen"] = "Acetaminophen",
        ["aspirin"] = "Aspirin",
        ["vitamin c"] = "Vitamin C"
    };

    public string Normalize(string rawName)
    {
        if (string.IsNullOrWhiteSpace(rawName))
        {
            return string.Empty;
        }

        var working = RemoveDiacritics(rawName).ToLowerInvariant();
        working = ParentheticalPattern.Replace(working, " ");
        working = StrengthPattern.Replace(working, " ");
        working = NonAlphaPattern.Replace(working, " ");
        working = WhitespacePattern.Replace(working, " ").Trim();

        if (working.Length == 0)
        {
            return string.Empty;
        }

        if (Synonyms.TryGetValue(working, out var directSynonym))
        {
            return directSynonym;
        }

        var tokens = working.Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .Where(token => !SaltAndHydrateForms.Contains(token, StringComparer.OrdinalIgnoreCase))
            .ToArray();

        var stripped = tokens.Length == 0 ? working : string.Join(' ', tokens);

        return Synonyms.TryGetValue(stripped, out var synonym) ? synonym : stripped;
    }

    public string ToDisplayName(string normalizedName)
    {
        if (string.IsNullOrWhiteSpace(normalizedName))
        {
            return string.Empty;
        }

        if (DisplayOverrides.TryGetValue(normalizedName, out var display))
        {
            return display;
        }

        return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(normalizedName);
    }

    public ActiveIngredient Normalize(string rawName, decimal? strength, string? unit, string? rxCui)
    {
        var normalized = Normalize(rawName);
        var original = string.IsNullOrWhiteSpace(rawName) ? normalized : rawName.Trim();
        var normalizedUnit = NormalizeUnit(unit);

        return new ActiveIngredient(
            normalized,
            original,
            strength,
            normalizedUnit,
            string.IsNullOrWhiteSpace(rxCui) ? null : rxCui.Trim());
    }

    public static string? NormalizeUnit(string? unit)
    {
        if (string.IsNullOrWhiteSpace(unit))
        {
            return null;
        }

        var value = unit.Trim().ToLowerInvariant();
        return value switch
        {
            "milligram" or "milligrams" or "mgs" => "mg",
            "microgram" or "micrograms" or "ug" or "µg" => "mcg",
            "gram" or "grams" or "gr" => "g",
            "millilitre" or "milliliter" or "millilitres" or "milliliters" => "ml",
            "iu" or "i.u." or "international unit" or "international units" => "IU",
            _ => value
        };
    }

    private static string RemoveDiacritics(string value)
    {
        var decomposed = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(decomposed.Length);

        foreach (var character in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(character) != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(character);
            }
        }

        return builder.ToString().Normalize(NormalizationForm.FormC);
    }
}
