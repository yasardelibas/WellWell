namespace MedGuard.Contracts.Adherence;

public sealed record DoseResponse(
    Guid Id,
    Guid MedicationId,
    Guid ScheduleId,
    string MedicationName,
    string? StrengthText,
    string? DoseAmountText,
    DateTimeOffset ScheduledAt,
    string ScheduledTime,
    string Status,
    string StatusLabel,
    DateTimeOffset? CompletedAt,
    DateTimeOffset? SnoozedUntil);

/// <summary>
/// Today's plan. Counts use neutral wording: completed / pending / missed, never a score.
/// </summary>
public sealed record TodayScheduleResponse(
    DateOnly Date,
    IReadOnlyCollection<DoseResponse> Doses,
    int CompletedCount,
    int TotalCount,
    string ProgressLabel);

public sealed record SnoozeDoseRequest(int Minutes = 15);

public sealed record AdherenceDayResponse(DateOnly Date, IReadOnlyCollection<DoseResponse> Doses);

public sealed record AdherenceHistoryResponse(
    DateOnly From,
    DateOnly To,
    IReadOnlyCollection<AdherenceDayResponse> Days,
    int TakenCount,
    int SkippedCount,
    int MissedCount,
    int PendingCount);

/// <summary>
/// A short, encouraging weekly recap. The counts are deterministic; <see cref="Message"/> is
/// a plain-language rephrasing (AI or template) that never adds medical advice.
/// </summary>
public sealed record AdherenceSummaryResponse(
    DateOnly From,
    DateOnly To,
    int TakenCount,
    int SkippedCount,
    int MissedCount,
    int PendingCount,
    int AdherencePercent,
    string Message,
    bool GeneratedByAi);

/// <summary>A one-sentence, non-judgemental nudge for today's plan.</summary>
public sealed record DailyNudgeResponse(
    int CompletedCount,
    int TotalCount,
    string Message,
    bool GeneratedByAi);

/// <summary>
/// A richer wellness recap over the last 30 days: adherence, an on-time streak and the
/// time-of-day window most often missed. Counts and streak are deterministic; the message
/// is a plain-language rephrasing that never adds medical advice.
/// </summary>
public sealed record AdherenceInsightsResponse(
    DateOnly From,
    DateOnly To,
    int TakenCount,
    int SkippedCount,
    int MissedCount,
    int PendingCount,
    int AdherencePercent,
    int StreakDays,
    string? WeakestTimeOfDay,
    string Message,
    bool GeneratedByAi);
