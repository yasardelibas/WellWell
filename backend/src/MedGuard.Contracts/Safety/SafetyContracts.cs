namespace MedGuard.Contracts.Safety;

public sealed record SafetyIngredientResponse(string Name, string? Identifier, string? IdentifierSystem);

public sealed record SafetyMedicationResponse(
    Guid Id,
    string Name,
    string? IngredientOriginalName,
    string? StrengthText,
    bool Verified);

public sealed record SafetyFindingResponse(
    Guid Id,
    string Type,
    string Severity,
    string Title,
    string Message,
    SafetyIngredientResponse? Ingredient,
    IReadOnlyCollection<SafetyMedicationResponse> Medications,
    bool Verified,
    string Source,
    string? DatasetVersion,
    DateTimeOffset DetectedAt);

public sealed record SafetyCheckResponse(string Check, string State, string? Detail);

public sealed record SafetyAnalysisResponse(
    string Status,
    string Headline,
    string Subtext,
    IReadOnlyCollection<SafetyFindingResponse> Findings,
    IReadOnlyCollection<SafetyCheckResponse> Checks,
    DateTimeOffset AnalyzedAt);

public sealed record AnalyzeSafetyRequest(Guid? MedicationId);

/// <summary>
/// Plain-language explanation of an existing, already-verified finding.
/// <paramref name="GeneratedByAi"/> is false when the deterministic fallback text was used.
/// </summary>
public sealed record SafetyExplanationResponse(
    Guid FindingId,
    string Explanation,
    bool GeneratedByAi,
    string Source,
    string Disclaimer);
