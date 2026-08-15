using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Safety;

namespace MedGuard.Contracts.Scanning;

/// <summary>
/// A scan submission. Either a captured image or client-side OCR text may be supplied.
/// The image is processed in memory and discarded unless <paramref name="RetainImage"/> is set.
/// </summary>
public sealed record ScanRequest(
    string? ImageBase64,
    string? MimeType,
    string? OcrText,
    bool RetainImage = false);

/// <summary>A single extracted value with its confidence metadata.</summary>
public sealed record ExtractedField(string? Value, double Confidence, string Source);

public sealed record ExtractedIngredient(
    ExtractedField Name,
    ExtractedField? Strength,
    ExtractedField? Unit);

public sealed record LabelExtractionResponse(
    ExtractedField BrandName,
    ExtractedField GenericName,
    IReadOnlyCollection<ExtractedIngredient> ActiveIngredients,
    ExtractedField DosageForm,
    ExtractedField Route,
    ExtractedField Directions,
    ExtractedField Manufacturer,
    ExtractedField ExpirationDate);

public sealed record MedicationCandidateResponse(
    string? RxCui,
    string BrandName,
    string GenericName,
    IReadOnlyCollection<IngredientInput> Ingredients,
    string? DosageForm,
    string? Strength,
    string? Manufacturer,
    double MatchScore,
    ProvenanceResponse Provenance);

public sealed record ScanResponse(
    Guid ScanId,
    string Status,
    decimal ExtractionConfidence,
    bool RequiresManualReview,
    string VerificationStatus,
    string Message,
    LabelExtractionResponse? Extraction,
    IReadOnlyCollection<MedicationCandidateResponse> Candidates,
    ScheduleSuggestionResponse? ScheduleSuggestion);

public sealed record ConfirmScanRequest(
    string? SelectedCandidateRxCui,
    string? BrandName,
    string? GenericName,
    IReadOnlyCollection<IngredientInput>? Ingredients,
    string? DosageForm,
    string? Strength,
    string? Route,
    string? LabelDirections,
    bool AcknowledgedUnverified = false);

public sealed record ConfirmScanResponse(
    MedicationResponse Medication,
    SafetyAnalysisResponse Safety,
    ScheduleSuggestionResponse? ScheduleSuggestion);

/// <summary>
/// Reminder times derived from the label wording. Purely a convenience suggestion:
/// nothing is created until the user confirms.
/// </summary>
public sealed record ScheduleSuggestionResponse(
    string? LabelInstruction,
    int TimesPerDay,
    IReadOnlyCollection<string> SuggestedTimes,
    string? DoseAmountText,
    bool RequiresUserConfirmation = true);
