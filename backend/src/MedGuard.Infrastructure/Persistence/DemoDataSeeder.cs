using MedGuard.Application.Abstractions;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Drugs;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace MedGuard.Infrastructure.Persistence;

/// <summary>
/// Seeds the demo account used for the walkthrough: one saved medication that already
/// contains acetaminophen, a couple of confirmed schedules and a week of adherence history.
/// The second acetaminophen product is intentionally not seeded so it can be scanned live.
/// </summary>
public sealed class DemoDataSeeder
{
    private const string TimeZoneId = "Europe/Istanbul";

    private readonly MedGuardDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IIngredientNormalizer _normalizer;
    private readonly IDateTimeProvider _clock;
    private readonly DemoOptions _demoOptions;
    private readonly EmergencyCardOptions _emergencyOptions;
    private readonly ILogger<DemoDataSeeder> _logger;

    public DemoDataSeeder(
        MedGuardDbContext dbContext,
        IPasswordHasher passwordHasher,
        IIngredientNormalizer normalizer,
        IDateTimeProvider clock,
        IOptions<DemoOptions> demoOptions,
        IOptions<EmergencyCardOptions> emergencyOptions,
        ILogger<DemoDataSeeder> logger)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _normalizer = normalizer;
        _clock = clock;
        _demoOptions = demoOptions.Value;
        _emergencyOptions = emergencyOptions.Value;
        _logger = logger;
    }

    public async Task<Guid?> SeedAsync(CancellationToken cancellationToken)
    {
        if (!_demoOptions.Enabled)
        {
            return null;
        }

        var normalizedEmail = User.NormalizeEmail(_demoOptions.Email);
        var existing = await _dbContext.Users
            .FirstOrDefaultAsync(user => user.NormalizedEmail == normalizedEmail, cancellationToken)
            .ConfigureAwait(false);

        if (existing is not null)
        {
            return existing.Id;
        }

        var now = _clock.UtcNow;
        var user = User.Create(
            _demoOptions.Email,
            _passwordHasher.Hash(_demoOptions.Password),
            "Burak",
            now,
            TimeZoneId,
            isDemoAccount: true);

        user.AcknowledgeSafetyNotice(now);
        _dbContext.Users.Add(user);

        var timeZone = DoseEventService.ResolveTimeZone(TimeZoneId);

        var acetaminophen = CreateMedication(
            user.Id,
            brandName: "Tylenol Extra Strength",
            genericName: "Acetaminophen",
            rxCui: "198440",
            dosageForm: "Tablet",
            strength: "500 mg",
            directions: "Take 1 tablet every 6 hours as needed.",
            ingredients: new[] { ("Acetaminophen", 500m, "mg", "161") },
            now.AddDays(-30));

        var metformin = CreateMedication(
            user.Id,
            brandName: "Glucophage",
            genericName: "Metformin",
            rxCui: "861007",
            dosageForm: "Tablet",
            strength: "500 mg",
            directions: "Take 1 tablet twice daily with meals.",
            ingredients: new[] { ("Metformin Hydrochloride", 500m, "mg", "6809") },
            now.AddDays(-60));

        var cetirizine = CreateMedication(
            user.Id,
            brandName: "Zyrtec",
            genericName: "Cetirizine",
            rxCui: "1014678",
            dosageForm: "Tablet",
            strength: "10 mg",
            directions: "Take 1 tablet once daily.",
            ingredients: new[] { ("Cetirizine Hydrochloride", 10m, "mg", "20610") },
            now.AddDays(-14));

        _dbContext.Medications.AddRange(acetaminophen, metformin, cetirizine);

        var schedules = new[]
        {
            MedicationSchedule.Create(user.Id, metformin.Id, new TimeOnly(8, 0), true, now, metformin.LabelDirections, "1 tablet"),
            MedicationSchedule.Create(user.Id, metformin.Id, new TimeOnly(20, 0), true, now, metformin.LabelDirections, "1 tablet"),
            MedicationSchedule.Create(user.Id, cetirizine.Id, new TimeOnly(13, 0), true, now, cetirizine.LabelDirections, "1 tablet")
        };

        _dbContext.MedicationSchedules.AddRange(schedules);
        _dbContext.DoseEvents.AddRange(BuildHistory(user.Id, schedules, timeZone, now));

        var demoToken = TokenGenerator.CreateToken();
        var card = EmergencyCard.Create(
            user.Id,
            demoToken,
            TokenGenerator.Hash(demoToken),
            now,
            _emergencyOptions.TokenLifetimeDays.HasValue
                ? TimeSpan.FromDays(_emergencyOptions.TokenLifetimeDays.Value)
                : null);

        card.Update(
            isEnabled: true,
            shareName: true,
            shareAllergies: true,
            shareMedications: true,
            shareEmergencyContact: true,
            shareNotes: false,
            displayName: "Burak",
            allergies: "Penicillin",
            emergencyContactName: "Elif (sister)",
            emergencyContactPhone: "+90 555 000 00 00",
            notes: null,
            now);

        _dbContext.EmergencyCards.Add(card);

        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Demo account seeded with {MedicationCount} medications.", 3);

        return user.Id;
    }

    private Medication CreateMedication(
        Guid userId,
        string brandName,
        string genericName,
        string rxCui,
        string dosageForm,
        string strength,
        string directions,
        IEnumerable<(string Name, decimal Strength, string Unit, string RxCui)> ingredients,
        DateTimeOffset createdAt)
    {
        var activeIngredients = ingredients
            .Select(ingredient => _normalizer.Normalize(ingredient.Name, ingredient.Strength, ingredient.Unit, ingredient.RxCui))
            .ToList();

        return Medication.Create(
            userId,
            brandName,
            genericName,
            activeIngredients,
            MedicationVerificationStatus.Verified,
            createdAt,
            rxCui,
            dosageForm,
            strength,
            "Oral",
            directions,
            manufacturer: null,
            notes: null,
            provenance: new DataProvenance(
                LocalDrugDataProvider.ProviderName,
                rxCui,
                createdAt,
                LocalDrugDataProvider.DatasetVersion));
    }

    /// <summary>
    /// Seven days of history plus today. Today's morning dose is already taken so the
    /// dashboard shows real progress; the rest stay pending.
    /// </summary>
    private IEnumerable<DoseEvent> BuildHistory(
        Guid userId,
        IReadOnlyList<MedicationSchedule> schedules,
        TimeZoneInfo timeZone,
        DateTimeOffset now)
    {
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(now, timeZone).DateTime);

        for (var dayOffset = 7; dayOffset >= 0; dayOffset--)
        {
            var date = today.AddDays(-dayOffset);

            foreach (var schedule in schedules)
            {
                var scheduledAt = DoseEventService.ToInstant(date, schedule.ReminderTime, timeZone);
                var dose = DoseEvent.CreatePending(userId, schedule.MedicationId, schedule.Id, scheduledAt, now);

                if (dayOffset == 0)
                {
                    if (scheduledAt.AddMinutes(30) < now)
                    {
                        dose.MarkTaken(scheduledAt.AddMinutes(2));
                    }

                    yield return dose;
                    continue;
                }

                // A deterministic pattern keeps the demo timeline stable between runs.
                var slot = (dayOffset + schedule.ReminderTime.Hour) % 7;
                if (slot == 3)
                {
                    dose.MarkSkipped(scheduledAt.AddMinutes(5));
                }
                else if (slot == 5)
                {
                    dose.MarkMissed(scheduledAt.AddHours(3));
                }
                else
                {
                    dose.MarkTaken(scheduledAt.AddMinutes(slot + 1));
                }

                yield return dose;
            }
        }
    }
}
