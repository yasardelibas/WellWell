using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Insights;
using MedGuard.Contracts.Adherence;
using MedGuard.Contracts.Common;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Api.Features.Adherence;

public static class AdherenceEndpoints
{
    public static IEndpointRouteBuilder MapAdherenceEndpoints(this IEndpointRouteBuilder app)
    {
        var adherence = app.MapGroup("/api/adherence").WithTags("Adherence").RequireAuthorization();
        adherence.MapGet("/today", GetTodayAsync);
        adherence.MapGet("/history", GetHistoryAsync);
        adherence.MapGet("/summary", GetSummaryAsync);
        adherence.MapGet("/nudge", GetNudgeAsync);
        adherence.MapGet("/insights", GetInsightsAsync);

        var doses = app.MapGroup("/api/doses").WithTags("Adherence").RequireAuthorization();
        doses.MapPost("/{id:guid}/taken", MarkTakenAsync);
        doses.MapPost("/{id:guid}/skip", MarkSkippedAsync);
        doses.MapPost("/{id:guid}/snooze", SnoozeAsync);

        return app;
    }

    private static async Task<IResult> GetTodayAsync(
        MedGuardDbContext dbContext,
        DoseEventService doseEvents,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId, cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);

        var doses = await doseEvents.EnsureForDayAsync(userId, today, timeZone, cancellationToken);

        var completed = doses.Count(dose => dose.Status == DoseEventStatus.Taken);
        var total = doses.Count;

        return Results.Ok(new TodayScheduleResponse(
            today,
            doses.Select(dose => dose.ToResponse(timeZone, user.PreferredLanguage)).ToList(),
            completed,
            total,
            ProgressLabel(completed, total, user.PreferredLanguage)));
    }

    private static string ProgressLabel(int completed, int total, string? language)
    {
        var tr = string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);
        if (total == 0)
        {
            return tr ? "Bugün için planlanmış doz yok." : "No doses are scheduled for today.";
        }

        return tr ? $"{total} planlanmış dozdan {completed} tanesi tamamlandı." : $"{completed} of {total} scheduled doses completed.";
    }

    private static async Task<IResult> GetHistoryAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        DateOnly? from,
        DateOnly? to,
        Guid? medicationId,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId, cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);

        var end = to ?? today;
        var start = from ?? end.AddDays(-13);

        if (start > end)
        {
            return Results.BadRequest(new ApiError("invalid_range", "The start date must be before the end date."));
        }

        var rangeStart = DoseEventService.ToInstant(start, TimeOnly.MinValue, timeZone);
        var rangeEnd = DoseEventService.ToInstant(end.AddDays(1), TimeOnly.MinValue, timeZone);

        var doses = await dbContext.DoseEvents
            .Include(dose => dose.Medication)
            .Include(dose => dose.Schedule)
            .Where(dose => dose.UserId == userId && dose.ScheduledAt >= rangeStart && dose.ScheduledAt < rangeEnd)
            .Where(dose => medicationId == null || dose.MedicationId == medicationId)
            .OrderBy(dose => dose.ScheduledAt)
            .ToListAsync(cancellationToken);

        var days = doses
            .GroupBy(dose => DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(dose.ScheduledAt, timeZone).DateTime))
            .OrderByDescending(group => group.Key)
            .Select(group => new AdherenceDayResponse(
                group.Key,
                group.Select(dose => dose.ToResponse(timeZone, user.PreferredLanguage)).ToList()))
            .ToList();

        return Results.Ok(new AdherenceHistoryResponse(
            start,
            end,
            days,
            doses.Count(dose => dose.Status == DoseEventStatus.Taken),
            doses.Count(dose => dose.Status == DoseEventStatus.Skipped),
            doses.Count(dose => dose.Status == DoseEventStatus.Missed),
            doses.Count(dose => dose.Status is DoseEventStatus.Pending or DoseEventStatus.Snoozed)));
    }

    /// <summary>A short, encouraging recap of the last 7 days. Counts are deterministic.</summary>
    private static async Task<IResult> GetSummaryAsync(
        MedGuardDbContext dbContext,
        IAdherenceInsightService insights,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId, cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);
        var start = today.AddDays(-6);

        var rangeStart = DoseEventService.ToInstant(start, TimeOnly.MinValue, timeZone);
        var rangeEnd = DoseEventService.ToInstant(today.AddDays(1), TimeOnly.MinValue, timeZone);

        var doses = await dbContext.DoseEvents
            .Where(dose => dose.UserId == userId && dose.ScheduledAt >= rangeStart && dose.ScheduledAt < rangeEnd)
            .ToListAsync(cancellationToken);

        var stats = new AdherenceStats(
            doses.Count(dose => dose.Status == DoseEventStatus.Taken),
            doses.Count(dose => dose.Status == DoseEventStatus.Skipped),
            doses.Count(dose => dose.Status == DoseEventStatus.Missed),
            doses.Count(dose => dose.Status is DoseEventStatus.Pending or DoseEventStatus.Snoozed));

        var insight = await insights.SummarizeWeekAsync(stats, user.PreferredLanguage, cancellationToken);

        return Results.Ok(new AdherenceSummaryResponse(
            start,
            today,
            stats.TakenCount,
            stats.SkippedCount,
            stats.MissedCount,
            stats.PendingCount,
            stats.AdherencePercent,
            insight.Message,
            insight.GeneratedByAi));
    }

    /// <summary>A one-sentence, non-judgemental nudge for today's plan.</summary>
    private static async Task<IResult> GetNudgeAsync(
        MedGuardDbContext dbContext,
        DoseEventService doseEvents,
        IAdherenceInsightService insights,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId, cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);

        var doses = await doseEvents.EnsureForDayAsync(userId, today, timeZone, cancellationToken);

        var completed = doses.Count(dose => dose.Status == DoseEventStatus.Taken);
        var total = doses.Count;

        var insight = await insights.DailyNudgeAsync(new DailyAdherenceStats(completed, total), user.PreferredLanguage, cancellationToken);

        return Results.Ok(new DailyNudgeResponse(completed, total, insight.Message, insight.GeneratedByAi));
    }

    /// <summary>A 30-day wellness recap: adherence %, on-time streak and the most-missed time of day.</summary>
    private static async Task<IResult> GetInsightsAsync(
        MedGuardDbContext dbContext,
        IAdherenceInsightService insights,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId, cancellationToken);

        if (user is null)
        {
            return Results.NotFound();
        }

        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);
        var start = today.AddDays(-29);

        var rangeStart = DoseEventService.ToInstant(start, TimeOnly.MinValue, timeZone);
        var rangeEnd = DoseEventService.ToInstant(today.AddDays(1), TimeOnly.MinValue, timeZone);

        var doses = await dbContext.DoseEvents
            .Where(dose => dose.UserId == userId && dose.ScheduledAt >= rangeStart && dose.ScheduledAt < rangeEnd)
            .Select(dose => new { dose.ScheduledAt, dose.Status })
            .ToListAsync(cancellationToken);

        var taken = doses.Count(d => d.Status == DoseEventStatus.Taken);
        var skipped = doses.Count(d => d.Status == DoseEventStatus.Skipped);
        var missed = doses.Count(d => d.Status == DoseEventStatus.Missed);
        var pending = doses.Count(d => d.Status is DoseEventStatus.Pending or DoseEventStatus.Snoozed);
        var resolved = taken + skipped + missed;
        var adherencePercent = resolved == 0 ? 0 : (int)Math.Round(100.0 * taken / resolved, MidpointRounding.AwayFromZero);

        // Project every dose into the owner's local day + hour once, so streak and time-of-day
        // patterns share the same view of "when" a dose was scheduled.
        var local = doses
            .Select(d =>
            {
                var when = TimeZoneInfo.ConvertTime(d.ScheduledAt, timeZone);
                return (Day: DateOnly.FromDateTime(when.DateTime), Hour: when.Hour, d.Status);
            })
            .ToList();

        var streak = ComputeStreak(local, today);
        var weakest = WeakestTimeOfDay(local);

        var insight = await insights.SummarizeInsightsAsync(
            new AdherenceInsightsInput(adherencePercent, streak, weakest),
            user.PreferredLanguage,
            cancellationToken);

        return Results.Ok(new AdherenceInsightsResponse(
            start,
            today,
            taken,
            skipped,
            missed,
            pending,
            adherencePercent,
            streak,
            weakest,
            insight.Message,
            insight.GeneratedByAi));
    }

    /// <summary>
    /// Consecutive days (ending today) where every scheduled dose was taken. Days with no
    /// scheduled doses are neutral (they neither add to nor break the streak). Today only
    /// counts when it is already perfect, so an in-progress day never breaks a good run.
    /// </summary>
    private static int ComputeStreak(
        List<(DateOnly Day, int Hour, DoseEventStatus Status)> local,
        DateOnly today)
    {
        var byDay = local
            .GroupBy(item => item.Day)
            .ToDictionary(
                group => group.Key,
                group => group.All(item => item.Status == DoseEventStatus.Taken));

        var streak = 0;
        for (var day = today; ; day = day.AddDays(-1))
        {
            if (!byDay.TryGetValue(day, out var allTaken))
            {
                // No scheduled doses this day: neutral. Stop scanning once we run past the
                // 30-day window (no data) but keep the streak accumulated so far.
                if (day < today.AddDays(-29))
                {
                    break;
                }

                continue;
            }

            if (allTaken)
            {
                streak++;
            }
            else if (day == today)
            {
                // Today isn't perfect yet — don't count it, but don't break an earlier run.
                continue;
            }
            else
            {
                break;
            }
        }

        return streak;
    }

    private static string? WeakestTimeOfDay(List<(DateOnly Day, int Hour, DoseEventStatus Status)> local)
    {
        (string Label, int From, int To)[] buckets =
        {
            ("morning", 5, 11),
            ("afternoon", 12, 16),
            ("evening", 17, 21),
            ("night", 22, 4),
        };

        string? weakest = null;
        var lowest = 1.0;

        foreach (var (label, from, to) in buckets)
        {
            bool InBucket(int hour) => from <= to ? hour >= from && hour <= to : hour >= from || hour <= to;

            var inBucket = local.Where(item => InBucket(item.Hour)).ToList();
            var resolved = inBucket.Count(item => item.Status is DoseEventStatus.Taken or DoseEventStatus.Skipped or DoseEventStatus.Missed);
            if (resolved < 3)
            {
                continue;
            }

            var takenRate = (double)inBucket.Count(item => item.Status == DoseEventStatus.Taken) / resolved;
            if (takenRate < lowest && takenRate < 1.0)
            {
                lowest = takenRate;
                weakest = label;
            }
        }

        return weakest;
    }

    private static Task<IResult> MarkTakenAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken) =>
        UpdateDoseAsync(id, dbContext, currentUser, auditLogger, cancellationToken, dose => dose.MarkTaken(clock.UtcNow), "taken");

    private static Task<IResult> MarkSkippedAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken) =>
        UpdateDoseAsync(id, dbContext, currentUser, auditLogger, cancellationToken, dose => dose.MarkSkipped(clock.UtcNow), "skipped");

    private static Task<IResult> SnoozeAsync(
        Guid id,
        SnoozeDoseRequest? request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var minutes = Math.Clamp(request?.Minutes ?? 15, 5, 240);

        return UpdateDoseAsync(
            id,
            dbContext,
            currentUser,
            auditLogger,
            cancellationToken,
            dose => dose.Snooze(clock.UtcNow.AddMinutes(minutes), clock.UtcNow),
            "snoozed");
    }

    private static async Task<IResult> UpdateDoseAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken,
        Action<DoseEvent> mutate,
        string outcome)
    {
        var userId = currentUser.RequireUserId();

        var dose = await dbContext.DoseEvents
            .Include(item => item.Medication)
            .Include(item => item.Schedule)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (dose is null)
        {
            return Results.NotFound(new ApiError("dose_not_found", "This dose is no longer available."));
        }

        mutate(dose);
        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.DoseRecorded, userId, dose.Id, outcome, cancellationToken);

        var user = await dbContext.Users.FirstAsync(item => item.Id == userId, cancellationToken);
        var timeZone = DoseEventService.ResolveTimeZone(user.TimeZoneId);

        return Results.Ok(dose.ToResponse(timeZone, user.PreferredLanguage));
    }
}
