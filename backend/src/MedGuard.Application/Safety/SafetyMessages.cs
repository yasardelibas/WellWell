using MedGuard.Domain.Enums;

namespace MedGuard.Application.Safety;

/// <summary>
/// Single source of truth for user-facing safety copy. The wording deliberately avoids
/// reassurance ("safe together") and moral judgement ("poor adherence"). Every method here
/// derives text fresh from a language-neutral <see cref="SafetyFindingType"/>/<see cref="SafetyStatus"/>
/// at read time — nothing here is ever persisted as literal text, so switching a user's language
/// changes what they see on the next request with no data migration involved.
/// </summary>
public static class SafetyMessages
{
    public const string DuplicateCheckName = "duplicate_active_ingredient";

    public const string InteractionCheckName = "drug_interaction";

    public const string VerificationCheckName = "medication_verification";

    private const string DuplicateIngredientTitleEn = "Possible duplicate ingredient";
    private const string DuplicateIngredientTitleTr = "Olası aktif madde tekrarı";

    private const string DuplicateIngredientBodyEn =
        "Taking multiple products containing the same active ingredient can require additional attention. " +
        "Review the medication labels and confirm with a pharmacist or healthcare professional if you're unsure.";
    private const string DuplicateIngredientBodyTr =
        "Aynı aktif maddeyi içeren birden fazla ürünü kullanmak ekstra dikkat gerektirebilir. " +
        "İlaç etiketlerini gözden geçirin ve emin değilseniz bir eczacıya veya sağlık uzmanına danışın.";

    private const string UnverifiedTitleEn = "Not independently verified";
    private const string UnverifiedTitleTr = "Bağımsız olarak doğrulanmadı";

    private const string UnverifiedBodyEn =
        "WellWell could not match this medication against a trusted medication database, so its details " +
        "come from what was entered or read from the label. Please double-check the label.";
    private const string UnverifiedBodyTr =
        "WellWell bu ilacı güvenilir bir ilaç veritabanıyla eşleştiremedi, bu yüzden bilgiler girilen " +
        "veya etiketten okunan verilere dayanıyor. Lütfen etiketi tekrar kontrol edin.";

    private const string InteractionUnavailableTitleEn = "Interaction checking is not available";
    private const string InteractionUnavailableTitleTr = "Etkileşim kontrolü kullanılamıyor";

    private const string InteractionUnavailableBodyEn =
        "Interaction checking is not available for this medication. WellWell has not checked for " +
        "drug-drug interactions and this does not mean none exist.";
    private const string InteractionUnavailableBodyTr =
        "Bu ilaç için etkileşim kontrolü kullanılamıyor. WellWell ilaç-ilaç etkileşimlerini kontrol " +
        "etmedi; bu, herhangi bir etkileşim olmadığı anlamına gelmez.";

    private const string NoFindingsHeadlineEn = "No duplicate active ingredients detected";
    private const string NoFindingsHeadlineTr = "Tekrarlayan aktif madde tespit edilmedi";

    private const string NoFindingsSubtextEn =
        "Based on the medications currently saved in WellWell. This is not a confirmation that these medications are suitable together.";
    private const string NoFindingsSubtextTr =
        "WellWell'da şu anda kayıtlı olan ilaçlara dayanmaktadır. Bu, ilaçların birlikte kullanıma uygun olduğunun onayı değildir.";

    private const string AttentionHeadlineEn = "Some details need your attention";
    private const string AttentionHeadlineTr = "Bazı ayrıntılar dikkatinizi gerektiriyor";

    private const string AttentionSubtextEn =
        "WellWell could not complete every check, or some medications are unverified. Unknown does not mean safe.";
    private const string AttentionSubtextTr =
        "WellWell tüm kontrolleri tamamlayamadı veya bazı ilaçlar doğrulanmadı. Bilinmiyor olması güvenli anlamına gelmez.";

    private const string WarningHeadlineEn = "Possible duplicate ingredient detected";
    private const string WarningHeadlineTr = "Olası tekrarlayan aktif madde tespit edildi";

    private const string WarningSubtextEn =
        "Review the medication labels and speak with a pharmacist or healthcare professional if you're unsure.";
    private const string WarningSubtextTr =
        "İlaç etiketlerini gözden geçirin ve emin değilseniz bir eczacı veya sağlık uzmanıyla görüşün.";

    private const string HighHeadlineEn = "Please review this with a healthcare professional";
    private const string HighHeadlineTr = "Lütfen bunu bir sağlık uzmanıyla gözden geçirin";

    private const string HighSubtextEn =
        "WellWell found something that needs attention before your next dose. Follow your medication label.";
    private const string HighSubtextTr =
        "WellWell bir sonraki dozunuzdan önce dikkat gerektiren bir şey buldu. İlaç etiketinizi takip edin.";

    private const string GeneralDisclaimerEn =
        "WellWell does not provide medical advice, diagnoses or dosage instructions. Always follow your medication label and your healthcare professional.";
    private const string GeneralDisclaimerTr =
        "WellWell tıbbi tavsiye, teşhis veya doz talimatı sunmaz. Her zaman ilaç etiketinizi ve sağlık uzmanınızı takip edin.";

    private static bool IsTurkish(string? language) => string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);

    public static string GeneralDisclaimer(string? language) => IsTurkish(language) ? GeneralDisclaimerTr : GeneralDisclaimerEn;

    public static (string Headline, string Subtext) ForStatus(SafetyStatus status, string? language)
    {
        var tr = IsTurkish(language);
        return status switch
        {
            SafetyStatus.High => (tr ? HighHeadlineTr : HighHeadlineEn, tr ? HighSubtextTr : HighSubtextEn),
            SafetyStatus.Warning => (tr ? WarningHeadlineTr : WarningHeadlineEn, tr ? WarningSubtextTr : WarningSubtextEn),
            SafetyStatus.Attention => (tr ? AttentionHeadlineTr : AttentionHeadlineEn, tr ? AttentionSubtextTr : AttentionSubtextEn),
            _ => (tr ? NoFindingsHeadlineTr : NoFindingsHeadlineEn, tr ? NoFindingsSubtextTr : NoFindingsSubtextEn)
        };
    }

    public static string TitleFor(SafetyFindingType type, string? language)
    {
        var tr = IsTurkish(language);
        return type switch
        {
            SafetyFindingType.DuplicateActiveIngredient => tr ? DuplicateIngredientTitleTr : DuplicateIngredientTitleEn,
            SafetyFindingType.UnverifiedMedication => tr ? UnverifiedTitleTr : UnverifiedTitleEn,
            SafetyFindingType.InteractionCheckUnavailable => tr ? InteractionUnavailableTitleTr : InteractionUnavailableTitleEn,
            _ => tr ? DuplicateIngredientTitleTr : DuplicateIngredientTitleEn
        };
    }

    public static string BodyFor(SafetyFindingType type, string? language)
    {
        var tr = IsTurkish(language);
        return type switch
        {
            SafetyFindingType.DuplicateActiveIngredient => tr ? DuplicateIngredientBodyTr : DuplicateIngredientBodyEn,
            SafetyFindingType.UnverifiedMedication => tr ? UnverifiedBodyTr : UnverifiedBodyEn,
            SafetyFindingType.InteractionCheckUnavailable => tr ? InteractionUnavailableBodyTr : InteractionUnavailableBodyEn,
            _ => tr ? GeneralDisclaimerTr : GeneralDisclaimerEn
        };
    }

    // English-only literals, used solely at finding-creation time in MedicationSafetyEngine where the
    // value is persisted (Domain.SafetyFinding.Title). Not part of the read-time localization surface -
    // ContractMapping.ToResponse prefers TitleFor(type, language)/BodyFor(type, language) over these.
    public const string DuplicateIngredientTitle = DuplicateIngredientTitleEn;
    public const string UnverifiedTitle = UnverifiedTitleEn;
    public const string InteractionUnavailableBody = InteractionUnavailableBodyEn;
}
