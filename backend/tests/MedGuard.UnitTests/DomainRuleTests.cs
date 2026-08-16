using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.Safety;
using MedGuard.Domain.ValueObjects;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class MedicationDomainTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly DateTimeOffset Now = new(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Create_ShouldReject_WhenMarkedVerifiedWithoutProvenance()
    {
        var exception = Assert.Throws<InvalidOperationException>(() => Medication.Create(
            UserId,
            "Product A",
            "Acetaminophen",
            Array.Empty<ActiveIngredient>(),
            MedicationVerificationStatus.Verified,
            Now));

        Assert.Contains("provenance", exception.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Create_ShouldReject_WhenNoNameIsProvided() =>
        Assert.Throws<ArgumentException>(() => Medication.Create(
            UserId,
            string.Empty,
            string.Empty,
            Array.Empty<ActiveIngredient>(),
            MedicationVerificationStatus.Unverified,
            Now));

    [Fact]
    public void InvalidateVerification_ShouldDropProvenance()
    {
        var medication = TestMedications.Create(UserId, "Product A", new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)"161") });

        medication.InvalidateVerification(Now);

        Assert.Equal(MedicationVerificationStatus.Unverified, medication.VerificationStatus);
        Assert.Null(medication.Provenance);
    }

    [Fact]
    public void MarkVerified_ShouldRecordProvenanceAndIdentifier()
    {
        var medication = TestMedications.Create(
            UserId,
            "Product A",
            new[] { ("Acetaminophen", (decimal?)500m, "mg", (string?)null) },
            MedicationVerificationStatus.Unverified);

        medication.MarkVerified(new DataProvenance("rxnorm", "198440", Now, "rxnav-current"), "198440", Now);

        Assert.Equal(MedicationVerificationStatus.Verified, medication.VerificationStatus);
        Assert.Equal("rxnorm", medication.Provenance!.Provider);
        Assert.Equal("198440", medication.RxCui);
    }

    [Fact]
    public void DisplayName_ShouldFallBackToGenericName_WhenNoBrandIsKnown()
    {
        var medication = Medication.Create(
            UserId,
            string.Empty,
            "Acetaminophen",
            Array.Empty<ActiveIngredient>(),
            MedicationVerificationStatus.Unverified,
            Now);

        Assert.Equal("Acetaminophen", medication.DisplayName);
    }
}

public sealed class MedicationScheduleTests
{
    private static readonly DateTimeOffset Now = new(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Create_ShouldStayInactive_WhenTheUserHasNotConfirmed()
    {
        var schedule = MedicationSchedule.Create(Guid.NewGuid(), Guid.NewGuid(), new TimeOnly(8, 0), userConfirmed: false, Now);

        Assert.False(schedule.IsActive);
        Assert.False(schedule.UserConfirmed);
    }

    [Fact]
    public void Update_ShouldNotActivate_WhenTheUserHasNotConfirmed()
    {
        var schedule = MedicationSchedule.Create(Guid.NewGuid(), Guid.NewGuid(), new TimeOnly(8, 0), userConfirmed: false, Now);

        schedule.Update(null, null, isActive: true, Now);

        Assert.False(schedule.IsActive);
    }

    [Fact]
    public void Confirm_ShouldActivateTheReminder()
    {
        var schedule = MedicationSchedule.Create(Guid.NewGuid(), Guid.NewGuid(), new TimeOnly(8, 0), userConfirmed: false, Now);

        schedule.Confirm(Now);

        Assert.True(schedule.IsActive);
        Assert.True(schedule.UserConfirmed);
    }
}

public sealed class DoseEventTests
{
    private static readonly DateTimeOffset Scheduled = new(2025, 1, 15, 8, 0, 0, TimeSpan.Zero);

    private static DoseEvent CreateDose() =>
        DoseEvent.CreatePending(Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Scheduled, Scheduled);

    [Fact]
    public void MarkTaken_ShouldRecordCompletionTime()
    {
        var dose = CreateDose();

        dose.MarkTaken(Scheduled.AddMinutes(2));

        Assert.Equal(DoseEventStatus.Taken, dose.Status);
        Assert.Equal(Scheduled.AddMinutes(2), dose.CompletedAt);
    }

    [Fact]
    public void MarkMissed_ShouldNotOverrideACompletedDose()
    {
        var dose = CreateDose();
        dose.MarkTaken(Scheduled);

        dose.MarkMissed(Scheduled.AddHours(4));

        Assert.Equal(DoseEventStatus.Taken, dose.Status);
    }

    [Fact]
    public void Snooze_ShouldRecordTheNewReminderTime()
    {
        var dose = CreateDose();

        dose.Snooze(Scheduled.AddMinutes(15), Scheduled);

        Assert.Equal(DoseEventStatus.Snoozed, dose.Status);
        Assert.Equal(Scheduled.AddMinutes(15), dose.SnoozedUntil);
    }
}

public sealed class SafetyStatusTests
{
    private static SafetyFinding Finding(SafetySeverity severity) => SafetyFinding.Create(
        Guid.NewGuid(),
        SafetyFindingType.DuplicateActiveIngredient,
        severity,
        "Title",
        "source",
        true,
        DateTimeOffset.UtcNow);

    [Fact]
    public void DeriveStatus_ShouldReportNoFindings_WhenEveryCheckCompletedCleanly() =>
        Assert.Equal(
            SafetyStatus.NoFindings,
            SafetyAnalysisResult.DeriveStatus(
                Array.Empty<SafetyFinding>(),
                new[] { new SafetyCheckOutcome("duplicate_active_ingredient", SafetyCheckState.Completed) }));

    [Fact]
    public void DeriveStatus_ShouldRequireAttention_WhenAConfiguredSourceFailed() =>
        Assert.Equal(
            SafetyStatus.Attention,
            SafetyAnalysisResult.DeriveStatus(
                Array.Empty<SafetyFinding>(),
                new[] { new SafetyCheckOutcome("drug_interaction", SafetyCheckState.Unavailable) }));

    [Fact]
    public void DeriveStatus_ShouldStayNeutral_WhenACapabilityWasNeverConfigured() =>
        Assert.Equal(
            SafetyStatus.NoFindings,
            SafetyAnalysisResult.DeriveStatus(
                Array.Empty<SafetyFinding>(),
                new[] { new SafetyCheckOutcome("drug_interaction", SafetyCheckState.NotConfigured) }));

    [Fact]
    public void DeriveStatus_ShouldEscalateToTheHighestSeverityPresent() =>
        Assert.Equal(
            SafetyStatus.High,
            SafetyAnalysisResult.DeriveStatus(
                new[] { Finding(SafetySeverity.Info), Finding(SafetySeverity.Warning), Finding(SafetySeverity.High) },
                Array.Empty<SafetyCheckOutcome>()));
}

public sealed class CaregiverRelationshipTests
{
    private static readonly DateTimeOffset Now = new(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    private static CaregiverRelationship Invite() => CaregiverRelationship.Invite(
        Guid.NewGuid(),
        "Caregiver@Example.com",
        "hash",
        Now,
        TimeSpan.FromHours(72),
        new[] { CaregiverPermission.ViewMedicationList });

    [Fact]
    public void Invite_ShouldNotGrantAccessBeforeOwnerApproval()
    {
        var relationship = Invite();

        Assert.False(relationship.HasPermission(CaregiverPermission.ViewMedicationList, Now));
        Assert.Equal("caregiver@example.com", relationship.CaregiverEmail);
    }

    [Fact]
    public void ApprovePermissions_ShouldGrantOnlyTheApprovedCapabilities()
    {
        var relationship = Invite();
        relationship.Accept(Guid.NewGuid(), "Elif", Now);
        relationship.ApprovePermissions(new[] { CaregiverPermission.ViewAdherence }, Now);

        Assert.True(relationship.HasPermission(CaregiverPermission.ViewAdherence, Now));
        Assert.False(relationship.HasPermission(CaregiverPermission.ViewMedicationList, Now));
    }

    [Fact]
    public void Revoke_ShouldRemoveAccessImmediately()
    {
        var relationship = Invite();
        relationship.Accept(Guid.NewGuid(), "Elif", Now);
        relationship.ApprovePermissions(new[] { CaregiverPermission.ViewAdherence }, Now);

        relationship.Revoke(Now);

        Assert.False(relationship.HasPermission(CaregiverPermission.ViewAdherence, Now));
        Assert.Empty(relationship.Permissions);
    }
}

public sealed class EmergencyCardTests
{
    private static readonly DateTimeOffset Now = new(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Create_ShouldStartDisabled()
    {
        var card = EmergencyCard.Create(Guid.NewGuid(), "token", "hash", Now, TimeSpan.FromDays(365));

        Assert.False(card.IsEnabled);
        Assert.False(card.IsTokenUsable(Now));
    }

    [Fact]
    public void RegenerateToken_ShouldInvalidateThePreviousToken()
    {
        var card = EmergencyCard.Create(Guid.NewGuid(), "token", "hash", Now, null);

        card.RegenerateToken("new-token", "new-hash", Now.AddDays(1), null);

        Assert.Equal("new-hash", card.TokenHash);
        Assert.Equal("new-token", card.Token);
    }

    [Fact]
    public void IsTokenUsable_ShouldReturnFalse_AfterExpiry()
    {
        var card = EmergencyCard.Create(Guid.NewGuid(), "token", "hash", Now, TimeSpan.FromDays(1));
        card.Update(true, true, false, false, false, false, "Burak", null, null, null, null, Now);

        Assert.True(card.IsTokenUsable(Now));
        Assert.False(card.IsTokenUsable(Now.AddDays(2)));
    }
}

public sealed class RefreshTokenTests
{
    private static readonly DateTimeOffset Now = new(2025, 1, 15, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void IsActive_ShouldReturnFalse_AfterRevocation()
    {
        var token = RefreshToken.Issue(Guid.NewGuid(), "hash", Now, TimeSpan.FromDays(30));

        Assert.True(token.IsActive(Now));

        token.Revoke(Now, "rotated");

        Assert.False(token.IsActive(Now));
        Assert.Equal("rotated", token.RevokedReason);
    }

    [Fact]
    public void IsActive_ShouldReturnFalse_AfterExpiry()
    {
        var token = RefreshToken.Issue(Guid.NewGuid(), "hash", Now, TimeSpan.FromDays(1));

        Assert.False(token.IsActive(Now.AddDays(2)));
    }
}
