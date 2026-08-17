using System.Collections.Concurrent;
using System.Text.Json;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Education;
using MedGuard.Infrastructure.Ai;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class CachingMedicationEducationServiceTests
{
    private static readonly MedicationEducationInput Metformin = new(
        "Metformin",
        "Metformin",
        new[] { "Metformin Hydrochloride" });

    [Fact]
    public async Task ExplainAsync_ShouldCallModelOnce_WhenSameDrugRequestedTwice()
    {
        var inner = new CountingEducationService(Ai("Used for type 2 diabetes."));
        var sut = new CachingMedicationEducationService(inner, new InMemoryCacheStore(), NullLogger<CachingMedicationEducationService>.Instance);

        var first = await sut.ExplainAsync(Metformin, "en", CancellationToken.None);
        var second = await sut.ExplainAsync(Metformin, "en", CancellationToken.None);

        Assert.Equal(1, inner.CallCount);
        Assert.Equal(first.Message, second.Message);
    }

    [Fact]
    public async Task ExplainAsync_ShouldCallModelEachTime_WhenResultIsNotAiGenerated()
    {
        var inner = new CountingEducationService(Fallback("Ask your pharmacist."));
        var sut = new CachingMedicationEducationService(inner, new InMemoryCacheStore(), NullLogger<CachingMedicationEducationService>.Instance);

        await sut.ExplainAsync(Metformin, "en", CancellationToken.None);
        await sut.ExplainAsync(Metformin, "en", CancellationToken.None);

        Assert.Equal(2, inner.CallCount);
    }

    [Fact]
    public async Task ExplainAsync_ShouldUseSeparateEntries_WhenLanguageDiffers()
    {
        var inner = new CountingEducationService(Ai("Used for type 2 diabetes."));
        var sut = new CachingMedicationEducationService(inner, new InMemoryCacheStore(), NullLogger<CachingMedicationEducationService>.Instance);

        await sut.ExplainAsync(Metformin, "en", CancellationToken.None);
        await sut.ExplainAsync(Metformin, "tr", CancellationToken.None);

        Assert.Equal(2, inner.CallCount);
    }

    [Fact]
    public async Task ExplainAsync_ShouldReturnCachedValue_WithoutCallingModelAgain()
    {
        var cache = new InMemoryCacheStore();
        var inner = new CountingEducationService(Ai("Used for type 2 diabetes."));
        var sut = new CachingMedicationEducationService(inner, cache, NullLogger<CachingMedicationEducationService>.Instance);

        await sut.ExplainAsync(Metformin, "en", CancellationToken.None);
        var cachedRun = await sut.ExplainAsync(Metformin, "en", CancellationToken.None);

        Assert.Equal(1, inner.CallCount);
        Assert.True(cachedRun.GeneratedByAi);
        Assert.Single(cache.Entries);
    }

    private static MedicationEducation Ai(string message) => new(message, GeneratedByAi: true, IsAvailable: true, "model:test");

    private static MedicationEducation Fallback(string message) => new(message, GeneratedByAi: false, IsAvailable: false, "template");

    private sealed class CountingEducationService : IMedicationEducationService
    {
        private readonly MedicationEducation _result;

        public CountingEducationService(MedicationEducation result) => _result = result;

        public int CallCount { get; private set; }

        public Task<MedicationEducation> ExplainAsync(MedicationEducationInput input, string? language, CancellationToken cancellationToken)
        {
            CallCount++;
            return Task.FromResult(_result);
        }
    }

    private sealed class InMemoryCacheStore : ICacheStore
    {
        public ConcurrentDictionary<string, string> Entries { get; } = new();

        public Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken) where T : class =>
            Task.FromResult(Entries.TryGetValue(key, out var payload)
                ? JsonSerializer.Deserialize<T>(payload)
                : null);

        public Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken) where T : class
        {
            Entries[key] = JsonSerializer.Serialize(value);
            return Task.CompletedTask;
        }
    }
}
