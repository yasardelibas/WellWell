using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.Domain.Entities;

public sealed class Medication
{
    private readonly List<MedicationIngredient> _ingredients = new();

    private Medication()
    {
        BrandName = string.Empty;
        GenericName = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string? RxCui { get; private set; }

    public string BrandName { get; private set; }

    public string GenericName { get; private set; }

    public IReadOnlyCollection<MedicationIngredient> Ingredients => _ingredients.AsReadOnly();

    public string? DosageForm { get; private set; }

    public string? Strength { get; private set; }

    public string? Route { get; private set; }

    /// <summary>Directions exactly as printed on the label. MedGuard never rewrites these.</summary>
    public string? LabelDirections { get; private set; }

    public string? Manufacturer { get; private set; }

    public string? Notes { get; private set; }

    /// <summary>How many doses (pills, sprays, etc.) the user says they have left. Optional.</summary>
    public int? RemainingQuantity { get; private set; }

    /// <summary>When the user last updated <see cref="RemainingQuantity"/>, used to age the count.</summary>
    public DateTimeOffset? RemainingUpdatedAt { get; private set; }

    /// <summary>Printed on the label. Self-reported or scan-extracted, never a clinical instruction.</summary>
    public DateOnly? ExpirationDate { get; private set; }

    public MedicationVerificationStatus VerificationStatus { get; private set; }
        = MedicationVerificationStatus.Unverified;

    public string? ProvenanceProvider { get; private set; }

    public string? ProvenanceExternalId { get; private set; }

    public DateTimeOffset? ProvenanceRetrievedAt { get; private set; }

    public string? ProvenanceDatasetVersion { get; private set; }

    public Guid? SourceScanId { get; private set; }

    public bool IsArchived { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public DataProvenance? Provenance => ProvenanceProvider is null || ProvenanceRetrievedAt is null
        ? null
        : new DataProvenance(ProvenanceProvider, ProvenanceExternalId, ProvenanceRetrievedAt.Value, ProvenanceDatasetVersion);

    public string DisplayName => string.IsNullOrWhiteSpace(BrandName) ? GenericName : BrandName;

    /// <summary>
    /// Domain Rule 1: a medication may only be created as <see cref="MedicationVerificationStatus.Verified"/>
    /// when trusted provider provenance accompanies it.
    /// </summary>
    public static Medication Create(
        Guid userId,
        string brandName,
        string genericName,
        IEnumerable<ActiveIngredient> ingredients,
        MedicationVerificationStatus verificationStatus,
        DateTimeOffset now,
        string? rxCui = null,
        string? dosageForm = null,
        string? strength = null,
        string? route = null,
        string? labelDirections = null,
        string? manufacturer = null,
        string? notes = null,
        DataProvenance? provenance = null,
        Guid? sourceScanId = null,
        DateOnly? expirationDate = null)
    {
        if (string.IsNullOrWhiteSpace(brandName) && string.IsNullOrWhiteSpace(genericName))
        {
            throw new ArgumentException("A medication needs at least a brand name or a generic name.", nameof(brandName));
        }

        if (verificationStatus == MedicationVerificationStatus.Verified && provenance is null)
        {
            throw new InvalidOperationException(
                "A medication cannot be marked verified without provenance from a trusted drug data provider.");
        }

        var medication = new Medication
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BrandName = (brandName ?? string.Empty).Trim(),
            GenericName = (genericName ?? string.Empty).Trim(),
            RxCui = rxCui,
            DosageForm = dosageForm,
            Strength = strength,
            Route = route,
            LabelDirections = labelDirections,
            Manufacturer = manufacturer,
            Notes = notes,
            VerificationStatus = verificationStatus,
            SourceScanId = sourceScanId,
            ExpirationDate = expirationDate,
            CreatedAt = now,
            UpdatedAt = now
        };

        medication.ApplyProvenance(provenance);
        medication.ReplaceIngredients(ingredients, now);
        return medication;
    }

    public void ReplaceIngredients(IEnumerable<ActiveIngredient> ingredients, DateTimeOffset now)
    {
        _ingredients.Clear();
        foreach (var ingredient in ingredients)
        {
            _ingredients.Add(MedicationIngredient.FromValue(ingredient));
        }

        UpdatedAt = now;
    }

    public void UpdateDetails(
        string? brandName,
        string? genericName,
        string? dosageForm,
        string? strength,
        string? route,
        string? labelDirections,
        string? notes,
        DateTimeOffset now)
    {
        if (!string.IsNullOrWhiteSpace(brandName))
        {
            BrandName = brandName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(genericName))
        {
            GenericName = genericName.Trim();
        }

        DosageForm = dosageForm ?? DosageForm;
        Strength = strength ?? Strength;
        Route = route ?? Route;
        LabelDirections = labelDirections ?? LabelDirections;
        Notes = notes ?? Notes;
        UpdatedAt = now;
    }

    /// <summary>
    /// Any user edit of identifying fields invalidates a previous provider match:
    /// the record falls back to unverified until it is matched again.
    /// </summary>
    public void InvalidateVerification(DateTimeOffset now)
    {
        VerificationStatus = MedicationVerificationStatus.Unverified;
        ApplyProvenance(null);
        UpdatedAt = now;
    }

    public void MarkVerified(DataProvenance provenance, string? rxCui, DateTimeOffset now)
    {
        ArgumentNullException.ThrowIfNull(provenance);
        VerificationStatus = MedicationVerificationStatus.Verified;
        RxCui = rxCui ?? RxCui;
        ApplyProvenance(provenance);
        UpdatedAt = now;
    }

    public void MarkVerificationUnavailable(DateTimeOffset now)
    {
        VerificationStatus = MedicationVerificationStatus.VerificationUnavailable;
        UpdatedAt = now;
    }

    public void Archive(DateTimeOffset now)
    {
        IsArchived = true;
        UpdatedAt = now;
    }

    /// <summary>
    /// Records the user's own count of remaining doses. Passing null clears it. Negative
    /// values are clamped to zero. This is a self-reported convenience for refill reminders,
    /// never a clinical instruction.
    /// </summary>
    public void SetRemainingQuantity(int? remainingQuantity, DateTimeOffset now)
    {
        RemainingQuantity = remainingQuantity is < 0 ? 0 : remainingQuantity;
        RemainingUpdatedAt = remainingQuantity is null ? null : now;
        UpdatedAt = now;
    }

    /// <summary>Records the expiration date printed on the label. Passing null clears it.</summary>
    public void SetExpirationDate(DateOnly? expirationDate, DateTimeOffset now)
    {
        ExpirationDate = expirationDate;
        UpdatedAt = now;
    }

    private void ApplyProvenance(DataProvenance? provenance)
    {
        ProvenanceProvider = provenance?.Provider;
        ProvenanceExternalId = provenance?.ExternalIdentifier;
        ProvenanceRetrievedAt = provenance?.RetrievedAt;
        ProvenanceDatasetVersion = provenance?.DatasetVersion;
    }
}
