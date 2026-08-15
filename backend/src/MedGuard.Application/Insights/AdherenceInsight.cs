namespace MedGuard.Application.Insights;

/// <summary>
/// Deterministic adherence counts for a window. These come straight from dose events;
/// the insight layer may only rephrase them, never invent or reinterpret them.
/// </summary>
public sealed record AdherenceStats(
    int TakenCount,
    int SkippedCount,
    int MissedCount,
    int PendingCount)
{
    /// <summary>Doses that already have an outcome (taken, skipped or missed).</summary>
    public int ResolvedCount => TakenCount + SkippedCount + MissedCount;

    public int TotalCount => ResolvedCount + PendingCount;

    /// <summary>Share of resolved doses that were taken. 0 when nothing has resolved yet.</summary>
    public int AdherencePercent => ResolvedCount == 0
        ? 0
        : (int)Math.Round(100.0 * TakenCount / ResolvedCount, MidpointRounding.AwayFromZero);
}

/// <summary>Today's plan reduced to the numbers a daily nudge needs.</summary>
public sealed record DailyAdherenceStats(int CompletedCount, int TotalCount)
{
    public int RemainingCount => Math.Max(0, TotalCount - CompletedCount);
}

/// <summary>
/// Deterministic inputs for the richer wellness recap: an on-time streak and the time-of-day
/// window (if any) the user tends to miss. All values are computed from dose events.
/// </summary>
public sealed record AdherenceInsightsInput(
    int AdherencePercent,
    int StreakDays,
    string? WeakestTimeOfDay);

/// <summary>
/// Result of the insight layer. <see cref="GeneratedByAi"/> is false whenever the
/// deterministic template was used, so the UI can stay honest about its source.
/// </summary>
public sealed record AdherenceInsight(string Message, bool GeneratedByAi, string Source);

/// <summary>
/// Turns deterministic adherence counts into a short, encouraging, non-judgemental
/// sentence. It must never give medical advice, name a medication, change a dose or
/// invent numbers; it only rephrases what already happened.
/// </summary>
public interface IAdherenceInsightService
{
    Task<AdherenceInsight> SummarizeWeekAsync(AdherenceStats stats, CancellationToken cancellationToken);

    Task<AdherenceInsight> DailyNudgeAsync(DailyAdherenceStats stats, CancellationToken cancellationToken);

    Task<AdherenceInsight> SummarizeInsightsAsync(AdherenceInsightsInput input, CancellationToken cancellationToken);
}
