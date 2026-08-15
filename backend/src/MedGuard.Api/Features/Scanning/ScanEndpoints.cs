using System.Text.Json;
using MedGuard.Api.Common;
using MedGuard.Api.Features.Medications;
using MedGuard.Api.Features.Safety;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Medications;
using MedGuard.Application.Schedules;
using MedGuard.Application.Telemetry;
using MedGuard.Contracts.Common;
using MedGuard.Contracts.Medications;
using MedGuard.Contracts.Scanning;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Scanning;

public static class ScanEndpoints
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    public static IEndpointRouteBuilder MapScanEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/medications/scan").WithTags("Scanning").RequireAuthorization();

        group.MapPost("/", ScanAsync).RequireRateLimiting("scan");
        group.MapPost("/{scanId:guid}/confirm", ConfirmAsync);

        return app;
    }

    private static async Task<IResult> ScanAsync(
        ScanRequest request,
        MedGuardDbContext dbContext,
        ILabelExtractionService extractionService,
        MedicationVerificationService verification,
        IDateTimeProvider clock,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        IOptions<ScanOptions> scanOptions,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var options = scanOptions.Value;
        var retention = TimeSpan.FromHours(options.RetentionHours);

        byte[]? imageBytes = null;
        if (!string.IsNullOrWhiteSpace(request.ImageBase64))
        {
            try
            {
                imageBytes = Convert.FromBase64String(StripDataUri(request.ImageBase64));
            }
            catch (FormatException)
            {
                return Results.BadRequest(new ApiError("invalid_image", "The captured image could not be read."));
            }

            if (imageBytes.Length > options.MaxImageBytes)
            {
                return Results.BadRequest(new ApiError("image_too_large", "The captured image is too large. Please try again."));
            }
        }

        if (imageBytes is null && string.IsNullOrWhiteSpace(request.OcrText))
        {
            return Results.BadRequest(new ApiError("nothing_to_read", "Provide a captured image or label text."));
        }

        // The image lives in memory for the duration of extraction only; it is never persisted.
        var extraction = await extractionService.ExtractAsync(
            new LabelExtractionInput(imageBytes, request.MimeType, request.OcrText),
            cancellationToken);

        if (!extraction.Succeeded)
        {
            var failedScan = MedicationScan.Failed(
                userId,
                extraction.FailureReason ?? "We couldn't read the label clearly.",
                clock.UtcNow,
                retention);

            dbContext.MedicationScans.Add(failedScan);
            await dbContext.SaveChangesAsync(cancellationToken);

            MedGuardTelemetry.ScansProcessed.Add(1, new KeyValuePair<string, object?>("outcome", "extraction-failed"));
            await auditLogger.LogAsync(AuditEventType.MedicationScanCreated, userId, failedScan.Id, "extraction-failed", cancellationToken);

            return Results.Ok(new ScanResponse(
                failedScan.Id,
                "extraction_failed",
                0m,
                RequiresManualReview: true,
                VerificationStatus: ContractMapping.ToWireValue(MedicationVerificationStatus.Unverified),
                Message: "We couldn't read the label clearly. Try again in better light, or enter the details manually.",
                Extraction: null,
                Candidates: Array.Empty<MedicationCandidateResponse>(),
                ScheduleSuggestion: null));
        }

        var ingredientNames = extraction.ActiveIngredients
            .Select(ingredient => ingredient.Name.Value)
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Select(name => name!)
            .ToList();

        var outcome = await verification.VerifyAsync(
            new DrugSearchRequest(
                extraction.BrandName.Value,
                extraction.GenericName.Value,
                ingredientNames,
                null,
                extraction.DosageForm.Value),
            cancellationToken);

        var confidence = (decimal)extraction.OverallConfidence;
        var scan = MedicationScan.AwaitingConfirmation(
            userId,
            confidence,
            extraction.Source,
            JsonSerializer.Serialize(extraction, SerializerOptions),
            clock.UtcNow,
            retention);

        dbContext.MedicationScans.Add(scan);
        await dbContext.SaveChangesAsync(cancellationToken);

        MedGuardTelemetry.ScansProcessed.Add(
            1,
            new KeyValuePair<string, object?>("outcome", "extracted"),
            new KeyValuePair<string, object?>("verification", outcome.Status.ToString()));

        await auditLogger.LogAsync(AuditEventType.MedicationScanCreated, userId, scan.Id, "extracted", cancellationToken);

        var requiresManualReview =
            extraction.OverallConfidence < options.ManualReviewThreshold ||
            outcome.Status != MedicationVerificationStatus.Verified;

        var suggestion = LabelDirectionsParser.Parse(extraction.Directions.Value);

        return Results.Ok(new ScanResponse(
            scan.Id,
            "awaiting_confirmation",
            confidence,
            requiresManualReview,
            ContractMapping.ToWireValue(outcome.Status),
            BuildMessage(extraction.OverallConfidence, options.ManualReviewThreshold, outcome.Status, outcome.Detail),
            extraction.ToResponse(),
            outcome.Candidates.Select(candidate => candidate.ToResponse()).ToList(),
            suggestion.TimesPerDay > 0 ? suggestion.ToResponse() : null));
    }

    private static async Task<IResult> ConfirmAsync(
        Guid scanId,
        ConfirmScanRequest request,
        MedGuardDbContext dbContext,
        MedicationBuilder builder,
        IMedicationSafetyEngine safetyEngine,
        SafetyFindingStore findingStore,
        IDateTimeProvider clock,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var scan = await dbContext.MedicationScans
            .FirstOrDefaultAsync(item => item.Id == scanId && item.UserId == userId, cancellationToken);

        if (scan is null)
        {
            return Results.NotFound(new ApiError("scan_not_found", "This scan is no longer available. Please scan again."));
        }

        if (scan.Status != ScanStatus.AwaitingConfirmation)
        {
            return Results.Conflict(new ApiError("scan_already_handled", "This scan has already been confirmed or discarded."));
        }

        var extraction = TryReadExtraction(scan.ExtractionJson);
        var draft = BuildDraft(request, extraction);

        if (string.IsNullOrWhiteSpace(draft.BrandName) && string.IsNullOrWhiteSpace(draft.GenericName))
        {
            return Results.BadRequest(new ApiError(
                "medication_name_required",
                "Add a brand name or a generic name before confirming."));
        }

        var built = await builder.BuildAsync(
            userId,
            draft,
            attemptVerification: true,
            sourceScanId: scan.Id,
            cancellationToken: cancellationToken,
            preferredExternalId: request.SelectedCandidateRxCui);

        // A medication that could not be verified is only saved once the user has
        // explicitly acknowledged that it will be stored as unverified.
        if (built.Medication.VerificationStatus != MedicationVerificationStatus.Verified && !request.AcknowledgedUnverified)
        {
            return Results.Json(
                new ApiError(
                    "unverified_requires_acknowledgement",
                    built.Outcome.Detail,
                    new Dictionary<string, string[]>
                    {
                        ["verificationStatus"] = new[] { ContractMapping.ToWireValue(built.Medication.VerificationStatus) }
                    }),
                statusCode: StatusCodes.Status409Conflict);
        }

        dbContext.Medications.Add(built.Medication);
        scan.Confirm(built.Medication.Id, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogger.LogAsync(AuditEventType.MedicationScanConfirmed, userId, scan.Id, cancellationToken: cancellationToken);
        await auditLogger.LogAsync(
            AuditEventType.MedicationAdded,
            userId,
            built.Medication.Id,
            ContractMapping.ToWireValue(built.Medication.VerificationStatus),
            cancellationToken);

        // The safety engine runs immediately after the medication becomes part of the list.
        var analysis = await safetyEngine.AnalyzeAsync(userId, built.Medication, cancellationToken);
        var persisted = await findingStore.SyncAsync(userId, analysis, built.Medication.Id, cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.SafetyCheckPerformed,
            userId,
            built.Medication.Id,
            ContractMapping.ToWireValue(persisted.Status),
            cancellationToken);

        var suggestion = LabelDirectionsParser.Parse(built.Medication.LabelDirections);

        return Results.Ok(new ConfirmScanResponse(
            built.Medication.ToResponse(),
            persisted.ToResponse(),
            suggestion.TimesPerDay > 0 ? suggestion.ToResponse() : null));
    }

    private static MedicationDraft BuildDraft(ConfirmScanRequest request, LabelExtraction? extraction)
    {
        var ingredients = request.Ingredients is { Count: > 0 }
            ? request.Ingredients
            : extraction?.ActiveIngredients
                .Where(ingredient => !string.IsNullOrWhiteSpace(ingredient.Name.Value))
                .Select(ingredient => new IngredientInput(
                    ingredient.Name.Value!,
                    decimal.TryParse(ingredient.Strength?.Value, out var strength) ? strength : null,
                    ingredient.Unit?.Value,
                    null))
                .ToList()
              ?? new List<IngredientInput>();

        return new MedicationDraft(
            request.BrandName ?? extraction?.BrandName.Value,
            request.GenericName ?? extraction?.GenericName.Value,
            ingredients,
            request.DosageForm ?? extraction?.DosageForm.Value,
            request.Strength,
            request.Route ?? extraction?.Route.Value,
            request.LabelDirections ?? extraction?.Directions.Value,
            Notes: null);
    }

    private static LabelExtraction? TryReadExtraction(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<LabelExtraction>(json, SerializerOptions);
        }
        catch (JsonException)
        {
            return null;
        }
    }

    private static string BuildMessage(
        double confidence,
        double threshold,
        MedicationVerificationStatus status,
        string detail)
    {
        if (confidence < threshold)
        {
            return "We couldn't confidently identify this medication. Please review the information manually.";
        }

        return status switch
        {
            MedicationVerificationStatus.Verified => "We found this medication. Please confirm the details match the label.",
            MedicationVerificationStatus.VerificationUnavailable => detail,
            _ => detail
        };
    }

    private static string StripDataUri(string value)
    {
        var separator = value.IndexOf("base64,", StringComparison.OrdinalIgnoreCase);
        return separator < 0 ? value : value[(separator + "base64,".Length)..];
    }
}
