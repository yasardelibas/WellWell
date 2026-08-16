using MedGuard.Domain.Enums;

namespace MedGuard.Domain.Entities;

/// <summary>
/// A label scan. The original image is not persisted by default: it is processed in memory and
/// discarded once structured fields are extracted, unless the user explicitly opts into retention.
/// </summary>
public sealed class MedicationScan
{
    private MedicationScan()
    {
        ExtractionJson = "{}";
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public ScanStatus Status { get; private set; }

    /// <summary>Lowest confidence across the extracted fields, 0..1.</summary>
    public decimal ExtractionConfidence { get; private set; }

    public string ExtractionSource { get; private set; } = "unknown";

    /// <summary>Structured extraction payload with per-field confidence. Never logged.</summary>
    public string ExtractionJson { get; private set; }

    public string? FailureReason { get; private set; }

    public bool ImageRetained { get; private set; }

    public string? RetainedImageReference { get; private set; }

    public Guid? MedicationId { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset? ConfirmedAt { get; private set; }

    public DateTimeOffset ExpiresAt { get; private set; }

    public static MedicationScan AwaitingConfirmation(
        Guid userId,
        decimal extractionConfidence,
        string extractionSource,
        string extractionJson,
        DateTimeOffset now,
        TimeSpan retention) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Status = ScanStatus.AwaitingConfirmation,
            ExtractionConfidence = extractionConfidence,
            ExtractionSource = extractionSource,
            ExtractionJson = extractionJson,
            CreatedAt = now,
            ExpiresAt = now.Add(retention)
        };

    public static MedicationScan Failed(Guid userId, string reason, DateTimeOffset now, TimeSpan retention) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Status = ScanStatus.ExtractionFailed,
            ExtractionConfidence = 0m,
            ExtractionSource = "none",
            ExtractionJson = "{}",
            FailureReason = reason,
            CreatedAt = now,
            ExpiresAt = now.Add(retention)
        };

    public void Confirm(Guid medicationId, DateTimeOffset now)
    {
        Status = ScanStatus.Confirmed;
        MedicationId = medicationId;
        ConfirmedAt = now;
    }

    public void Discard() => Status = ScanStatus.Discarded;

    public void RetainImage(string reference)
    {
        ImageRetained = true;
        RetainedImageReference = reference;
    }
}
