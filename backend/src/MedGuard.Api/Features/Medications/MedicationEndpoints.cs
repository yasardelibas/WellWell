using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Education;
using MedGuard.Application.Medications;
using MedGuard.Contracts.Common;
using MedGuard.Contracts.Medications;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Api.Features.Medications;

public static class MedicationEndpoints
{
    public static IEndpointRouteBuilder MapMedicationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/medications").WithTags("Medications").RequireAuthorization();

        group.MapGet("/", ListAsync);
        group.MapGet("/{id:guid}", GetAsync);
        group.MapGet("/{id:guid}/education", GetEducationAsync);
        group.MapPost("/", CreateAsync).WithValidation<CreateMedicationRequest>();
        group.MapPut("/{id:guid}", UpdateAsync).WithValidation<UpdateMedicationRequest>();
        group.MapPut("/{id:guid}/refill", SetRefillAsync);
        group.MapDelete("/{id:guid}", DeleteAsync);

        return app;
    }

    private static async Task<IResult> ListAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medications = await dbContext.Medications
            .Include(medication => medication.Ingredients)
            .Where(medication => medication.UserId == userId && !medication.IsArchived)
            .OrderByDescending(medication => medication.CreatedAt)
            .ToListAsync(cancellationToken);

        var scheduleCounts = await dbContext.MedicationSchedules
            .Where(schedule => schedule.UserId == userId && schedule.IsActive)
            .GroupBy(schedule => schedule.MedicationId)
            .Select(group => new { MedicationId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(item => item.MedicationId, item => item.Count, cancellationToken);

        var response = medications
            .Select(medication => medication.ToResponse(scheduleCounts.GetValueOrDefault(medication.Id)))
            .ToList();

        return Results.Ok(response);
    }

    private static async Task<IResult> GetAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medication = await dbContext.Medications
            .Include(item => item.Ingredients)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        var scheduleCount = await dbContext.MedicationSchedules
            .CountAsync(schedule => schedule.MedicationId == id && schedule.IsActive, cancellationToken);

        return Results.Ok(medication.ToResponse(scheduleCount));
    }

    /// <summary>
    /// General, plain-language educational context about a medication. Never dosing or personal
    /// advice: the education service defers to a professional and falls back to a safe message.
    /// </summary>
    private static async Task<IResult> GetEducationAsync(
        Guid id,
        MedGuardDbContext dbContext,
        IMedicationEducationService education,
        IDrugClassificationProvider classifier,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medication = await dbContext.Medications
            .Include(item => item.Ingredients)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        // Deterministic RxClass enrichment: try the product RxCUI first, then ingredient RxCUIs,
        // stopping at the first one that yields authoritative uses or a therapeutic class.
        var classification = await ResolveClassificationAsync(medication, classifier, cancellationToken);

        var input = new MedicationEducationInput(
            medication.DisplayName,
            string.IsNullOrWhiteSpace(medication.GenericName) ? null : medication.GenericName,
            medication.Ingredients
                .Select(ingredient => ingredient.OriginalName)
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .ToList(),
            classification.UsedFor.Count > 0 ? classification.UsedFor : null,
            classification.PharmacologicClass);

        var result = await education.ExplainAsync(input, cancellationToken);

        return Results.Ok(new MedicationEducationResponse(
            result.Message,
            result.GeneratedByAi,
            result.IsAvailable,
            classification.UsedFor,
            classification.PharmacologicClass));
    }

    private static async Task<DrugClassification> ResolveClassificationAsync(
        Domain.Entities.Medication medication,
        IDrugClassificationProvider classifier,
        CancellationToken cancellationToken)
    {
        var rxCuis = new List<string>();
        if (!string.IsNullOrWhiteSpace(medication.RxCui))
        {
            rxCuis.Add(medication.RxCui);
        }

        rxCuis.AddRange(medication.Ingredients
            .Select(ingredient => ingredient.RxCui)
            .Where(rxCui => !string.IsNullOrWhiteSpace(rxCui))!);

        foreach (var rxCui in rxCuis.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var classification = await classifier.GetByRxCuiAsync(rxCui!, cancellationToken);
            if (classification.HasContent)
            {
                return classification;
            }
        }

        return DrugClassification.Empty;
    }

    /// <summary>Records the user's own count of remaining doses, used for refill reminders.</summary>
    private static async Task<IResult> SetRefillAsync(
        Guid id,
        SetRefillRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medication = await dbContext.Medications
            .Include(item => item.Ingredients)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        medication.SetRemainingQuantity(request.RemainingQuantity, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        var scheduleCount = await dbContext.MedicationSchedules
            .CountAsync(schedule => schedule.MedicationId == id && schedule.IsActive, cancellationToken);

        return Results.Ok(medication.ToResponse(scheduleCount));
    }

    private static async Task<IResult> CreateAsync(
        CreateMedicationRequest request,
        MedGuardDbContext dbContext,
        MedicationBuilder builder,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var built = await builder.BuildAsync(
            userId,
            new MedicationDraft(
                request.BrandName,
                request.GenericName,
                request.Ingredients,
                request.DosageForm,
                request.Strength,
                request.Route,
                request.LabelDirections,
                request.Notes),
            request.AttemptVerification,
            sourceScanId: null,
            cancellationToken);

        dbContext.Medications.Add(built.Medication);
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.MedicationAdded,
            userId,
            built.Medication.Id,
            ContractMapping.ToWireValue(built.Medication.VerificationStatus),
            cancellationToken);

        return Results.Created($"/api/medications/{built.Medication.Id}", built.Medication.ToResponse());
    }

    private static async Task<IResult> UpdateAsync(
        Guid id,
        UpdateMedicationRequest request,
        MedGuardDbContext dbContext,
        MedicationVerificationService verification,
        ICurrentUser currentUser,
        IIngredientNormalizer normalizer,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var medication = await dbContext.Medications
            .Include(item => item.Ingredients)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        var identityChanged =
            (!string.IsNullOrWhiteSpace(request.BrandName) && request.BrandName != medication.BrandName) ||
            (!string.IsNullOrWhiteSpace(request.GenericName) && request.GenericName != medication.GenericName) ||
            request.Ingredients is { Count: > 0 };

        medication.UpdateDetails(
            request.BrandName,
            request.GenericName,
            request.DosageForm,
            request.Strength,
            request.Route,
            request.LabelDirections,
            request.Notes,
            clock.UtcNow);

        if (request.Ingredients is { Count: > 0 })
        {
            medication.ReplaceIngredients(
                request.Ingredients.Select(ingredient =>
                    normalizer.Normalize(ingredient.Name, ingredient.Strength, ingredient.Unit, ingredient.RxCui)),
                clock.UtcNow);
        }

        if (request.AttemptVerification)
        {
            var outcome = await verification.VerifyAsync(
                new DrugSearchRequest(
                    medication.BrandName,
                    medication.GenericName,
                    medication.Ingredients.Select(ingredient => ingredient.OriginalName).ToList(),
                    medication.Strength,
                    medication.DosageForm),
                cancellationToken);

            if (outcome.Status == MedicationVerificationStatus.Verified && outcome.Provenance is not null)
            {
                medication.MarkVerified(outcome.Provenance, outcome.BestMatch?.RxCui, clock.UtcNow);
            }
            else
            {
                medication.InvalidateVerification(clock.UtcNow);
                if (outcome.Status == MedicationVerificationStatus.VerificationUnavailable)
                {
                    medication.MarkVerificationUnavailable(clock.UtcNow);
                }
            }
        }
        else if (identityChanged && medication.VerificationStatus == MedicationVerificationStatus.Verified)
        {
            medication.InvalidateVerification(clock.UtcNow);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.MedicationUpdated, userId, medication.Id, cancellationToken: cancellationToken);

        return Results.Ok(medication.ToResponse());
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

        var medication = await dbContext.Medications
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (medication is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        medication.Archive(clock.UtcNow);

        var schedules = await dbContext.MedicationSchedules
            .Where(schedule => schedule.MedicationId == id && schedule.UserId == userId)
            .ToListAsync(cancellationToken);

        foreach (var schedule in schedules)
        {
            schedule.Deactivate(clock.UtcNow);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.MedicationRemoved, userId, id, cancellationToken: cancellationToken);

        return Results.NoContent();
    }
}
