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
