using System.Net;
using System.Net.Http.Headers;
using MedGuard.Contracts.Adherence;
using MedGuard.Contracts.Auth;
using MedGuard.Contracts.Emergency;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Safety;
using MedGuard.Contracts.Scanning;
using Xunit;

namespace MedGuard.IntegrationTests;

public sealed class AuthFlowTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public AuthFlowTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Register_ShouldIssueTokens_AndExposeTheProfile()
    {
        var user = await _factory.RegisterAsync();

        var profile = await user.Client.GetAsync<UserResponse>("/api/me");

        Assert.Equal(user.Email, profile.Email);
        Assert.False(profile.SafetyNoticeAcknowledged);
        Assert.True(user.Auth.ExpiresInSeconds > 0);
    }

    [Fact]
    public async Task Register_ShouldSendAVerificationCode_AndLeaveTheAccountUnverified()
    {
        var user = await _factory.RegisterAsync();

        var profile = await user.Client.GetAsync<UserResponse>("/api/me");
        Assert.False(profile.EmailVerified);
        Assert.NotNull(_factory.LastVerificationCodeFor(user.Email));
    }

    [Fact]
    public async Task VerifyEmail_ShouldMarkTheAccountVerified_WhenTheCodeIsCorrect()
    {
        var user = await _factory.RegisterAsync();
        var code = _factory.LastVerificationCodeFor(user.Email);
        Assert.NotNull(code);

        var response = await user.Client.PostJsonAsync("/api/me/verify-email", new VerifyEmailRequest(code!));
        var profile = await response.ReadAsync<UserResponse>();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(profile.EmailVerified);
    }

    [Fact]
    public async Task VerifyEmail_ShouldReject_WhenTheCodeIsWrong()
    {
        var user = await _factory.RegisterAsync();

        var response = await user.Client.PostJsonAsync("/api/me/verify-email", new VerifyEmailRequest("000000"));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var profile = await user.Client.GetAsync<UserResponse>("/api/me");
        Assert.False(profile.EmailVerified);
    }

    [Fact]
    public async Task ResendVerificationCode_ShouldIssueANewCode_ThatSupersedesThePreviousOne()
    {
        var user = await _factory.RegisterAsync();
        var firstCode = _factory.LastVerificationCodeFor(user.Email);

        var resend = await user.Client.PostJsonAsync("/api/me/resend-verification-code", new { });
        Assert.Equal(HttpStatusCode.Accepted, resend.StatusCode);

        var secondCode = _factory.LastVerificationCodeFor(user.Email);
        Assert.NotNull(secondCode);
        Assert.NotEqual(firstCode, secondCode);

        var verify = await user.Client.PostJsonAsync("/api/me/verify-email", new VerifyEmailRequest(secondCode!));
        Assert.Equal(HttpStatusCode.OK, verify.StatusCode);
    }

    [Fact]
    public async Task Register_ShouldRejectAnAlreadyUsedEmail()
    {
        var user = await _factory.RegisterAsync();

        var response = await _factory.CreateApiClient().PostJsonAsync(
            "/api/auth/register",
            new RegisterRequest(user.Email.ToUpperInvariant(), "StrongPass123!", "Someone", "UTC"));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Register_ShouldRejectAWeakPassword()
    {
        var response = await _factory.CreateApiClient().PostJsonAsync(
            "/api/auth/register",
            new RegisterRequest($"weak-{Guid.NewGuid():N}@example.com", "short", "Someone", "UTC"));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Login_ShouldAnswerIdentically_ForUnknownAccountsAndWrongPasswords()
    {
        var user = await _factory.RegisterAsync();
        var client = _factory.CreateApiClient();

        var wrongPassword = await client.PostJsonAsync("/api/auth/login", new LoginRequest(user.Email, "WrongPass123!"));
        var unknownAccount = await client.PostJsonAsync(
            "/api/auth/login",
            new LoginRequest($"nobody-{Guid.NewGuid():N}@example.com", "WrongPass123!"));

        Assert.Equal(HttpStatusCode.Unauthorized, wrongPassword.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, unknownAccount.StatusCode);
        Assert.Equal(
            await wrongPassword.Content.ReadAsStringAsync(),
            await unknownAccount.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Refresh_ShouldRotateTheToken_AndRejectTheUsedOne()
    {
        var user = await _factory.RegisterAsync();

        var first = await user.Client.PostJsonAsync("/api/auth/refresh", new RefreshTokenRequest(user.Auth.RefreshToken));
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);

        var rotated = await first.ReadAsync<AuthResponse>();
        Assert.NotEqual(user.Auth.RefreshToken, rotated.RefreshToken);

        var reuse = await user.Client.PostJsonAsync("/api/auth/refresh", new RefreshTokenRequest(user.Auth.RefreshToken));
        Assert.Equal(HttpStatusCode.Unauthorized, reuse.StatusCode);
    }

    [Fact]
    public async Task Logout_ShouldInvalidateTheRefreshToken()
    {
        var user = await _factory.RegisterAsync();

        var logout = await user.Client.PostJsonAsync("/api/auth/logout", new LogoutRequest(user.Auth.RefreshToken));
        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);

        var refresh = await user.Client.PostJsonAsync("/api/auth/refresh", new RefreshTokenRequest(user.Auth.RefreshToken));
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task ForgotPassword_ShouldNotRevealWhetherTheAccountExists()
    {
        var user = await _factory.RegisterAsync();
        var client = _factory.CreateApiClient();

        var known = await client.PostJsonAsync("/api/auth/forgot-password", new ForgotPasswordRequest(user.Email));
        var unknown = await client.PostJsonAsync(
            "/api/auth/forgot-password",
            new ForgotPasswordRequest($"nobody-{Guid.NewGuid():N}@example.com"));

        Assert.Equal(HttpStatusCode.Accepted, known.StatusCode);
        Assert.Equal(HttpStatusCode.Accepted, unknown.StatusCode);
    }

    [Fact]
    public async Task AcknowledgeSafetyNotice_ShouldBeRecordedOnTheProfile()
    {
        var user = await _factory.RegisterAsync();

        var response = await user.Client.PostJsonAsync("/api/me/acknowledge-safety-notice", new { });
        var profile = await response.ReadAsync<UserResponse>();

        Assert.True(profile.SafetyNoticeAcknowledged);
    }

    [Fact]
    public async Task ProtectedEndpoints_ShouldRejectATamperedToken()
    {
        var client = _factory.CreateApiClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "not.a.jwt");

        var response = await client.GetAsync("/api/medications");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Medications_ShouldNeverLeakAcrossAccounts()
    {
        var owner = await _factory.RegisterAsync();
        var created = await owner.Client.PostJsonAsync(
            "/api/medications",
            new CreateMedicationRequest(
                "Advil",
                "Ibuprofen",
                new[] { new IngredientInput("Ibuprofen", 400m, "mg", null) },
                "Tablet",
                "400 mg",
                "Oral",
                null,
                null));

        var medication = await created.ReadAsync<MedicationResponse>();
        var stranger = await _factory.RegisterAsync();

        Assert.Equal(HttpStatusCode.NotFound, (await stranger.Client.GetAsync($"/api/medications/{medication.Id}")).StatusCode);
        Assert.Empty(await stranger.Client.GetAsync<List<MedicationResponse>>("/api/medications"));
    }
}

public sealed class DemoAccountTests : IClassFixture<MedGuardApiFactory>
{
    private readonly MedGuardApiFactory _factory;

    public DemoAccountTests(MedGuardApiFactory factory) => _factory = factory;

    [Fact]
    public async Task DemoLogin_ShouldOpenAnAccountWithMedicationsSchedulesAndHistory()
    {
        var client = await SignInToTheDemoAccountAsync();

        var medications = await client.GetAsync<List<MedicationResponse>>("/api/medications");
        Assert.True(medications.Count >= 3);
        Assert.Contains(
            medications,
            medication => medication.Ingredients.Any(ingredient => ingredient.NormalizedName == "acetaminophen"));
        Assert.All(medications, medication => Assert.Equal("verified", medication.VerificationStatus));

        var today = await client.GetAsync<TodayScheduleResponse>("/api/adherence/today");
        Assert.NotEmpty(today.Doses);

        var history = await client.GetAsync<AdherenceHistoryResponse>("/api/adherence/history");
        Assert.True(history.TakenCount > 0);

        // No duplicate is seeded: the second acetaminophen product is scanned during the walkthrough.
        var analysis = await AnalyzeAsync(client);
        Assert.DoesNotContain(analysis.Findings, finding => finding.Type == "duplicate_active_ingredient");
    }

    [Fact]
    public async Task DemoWalkthrough_ShouldSurfaceTheDuplicateIngredient_WhenTheSecondProductIsScanned()
    {
        var client = await SignInToTheDemoAccountAsync();

        const string parolLabel = """
            PAROL
            Active ingredient: Paracetamol 500 mg
            Tablet
            Directions: Take 1 tablet twice daily.
            """;

        var scan = await (await client.PostJsonAsync("/api/medications/scan", new ScanRequest(null, null, parolLabel)))
            .ReadAsync<ScanResponse>();

        Assert.Equal("verified", scan.VerificationStatus);

        var confirmed = await (await client.PostJsonAsync(
                $"/api/medications/scan/{scan.ScanId}/confirm",
                new ConfirmScanRequest(null, null, null, null, null, null, null, null)))
            .ReadAsync<ConfirmScanResponse>();

        Assert.Equal("warning", confirmed.Safety.Status);
        var finding = Assert.Single(confirmed.Safety.Findings, item => item.Type == "duplicate_active_ingredient");
        Assert.Equal("Acetaminophen", finding.Ingredient!.Name);
        Assert.Contains(finding.Medications, medication => medication.Name == "Tylenol Extra Strength");

        var explanation = await client.GetAsync<SafetyExplanationResponse>(
            $"/api/safety/findings/{finding.Id}/explanation");
        Assert.NotEmpty(explanation.Explanation);

        var card = await client.GetAsync<EmergencyCardResponse>("/api/emergency-card");
        Assert.True(card.IsEnabled);
        Assert.StartsWith("https://test.medguard.app/e/", card.ShareUrl);
    }

    private async Task<HttpClient> SignInToTheDemoAccountAsync()
    {
        var client = _factory.CreateApiClient();

        var response = await client.PostJsonAsync("/api/demo/login", new { });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var auth = await response.ReadAsync<AuthResponse>();
        Assert.True(auth.User.IsDemoAccount);

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        return client;
    }

    private static async Task<SafetyAnalysisResponse> AnalyzeAsync(HttpClient client) =>
        await (await client.PostJsonAsync("/api/safety/analyze", new AnalyzeSafetyRequest(null)))
            .ReadAsync<SafetyAnalysisResponse>();

    [Fact]
    public async Task DemoLogin_ShouldBeIdempotent()
    {
        var client = _factory.CreateApiClient();

        var first = await (await client.PostJsonAsync("/api/demo/login", new { })).ReadAsync<AuthResponse>();
        var second = await (await client.PostJsonAsync("/api/demo/login", new { })).ReadAsync<AuthResponse>();

        Assert.Equal(first.User.Id, second.User.Id);
    }
}
