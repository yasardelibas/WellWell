using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Contracts.Adherence;
using MedGuard.Contracts.Caregivers;
using MedGuard.Contracts.Common;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Caregivers;

public static class CaregiverEndpoints
{
    public static IEndpointRouteBuilder MapCaregiverEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/caregivers").WithTags("Caregivers").RequireAuthorization();

        group.MapGet("/", ListAsync);
        group.MapPost("/invitations", InviteAsync).WithValidation<InviteCaregiverRequest>();
        group.MapPost("/invitations/{id:guid}/accept", AcceptAsync).WithValidation<AcceptCaregiverInvitationRequest>();
        group.MapPut("/{id:guid}/permissions", UpdatePermissionsAsync).WithValidation<UpdateCaregiverPermissionsRequest>();
        group.MapDelete("/{id:guid}", RevokeAsync);

        group.MapGet("/shared-with-me", ListSharedWithMeAsync);
        group.MapGet("/shared-with-me/{id:guid}/medications", GetSharedMedicationsAsync);
        group.MapGet("/shared-with-me/{id:guid}/adherence", GetSharedAdherenceAsync);

        return app;
    }

    private static async Task<IResult> ListAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var relationships = await dbContext.CaregiverRelationships
            .Include(relationship => relationship.Permissions)
            .Where(relationship => relationship.OwnerUserId == userId &&
                                   relationship.Status != CaregiverRelationshipStatus.Revoked)
            .OrderByDescending(relationship => relationship.CreatedAt)
            .ToListAsync(cancellationToken);

        return Results.Ok(relationships.Select(ToResponse).ToList());
    }

    private static async Task<IResult> InviteAsync(
        InviteCaregiverRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        INotificationSender notificationSender,
        IAuditLogger auditLogger,
        IOptions<CaregiverOptions> options,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        if (!TryParsePermissions(request.Permissions, out var permissions, out var invalid))
        {
            return Results.BadRequest(new ApiError("invalid_permission", $"Unknown permission '{invalid}'."));
        }

        var owner = await dbContext.Users.FirstAsync(user => user.Id == userId, cancellationToken);
        if (string.Equals(owner.NormalizedEmail, User.NormalizeEmail(request.Email), StringComparison.Ordinal))
        {
            return Results.BadRequest(new ApiError("invalid_caregiver", "You cannot invite yourself as a caregiver."));
        }

        var rawToken = TokenGenerator.CreateToken();

        var relationship = CaregiverRelationship.Invite(
            userId,
            request.Email,
            TokenGenerator.Hash(rawToken),
            clock.UtcNow,
            TimeSpan.FromHours(options.Value.InvitationLifetimeHours),
            permissions);

        dbContext.CaregiverRelationships.Add(relationship);
        await dbContext.SaveChangesAsync(cancellationToken);

        await notificationSender.SendCaregiverInvitationAsync(request.Email, rawToken, null, cancellationToken);
        await auditLogger.LogAsync(AuditEventType.CaregiverInvited, userId, relationship.Id, cancellationToken: cancellationToken);

        return Results.Created(
            $"/api/caregivers/{relationship.Id}",
            new CaregiverInvitationResponse(
                ToResponse(relationship),
                options.Value.ExposeInvitationToken ? rawToken : null));
    }

    private static async Task<IResult> AcceptAsync(
        Guid id,
        AcceptCaregiverInvitationRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var caregiverUserId = currentUser.RequireUserId();

        var relationship = await dbContext.CaregiverRelationships
            .Include(item => item.Permissions)
            .FirstOrDefaultAsync(item => item.Id == id, cancellationToken);

        if (relationship is null || relationship.InvitationTokenHash != TokenGenerator.Hash(request.Token))
        {
            return Results.NotFound(new ApiError("invitation_not_found", "This invitation is no longer valid."));
        }

        if (relationship.InvitationExpiresAt <= clock.UtcNow || relationship.Status != CaregiverRelationshipStatus.Invited)
        {
            return Results.BadRequest(new ApiError("invitation_expired", "This invitation is no longer valid."));
        }

        var caregiver = await dbContext.Users.FirstAsync(user => user.Id == caregiverUserId, cancellationToken);

        if (!string.Equals(caregiver.NormalizedEmail, relationship.CaregiverEmail, StringComparison.Ordinal))
        {
            return Results.Json(
                new ApiError("invitation_mismatch", "This invitation was sent to a different email address."),
                statusCode: StatusCodes.Status403Forbidden);
        }

        relationship.Accept(caregiverUserId, caregiver.DisplayName, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.CaregiverInvitationAccepted,
            relationship.OwnerUserId,
            relationship.Id,
            cancellationToken: cancellationToken);

        return Results.Ok(ToResponse(relationship));
    }

    /// <summary>
    /// The owner approves the exact capability set. Access only starts after this step,
    /// so accepting an invitation alone grants nothing.
    /// </summary>
    private static async Task<IResult> UpdatePermissionsAsync(
        Guid id,
        UpdateCaregiverPermissionsRequest request,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        if (!TryParsePermissions(request.Permissions, out var permissions, out var invalid))
        {
            return Results.BadRequest(new ApiError("invalid_permission", $"Unknown permission '{invalid}'."));
        }

        var relationship = await dbContext.CaregiverRelationships
            .Include(item => item.Permissions)
            .FirstOrDefaultAsync(item => item.Id == id && item.OwnerUserId == userId, cancellationToken);

        if (relationship is null)
        {
            return Results.NotFound(new ApiError("caregiver_not_found", "This caregiver is not linked to your account."));
        }

        if (relationship.Status is CaregiverRelationshipStatus.Invited)
        {
            return Results.BadRequest(new ApiError(
                "invitation_pending",
                "This caregiver has not accepted the invitation yet."));
        }

        relationship.ApprovePermissions(permissions, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        await auditLogger.LogAsync(
            AuditEventType.CaregiverPermissionChanged,
            userId,
            relationship.Id,
            cancellationToken: cancellationToken);

        return Results.Ok(ToResponse(relationship));
    }

    private static async Task<IResult> RevokeAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var relationship = await dbContext.CaregiverRelationships
            .Include(item => item.Permissions)
            .FirstOrDefaultAsync(item => item.Id == id && item.OwnerUserId == userId, cancellationToken);

        if (relationship is null)
        {
            return Results.NotFound(new ApiError("caregiver_not_found", "This caregiver is not linked to your account."));
        }

        relationship.Revoke(clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);
        await auditLogger.LogAsync(AuditEventType.CaregiverRevoked, userId, relationship.Id, cancellationToken: cancellationToken);

        return Results.NoContent();
    }

    private static async Task<IResult> ListSharedWithMeAsync(
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var relationships = await dbContext.CaregiverRelationships
            .Include(relationship => relationship.Permissions)
            .Where(relationship => relationship.CaregiverUserId == userId &&
                                   relationship.Status == CaregiverRelationshipStatus.Active)
            .ToListAsync(cancellationToken);

        var ownerIds = relationships.Select(relationship => relationship.OwnerUserId).ToHashSet();
        var owners = await dbContext.Users
            .Where(user => ownerIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id, cancellationToken);

        return Results.Ok(relationships.Select(relationship => ToSharedWithMeResponse(relationship, owners[relationship.OwnerUserId])).ToList());
    }

    private static SharedWithMeResponse ToSharedWithMeResponse(CaregiverRelationship relationship, User owner) => new(
        relationship.Id,
        owner.Email,
        owner.DisplayName,
        relationship.Status.ToString(),
        relationship.Permissions
            .Where(permission => permission.Approved)
            .Select(permission => ToWireValue(permission.Permission))
            .ToList(),
        relationship.CreatedAt,
        relationship.AcceptedAt);

    private static async Task<IResult> GetSharedMedicationsAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var relationship = await RequirePermissionAsync(
            id,
            CaregiverPermission.ViewMedicationList,
            dbContext,
            currentUser,
            clock,
            cancellationToken);

        if (relationship is null)
        {
            return Forbidden();
        }

        var medications = await dbContext.Medications
            .Include(medication => medication.Ingredients)
            .Where(medication => medication.UserId == relationship.OwnerUserId && !medication.IsArchived)
            .OrderBy(medication => medication.BrandName)
            .ToListAsync(cancellationToken);

        var language = await GetLanguageAsync(dbContext, currentUser.RequireUserId(), cancellationToken);
        return Results.Ok(medications.Select(medication => medication.ToResponse(language: language)).ToList());
    }

    private static Task<string?> GetLanguageAsync(MedGuardDbContext dbContext, Guid userId, CancellationToken cancellationToken) =>
        dbContext.Users.Where(user => user.Id == userId).Select(user => user.PreferredLanguage).FirstOrDefaultAsync(cancellationToken);

    private static async Task<IResult> GetSharedAdherenceAsync(
        Guid id,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var relationship = await RequirePermissionAsync(
            id,
            CaregiverPermission.ViewAdherence,
            dbContext,
            currentUser,
            clock,
            cancellationToken);

        if (relationship is null)
        {
            return Forbidden();
        }

        var owner = await dbContext.Users.FirstAsync(user => user.Id == relationship.OwnerUserId, cancellationToken);
        var timeZone = DoseEventService.ResolveTimeZone(owner.TimeZoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(clock.UtcNow, timeZone).DateTime);
        var start = DoseEventService.ToInstant(today.AddDays(-6), TimeOnly.MinValue, timeZone);

        var doses = await dbContext.DoseEvents
            .Include(dose => dose.Medication)
            .Include(dose => dose.Schedule)
            .Where(dose => dose.UserId == owner.Id && dose.ScheduledAt >= start)
            .OrderBy(dose => dose.ScheduledAt)
            .ToListAsync(cancellationToken);

        var viewerLanguage = await GetLanguageAsync(dbContext, currentUser.RequireUserId(), cancellationToken);
        var days = doses
            .GroupBy(dose => DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(dose.ScheduledAt, timeZone).DateTime))
            .OrderByDescending(group => group.Key)
            .Select(group => new AdherenceDayResponse(
                group.Key,
                group.Select(dose => dose.ToResponse(timeZone, viewerLanguage)).ToList()))
            .ToList();

        return Results.Ok(new AdherenceHistoryResponse(
            today.AddDays(-6),
            today,
            days,
            doses.Count(dose => dose.Status == DoseEventStatus.Taken),
            doses.Count(dose => dose.Status == DoseEventStatus.Skipped),
            doses.Count(dose => dose.Status == DoseEventStatus.Missed),
            doses.Count(dose => dose.Status is DoseEventStatus.Pending or DoseEventStatus.Snoozed)));
    }

    private static async Task<CaregiverRelationship?> RequirePermissionAsync(
        Guid relationshipId,
        CaregiverPermission permission,
        MedGuardDbContext dbContext,
        ICurrentUser currentUser,
        IDateTimeProvider clock,
        CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();

        var relationship = await dbContext.CaregiverRelationships
            .Include(item => item.Permissions)
            .FirstOrDefaultAsync(item => item.Id == relationshipId && item.CaregiverUserId == userId, cancellationToken);

        return relationship?.HasPermission(permission, clock.UtcNow) == true ? relationship : null;
    }

    private static IResult Forbidden() => Results.Json(
        new ApiError("permission_denied", "You do not have access to this information."),
        statusCode: StatusCodes.Status403Forbidden);

    private static CaregiverResponse ToResponse(CaregiverRelationship relationship) => new(
        relationship.Id,
        relationship.CaregiverEmail,
        relationship.CaregiverDisplayName,
        relationship.Status.ToString(),
        relationship.Permissions
            .Where(permission => permission.Approved)
            .Select(permission => ToWireValue(permission.Permission))
            .ToList(),
        relationship.CreatedAt,
        relationship.AcceptedAt);

    public static string ToWireValue(CaregiverPermission permission) => permission switch
    {
        CaregiverPermission.ViewMedicationList => "VIEW_MEDICATION_LIST",
        CaregiverPermission.ViewAdherence => "VIEW_ADHERENCE",
        CaregiverPermission.ViewSchedule => "VIEW_SCHEDULE",
        _ => "RECEIVE_MISSED_DOSE_ALERT"
    };

    private static bool TryParsePermissions(
        IEnumerable<string> values,
        out List<CaregiverPermission> permissions,
        out string? invalid)
    {
        permissions = new List<CaregiverPermission>();
        invalid = null;

        foreach (var value in values)
        {
            var normalized = value.Replace("_", string.Empty).Trim();

            if (Enum.TryParse<CaregiverPermission>(normalized, ignoreCase: true, out var permission))
            {
                permissions.Add(permission);
                continue;
            }

            invalid = value;
            return false;
        }

        return true;
    }
}
