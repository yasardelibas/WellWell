using MedGuard.Domain.Enums;

namespace MedGuard.Domain.Entities;

/// <summary>
/// Structured audit trail. Rows hold identifiers and outcomes only, never medication
/// names, label text, OCR output or emergency card content.
/// </summary>
public sealed class AuditEvent
{
    private AuditEvent()
    {
    }

    public Guid Id { get; private set; }

    public Guid? UserId { get; private set; }

    public AuditEventType Type { get; private set; }

    public Guid? SubjectId { get; private set; }

    public string? CorrelationId { get; private set; }

    /// <summary>Short non-sensitive outcome marker, e.g. "success", "denied", "provider-unavailable".</summary>
    public string? Outcome { get; private set; }

    public DateTimeOffset OccurredAt { get; private set; }

    public static AuditEvent Create(
        AuditEventType type,
        Guid? userId,
        DateTimeOffset now,
        Guid? subjectId = null,
        string? outcome = null,
        string? correlationId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Type = type,
            UserId = userId,
            SubjectId = subjectId,
            Outcome = outcome,
            CorrelationId = correlationId,
            OccurredAt = now
        };
}
