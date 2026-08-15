namespace MedGuard.Contracts.Medications;

public sealed record IngredientInput(string Name, decimal? Strength, string? Unit, string? RxCui);

public sealed record CreateMedicationRequest(
    string? BrandName,
    string? GenericName,
    IReadOnlyCollection<IngredientInput> Ingredients,
    string? DosageForm,
    string? Strength,
    string? Route,
    string? LabelDirections,
    string? Notes,
    bool AttemptVerification = true);

public sealed record UpdateMedicationRequest(
    string? BrandName,
    string? GenericName,
    IReadOnlyCollection<IngredientInput>? Ingredients,
    string? DosageForm,
    string? Strength,
    string? Route,
    string? LabelDirections,
    string? Notes);

public sealed record ProvenanceResponse(
    string Provider,
    string? ExternalIdentifier,
    DateTimeOffset RetrievedAt,
    string? DatasetVersion);

public sealed record IngredientResponse(
    Guid Id,
    string NormalizedName,
    string OriginalName,
    decimal? Strength,
    string? Unit,
    string? RxCui,
    string DisplayStrength);

public sealed record MedicationResponse(
    Guid Id,
    string DisplayName,
    string BrandName,
    string GenericName,
    string? RxCui,
    string? DosageForm,
    string? Strength,
    string? Route,
    string? LabelDirections,
    string? Manufacturer,
    string? Notes,
    string VerificationStatus,
    string VerificationLabel,
    IReadOnlyCollection<IngredientResponse> Ingredients,
    ProvenanceResponse? Provenance,
    int ActiveScheduleCount,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
