namespace MedGuard.Contracts.Schedules;

public sealed record CreateScheduleRequest(
    Guid MedicationId,
    IReadOnlyCollection<string> Times,
    string? LabelInstruction,
    string? DoseAmountText,
    bool UserConfirmed);

public sealed record UpdateScheduleRequest(string? Time, string? DoseAmountText, bool? IsActive);

public sealed record ScheduleResponse(
    Guid Id,
    Guid MedicationId,
    string MedicationName,
    string Time,
    string? LabelInstruction,
    string? DoseAmountText,
    bool UserConfirmed,
    bool IsActive);
