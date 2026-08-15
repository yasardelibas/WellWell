using MedGuard.Application.Safety;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class IngredientNormalizerTests
{
    private readonly IngredientNormalizer _normalizer = new();

    [Theory]
    [InlineData("Paracetamol", "acetaminophen")]
    [InlineData("PARACETAMOL 500 MG", "acetaminophen")]
    [InlineData("Acetaminophen", "acetaminophen")]
    [InlineData("APAP", "acetaminophen")]
    [InlineData("Acetylsalicylic acid", "aspirin")]
    [InlineData("Metformin Hydrochloride", "metformin")]
    [InlineData("Cetirizine HCl", "cetirizine")]
    [InlineData("Atorvastatin Calcium", "atorvastatin")]
    [InlineData("Ibuprofen (as lysine salt)", "ibuprofen")]
    [InlineData("Amoxicillin trihydrate", "amoxicillin")]
    public void Normalize_ShouldReturnCanonicalName_WhenGivenLabelVariants(string input, string expected) =>
        Assert.Equal(expected, _normalizer.Normalize(input));

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("500 mg")]
    public void Normalize_ShouldReturnEmpty_WhenNothingIdentifiableRemains(string input) =>
        Assert.Equal(string.Empty, _normalizer.Normalize(input));

    [Fact]
    public void Normalize_ShouldPreserveOriginalLabelWording()
    {
        var ingredient = _normalizer.Normalize("  PARACETAMOL 500mg  ", 500m, "MG", null);

        Assert.Equal("acetaminophen", ingredient.NormalizedName);
        Assert.Equal("PARACETAMOL 500mg", ingredient.OriginalName);
        Assert.Equal("mg", ingredient.Unit);
        Assert.Equal(500m, ingredient.Strength);
    }

    [Fact]
    public void Normalize_ShouldPreferConceptIdentifier_ForComparison()
    {
        var withIdentifier = _normalizer.Normalize("Paracetamol", 500m, "mg", "161");
        var withoutIdentifier = _normalizer.Normalize("Paracetamol", 500m, "mg", null);

        Assert.Equal("rxcui:161", withIdentifier.ComparisonKey);
        Assert.Equal("name:acetaminophen", withoutIdentifier.ComparisonKey);
        Assert.True(withIdentifier.HasCanonicalIdentifier);
    }

    [Theory]
    [InlineData("milligrams", "mg")]
    [InlineData("MCG", "mcg")]
    [InlineData("µg", "mcg")]
    [InlineData("international units", "IU")]
    public void NormalizeUnit_ShouldCollapseEquivalentUnits(string input, string expected) =>
        Assert.Equal(expected, IngredientNormalizer.NormalizeUnit(input));

    [Fact]
    public void ToDisplayName_ShouldTitleCaseCanonicalNames()
    {
        Assert.Equal("Acetaminophen", _normalizer.ToDisplayName("acetaminophen"));
        Assert.Equal("Metformin", _normalizer.ToDisplayName("metformin"));
        Assert.Equal(string.Empty, _normalizer.ToDisplayName(string.Empty));
    }
}
