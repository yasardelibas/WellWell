namespace MedGuard.Domain.Entities;

/// <summary>
/// A reminder time chosen by the user. Suggested times are a convenience only:
/// Domain Rule 4 requires <see cref="UserConfirmed"/> before a schedule becomes active.
/// </summary>
public sealed class MedicationSchedule
{
    private MedicationSchedule()
    {
    }

    public Guid Id { get; private set; }

    public Guid MedicationId { get; private set; }

    public Guid UserId { get; private set; }

    public TimeOnly ReminderTime { get; private set; }

    /// <summary>The label wording this reminder was derived from, verbatim.</summary>
    public string? LabelInstruction { get; private set; }

    /// <summary>Free-text dose description as printed on the label, e.g. "1 tablet".</summary>
    public string? DoseAmountText { get; private set; }

    public bool UserConfirmed { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public Medication? Medication { get; private set; }

    public static MedicationSchedule Create(
        Guid userId,
        Guid medicationId,
        TimeOnly reminderTime,
        bool userConfirmed,
        DateTimeOffset now,
        string? labelInstruction = null,
        string? doseAmountText = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            MedicationId = medicationId,
            ReminderTime = reminderTime,
            LabelInstruction = labelInstruction,
            DoseAmountText = doseAmountText,
            UserConfirmed = userConfirmed,
            IsActive = userConfirmed,
            CreatedAt = now,
            UpdatedAt = now
        };

    public void Update(TimeOnly? reminderTime, string? doseAmountText, bool? isActive, DateTimeOffset now)
    {
        if (reminderTime.HasValue)
        {
            ReminderTime = reminderTime.Value;
        }

        if (doseAmountText is not null)
        {
            DoseAmountText = doseAmountText;
        }

        if (isActive.HasValue)
        {
            // A schedule can never be activated without explicit user confirmation.
            IsActive = isActive.Value && UserConfirmed;
        }

        UpdatedAt = now;
    }

    public void Confirm(DateTimeOffset now)
    {
        UserConfirmed = true;
        IsActive = true;
        UpdatedAt = now;
    }

    public void Deactivate(DateTimeOffset now)
    {
        IsActive = false;
        UpdatedAt = now;
    }
}
