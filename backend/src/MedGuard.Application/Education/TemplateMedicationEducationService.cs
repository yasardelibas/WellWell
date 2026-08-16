namespace MedGuard.Application.Education;

/// <summary>
/// Deterministic fallback used when no model is configured, the model is unreachable, the
/// medication is not recognised, or generated text fails the output guard. It never claims
/// to know what a medication is for; it simply points the user to a trusted human source.
/// </summary>
public sealed class TemplateMedicationEducationService : IMedicationEducationService
{
    public const string SourceName = "medguard-template";
    public const string RxClassSourceName = "medguard-rxclass";

    public const string DisclaimerSentence =
        "This is general information, not medical advice — ask your pharmacist or doctor for guidance.";
    public const string DisclaimerSentenceTr =
        "Bu genel bir bilgidir, tıbbi tavsiye değildir — rehberlik için eczacınıza veya doktorunuza danışın.";

    public const string FallbackMessage =
        "General information about this medication isn't available here. Check the label and " +
        "ask your pharmacist or doctor what it's for and how to take it.";
    public const string FallbackMessageTr =
        "Bu ilaç hakkında genel bilgi burada mevcut değil. Etiketi kontrol edin ve ne için " +
        "olduğunu ve nasıl kullanılacağını eczacınıza veya doktorunuza sorun.";

    public Task<MedicationEducation> ExplainAsync(MedicationEducationInput input, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        var tr = string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);

        // When authoritative RxClass data is available we can build a factual, deterministic
        // description without any model — this is safer than an AI guess and always cited.
        if (input.KnownUses is { Count: > 0 })
        {
            return Task.FromResult(new MedicationEducation(BuildFromClassification(input, language), GeneratedByAi: false, IsAvailable: true, RxClassSourceName));
        }

        return Task.FromResult(new MedicationEducation(tr ? FallbackMessageTr : FallbackMessage, GeneratedByAi: false, IsAvailable: false, SourceName));
    }

    public static string BuildFromClassification(MedicationEducationInput input, string? language = null)
    {
        var tr = string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);
        var uses = string.Join(", ", input.KnownUses!.Take(4));

        if (tr)
        {
            var classPartTr = string.IsNullOrWhiteSpace(input.KnownClass)
                ? string.Empty
                : $" {input.KnownClass} sınıfı ilaçlardandır.";
            return $"{input.DisplayName} genellikle şunlar için kullanılır: {uses}.{classPartTr} {DisclaimerSentenceTr}";
        }

        var classPart = string.IsNullOrWhiteSpace(input.KnownClass)
            ? string.Empty
            : $" It belongs to the {input.KnownClass} class of medicines.";

        return $"{input.DisplayName} is commonly used for: {uses}.{classPart} {DisclaimerSentence}";
    }
}
