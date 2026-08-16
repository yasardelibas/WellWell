namespace MedGuard.Domain.Enums;

/// <summary>
/// Verification state of a medication record.
/// A medication may only reach <see cref="Verified"/> after a successful match against an
/// approved external drug data provider. Provider failures map to
/// <see cref="VerificationUnavailable"/> and never to <see cref="Verified"/>.
/// </summary>
public enum MedicationVerificationStatus
{
    /// <summary>Entered or extracted, never matched against a trusted provider.</summary>
    Unverified = 0,

    /// <summary>Matched against an approved trusted drug data provider.</summary>
    Verified = 1,

    /// <summary>A trusted provider was queried but could not be reached.</summary>
    VerificationUnavailable = 2,

    /// <summary>A trusted provider responded but returned no confident match.</summary>
    NoConfidentMatch = 3
}
