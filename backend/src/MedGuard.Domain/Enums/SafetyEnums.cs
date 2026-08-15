namespace MedGuard.Domain.Enums;

public enum SafetyFindingType
{
    DuplicateActiveIngredient = 0,
    UnverifiedMedication = 1,
    InteractionCheckUnavailable = 2,
    DrugInteraction = 3
}

/// <summary>
/// Severity is never expressed through colour alone in the UI; every severity has an icon and label.
/// </summary>
public enum SafetySeverity
{
    Info = 0,
    Warning = 1,
    High = 2
}

/// <summary>
/// Overall outcome of a safety analysis. There is deliberately no "Safe" member:
/// MedGuard can only report that its currently available checks found nothing.
/// </summary>
public enum SafetyStatus
{
    NoFindings = 0,
    Attention = 1,
    Warning = 2,
    High = 3
}
