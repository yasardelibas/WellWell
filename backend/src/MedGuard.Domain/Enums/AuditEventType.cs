namespace MedGuard.Domain.Enums;

/// <summary>
/// Audit event kinds. Audit rows never contain raw medical detail, only identifiers and outcomes.
/// </summary>
public enum AuditEventType
{
    UserRegistered = 0,
    UserSignedIn = 1,
    UserSignedOut = 2,
    PasswordResetRequested = 3,
    EmailVerificationRequested = 4,
    EmailVerified = 5,
    MedicationAdded = 10,
    MedicationUpdated = 11,
    MedicationRemoved = 12,
    MedicationScanCreated = 13,
    MedicationScanConfirmed = 14,
    SafetyCheckPerformed = 20,
    SafetyExplanationRequested = 21,
    ScheduleCreated = 30,
    ScheduleUpdated = 31,
    ScheduleDeleted = 32,
    DoseRecorded = 40,
    EmergencyCardUpdated = 50,
    EmergencyCardTokenRegenerated = 51,
    EmergencyCardViewed = 52,
    CaregiverInvited = 60,
    CaregiverInvitationAccepted = 61,
    CaregiverPermissionChanged = 62,
    CaregiverRevoked = 63
}
