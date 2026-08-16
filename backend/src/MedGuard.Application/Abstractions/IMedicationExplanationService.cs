using MedGuard.Domain.Entities;

namespace MedGuard.Application.Abstractions;

/// <summary>
/// Result of the explanation layer. <see cref="GeneratedByAi"/> is false whenever the
/// deterministic fallback text was used, so the UI can stay honest about its source.
/// </summary>
public sealed record MedicationExplanation(string Text, bool GeneratedByAi, string Source);

/// <summary>
/// Domain Rule 3: this service may only rephrase a finding that the deterministic
/// safety engine already produced. It can never create, upgrade or dismiss a finding.
/// </summary>
public interface IMedicationExplanationService
{
    Task<MedicationExplanation> ExplainAsync(
        SafetyFinding finding,
        string? language,
        CancellationToken cancellationToken);
}
