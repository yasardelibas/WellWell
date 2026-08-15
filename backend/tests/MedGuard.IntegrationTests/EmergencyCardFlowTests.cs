using System.Net;
using MedGuard.Contracts.Emergency;
using MedGuard.Contracts.Medications;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>QR token → emergency card</summary>
public sealed class EmergencyCardFlowTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public EmergencyCardFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Card_ShouldStayClosed_UntilTheOwnerEnablesIt()
    {
        var user = await _factory.RegisterAsync();
        var card = await user.Client.GetAsync<EmergencyCardResponse>("/api/emergency-card");

        Assert.False(card.IsEnabled);
        Assert.StartsWith("https://test.medguard.app/e/", card.ShareUrl);

        var response = await PublicGetAsync(TokenOf(card));
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task PublicCard_ShouldExposeOnlyTheExplicitlySharedFields()
    {
        var user = await _factory.RegisterAsync();
        await AddMedicationAsync(user);

        var card = await EnableCardAsync(user, shareMedications: true, shareContact: false, shareNotes: false);

        var response = await PublicGetAsync(TokenOf(card));
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var publicCard = await response.ReadAsync<PublicEmergencyCardResponse>();

        Assert.Equal("Burak", publicCard.Name);
        Assert.Equal("Penicillin", publicCard.Allergies);
        Assert.Equal("Advil", Assert.Single(publicCard.Medications).Name);
        Assert.Null(publicCard.EmergencyContactName);
        Assert.Null(publicCard.EmergencyContactPhone);
        Assert.Null(publicCard.Notes);
        Assert.NotEmpty(publicCard.Disclaimer);
    }

    [Fact]
    public async Task PublicCard_ShouldOmitMedications_WhenTheOwnerDidNotShareThem()
    {
        var user = await _factory.RegisterAsync();
        await AddMedicationAsync(user);

        var card = await EnableCardAsync(user, shareMedications: false, shareContact: true, shareNotes: true);
        var publicCard = await (await PublicGetAsync(TokenOf(card))).ReadAsync<PublicEmergencyCardResponse>();

        Assert.Empty(publicCard.Medications);
        Assert.Equal("Emergency Contact", publicCard.EmergencyContactName);
        Assert.Equal("Carries an inhaler.", publicCard.Notes);
    }

    [Fact]
    public async Task Regenerate_ShouldInvalidateThePreviouslySharedToken()
    {
        var user = await _factory.RegisterAsync();
        var card = await EnableCardAsync(user, shareMedications: true, shareContact: false, shareNotes: false);
        var originalToken = TokenOf(card);

        var response = await user.Client.PostJsonAsync("/api/emergency-card/regenerate", new { });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var regenerated = await response.ReadAsync<EmergencyCardResponse>();
        var newToken = TokenOf(regenerated);

        Assert.NotEqual(originalToken, newToken);
        Assert.Equal(HttpStatusCode.NotFound, (await PublicGetAsync(originalToken)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await PublicGetAsync(newToken)).StatusCode);
        Assert.True(regenerated.IsEnabled);
    }

    [Fact]
    public async Task PublicCard_ShouldNotRevealAnythingForAnUnknownToken()
    {
        var response = await PublicGetAsync("a-token-that-was-never-issued");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Card_ShouldRequireAuthentication()
    {
        var response = await _factory.CreateApiClient().GetAsync("/api/emergency-card");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private Task<HttpResponseMessage> PublicGetAsync(string token) =>
        _factory.CreateApiClient().GetAsync($"/e/{token}");

    private static string TokenOf(EmergencyCardResponse card) =>
        card.ShareUrl[(card.ShareUrl.LastIndexOf('/') + 1)..];

    private static async Task<EmergencyCardResponse> EnableCardAsync(
        TestUser user,
        bool shareMedications,
        bool shareContact,
        bool shareNotes)
    {
        var response = await user.Client.PutJsonAsync(
            "/api/emergency-card",
            new UpdateEmergencyCardRequest(
                IsEnabled: true,
                ShareName: true,
                ShareAllergies: true,
                ShareMedications: shareMedications,
                ShareEmergencyContact: shareContact,
                ShareNotes: shareNotes,
                DisplayName: "Burak",
                Allergies: "Penicillin",
                EmergencyContactName: "Emergency Contact",
                EmergencyContactPhone: "+90 555 000 00 00",
                Notes: "Carries an inhaler."));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.ReadAsync<EmergencyCardResponse>();
    }

    private static async Task AddMedicationAsync(TestUser user)
    {
        var response = await user.Client.PostJsonAsync(
            "/api/medications",
            new CreateMedicationRequest(
                "Advil",
                "Ibuprofen",
                new[] { new IngredientInput("Ibuprofen", 400m, "mg", null) },
                "Tablet",
                "400 mg",
                "Oral",
                "Take 1 tablet twice daily.",
                null));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
