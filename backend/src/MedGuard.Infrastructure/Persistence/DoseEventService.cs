using MedGuard.Application.Abstractions;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Infrastructure.Persistence;

/// <summary>
/// Materialises the dose events implied by a user's confirmed schedules.
/// Only schedules the user confirmed produce reminders.
/// </summary>
public sealed class DoseEventService
{
    private readonly MedGuardDbContext _dbContext;
    private readonly IDateTimeProvider _clock;

    public DoseEventService(MedGuardDbContext dbContext, IDateTimeProvider clock)
    {
        _dbContext = dbContext;
        _clock = clock;
    }

    public static TimeZoneInfo ResolveTimeZone(string? timeZoneId)
    {
        if (string.IsNullOrWhiteSpace(timeZoneId))
        {
            return TimeZoneInfo.Utc;
        }

        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
        }
        catch (Exception exception) when (exception is TimeZoneNotFoundException or InvalidTimeZoneException)
        {
            return TimeZoneInfo.Utc;
        }
    }

    public static DateTimeOffset ToInstant(DateOnly date, TimeOnly time, TimeZoneInfo timeZone)
    {
        var local = date.ToDateTime(time, DateTimeKind.Unspecified);
        var offset = timeZone.GetUtcOffset(local);
        return new DateTimeOffset(local, offset);
    }

    public async Task<IReadOnlyList<DoseEvent>> EnsureForDayAsync(
        Guid userId,
        DateOnly date,
        TimeZoneInfo timeZone,
        CancellationToken cancellationToken)
    {
        var schedules = await _dbContext.MedicationSchedules
            .Include(schedule => schedule.Medication)
            .Where(schedule => schedule.UserId == userId && schedule.IsActive && schedule.UserConfirmed)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var dayStart = ToInstant(date, TimeOnly.MinValue, timeZone);
        var dayEnd = dayStart.AddDays(1);

        var existing = await _dbContext.DoseEvents
            .Include(dose => dose.Medication)
            .Where(dose => dose.UserId == userId && dose.ScheduledAt >= dayStart && dose.ScheduledAt < dayEnd)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var created = false;

        foreach (var schedule in schedules)
        {
            var scheduledAt = ToInstant(date, schedule.ReminderTime, timeZone);

            if (existing.Any(dose => dose.ScheduleId == schedule.Id && dose.ScheduledAt == scheduledAt))
            {
                continue;
            }

            var dose = DoseEvent.CreatePending(userId, schedule.MedicationId, schedule.Id, scheduledAt, _clock.UtcNow);
            _dbContext.DoseEvents.Add(dose);
            existing.Add(dose);
            created = true;
        }

        if (created)
        {
            await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        }

        MarkOverdueAsMissed(existing);

        if (_dbContext.ChangeTracker.HasChanges())
        {
            await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        }

        // A dose event materialised before its medication was removed (schedule deactivated)
        // must stop appearing in "today" once removed, even though the row itself is kept
        // for dose history.
        var activeScheduleIds = schedules.Select(schedule => schedule.Id).ToHashSet();

        return existing
            .Where(dose => activeScheduleIds.Contains(dose.ScheduleId))
            .OrderBy(dose => dose.ScheduledAt)
            .ToList();
    }

    /// <summary>
    /// A pending dose more than two hours past its time is recorded as missed.
    /// "Missed" is a neutral state, not a judgement about the person.
    /// </summary>
    private void MarkOverdueAsMissed(IEnumerable<DoseEvent> doses)
    {
        var cutoff = _clock.UtcNow.AddHours(-2);

        foreach (var dose in doses.Where(dose => dose.Status == DoseEventStatus.Pending && dose.ScheduledAt < cutoff))
        {
            dose.MarkMissed(_clock.UtcNow);
        }
    }
}
