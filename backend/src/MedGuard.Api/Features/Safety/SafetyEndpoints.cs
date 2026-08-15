using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Contracts.Common;
using MedGuard.Contracts.Safety;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Api.Features.Safety;

public static class SafetyEndpoints
{
    public static IEndpointRouteBuilder MapSafetyEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/safety").WithTags("Safety").RequireAuthorization();

        group.MapPost("/analyze", AnalyzeAsync);
        group.MapGet("/findings", GetFindingsAsync);
        group.MapGet("/findings/{id:guid}/explanation", ExplainAsync);

        return app;
    }

    private static async Task<IResult> AnalyzeAsync(
        AnalyzeSafetyRequest? request,
        IMedicationSafetyEngine engine,
        IMedicationRepository medications,
        SafetyFindingStore store,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var result = request?.MedicationId is { } medicationId
            ? await AnalyzeCandidateAsync(engine, medications, userId, medicationId, cancellationToken)
            : await engine.AnalyzeUserAsync(userId, cancellationToken);

        if (result is null)
        {
            return Results.NotFound(new ApiError("medication_not_found", "This medication is not in your list."));
        }

        var persisted = await store.SyncAsync(userId, result, request?.MedicationId, cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.SafetyCheckPerformed,
            userId,
            request?.MedicationId,
            ContractMapping.ToWireValue(persisted.Status),
            cancellationToken);

        return Results.Ok(persisted.ToResponse());
    }

    private static async Task<Domain.Safety.SafetyAnalysisResult?> AnalyzeCandidateAsync(
        IMedicationSafetyEngine engine,
        IMedicationRepository medications,
        Guid userId,
        Guid medicationId,
        CancellationToken cancellationToken)
    {
        var candidate = await medications.GetByIdAsync(userId, medicationId, cancellationToken);
        return candidate is null ? null : await engine.AnalyzeAsync(userId, candidate, cancellationToken);
    }

    private static async Task<IResult> GetFindingsAsync(
        SafetyFindingStore store,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var findings = await store.GetOpenFindingsAsync(currentUser.RequireUserId(), cancellationToken);
        return Results.Ok(findings.Select(finding => finding.ToResponse()).ToList());
    }

    private static async Task<IResult> ExplainAsync(
        Guid id,
        MedGuardDbContext dbContext,
        IMedicationExplanationService explanationService,
        ICurrentUser currentUser,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var finding = await dbContext.SafetyFindings
            .Include(item => item.Subjects)
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId, cancellationToken);

        if (finding is null)
        {
            return Results.NotFound(new ApiError("finding_not_found", "This safety finding is no longer available."));
        }

        // The explanation layer only ever sees a finding the deterministic engine produced.
        var explanation = await explanationService.ExplainAsync(finding, cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.SafetyExplanationRequested,
            userId,
            finding.Id,
            explanation.GeneratedByAi ? "model" : "template",
            cancellationToken);

        return Results.Ok(new SafetyExplanationResponse(
            finding.Id,
            explanation.Text,
            explanation.GeneratedByAi,
            explanation.Source,
            SafetyMessages.GeneralDisclaimer));
    }
}
