using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Application.Schedules;
using MedGuard.Contracts.Adherence;
using MedGuard.Contracts.Auth;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Safety;
using MedGuard.Contracts.Scanning;
using MedGuard.Contracts.Schedules;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.Safety;

namespace MedGuard.Api.Common;

/// <summary>
/// Domain to contract mapping, including the user-facing wording for every state.
/// Copy lives here so the API and the app cannot drift apart.
/// </summary>
public static class ContractMapping
{
    public static UserResponse ToResponse(this User user) => new(
        user.Id,
        user.Email,
        user.DisplayName,
        user.TimeZoneId,
        user.SafetyNoticeAcknowledged,
        user.PrivacyNotificationsEnabled,
        user.BiometricLockEnabled,
        user.IsDemoAccount,
        user.EmailVerified);

    public static MedicationResponse ToResponse(this Medication medication, int activeScheduleCount = 0) => new(
        medication.Id,
        medication.DisplayName,
        medication.BrandName,
        medication.GenericName,
        medication.RxCui,
        medication.DosageForm,
        medication.Strength,
        medication.Route,
        medication.LabelDirections,
        medication.Manufacturer,
        medication.Notes,
        ToWireValue(medication.VerificationStatus),
        ToLabel(medication.VerificationStatus),
        medication.Ingredients.Select(ToResponse).ToList(),
        medication.Provenance is null
            ? null
            : new ProvenanceResponse(
                medication.Provenance.Provider,
                medication.Provenance.ExternalIdentifier,
                medication.Provenance.RetrievedAt,
                medication.Provenance.DatasetVersion),
        activeScheduleCount,
        medication.RemainingQuantity,
        medication.RemainingUpdatedAt,
        medication.CreatedAt,
        medication.UpdatedAt);

    public static IngredientResponse ToResponse(this MedicationIngredient ingredient) => new(
        ingredient.Id,
        ingredient.NormalizedName,
        ingredient.OriginalName,
        ingredient.Strength,
        ingredient.Unit,
        ingredient.RxCui,
        ingredient.DisplayStrength);

    public static string ToWireValue(MedicationVerificationStatus status) => status switch
    {
        MedicationVerificationStatus.Verified => "verified",
        MedicationVerificationStatus.VerificationUnavailable => "verification_unavailable",
        MedicationVerificationStatus.NoConfidentMatch => "no_confident_match",
        _ => "unverified"
    };

    public static string ToLabel(MedicationVerificationStatus status) => status switch
    {
        MedicationVerificationStatus.Verified => "Verified against a trusted medication database",
        MedicationVerificationStatus.VerificationUnavailable => "Verification unavailable right now",
        MedicationVerificationStatus.NoConfidentMatch => "No confident match found",
        _ => "Not independently verified"
    };

    public static SafetyAnalysisResponse ToResponse(this SafetyAnalysisResult result)
    {
        var (headline, subtext) = SafetyMessages.ForStatus(result.Status);

        return new SafetyAnalysisResponse(
            ToWireValue(result.Status),
            headline,
            subtext,
            result.Findings.Select(ToResponse).ToList(),
            result.Checks.Select(ToResponse).ToList(),
            result.AnalyzedAt);
    }

    public static SafetyFindingResponse ToResponse(this SafetyFinding finding) => new(
        finding.Id,
        ToWireValue(finding.Type),
        ToWireValue(finding.Severity),
        finding.Title,
        SafetyMessages.BodyFor(finding.Type),
        finding.IngredientNormalizedName is null && finding.IngredientRxCui is null
            ? null
            : new SafetyIngredientResponse(
                finding.IngredientDisplayName ?? finding.IngredientNormalizedName ?? string.Empty,
                finding.IngredientRxCui,
                finding.IngredientRxCui is null ? null : "RxNorm"),
        finding.Subjects
            .Select(subject => new SafetyMedicationResponse(
                subject.MedicationId,
                subject.MedicationName,
                subject.IngredientOriginalName,
                subject.StrengthText,
                subject.MedicationVerified))
            .ToList(),
        finding.SourceVerified,
        finding.Source,
        finding.DatasetVersion,
        finding.DetectedAt);

    public static SafetyCheckResponse ToResponse(this SafetyCheckOutcome outcome) => new(
        outcome.CheckName,
        outcome.State switch
        {
            SafetyCheckState.Completed => "completed",
            SafetyCheckState.Unavailable => "unavailable",
            SafetyCheckState.NotConfigured => "not_configured",
            _ => "skipped"
        },
        outcome.Detail);

    public static string ToWireValue(SafetyStatus status) => status switch
    {
        SafetyStatus.High => "high",
        SafetyStatus.Warning => "warning",
        SafetyStatus.Attention => "attention",
        _ => "no_findings"
    };

    public static string ToWireValue(SafetyFindingType type) => type switch
    {
        SafetyFindingType.DuplicateActiveIngredient => "duplicate_active_ingredient",
        SafetyFindingType.UnverifiedMedication => "unverified_medication",
        SafetyFindingType.InteractionCheckUnavailable => "interaction_check_unavailable",
        _ => "drug_interaction"
    };

    public static string ToWireValue(SafetySeverity severity) => severity switch
    {
        SafetySeverity.High => "high",
        SafetySeverity.Warning => "warning",
        _ => "info"
    };

    public static ScheduleResponse ToResponse(this MedicationSchedule schedule, string medicationName) => new(
        schedule.Id,
        schedule.MedicationId,
        medicationName,
        schedule.ReminderTime.ToString("HH:mm"),
        schedule.LabelInstruction,
        schedule.DoseAmountText,
        schedule.UserConfirmed,
        schedule.IsActive);

    public static DoseResponse ToResponse(this DoseEvent dose, TimeZoneInfo timeZone) => new(
        dose.Id,
        dose.MedicationId,
        dose.ScheduleId,
        dose.Medication?.DisplayName ?? "Medication",
        dose.Medication?.Strength,
        dose.Schedule?.DoseAmountText,
        dose.ScheduledAt,
        TimeZoneInfo.ConvertTime(dose.ScheduledAt, timeZone).ToString("HH:mm"),
        ToWireValue(dose.Status),
        ToLabel(dose.Status),
        dose.CompletedAt,
        dose.SnoozedUntil);

    public static string ToWireValue(DoseEventStatus status) => status switch
    {
        DoseEventStatus.Taken => "taken",
        DoseEventStatus.Skipped => "skipped",
        DoseEventStatus.Missed => "missed",
        DoseEventStatus.Snoozed => "snoozed",
        _ => "pending"
    };

    /// <summary>Neutral, non-judgemental status wording.</summary>
    public static string ToLabel(DoseEventStatus status) => status switch
    {
        DoseEventStatus.Taken => "Taken",
        DoseEventStatus.Skipped => "Skipped",
        DoseEventStatus.Missed => "Missed",
        DoseEventStatus.Snoozed => "Snoozed",
        _ => "Pending"
    };

    public static ScheduleSuggestionResponse ToResponse(this ScheduleSuggestion suggestion) => new(
        suggestion.LabelInstruction,
        suggestion.TimesPerDay,
        suggestion.SuggestedTimes.Select(time => time.ToString("HH:mm")).ToList(),
        suggestion.DoseAmountText);

    public static LabelExtractionResponse ToResponse(this LabelExtraction extraction) => new(
        ToResponse(extraction.BrandName),
        ToResponse(extraction.GenericName),
        extraction.ActiveIngredients
            .Select(ingredient => new ExtractedIngredient(
                ToResponse(ingredient.Name),
                ingredient.Strength is null ? null : ToResponse(ingredient.Strength),
                ingredient.Unit is null ? null : ToResponse(ingredient.Unit)))
            .ToList(),
        ToResponse(extraction.DosageForm),
        ToResponse(extraction.Route),
        ToResponse(extraction.Directions),
        ToResponse(extraction.Manufacturer),
        ToResponse(extraction.ExpirationDate));

    public static ExtractedField ToResponse(this ExtractedValue value) =>
        new(value.Value, Math.Round(value.Confidence, 2), value.Source);

    public static MedicationCandidateResponse ToResponse(this DrugCandidate candidate) => new(
        candidate.Identity.RxCui,
        candidate.Identity.BrandName,
        candidate.Identity.GenericName,
        candidate.Identity.Ingredients
            .Select(ingredient => new IngredientInput(
                ingredient.OriginalName,
                ingredient.Strength,
                ingredient.Unit,
                ingredient.RxCui))
            .ToList(),
        candidate.Identity.DosageForm,
        candidate.Identity.Strength,
        candidate.Identity.Manufacturer,
        Math.Round(candidate.MatchScore, 3),
        new ProvenanceResponse(
            candidate.Identity.Provenance.Provider,
            candidate.Identity.Provenance.ExternalIdentifier,
            candidate.Identity.Provenance.RetrievedAt,
            candidate.Identity.Provenance.DatasetVersion));
}
