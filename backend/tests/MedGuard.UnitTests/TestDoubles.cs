using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.UnitTests;

public sealed class FixedClock : IDateTimeProvider
{
    public FixedClock(DateTimeOffset? now = null) =>
        UtcNow = now ?? new DateTimeOffset(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    public DateTimeOffset UtcNow { get; set; }
}

public sealed class InMemoryMedicationRepository : IMedicationRepository
{
    private readonly List<Medication> _medications;

    public InMemoryMedicationRepository(params Medication[] medications) => _medications = medications.ToList();

    public Task<IReadOnlyCollection<Medication>> GetActiveForUserAsync(Guid userId, CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<Medication>>(_medications.Where(m => m.UserId == userId).ToList());

    public Task<Medication?> GetByIdAsync(Guid userId, Guid medicationId, CancellationToken cancellationToken) =>
        Task.FromResult(_medications.FirstOrDefault(m => m.UserId == userId && m.Id == medicationId));
}

public sealed class StubInteractionProvider : IDrugInteractionProvider
{
    private readonly Func<Task<DrugInteractionResult>> _behaviour;

    private StubInteractionProvider(bool isConfigured, Func<Task<DrugInteractionResult>> behaviour)
    {
        IsConfigured = isConfigured;
        _behaviour = behaviour;
    }

    public string Name => "stub-interactions";

    public bool IsConfigured { get; }

    public static StubInteractionProvider NotConfigured() =>
        new(false, () => Task.FromResult(DrugInteractionResult.NotConfigured()));

    public static StubInteractionProvider Throwing() =>
        new(true, () => throw new HttpRequestException("provider down"));

    public static StubInteractionProvider Unavailable() =>
        new(true, () => Task.FromResult(DrugInteractionResult.Unavailable()));

    public Task<DrugInteractionResult> GetInteractionsAsync(
        IEnumerable<string> medicationIdentifiers,
        CancellationToken cancellationToken) => _behaviour();
}

public sealed class StubDrugDataProvider : IDrugDataProvider
{
    private readonly Func<DrugSearchResult?> _behaviour;

    private StubDrugDataProvider(string name, Func<DrugSearchResult?> behaviour)
    {
        Name = name;
        _behaviour = behaviour;
    }

    public string Name { get; }

    public static StubDrugDataProvider Throwing(string name = "broken") =>
        new(name, () => throw new HttpRequestException("provider down"));

    public static StubDrugDataProvider Unavailable(string name = "offline") =>
        new(name, DrugSearchResult.Unavailable);

    public static StubDrugDataProvider NoMatch(string name = "empty") =>
        new(name, DrugSearchResult.NoMatch);

    public static StubDrugDataProvider Matching(DrugIdentity identity, double score, string name = "stub") =>
        new(name, () => DrugSearchResult.Matched(new[] { new DrugCandidate(identity, score) }));

    public Task<DrugSearchResult?> SearchAsync(DrugSearchRequest request, CancellationToken cancellationToken) =>
        Task.FromResult(_behaviour());

    public Task<DrugDetails?> GetDrugAsync(string externalId, CancellationToken cancellationToken) =>
        Task.FromResult<DrugDetails?>(null);
}

public sealed class NoOpCacheStore : ICacheStore
{
    public Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken) where T : class =>
        Task.FromResult<T?>(null);

    public Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken) where T : class =>
        Task.CompletedTask;
}

public static class TestMedications
{
    private static readonly IngredientNormalizer Normalizer = new();

    public static Medication Create(
        Guid userId,
        string brandName,
        IEnumerable<(string Name, decimal? Strength, string Unit, string? RxCui)> ingredients,
        MedicationVerificationStatus status = MedicationVerificationStatus.Verified,
        DateTimeOffset? createdAt = null,
        string? rxCui = null)
    {
        var now = createdAt ?? new DateTimeOffset(2025, 1, 1, 0, 0, 0, TimeSpan.Zero);

        return Medication.Create(
            userId,
            brandName,
            brandName,
            ingredients.Select(i => Normalizer.Normalize(i.Name, i.Strength, i.Unit, i.RxCui)),
            status,
            now,
            rxCui,
            "Tablet",
            null,
            "Oral",
            null,
            null,
            null,
            status == MedicationVerificationStatus.Verified
                ? new DataProvenance("test-provider", rxCui, now, "test-v1")
                : null);
    }
}
