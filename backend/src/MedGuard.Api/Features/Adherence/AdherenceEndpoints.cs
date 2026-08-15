using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
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
            doses.Select(dose => dose.ToResponse(timeZone)).ToList(),
            completed,
            total,
            total == 0
                ? "No doses are scheduled for today."
                : $"{completed} of {total} scheduled doses completed."));
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
                group.Select(dose => dose.ToResponse(timeZone)).ToList()))
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

        return Results.Ok(dose.ToResponse(timeZone));
    }
}
