using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Schedules;
using MedGuard.Contracts.Common;
using MedGuard.Contracts.Schedules;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Api.Features.Schedules;

public static class ScheduleEndpoints
{
    public static IEndpointRouteBuilder MapScheduleEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/schedules").WithTags("Schedules").RequireAuthorization();

        group.MapGet("/", ListAsync);
        group.MapGet("/suggestion", SuggestAsync);
        group.MapPost("/", CreateAsync).WithValidation<CreateScheduleRequest>();
        group.MapPut("/{id:guid}", UpdateAsync).WithValidation<UpdateScheduleRequest>();
        group.MapDelete("/{id:guid}", DeleteAsync);

        return app;
    }

    private static async Task<IResult> ListAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        Guid? medicationId,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var schedules = await dbContext.MedicationSchedules
            .Include(schedule => schedule.Medication)
            .Where(schedule => schedule.UserId == userId)
            .Where(schedule => medicationId == null || schedule.MedicationId == medicationId)
            .OrderBy(schedule => schedule.ReminderTime)
            .ToListAsync(cancellationToken);

        return Results.Ok(schedules
            .Select(schedule => schedule.ToResponse(schedule.Medication?.DisplayName ?? "Medication"))
            .ToList());
    }

    /// <summary>
    /// Suggests reminder times from the label wording. Nothing is created here: the user
    /// still has to confirm the times before any reminder exists.
    /// </summary>
    private static async Task<IResult> SuggestAsync(
        Guid medicationId,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medication = await dbContext.Medications
            .FirstOrDefaultAsync(item => item.Id == medicationId && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        var suggestion = LabelDirectionsParser.Parse(medication.LabelDirections);
        return Results.Ok(suggestion.ToResponse());
    }

    private static async Task<IResult> CreateAsync(
        CreateScheduleRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        // Domain Rule 4: reminders exist only when the user confirmed the times.
        if (!request.UserConfirmed)
        {
            return Results.BadRequest(new ApiError(
                "user_confirmation_required",
                "Confirm the reminder times before saving this schedule."));
        }

        var medication = await dbContext.Medications
            .FirstOrDefaultAsync(item => item.Id == request.MedicationId && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        var times = new List<TimeOnly>();
        foreach (var raw in request.Times)
        {
            if (!TimeOnly.TryParse(raw, out var time))
            {
                return Results.BadRequest(new ApiError("invalid_time", $"'{raw}' is not a valid time. Use HH:mm."));
            }

            times.Add(time);
        }

        var existing = await dbContext.MedicationSchedules
            .Where(schedule => schedule.UserId == userId && schedule.MedicationId == medication.Id)
            .ToListAsync(cancellationToken);

        var created = new List<MedicationSchedule>();

        foreach (var time in times.Distinct())
        {
            var match = existing.FirstOrDefault(schedule => schedule.ReminderTime == time);

            if (match is not null)
            {
                match.Confirm(clock.UtcNow);
                created.Add(match);
                continue;
            }

            var schedule = MedicationSchedule.Create(
                userId,
                medication.Id,
                time,
                userConfirmed: true,
                clock.UtcNow,
                request.LabelInstruction ?? medication.LabelDirections,
                request.DoseAmountText);

            dbContext.MedicationSchedules.Add(schedule);
            created.Add(schedule);
        }

        // Times the user removed from the set stop producing reminders.
        foreach (var stale in existing.Where(schedule => !times.Contains(schedule.ReminderTime)))
        {
            stale.Deactivate(clock.UtcNow);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.ScheduleCreated, userId, medication.Id, cancellationToken: cancellationToken);

        return Results.Ok(created
            .OrderBy(schedule => schedule.ReminderTime)
            .Select(schedule => schedule.ToResponse(medication.DisplayName))
            .ToList());
    }

    private static async Task<IResult> UpdateAsync(
        Guid id,
        UpdateScheduleRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var schedule = await dbContext.MedicationSchedules
            .Include(item => item.Medication)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (schedule is null)
        {
            return Results.NotFound(new ApiError("schedule_not_found", "This reminder no longer exists."));
        }

        TimeOnly? time = null;
        if (!string.IsNullOrWhiteSpace(request.Time))
        {
            if (!TimeOnly.TryParse(request.Time, out var parsed))
            {
                return Results.BadRequest(new ApiError("invalid_time", $"'{request.Time}' is not a valid time. Use HH:mm."));
            }

            time = parsed;
        }

        schedule.Update(time, request.DoseAmountText, request.IsActive, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.ScheduleUpdated, userId, schedule.Id, cancellationToken: cancellationToken);

        return Results.Ok(schedule.ToResponse(schedule.Medication?.DisplayName ?? "Medication"));
    }

    private static async Task<IResult> DeleteAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var schedule = await dbContext.MedicationSchedules
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (schedule is null)
        {
            return Results.NotFound(new ApiError("schedule_not_found", "This reminder no longer exists."));
        }

        schedule.Deactivate(clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.ScheduleDeleted, userId, schedule.Id, cancellationToken: cancellationToken);

        return Results.NoContent();
    }
}
