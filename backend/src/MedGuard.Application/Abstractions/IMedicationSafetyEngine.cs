using MedGuard.Domain.Entities;
using MedGuard.Domain.Safety;

namespace MedGuard.Application.Abstractions;

/// <summary>
/// The deterministic core of MedGuard. This component must never call a language model.
/// </summary>
public interface IMedicationSafetyEngine
{
    /// <summary>Analyses one candidate medication against everything the user already has saved.</summary>
    Task<SafetyAnalysisResult> AnalyzeAsync(
        Guid userId,
        Medication candidate,
        CancellationToken cancellationToken);

    /// <summary>Analyses the user's entire medication list.</summary>
    Task<SafetyAnalysisResult> AnalyzeUserAsync(
        Guid userId,
        CancellationToken cancellationToken);
}
