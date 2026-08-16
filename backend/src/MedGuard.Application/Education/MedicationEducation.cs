namespace MedGuard.Application.Education;

/// <summary>
/// Anonymous, non-identifying inputs for the education layer. Only the medication's names
/// and ingredient names are shared — never the user, dose, schedule or any personal data.
/// </summary>
public sealed record MedicationEducationInput(
    string DisplayName,
    string? GenericName,
    IReadOnlyCollection<string> Ingredients,
    IReadOnlyCollection<string>? KnownUses = null,
    string? KnownClass = null);

/// <summary>
/// Result of the education layer. <see cref="IsAvailable"/> is false when we could only
/// return the generic "ask your pharmacist" fallback, so the UI can present it honestly.
/// </summary>
public sealed record MedicationEducation(string Message, bool GeneratedByAi, bool IsAvailable, string Source);

/// <summary>
/// Produces a short, plain-language, general description of what a medication is commonly
/// used for. It must never give personal medical advice, mention doses, diagnose, or list
/// warnings — it only offers general educational context and always defers to a professional.
/// </summary>
public interface IMedicationEducationService
{
    Task<MedicationEducation> ExplainAsync(MedicationEducationInput input, string? language, CancellationToken cancellationToken);
}
