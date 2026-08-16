using System.Net;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Scanning;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>scan → confirmation → medication creation</summary>
public sealed class ScanFlowTests : IClassFixture<MedGuardApiFactory>
{
    private const string TylenolLabel = """
        TYLENOL®
        Extra Strength
        Active ingredients: Acetaminophen 500 mg
        Film-coated tablet
        Directions: Take 1 tablet twice daily.
        Manufactured by: Johnson & Johnson
        """;

    private const string UnknownLabel = """
        ZELTRIX
        Active ingredient: Fictitious Compound 250 mg
        Tablet
        """;

    private readonly MedGuardApiFactory _factory;

    public ScanFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Scan_ShouldExtractAndVerifyTheLabel_BeforeAnythingIsSaved()
    {
        var user = await _factory.RegisterAsync();

        var scan = await ScanAsync(user, TylenolLabel);

        Assert.Equal("awaiting_confirmation", scan.Status);
        Assert.Equal("verified", scan.VerificationStatus);
        Assert.NotNull(scan.Extraction);
        Assert.Equal("Acetaminophen", Assert.Single(scan.Extraction!.ActiveIngredients).Name.Value);
        Assert.Contains(scan.Candidates, candidate => candidate.RxCui == "198440");
        Assert.Equal(2, scan.ScheduleSuggestion!.TimesPerDay);

        // Nothing reaches the medication list until the user confirms.
        var medications = await user.Client.GetAsync<List<MedicationResponse>>("/api/medications");
        Assert.Empty(medications);
    }

    [Fact]
    public async Task Confirm_ShouldCreateAVerifiedMedication_CarryingItsProvenance()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, TylenolLabel);

        var response = await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm",
            EmptyConfirmation);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var confirmed = await response.ReadAsync<ConfirmScanResponse>();

        Assert.Equal("verified", confirmed.Medication.VerificationStatus);
        Assert.Equal("198440", confirmed.Medication.RxCui);
        Assert.Equal("medguard-local-dataset", confirmed.Medication.Provenance!.Provider);
        Assert.Equal("161", Assert.Single(confirmed.Medication.Ingredients).RxCui);

        var medications = await user.Client.GetAsync<List<MedicationResponse>>("/api/medications");
        Assert.Equal(confirmed.Medication.Id, Assert.Single(medications).Id);
    }

    [Fact]
    public async Task Confirm_ShouldPersistTheExpirationDate_WhenProvidedExplicitly()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, TylenolLabel);

        var response = await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm",
            EmptyConfirmation with { ExpirationDate = new DateOnly(2027, 6, 30) });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var confirmed = await response.ReadAsync<ConfirmScanResponse>();
        Assert.Equal(new DateOnly(2027, 6, 30), confirmed.Medication.ExpirationDate);
    }

    [Fact]
    public async Task SetExpiration_ShouldUpdateAndClearTheExpirationDate()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, TylenolLabel);
        var confirmed = await (await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm", EmptyConfirmation)).ReadAsync<ConfirmScanResponse>();

        var set = await user.Client.PutJsonAsync(
            $"/api/medications/{confirmed.Medication.Id}/expiration",
            new SetExpirationRequest(new DateOnly(2026, 12, 1)));
        Assert.Equal(HttpStatusCode.OK, set.StatusCode);
        Assert.Equal(new DateOnly(2026, 12, 1), (await set.ReadAsync<MedicationResponse>()).ExpirationDate);

        var cleared = await user.Client.PutJsonAsync(
            $"/api/medications/{confirmed.Medication.Id}/expiration",
            new SetExpirationRequest(null));
        Assert.Null((await cleared.ReadAsync<MedicationResponse>()).ExpirationDate);
    }

    [Fact]
    public async Task Confirm_ShouldRejectASecondConfirmation_ForTheSameScan()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, TylenolLabel);

        var first = await user.Client.PostJsonAsync($"/api/medications/scan/{scan.ScanId}/confirm", EmptyConfirmation);
        var second = await user.Client.PostJsonAsync($"/api/medications/scan/{scan.ScanId}/confirm", EmptyConfirmation);

        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Confirm_ShouldRequireAcknowledgement_WhenTheLookupFoundNoConfidentMatch()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, UnknownLabel);

        Assert.Equal("no_confident_match", scan.VerificationStatus);
        Assert.True(scan.RequiresManualReview);

        var refused = await user.Client.PostJsonAsync($"/api/medications/scan/{scan.ScanId}/confirm", EmptyConfirmation);
        Assert.Equal(HttpStatusCode.Conflict, refused.StatusCode);

        var accepted = await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm",
            EmptyConfirmation with { AcknowledgedUnverified = true });

        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);
        var confirmed = await accepted.ReadAsync<ConfirmScanResponse>();

        Assert.Equal("no_confident_match", confirmed.Medication.VerificationStatus);
        Assert.Null(confirmed.Medication.Provenance);
    }

    [Fact]
    public async Task Confirm_ShouldUseTheUserEditedValues_OverTheExtractedOnes()
    {
        var user = await _factory.RegisterAsync();
        var scan = await ScanAsync(user, TylenolLabel);

        var response = await user.Client.PostJsonAsync(
            $"/api/medications/scan/{scan.ScanId}/confirm",
            EmptyConfirmation with
            {
                BrandName = "Parol",
                GenericName = "Paracetamol",
                Ingredients = new[] { new IngredientInput("Paracetamol", 500m, "mg", null) }
            });

        var confirmed = await response.ReadAsync<ConfirmScanResponse>();

        Assert.Equal("Parol", confirmed.Medication.BrandName);
        Assert.Equal("acetaminophen", Assert.Single(confirmed.Medication.Ingredients).NormalizedName);
    }

    [Fact]
    public async Task Scan_ShouldReportAReadFailure_WhenTheTextCarriesNoLabelInformation()
    {
        var user = await _factory.RegisterAsync();

        var scan = await ScanAsync(user, "%%%   ###");

        Assert.Equal("extraction_failed", scan.Status);
        Assert.True(scan.RequiresManualReview);
        Assert.Null(scan.Extraction);
        Assert.Empty(scan.Candidates);
    }

    [Fact]
    public async Task Scan_ShouldRejectARequest_ThatCarriesNeitherAnImageNorText()
    {
        var user = await _factory.RegisterAsync();

        var response = await user.Client.PostJsonAsync("/api/medications/scan", new ScanRequest(null, null, null));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Scan_ShouldRequireAuthentication()
    {
        var response = await _factory.CreateApiClient()
            .PostJsonAsync("/api/medications/scan", new ScanRequest(null, null, TylenolLabel));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static readonly ConfirmScanRequest EmptyConfirmation =
        new(null, null, null, null, null, null, null, null);

    private static async Task<ScanResponse> ScanAsync(TestUser user, string ocrText)
    {
        var response = await user.Client.PostJsonAsync("/api/medications/scan", new ScanRequest(null, null, ocrText));
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        return await response.ReadAsync<ScanResponse>();
    }
}
