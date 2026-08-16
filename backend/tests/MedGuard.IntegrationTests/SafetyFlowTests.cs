using System.Net;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Safety;
using MedGuard.Contracts.Scanning;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>medication creation → safety analysis</summary>
public sealed class SafetyFlowTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public SafetyFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Analyze_ShouldFlagADuplicateIngredient_WhenTwoProductsShareAnActiveIngredient()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);
        await CreateMedicationAsync(user, "Parol", "Paracetamol", "Paracetamol", 500m);

        var analysis = await AnalyzeAsync(user);

        Assert.Equal("warning", analysis.Status);
        var finding = Assert.Single(analysis.Findings, item => item.Type == "duplicate_active_ingredient");

        Assert.Equal("warning", finding.Severity);
        Assert.Equal("Acetaminophen", finding.Ingredient!.Name);
        Assert.Equal("RxNorm", finding.Ingredient.IdentifierSystem);
        Assert.Equal(2, finding.Medications.Count);
        Assert.Contains(finding.Medications, medication => medication.Name == "Parol");
        Assert.True(finding.Verified);
    }

    [Fact]
    public async Task Analyze_ShouldReportNoFindings_WhenTheIngredientsDiffer()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Glucophage", "Metformin Hydrochloride", "Metformin Hydrochloride", 500m);
        await CreateMedicationAsync(user, "Zestril", "Lisinopril", "Lisinopril", 10m);

        var analysis = await AnalyzeAsync(user);

        Assert.Equal("no_findings", analysis.Status);
        Assert.DoesNotContain(analysis.Findings, finding => finding.Type == "duplicate_active_ingredient");
        Assert.DoesNotContain("safe together", analysis.Headline, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Analyze_ShouldReportTheInteractionCheckAsUnavailable_RatherThanClaimingNothingWasFound()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Advil", "Ibuprofen", "Ibuprofen", 400m);

        var analysis = await AnalyzeAsync(user);

        var interactionCheck = Assert.Single(analysis.Checks, check => check.Check == "drug_interaction");
        Assert.Contains(interactionCheck.State, new[] { "unavailable", "not_configured" });
        Assert.DoesNotContain(analysis.Findings, finding => finding.Type == "drug_interaction");
    }

    [Fact]
    public async Task Analyze_ShouldStayScopedToTheSignedInUser()
    {
        var owner = await _factory.RegisterAsync();
        var stranger = await _factory.RegisterAsync();

        await CreateMedicationAsync(owner, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);
        await CreateMedicationAsync(stranger, "Parol", "Paracetamol", "Paracetamol", 500m);

        var analysis = await AnalyzeAsync(stranger);

        Assert.Equal("no_findings", analysis.Status);
    }

    [Fact]
    public async Task Findings_ShouldPersistBetweenAnalyses_WithStableIdentifiers()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);
        await CreateMedicationAsync(user, "Parol", "Paracetamol", "Paracetamol", 500m);

        var first = await AnalyzeAsync(user);
        var second = await AnalyzeAsync(user);

        Assert.Equal(
            first.Findings.Select(finding => finding.Id).OrderBy(id => id),
            second.Findings.Select(finding => finding.Id).OrderBy(id => id));

        var stored = await user.Client.GetAsync<List<SafetyFindingResponse>>("/api/safety/findings");
        Assert.Contains(stored, finding => finding.Id == first.Findings.First().Id);
    }

    [Fact]
    public async Task Explanation_ShouldFallBackToDeterministicText_WhenTheModelIsDisabled()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);
        await CreateMedicationAsync(user, "Parol", "Paracetamol", "Paracetamol", 500m);

        var analysis = await AnalyzeAsync(user);
        var finding = analysis.Findings.First(item => item.Type == "duplicate_active_ingredient");

        var explanation = await user.Client.GetAsync<SafetyExplanationResponse>(
            $"/api/safety/findings/{finding.Id}/explanation");

        Assert.False(explanation.GeneratedByAi);
        Assert.Contains("Acetaminophen", explanation.Explanation);
        Assert.NotEmpty(explanation.Disclaimer);
    }

    [Fact]
    public async Task Explanation_ShouldNotBeReadableByAnotherAccount()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);
        await CreateMedicationAsync(user, "Parol", "Paracetamol", "Paracetamol", 500m);

        var analysis = await AnalyzeAsync(user);
        var findingId = analysis.Findings.First().Id;

        var stranger = await _factory.RegisterAsync();
        var response = await stranger.Client.GetAsync($"/api/safety/findings/{findingId}/explanation");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task ConfirmingAScan_ShouldReturnTheDuplicateWarningImmediately()
    {
        var user = await _factory.RegisterAsync();
        await CreateMedicationAsync(user, "Tylenol Extra Strength", "Acetaminophen", "Acetaminophen", 500m);

        const string parolLabel = """
            PAROL
            Active ingredient: Paracetamol 500 mg
            Tablet
            Directions: Take 1 tablet twice daily.
            """;

        var scanResponse = await user.Client.PostJsonAsync(
            "/api/medications/scan",
            new ScanRequest(null, null, parolLabel));
        var scan = await scanResponse.ReadAsync<ScanResponse>();

        var confirmResponse = await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm",
            new ConfirmScanRequest(null, null, null, null, null, null, null, null));

        Assert.Equal(HttpStatusCode.OK, confirmResponse.StatusCode);
        var confirmed = await confirmResponse.ReadAsync<ConfirmScanResponse>();

        Assert.Equal("warning", confirmed.Safety.Status);
        Assert.Contains(confirmed.Safety.Findings, finding => finding.Type == "duplicate_active_ingredient");
    }

    private static async Task<MedicationResponse> CreateMedicationAsync(
        TestUser user,
        string brandName,
        string genericName,
        string ingredientName,
        decimal strength)
    {
        var response = await user.Client.PostJsonAsync(
            "/api/medications",
            new CreateMedicationRequest(
                brandName,
                genericName,
                new[] { new IngredientInput(ingredientName, strength, "mg", null) },
                "Tablet",
                $"{strength:0.##} mg",
                "Oral",
                "Take 1 tablet twice daily.",
                null));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return await response.ReadAsync<MedicationResponse>();
    }

    private static async Task<SafetyAnalysisResponse> AnalyzeAsync(TestUser user)
    {
        var response = await user.Client.PostJsonAsync("/api/safety/analyze", new AnalyzeSafetyRequest(null));
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        return await response.ReadAsync<SafetyAnalysisResponse>();
    }
}
