using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.Infrastructure.Drugs;

/// <summary>
/// A small curated offline dataset. It exists so the product stays fully demonstrable and
/// testable without network access, and it reports its own provenance honestly rather than
/// pretending to be RxNorm.
/// </summary>
public sealed class LocalDrugDataProvider : IDrugDataProvider
{
    public const string ProviderName = "medguard-local-dataset";
    public const string DatasetVersion = "2025.01";

    private readonly IIngredientNormalizer _normalizer;
    private readonly IDateTimeProvider _clock;

    public LocalDrugDataProvider(IIngredientNormalizer normalizer, IDateTimeProvider clock)
    {
        _normalizer = normalizer;
        _clock = clock;
    }

    public string Name => ProviderName;

    private static readonly LocalDrugEntry[] Catalog =
    {
        new("198440", "Tylenol Extra Strength", "Acetaminophen", "Tablet", "500 mg", "Johnson & Johnson",
            new[] { new LocalIngredient("Acetaminophen", 500m, "mg", "161") }),
        new("1049630", "Nighttime Cold & Flu Relief", "Acetaminophen / Diphenhydramine", "Caplet", "325 mg", "Generic Health",
            new[]
            {
                new LocalIngredient("Acetaminophen", 325m, "mg", "161"),
                new LocalIngredient("Diphenhydramine HCl", 25m, "mg", "3498")
            }),
        new("198439", "Parol", "Paracetamol", "Tablet", "500 mg", "Atabay",
            new[] { new LocalIngredient("Paracetamol", 500m, "mg", "161") }),
        new("861007", "Glucophage", "Metformin Hydrochloride", "Tablet", "500 mg", "Merck",
            new[] { new LocalIngredient("Metformin Hydrochloride", 500m, "mg", "6809") }),
        new("197805", "Advil", "Ibuprofen", "Tablet", "400 mg", "Pfizer",
            new[] { new LocalIngredient("Ibuprofen", 400m, "mg", "5640") }),
        new("314076", "Zestril", "Lisinopril", "Tablet", "10 mg", "AstraZeneca",
            new[] { new LocalIngredient("Lisinopril", 10m, "mg", "29046") }),
        new("617311", "Lipitor", "Atorvastatin Calcium", "Tablet", "20 mg", "Pfizer",
            new[] { new LocalIngredient("Atorvastatin Calcium", 20m, "mg", "83367") }),
        new("308192", "Amoxil", "Amoxicillin", "Capsule", "500 mg", "GSK",
            new[] { new LocalIngredient("Amoxicillin", 500m, "mg", "723") }),
        new("1014678", "Zyrtec", "Cetirizine Hydrochloride", "Tablet", "10 mg", "UCB",
            new[] { new LocalIngredient("Cetirizine Hydrochloride", 10m, "mg", "20610") }),
        new("316945", "Vitamin D3", "Cholecalciferol", "Softgel", "1000 IU", "Nature's Own",
            new[] { new LocalIngredient("Cholecalciferol", 1000m, "IU", "2418") })
    };

    public Task<DrugSearchResult?> SearchAsync(DrugSearchRequest request, CancellationToken cancellationToken)
    {
        var candidates = Catalog
            .Select(entry => new DrugCandidate(
                ToIdentity(entry),
                MatchScoring.Score(
                    request,
                    entry.BrandName,
                    entry.GenericName,
                    entry.Ingredients.Select(i => i.Name))))
            .Where(candidate => candidate.MatchScore > 0.2)
            .OrderByDescending(candidate => candidate.MatchScore)
            .Take(5)
            .ToList();

        return Task.FromResult<DrugSearchResult?>(
            candidates.Count == 0 ? DrugSearchResult.NoMatch() : DrugSearchResult.Matched(candidates));
    }

    public Task<DrugDetails?> GetDrugAsync(string externalId, CancellationToken cancellationToken)
    {
        var entry = Catalog.FirstOrDefault(item => item.RxCui == externalId);
        return Task.FromResult(entry is null ? null : new DrugDetails(ToIdentity(entry), null));
    }

    private DrugIdentity ToIdentity(LocalDrugEntry entry) => new(
        entry.RxCui,
        entry.BrandName,
        entry.GenericName,
        entry.Ingredients
            .Select(ingredient => _normalizer.Normalize(ingredient.Name, ingredient.Strength, ingredient.Unit, ingredient.RxCui))
            .ToList(),
        entry.DosageForm,
        entry.Strength,
        entry.Manufacturer,
        new DataProvenance(ProviderName, entry.RxCui, _clock.UtcNow, DatasetVersion));

    private sealed record LocalDrugEntry(
        string RxCui,
        string BrandName,
        string GenericName,
        string DosageForm,
        string Strength,
        string Manufacturer,
        IReadOnlyCollection<LocalIngredient> Ingredients);

    private sealed record LocalIngredient(string Name, decimal? Strength, string? Unit, string? RxCui);
}
