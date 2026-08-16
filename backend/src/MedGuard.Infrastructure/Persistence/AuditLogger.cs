using System.Diagnostics;
using MedGuard.Application.Abstractions;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Persistence;

/// <summary>
/// Writes the audit trail. Only identifiers and short outcome markers are recorded:
/// medication names, label text and card contents never reach this table or the log sink.
/// </summary>
public sealed class AuditLogger : IAuditLogger
{
    private readonly MedGuardDbContext _dbContext;
    private readonly IDateTimeProvider _clock;
    private readonly ILogger<AuditLogger> _logger;

    public AuditLogger(MedGuardDbContext dbContext, IDateTimeProvider clock, ILogger<AuditLogger> logger)
    {
        _dbContext = dbContext;
        _clock = clock;
        _logger = logger;
    }

    public async Task LogAsync(
        AuditEventType type,
        Guid? userId,
        Guid? subjectId = null,
        string? outcome = null,
        CancellationToken cancellationToken = default)
    {
        var correlationId = Activity.Current?.TraceId.ToString();
        var auditEvent = AuditEvent.Create(type, userId, _clock.UtcNow, subjectId, outcome, correlationId);

        _dbContext.AuditEvents.Add(auditEvent);
        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation(
            "Audit {AuditType} user={UserId} subject={SubjectId} outcome={Outcome}",
            type,
            userId,
            subjectId,
            outcome ?? "success");
    }
}
