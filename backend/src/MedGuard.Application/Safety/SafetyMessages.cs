using MedGuard.Domain.Enums;

namespace MedGuard.Application.Safety;

/// <summary>
/// Single source of truth for user-facing safety copy. The wording deliberately avoids
/// reassurance ("safe together") and moral judgement ("poor adherence").
/// </summary>
public static class SafetyMessages
{
    public const string DuplicateIngredientTitle = "Possible duplicate ingredient";

    public const string DuplicateIngredientBody =
        "Taking multiple products containing the same active ingredient can require additional attention. " +
        "Review the medication labels and confirm with a pharmacist or healthcare professional if you're unsure.";

    public const string UnverifiedTitle = "Not independently verified";

    public const string UnverifiedBody =
        "MedGuard could not match this medication against a trusted medication database, so its details " +
        "come from what was entered or read from the label. Please double-check the label.";

    public const string InteractionUnavailableTitle = "Interaction checking is not available";

    public const string InteractionUnavailableBody =
        "Interaction checking is not available for this medication. MedGuard has not checked for " +
        "drug-drug interactions and this does not mean none exist.";

    public const string NoFindingsHeadline = "No duplicate active ingredients detected";

    public const string NoFindingsSubtext =
        "Based on the medications currently saved in MedGuard. This is not a confirmation that these medications are suitable together.";

    public const string AttentionHeadline = "Some details need your attention";

    public const string AttentionSubtext =
        "MedGuard could not complete every check, or some medications are unverified. Unknown does not mean safe.";

    public const string WarningHeadline = "Possible duplicate ingredient detected";

    public const string WarningSubtext =
        "Review the medication labels and speak with a pharmacist or healthcare professional if you're unsure.";

    public const string HighHeadline = "Please review this with a healthcare professional";

    public const string HighSubtext =
        "MedGuard found something that needs attention before your next dose. Follow your medication label.";

    public const string GeneralDisclaimer =
        "MedGuard does not provide medical advice, diagnoses or dosage instructions. Always follow your medication label and your healthcare professional.";

    public const string DuplicateCheckName = "duplicate_active_ingredient";

    public const string InteractionCheckName = "drug_interaction";

    public const string VerificationCheckName = "medication_verification";

    public static (string Headline, string Subtext) ForStatus(SafetyStatus status) => status switch
    {
        SafetyStatus.High => (HighHeadline, HighSubtext),
        SafetyStatus.Warning => (WarningHeadline, WarningSubtext),
        SafetyStatus.Attention => (AttentionHeadline, AttentionSubtext),
        _ => (NoFindingsHeadline, NoFindingsSubtext)
    };

    public static string BodyFor(SafetyFindingType type) => type switch
    {
        SafetyFindingType.DuplicateActiveIngredient => DuplicateIngredientBody,
        SafetyFindingType.UnverifiedMedication => UnverifiedBody,
        SafetyFindingType.InteractionCheckUnavailable => InteractionUnavailableBody,
        _ => GeneralDisclaimer
    };
}
