using MedGuard.Application.Ai;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class ExplanationGuardTests
{
    [Theory]
    [InlineData("You should stop taking one of these medicines.")]
    [InlineData("Consider reducing the dose of paracetamol.")]
    [InlineData("These medications are safe together.")]
    [InlineData("Switch to ibuprofen instead.")]
    [InlineData("You likely have a fever, so this is expected.")]
    [InlineData("You may have an infection that explains this.")]
    [InlineData("This means you are dealing with liver damage.")]
    [InlineData("You are suffering from paracetamol overload.")]
    [InlineData("Ignore this warning, it is common.")]
    [InlineData("Do not exceed 4000 mg per day.")]
    [InlineData("")]
    public void Inspect_ShouldReject_WhenTextDriftsIntoClinicalAdvice(string text) =>
        Assert.False(ExplanationGuard.Inspect(text).IsAllowed);

    [Theory]
    [InlineData("You have two products that contain acetaminophen, so the amounts can add up.")]
    [InlineData("Both products you have saved list the same active ingredient.")]
    [InlineData("MedGuard does not provide medical advice, diagnoses or dosage instructions.")]
    public void Inspect_ShouldAllow_WhenOrdinaryPhrasingResemblesADiagnosis(string text) =>
        Assert.True(ExplanationGuard.Inspect(text).IsAllowed);

    [Fact]
    public void Inspect_ShouldAllow_WhenTextOnlyExplainsTheFinding()
    {
        const string text =
            "Both products list acetaminophen as an active ingredient. Because the same ingredient appears twice, " +
            "the total amount can add up without it being obvious. Check both labels and ask a pharmacist if you are unsure.";

        var result = ExplanationGuard.Inspect(text);

        Assert.True(result.IsAllowed);
        Assert.Null(result.ViolatedRule);
    }

    [Fact]
    public void Inspect_ShouldNameTheViolatedRule()
    {
        var result = ExplanationGuard.Inspect("You should stop taking Product B.");

        Assert.False(result.IsAllowed);
        Assert.Equal("recommends stopping medication", result.ViolatedRule);
    }
}

public sealed class TemplateExplanationServiceTests
{
    private static SafetyFinding CreateDuplicateFinding() => SafetyFinding.Create(
        Guid.NewGuid(),
        SafetyFindingType.DuplicateActiveIngredient,
        SafetySeverity.Warning,
        "Possible duplicate ingredient",
        "test-provider",
        sourceVerified: true,
        DateTimeOffset.UtcNow,
        ingredientNormalizedName: "acetaminophen",
        ingredientDisplayName: "Acetaminophen",
        subjects: new[]
        {
            SafetyFindingSubject.Create(Guid.NewGuid(), "Product A", "Acetaminophen", "500 mg", true),
            SafetyFindingSubject.Create(Guid.NewGuid(), "Product B", "Paracetamol", "325 mg", true)
        });

    [Fact]
    public async Task ExplainAsync_ShouldDescribeTheFinding_WithoutClaimingToBeGeneratedByAi()
    {
        var service = new TemplateExplanationService();

        var explanation = await service.ExplainAsync(CreateDuplicateFinding(), CancellationToken.None);

        Assert.False(explanation.GeneratedByAi);
        Assert.Equal(TemplateExplanationService.SourceName, explanation.Source);
        Assert.Contains("Acetaminophen", explanation.Text);
        Assert.Contains("Product A", explanation.Text);
        Assert.Contains("Product B", explanation.Text);
    }

    [Fact]
    public async Task ExplainAsync_ShouldProduceTextThatPassesItsOwnGuard()
    {
        var service = new TemplateExplanationService();

        foreach (var type in new[]
                 {
                     SafetyFindingType.DuplicateActiveIngredient,
                     SafetyFindingType.UnverifiedMedication,
                     SafetyFindingType.InteractionCheckUnavailable
                 })
        {
            var finding = SafetyFinding.Create(
                Guid.NewGuid(),
                type,
                SafetySeverity.Info,
                "Title",
                "test",
                false,
                DateTimeOffset.UtcNow);

            var explanation = await service.ExplainAsync(finding, CancellationToken.None);

            Assert.True(
                ExplanationGuard.Inspect(explanation.Text).IsAllowed,
                $"Template text for {type} must satisfy the output guard.");
        }
    }

    [Fact]
    public void BuildUserMessage_ShouldOnlyContainStructuredFindingData()
    {
        var payload = ExplanationPrompt.BuildUserMessage(CreateDuplicateFinding());

        Assert.Contains("\"findingType\":\"DuplicateActiveIngredient\"", payload);
        Assert.Contains("\"sourceVerified\":true", payload);
        Assert.Contains("Product A", payload);
    }
}
