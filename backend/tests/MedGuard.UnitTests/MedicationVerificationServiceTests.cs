using MedGuard.Application.Medications;
using MedGuard.Application.Safety;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class MedicationVerificationServiceTests
{
    private static readonly DrugSearchRequest Request = new(
        "Tylenol Extra Strength",
        "Acetaminophen",
        new[] { "Acetaminophen" },
        "500 mg",
        "Tablet");

    private static MedicationVerificationService CreateService(params Application.Abstractions.IDrugDataProvider[] providers) =>
        new(providers, new NoOpCacheStore(), NullLogger<MedicationVerificationService>.Instance);

    private static DrugIdentity Identity(string provider = "test-provider") => new(
        "198440",
        "Tylenol Extra Strength",
        "Acetaminophen",
        new[] { new ActiveIngredient("acetaminophen", "Acetaminophen", 500m, "mg", "161") },
        "Tablet",
        "500 mg",
        "Test Pharma",
        new DataProvenance(provider, "198440", DateTimeOffset.UtcNow, "v1"));

    [Fact]
    public async Task VerifyAsync_ShouldReportVerified_WhenAProviderMatchesConfidently()
    {
        var service = CreateService(StubDrugDataProvider.Matching(Identity(), 0.95));

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.Verified, outcome.Status);
        Assert.NotNull(outcome.Provenance);
        Assert.Equal("test-provider", outcome.Provenance!.Provider);
    }

    [Fact]
    public async Task VerifyAsync_ShouldNotVerify_WhenTheOnlyProviderIsUnreachable()
    {
        var service = CreateService(StubDrugDataProvider.Unavailable());

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.VerificationUnavailable, outcome.Status);
        Assert.Null(outcome.Provenance);
        Assert.Empty(outcome.Candidates);
    }

    [Fact]
    public async Task VerifyAsync_ShouldNotVerify_WhenAProviderThrows()
    {
        var service = CreateService(StubDrugDataProvider.Throwing());

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.VerificationUnavailable, outcome.Status);
        Assert.Null(outcome.Provenance);
    }

    [Fact]
    public async Task VerifyAsync_ShouldReportNoConfidentMatch_WhenScoresStayBelowTheThreshold()
    {
        var service = CreateService(StubDrugDataProvider.Matching(Identity(), 0.4));

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.NoConfidentMatch, outcome.Status);
        Assert.Null(outcome.Provenance);
        Assert.Single(outcome.Candidates);
    }

    [Fact]
    public async Task VerifyAsync_ShouldReportNoConfidentMatch_WhenProvidersRespondWithNothing()
    {
        var service = CreateService(StubDrugDataProvider.NoMatch());

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.NoConfidentMatch, outcome.Status);
    }

    [Fact]
    public async Task VerifyAsync_ShouldFallThroughToTheNextProvider_WhenTheFirstIsUnreachable()
    {
        var service = CreateService(
            StubDrugDataProvider.Unavailable("offline"),
            StubDrugDataProvider.Matching(Identity("backup-provider"), 0.9, "backup-provider"));

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.Verified, outcome.Status);
        Assert.Equal("backup-provider", outcome.Provenance!.Provider);
    }

    [Fact]
    public async Task VerifyAsync_ShouldReportUnavailable_WhenNoProviderIsConfigured()
    {
        var service = CreateService();

        var outcome = await service.VerifyAsync(Request, CancellationToken.None);

        Assert.Equal(MedicationVerificationStatus.VerificationUnavailable, outcome.Status);
    }
}

public sealed class LocalDrugDataProviderTests
{
    [Fact]
    public async Task SearchAsync_ShouldMatchByBrandName()
    {
        var provider = new Infrastructure.Drugs.LocalDrugDataProvider(new IngredientNormalizer(), new FixedClock());

        var result = await provider.SearchAsync(
            new DrugSearchRequest("Tylenol Extra Strength", null, Array.Empty<string>(), null, null),
            CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal(DrugLookupStatus.Matched, result!.Status);
        Assert.Equal("198440", result.BestMatch!.Identity.RxCui);
    }

    [Fact]
    public async Task SearchAsync_ShouldNormalizeParacetamolOntoAcetaminophen()
    {
        var provider = new Infrastructure.Drugs.LocalDrugDataProvider(new IngredientNormalizer(), new FixedClock());

        var result = await provider.SearchAsync(
            new DrugSearchRequest("Parol", null, new[] { "Paracetamol" }, null, null),
            CancellationToken.None);

        var ingredient = Assert.Single(result!.BestMatch!.Identity.Ingredients);
        Assert.Equal("acetaminophen", ingredient.NormalizedName);
        Assert.Equal("161", ingredient.RxCui);
    }

    [Fact]
    public async Task SearchAsync_ShouldReportNoMatch_ForUnknownProducts()
    {
        var provider = new Infrastructure.Drugs.LocalDrugDataProvider(new IngredientNormalizer(), new FixedClock());

        var result = await provider.SearchAsync(
            new DrugSearchRequest("Completely Unknown Product", null, Array.Empty<string>(), null, null),
            CancellationToken.None);

        Assert.Equal(DrugLookupStatus.NoMatch, result!.Status);
    }
}
