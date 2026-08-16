using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;

namespace MedGuard.Domain.Safety;

public enum SafetyCheckState
{
    /// <summary>The check ran end to end against available data.</summary>
    Completed = 0,

    /// <summary>A required data source could not be reached. Not a pass.</summary>
    Unavailable = 1,

    /// <summary>No provider is configured for this check. Not a pass.</summary>
    NotConfigured = 2,

    /// <summary>Nothing to compare, e.g. no ingredients on record. Not a pass.</summary>
    Skipped = 3
}

/// <summary>
/// Per-check outcome so the UI can distinguish "we checked and found nothing"
/// from "we could not check". Domain Rule 7: unknown does not mean safe.
/// </summary>
public sealed record SafetyCheckOutcome(string CheckName, SafetyCheckState State, string? Detail = null);

public sealed record SafetyAnalysisResult(
    SafetyStatus Status,
    IReadOnlyCollection<SafetyFinding> Findings,
    IReadOnlyCollection<SafetyCheckOutcome> Checks,
    DateTimeOffset AnalyzedAt)
{
    public bool HasIncompleteChecks => Checks.Any(c => c.State is SafetyCheckState.Unavailable or SafetyCheckState.NotConfigured);

    public static SafetyStatus DeriveStatus(
        IReadOnlyCollection<SafetyFinding> findings,
        IReadOnlyCollection<SafetyCheckOutcome> checks)
    {
        if (findings.Any(f => f.Severity == SafetySeverity.High))
        {
            return SafetyStatus.High;
        }

        if (findings.Any(f => f.Severity == SafetySeverity.Warning))
        {
            return SafetyStatus.Warning;
        }

        // A configured source that failed is different from a capability MedGuard never had:
        // the first degrades the result, the second is reported as a permanently unavailable check.
        if (findings.Any(f => f.Severity == SafetySeverity.Info) ||
            checks.Any(c => c.State == SafetyCheckState.Unavailable))
        {
            return SafetyStatus.Attention;
        }

        return SafetyStatus.NoFindings;
    }
}
