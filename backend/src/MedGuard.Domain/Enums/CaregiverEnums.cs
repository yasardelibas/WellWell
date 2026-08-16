namespace MedGuard.Domain.Enums;

/// <summary>
/// Least-privilege caregiver capabilities. Nothing is granted by default.
/// </summary>
public enum CaregiverPermission
{
    ViewMedicationList = 0,
    ViewAdherence = 1,
    ViewSchedule = 2,
    ReceiveMissedDoseAlert = 3
}

public enum CaregiverRelationshipStatus
{
    Invited = 0,
    Accepted = 1,
    Active = 2,
    Declined = 3,
    Revoked = 4,
    Expired = 5
}
