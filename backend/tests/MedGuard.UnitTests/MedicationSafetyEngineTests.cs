using MedGuard.Application.Safety;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.Safety;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class MedicationSafetyEngineTests
{
    private static readonly Guid UserId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    private static MedicationSafetyEngine CreateEngine(
        IEnumerable<Medication> medications,
        StubInteractionProvider? interactionProvider = null) =>
        new(
            new InMemoryMedicationRepository(medications.ToArray()),
            new IngredientNormalizer(),
            interactionProvider ?? StubInteractionProvider.NotConfigured(),
            new FixedClock(),
            NullLogger<MedicationSafetyEngine>.Instance);

    [Fact]
    public async Task AnalyzeAsync_ShouldRaiseDuplicateWarning_WhenTwoMedicationsShareAnIngredient()
    {
        var productA = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var productB = TestMedications.Create(UserId, "Product B", new[] { ("Acetaminophen", (decimal?)325m, "mg", (string?)"161") });
        var engine = CreateEngine(new[] { productA, productB });

        var result = await engine.AnalyzeAsync(UserId, productB, CancellationToken.None);

        var finding = Assert.Single(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
        Assert.Equal(SafetySeverity.Warning, finding.Severity);
        Assert.Equal(SafetyStatus.Warning, result.Status);
        Assert.Equal(2, finding.Subjects.Count);
        Assert.Contains(finding.Subjects, s => s.MedicationName == "Product A" && s.StrengthText == "500 mg");
        Assert.Contains(finding.Subjects, s => s.MedicationName == "Product B" && s.StrengthText == "325 mg");
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldRaiseDuplicateWarning_WhenSpellingsDifferForTheSameIngredient()
    {
        // Paracetamol and acetaminophen are the same active moiety under different naming conventions.
        var productA = TestMedications.Create(UserId, "Parol", new[] { ("Paracetamol", (decimal?)500m, "mg", (string?)null) });
        var productB = TestMedications.Create(UserId, "Tylenol", new[] { ("ACETAMINOPHEN 500 mg", (decimal?)500m, "mg", (string?)null) });
        var engine = CreateEngine(new[] { productA, productB });

        var result = await engine.AnalyzeAsync(UserId, productB, CancellationToken.None);

        var finding = Assert.Single(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
        Assert.Equal("acetaminophen", finding.IngredientNormalizedName);
        Assert.Equal("Acetaminophen", finding.IngredientDisplayName);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldRaiseDuplicateWarning_WhenOnlyOneProductCarriesAConceptIdentifier()
    {
        var withIdentifier = TestMedications.Create(UserId, "Product A", new[] { ("Ibuprofen", (decimal?)400m, "mg", (string?)"5640") });
        var withoutIdentifier = TestMedications.Create(UserId, "Product B", new[] { ("Ibuprofen", (decimal?)200m, "mg", (string?)null) });
        var engine = CreateEngine(new[] { withIdentifier, withoutIdentifier });

        var result = await engine.AnalyzeAsync(UserId, withoutIdentifier, CancellationToken.None);

        var finding = Assert.Single(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
        Assert.Equal("5640", finding.IngredientRxCui);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldNotRaiseDuplicateWarning_WhenIngredientsDiffer()
    {
        var metformin = TestMedications.Create(UserId, "Glucophage", new[] { ("Metformin Hydrochloride", (decimal?)500m, "mg", (string?)"6809") });
        var lisinopril = TestMedications.Create(UserId, "Zestril", new[] { ("Lisinopril", (decimal?)10m, "mg", (string?)"29046") });
        var engine = CreateEngine(new[] { metformin, lisinopril });

        var result = await engine.AnalyzeAsync(UserId, lisinopril, CancellationToken.None);

        Assert.DoesNotContain(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
        Assert.Equal(SafetyStatus.NoFindings, result.Status);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldTreatSaltFormsAsTheSameIngredient()
    {
        var plain = TestMedications.Create(UserId, "Product A", new[] { ("Metformin", (decimal?)500m, "mg", (string?)null) });
        var salt = TestMedications.Create(UserId, "Product B", new[] { ("Metformin Hydrochloride", (decimal?)850m, "mg", (string?)null) });
        var engine = CreateEngine(new[] { plain, salt });

        var result = await engine.AnalyzeAsync(UserId, salt, CancellationToken.None);

        Assert.Contains(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldReportUnverifiedState_WhenMedicationHasNoProviderProvenance()
    {
        var unverified = TestMedications.Create(
            UserId,
            "Hand written entry",
            new[] { ("Ibuprofen", (decimal?)400m, "mg", (string?)null) },
            MedicationVerificationStatus.Unverified);

        var engine = CreateEngine(new[] { unverified });

        var result = await engine.AnalyzeAsync(UserId, unverified, CancellationToken.None);

        var finding = Assert.Single(result.Findings, f => f.Type == SafetyFindingType.UnverifiedMedication);
        Assert.Equal(SafetySeverity.Info, finding.Severity);
        Assert.False(finding.SourceVerified);
        Assert.Equal(SafetyStatus.Attention, result.Status);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldMarkDuplicateAsUnverified_WhenAnyInvolvedMedicationIsUnverified()
    {
        var verified = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var unverified = TestMedications.Create(
            UserId,
            "Product B",
            new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") },
            MedicationVerificationStatus.Unverified);

        var engine = CreateEngine(new[] { verified, unverified });

        var result = await engine.AnalyzeAsync(UserId, unverified, CancellationToken.None);

        var duplicate = Assert.Single(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
        Assert.False(duplicate.SourceVerified);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldFailSafely_WhenMedicationHasNoIngredients()
    {
        var empty = TestMedications.Create(UserId, "Unknown product", Array.Empty<(string, decimal?, string, string?)>());
        var engine = CreateEngine(new[] { empty });

        var result = await engine.AnalyzeAsync(UserId, empty, CancellationToken.None);

        Assert.DoesNotContain(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);

        var duplicateCheck = Assert.Single(result.Checks, c => c.CheckName == SafetyMessages.DuplicateCheckName);
        Assert.Equal(SafetyCheckState.Skipped, duplicateCheck.State);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldReportInteractionCheckAsNotConfigured_WhenNoProviderExists()
    {
        var medication = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var engine = CreateEngine(new[] { medication });

        var result = await engine.AnalyzeAsync(UserId, medication, CancellationToken.None);

        var interactionCheck = Assert.Single(result.Checks, c => c.CheckName == SafetyMessages.InteractionCheckName);
        Assert.Equal(SafetyCheckState.NotConfigured, interactionCheck.State);
        Assert.DoesNotContain(result.Findings, f => f.Type == SafetyFindingType.DrugInteraction);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldNotFabricateResults_WhenInteractionProviderFails()
    {
        var first = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") }, rxCui: "198440");
        var second = TestMedications.Create(UserId, "Product B", new[] { ("Ibuprofen", (decimal?)400m, "mg", (string?)"5640") }, rxCui: "197805");
        var engine = CreateEngine(new[] { first, second }, StubInteractionProvider.Throwing());

        var result = await engine.AnalyzeAsync(UserId, second, CancellationToken.None);

        var interactionCheck = Assert.Single(result.Checks, c => c.CheckName == SafetyMessages.InteractionCheckName);
        Assert.Equal(SafetyCheckState.Unavailable, interactionCheck.State);
        Assert.DoesNotContain(result.Findings, f => f.Type == SafetyFindingType.DrugInteraction);
        Assert.Equal(SafetyStatus.Attention, result.Status);
        Assert.True(result.HasIncompleteChecks);
    }

    [Fact]
    public async Task AnalyzeUserAsync_ShouldReportEveryDuplicateGroup_AcrossTheWholeList()
    {
        var acetaminophenA = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var acetaminophenB = TestMedications.Create(UserId, "Product B", new[] { ("Paracetamol", (decimal?)325m, "mg", (string?)null) });
        var ibuprofenA = TestMedications.Create(UserId, "Product C", new[] { ("Ibuprofen", (decimal?)400m, "mg", (string?)"5640") });
        var ibuprofenB = TestMedications.Create(UserId, "Product D", new[] { ("Ibuprofen", (decimal?)200m, "mg", (string?)"5640") });

        var engine = CreateEngine(new[] { acetaminophenA, acetaminophenB, ibuprofenA, ibuprofenB });

        var result = await engine.AnalyzeUserAsync(UserId, CancellationToken.None);

        Assert.Equal(2, result.Findings.Count(f => f.Type == SafetyFindingType.DuplicateActiveIngredient));
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldIgnoreMedicationsBelongingToAnotherUser()
    {
        var otherUsersMedication = TestMedications.Create(Guid.NewGuid(), "Someone else's product", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var mine = TestMedications.Create(UserId, "My product", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var engine = CreateEngine(new[] { otherUsersMedication, mine });

        var result = await engine.AnalyzeAsync(UserId, mine, CancellationToken.None);

        Assert.DoesNotContain(result.Findings, f => f.Type == SafetyFindingType.DuplicateActiveIngredient);
    }

    [Fact]
    public async Task AnalyzeAsync_ShouldProduceStableDeduplicationKeys_AcrossRepeatedRuns()
    {
        var productA = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });
        var productB = TestMedications.Create(UserId, "Product B", new[] { ("Acetaminophen", (decimal?)325m, "mg", (string?)"161") });
        var engine = CreateEngine(new[] { productA, productB });

        var first = await engine.AnalyzeAsync(UserId, productB, CancellationToken.None);
        var second = await engine.AnalyzeAsync(UserId, productB, CancellationToken.None);

        Assert.Equal(
            first.Findings.Select(f => f.DeduplicationKey).OrderBy(key => key),
            second.Findings.Select(f => f.DeduplicationKey).OrderBy(key => key));
    }
}
