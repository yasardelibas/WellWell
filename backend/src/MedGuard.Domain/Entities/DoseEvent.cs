using MedGuard.Domain.Enums;

namespace MedGuard.Domain.Entities;

public sealed class DoseEvent
{
    private DoseEvent()
    {
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public Guid MedicationId { get; private set; }

    public Guid ScheduleId { get; private set; }

    public DateTimeOffset ScheduledAt { get; private set; }

    public DateTimeOffset? CompletedAt { get; private set; }

    public DateTimeOffset? SnoozedUntil { get; private set; }

    public DoseEventStatus Status { get; private set; } = DoseEventStatus.Pending;

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public Medication? Medication { get; private set; }

    public MedicationSchedule? Schedule { get; private set; }

    public static DoseEvent CreatePending(
        Guid userId,
        Guid medicationId,
        Guid scheduleId,
        DateTimeOffset scheduledAt,
        DateTimeOffset now) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            MedicationId = medicationId,
            ScheduleId = scheduleId,
            ScheduledAt = scheduledAt,
            Status = DoseEventStatus.Pending,
            CreatedAt = now,
            UpdatedAt = now
        };

    public void MarkTaken(DateTimeOffset takenAt)
    {
        Status = DoseEventStatus.Taken;
        CompletedAt = takenAt;
        SnoozedUntil = null;
        UpdatedAt = takenAt;
    }

    public void MarkSkipped(DateTimeOffset at)
    {
        Status = DoseEventStatus.Skipped;
        CompletedAt = at;
        SnoozedUntil = null;
        UpdatedAt = at;
    }

    public void MarkMissed(DateTimeOffset at)
    {
        if (Status is DoseEventStatus.Taken or DoseEventStatus.Skipped)
        {
            return;
        }

        Status = DoseEventStatus.Missed;
        UpdatedAt = at;
    }

    public void Snooze(DateTimeOffset until, DateTimeOffset now)
    {
        Status = DoseEventStatus.Snoozed;
        SnoozedUntil = until;
        UpdatedAt = now;
    }
}
