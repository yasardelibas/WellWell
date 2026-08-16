using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Infrastructure.Extraction;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class TextLabelExtractionServiceTests
{
    private readonly TextLabelExtractionService _service = new(new IngredientNormalizer());

    private const string SampleLabel = """
        TYLENOL®
        Extra Strength
        Active ingredient: Acetaminophen 500 mg
        Film-coated tablet
        Directions: Take 1 tablet twice daily.
        Manufactured by: Test Pharma
        EXP 09/2027
        """;

    [Fact]
    public async Task ExtractAsync_ShouldReadTheLabel_WithPerFieldConfidence()
    {
        var extraction = await _service.ExtractAsync(new LabelExtractionInput(null, null, SampleLabel), CancellationToken.None);

        Assert.True(extraction.Succeeded);
        Assert.Equal("TYLENOL", extraction.BrandName.Value);
        Assert.Equal("Acetaminophen", extraction.GenericName.Value);
        Assert.Equal("Take 1 tablet twice daily.", extraction.Directions.Value);
        Assert.Equal("Test Pharma", extraction.Manufacturer.Value);
        Assert.Equal("09/2027", extraction.ExpirationDate.Value);

        var ingredient = Assert.Single(extraction.ActiveIngredients);
        Assert.Equal("Acetaminophen", ingredient.Name.Value);
        Assert.Equal("500", ingredient.Strength?.Value);
        Assert.Equal("mg", ingredient.Unit?.Value);
        Assert.True(ingredient.Name.Confidence > 0.9);
    }

    [Fact]
    public async Task ExtractAsync_ShouldLowerConfidence_WhenIngredientsAreOnlyInferred()
    {
        const string weakLabel = """
            Some Product
            Ibuprofen 400 mg
            """;

        var extraction = await _service.ExtractAsync(new LabelExtractionInput(null, null, weakLabel), CancellationToken.None);

        var ingredient = Assert.Single(extraction.ActiveIngredients);
        Assert.True(ingredient.Name.Confidence < 0.7, "An inferred ingredient must not look as certain as a labelled one.");
        Assert.True(extraction.OverallConfidence < 0.7);
    }

    [Fact]
    public async Task ExtractAsync_ShouldFail_WhenNoTextIsAvailable()
    {
        var extraction = await _service.ExtractAsync(new LabelExtractionInput(null, null, null), CancellationToken.None);

        Assert.False(extraction.Succeeded);
        Assert.Equal(0d, extraction.OverallConfidence);
        Assert.NotNull(extraction.FailureReason);
    }

    [Fact]
    public async Task ExtractAsync_ShouldReadMultipleIngredients_FromOneSection()
    {
        const string combination = "Active ingredients: Acetaminophen 325 mg, Diphenhydramine HCl 25 mg";

        var extraction = await _service.ExtractAsync(new LabelExtractionInput(null, null, combination), CancellationToken.None);

        Assert.Equal(2, extraction.ActiveIngredients.Count);
        Assert.Contains(extraction.ActiveIngredients, i => i.Name.Value == "Acetaminophen");
        Assert.Contains(extraction.ActiveIngredients, i => i.Name.Value == "Diphenhydramine HCl");
    }

    [Fact]
    public async Task ExtractAsync_ShouldNeverReportSuccess_WithoutAnyIdentifyingField()
    {
        var extraction = await _service.ExtractAsync(
            new LabelExtractionInput(null, null, "!!  ??  ;;"),
            CancellationToken.None);

        Assert.False(extraction.Succeeded);
    }
}
