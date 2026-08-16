namespace MedGuard.Domain.Enums;

public enum ScanStatus
{
    /// <summary>Scan row created, extraction not finished.</summary>
    Processing = 0,

    /// <summary>Extraction finished, waiting for explicit user confirmation.</summary>
    AwaitingConfirmation = 1,

    /// <summary>User confirmed and a medication record was created.</summary>
    Confirmed = 2,

    /// <summary>Extraction failed; nothing was saved to the medication list.</summary>
    ExtractionFailed = 3,

    /// <summary>User discarded the scan.</summary>
    Discarded = 4
}
