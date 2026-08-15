using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Persistence.Configurations;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace MedGuard.Infrastructure.Persistence;

public sealed class MedGuardDbContext : DbContext
{
    private readonly IFieldEncryptor _fieldEncryptor;

    public MedGuardDbContext(DbContextOptions<MedGuardDbContext> options, IFieldEncryptor fieldEncryptor)
        : base(options)
    {
        _fieldEncryptor = fieldEncryptor;
    }

    public DbSet<User> Users => Set<User>();

    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    public DbSet<EmailVerificationCode> EmailVerificationCodes => Set<EmailVerificationCode>();

    public DbSet<Medication> Medications => Set<Medication>();

    public DbSet<MedicationIngredient> MedicationIngredients => Set<MedicationIngredient>();

    public DbSet<MedicationSchedule> MedicationSchedules => Set<MedicationSchedule>();

    public DbSet<DoseEvent> DoseEvents => Set<DoseEvent>();

    public DbSet<SafetyFinding> SafetyFindings => Set<SafetyFinding>();

    public DbSet<SafetyFindingSubject> SafetyFindingSubjects => Set<SafetyFindingSubject>();

    public DbSet<MedicationScan> MedicationScans => Set<MedicationScan>();

    public DbSet<CaregiverRelationship> CaregiverRelationships => Set<CaregiverRelationship>();

    public DbSet<CaregiverPermissionGrant> CaregiverPermissions => Set<CaregiverPermissionGrant>();

    public DbSet<EmergencyCard> EmergencyCards => Set<EmergencyCard>();

    public DbSet<EmergencyCardAccessLog> EmergencyCardAccessLogs => Set<EmergencyCardAccessLog>();

    public DbSet<AuditEvent> AuditEvents => Set<AuditEvent>();

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        base.ConfigureConventions(configurationBuilder);

        configurationBuilder.Properties<DateTimeOffset>().HaveConversion<UtcDateTimeOffsetConverter>();
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new RefreshTokenConfiguration());
        modelBuilder.ApplyConfiguration(new PasswordResetTokenConfiguration());
        modelBuilder.ApplyConfiguration(new EmailVerificationCodeConfiguration());
        modelBuilder.ApplyConfiguration(new MedicationConfiguration(_fieldEncryptor));
        modelBuilder.ApplyConfiguration(new MedicationIngredientConfiguration());
        modelBuilder.ApplyConfiguration(new MedicationScheduleConfiguration());
        modelBuilder.ApplyConfiguration(new DoseEventConfiguration());
        modelBuilder.ApplyConfiguration(new SafetyFindingConfiguration());
        modelBuilder.ApplyConfiguration(new SafetyFindingSubjectConfiguration());
        modelBuilder.ApplyConfiguration(new MedicationScanConfiguration());
        modelBuilder.ApplyConfiguration(new CaregiverConfiguration());
        modelBuilder.ApplyConfiguration(new CaregiverPermissionConfiguration());
        modelBuilder.ApplyConfiguration(new EmergencyCardConfiguration(_fieldEncryptor));
        modelBuilder.ApplyConfiguration(new EmergencyCardAccessLogConfiguration());
        modelBuilder.ApplyConfiguration(new AuditEventConfiguration());

        UseDomainAssignedKeys(modelBuilder);
    }

    /// <summary>
    /// Every entity creates its own identifier in a factory method. Without this, EF treats a new
    /// child of an already tracked parent as an update to an existing row.
    /// </summary>
    private static void UseDomainAssignedKeys(ModelBuilder modelBuilder)
    {
        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            var key = entityType.FindPrimaryKey();

            if (key is { Properties: [{ ClrType: var clrType } property] } && clrType == typeof(Guid))
            {
                property.ValueGenerated = ValueGenerated.Never;
            }
        }
    }

    /// <summary>
    /// A scheduled dose carries the offset of the user's time zone, for example +03:00, while
    /// PostgreSQL timestamptz only accepts UTC. Normalising keeps the instant intact and matches
    /// the value that comes back on read.
    /// </summary>
    private sealed class UtcDateTimeOffsetConverter : ValueConverter<DateTimeOffset, DateTimeOffset>
    {
        public UtcDateTimeOffsetConverter()
            : base(value => value.ToUniversalTime(), value => value.ToUniversalTime())
        {
        }
    }
}
