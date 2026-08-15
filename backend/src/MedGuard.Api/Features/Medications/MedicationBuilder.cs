using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;
using MedGuard.Contracts.Medications;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.Api.Features.Medications;

public sealed record MedicationDraft(
    string? BrandName,
    string? GenericName,
    IReadOnlyCollection<IngredientInput> Ingredients,
    string? DosageForm,
    string? Strength,
    string? Route,
    string? LabelDirections,
    string? Notes);

public sealed record BuiltMedication(Medication Medication, MedicationVerificationOutcome Outcome);

/// <summary>
/// Single place where a medication record is created, so the verification rule is applied
/// identically whether the medication came from a scan or from manual entry.
/// </summary>
public sealed class MedicationBuilder
{
    private readonly IIngredientNormalizer _normalizer;
    private readonly MedicationVerificationService _verification;
    private readonly IDateTimeProvider _clock;

    public MedicationBuilder(
        IIngredientNormalizer normalizer,
        MedicationVerificationService verification,
        IDateTimeProvider clock)
    {
        _normalizer = normalizer;
        _verification = verification;
        _clock = clock;
    }

    public async Task<BuiltMedication> BuildAsync(
        Guid userId,
        MedicationDraft draft,
        bool attemptVerification,
        Guid? sourceScanId,
        CancellationToken cancellationToken,
        string? preferredExternalId = null)
    {
        var ingredients = draft.Ingredients
            .Where(ingredient => !string.IsNullOrWhiteSpace(ingredient.Name))
            .Select(ingredient => _normalizer.Normalize(ingredient.Name, ingredient.Strength, ingredient.Unit, ingredient.RxCui))
            .ToList();

        var outcome = attemptVerification
            ? await _verification.VerifyAsync(
                new DrugSearchRequest(
                    draft.BrandName,
                    draft.GenericName,
                    ingredients.Select(ingredient => ingredient.OriginalName).ToList(),
                    draft.Strength,
                    draft.DosageForm),
                cancellationToken,
                preferredExternalId)
            : new MedicationVerificationOutcome(
                MedicationVerificationStatus.Unverified,
                null,
                Array.Empty<DrugCandidate>(),
                "Verification was not requested for this medication.");

        var match = outcome.Status == MedicationVerificationStatus.Verified ? outcome.BestMatch : null;

        // Canonical ingredient identifiers only come from a confirmed provider match.
        if (match is not null)
        {
            ingredients = EnrichWithCanonicalIdentifiers(ingredients, match.Ingredients);
        }

        var medication = Medication.Create(
            userId,
            draft.BrandName ?? match?.BrandName ?? string.Empty,
            draft.GenericName ?? match?.GenericName ?? string.Empty,
            ingredients,
            outcome.Status,
            _clock.UtcNow,
            match?.RxCui,
            draft.DosageForm ?? match?.DosageForm,
            draft.Strength ?? match?.Strength,
            draft.Route,
            draft.LabelDirections,
            match?.Manufacturer,
            draft.Notes,
            outcome.Provenance,
            sourceScanId);

        return new BuiltMedication(medication, outcome);
    }

    private List<ActiveIngredient> EnrichWithCanonicalIdentifiers(
        IReadOnlyCollection<ActiveIngredient> ingredients,
        IReadOnlyCollection<ActiveIngredient> matched)
    {
        if (ingredients.Count == 0)
        {
            return matched.ToList();
        }

        return ingredients
            .Select(ingredient =>
            {
                if (!string.IsNullOrWhiteSpace(ingredient.RxCui))
                {
                    return ingredient;
                }

                var counterpart = matched.FirstOrDefault(candidate =>
                    string.Equals(candidate.NormalizedName, ingredient.NormalizedName, StringComparison.OrdinalIgnoreCase));

                return counterpart?.RxCui is null
                    ? ingredient
                    : ingredient with { RxCui = counterpart.RxCui };
            })
            .ToList();
    }
}
