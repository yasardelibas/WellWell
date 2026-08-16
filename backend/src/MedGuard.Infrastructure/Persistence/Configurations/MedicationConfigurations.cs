using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MedGuard.Infrastructure.Persistence.Configurations;

public sealed class MedicationConfiguration : IEntityTypeConfiguration<Medication>
{
    private readonly IFieldEncryptor _fieldEncryptor;

    public MedicationConfiguration(IFieldEncryptor fieldEncryptor) => _fieldEncryptor = fieldEncryptor;

    public void Configure(EntityTypeBuilder<Medication> builder)
    {
        builder.ToTable("Medications");
        builder.HasKey(medication => medication.Id);

        builder.Property(medication => medication.BrandName).HasMaxLength(200).IsRequired();
        builder.Property(medication => medication.GenericName).HasMaxLength(200).IsRequired();
        builder.Property(medication => medication.RxCui).HasMaxLength(32);
        builder.Property(medication => medication.DosageForm).HasMaxLength(80);
        builder.Property(medication => medication.Strength).HasMaxLength(80);
        builder.Property(medication => medication.Route).HasMaxLength(80);
        builder.Property(medication => medication.LabelDirections).HasMaxLength(500);
        builder.Property(medication => medication.Manufacturer).HasMaxLength(200);
        builder.Property(medication => medication.ProvenanceProvider).HasMaxLength(80);
        builder.Property(medication => medication.ProvenanceExternalId).HasMaxLength(120);
        builder.Property(medication => medication.ProvenanceDatasetVersion).HasMaxLength(60);

        builder.Property(medication => medication.VerificationStatus)
            .HasConversion<string>()
            .HasMaxLength(40)
            .IsRequired();

        // Free-text notes may contain personal detail, so they are encrypted at rest.
        builder.Property(medication => medication.Notes)
            .HasMaxLength(2000)
            .HasConversion(
                value => _fieldEncryptor.Encrypt(value),
                value => _fieldEncryptor.Decrypt(value));

        builder.Metadata
            .FindNavigation(nameof(Medication.Ingredients))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);

        builder.HasMany(medication => medication.Ingredients)
            .WithOne()
            .HasForeignKey(ingredient => ingredient.MedicationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(medication => medication.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(medication => new { medication.UserId, medication.IsArchived });
    }
}

public sealed class MedicationIngredientConfiguration : IEntityTypeConfiguration<MedicationIngredient>
{
    public void Configure(EntityTypeBuilder<MedicationIngredient> builder)
    {
        builder.ToTable("MedicationIngredients");
        builder.HasKey(ingredient => ingredient.Id);

        builder.Property(ingredient => ingredient.NormalizedName).HasMaxLength(200).IsRequired();
        builder.Property(ingredient => ingredient.OriginalName).HasMaxLength(200).IsRequired();
        builder.Property(ingredient => ingredient.Unit).HasMaxLength(20);
        builder.Property(ingredient => ingredient.RxCui).HasMaxLength(32);
        builder.Property(ingredient => ingredient.Strength).HasPrecision(12, 3);

        builder.Ignore(ingredient => ingredient.DisplayStrength);
        builder.Ignore(ingredient => ingredient.ComparisonKey);

        builder.HasIndex(ingredient => ingredient.NormalizedName);
        builder.HasIndex(ingredient => ingredient.RxCui);
    }
}

public sealed class MedicationScheduleConfiguration : IEntityTypeConfiguration<MedicationSchedule>
{
    public void Configure(EntityTypeBuilder<MedicationSchedule> builder)
    {
        builder.ToTable("MedicationSchedules");
        builder.HasKey(schedule => schedule.Id);

        builder.Property(schedule => schedule.LabelInstruction).HasMaxLength(500);
        builder.Property(schedule => schedule.DoseAmountText).HasMaxLength(120);

        builder.HasOne(schedule => schedule.Medication)
            .WithMany()
            .HasForeignKey(schedule => schedule.MedicationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(schedule => new { schedule.UserId, schedule.IsActive });
    }
}

public sealed class DoseEventConfiguration : IEntityTypeConfiguration<DoseEvent>
{
    public void Configure(EntityTypeBuilder<DoseEvent> builder)
    {
        builder.ToTable("DoseEvents");
        builder.HasKey(dose => dose.Id);

        builder.Property(dose => dose.Status).HasConversion<string>().HasMaxLength(20).IsRequired();

        builder.HasOne(dose => dose.Medication)
            .WithMany()
            .HasForeignKey(dose => dose.MedicationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(dose => dose.Schedule)
            .WithMany()
            .HasForeignKey(dose => dose.ScheduleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(dose => new { dose.UserId, dose.ScheduledAt });
        builder.HasIndex(dose => new { dose.ScheduleId, dose.ScheduledAt }).IsUnique();
    }
}

public sealed class MedicationScanConfiguration : IEntityTypeConfiguration<MedicationScan>
{
    public void Configure(EntityTypeBuilder<MedicationScan> builder)
    {
        builder.ToTable("MedicationScans");
        builder.HasKey(scan => scan.Id);

        builder.Property(scan => scan.Status).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(scan => scan.ExtractionConfidence).HasPrecision(4, 2);
        builder.Property(scan => scan.ExtractionSource).HasMaxLength(60).IsRequired();
        builder.Property(scan => scan.FailureReason).HasMaxLength(300);
        builder.Property(scan => scan.RetainedImageReference).HasMaxLength(300);

        // Structured extraction output. Kept for the confirmation step only and never logged.
        builder.Property(scan => scan.ExtractionJson).IsRequired();

        builder.HasIndex(scan => new { scan.UserId, scan.CreatedAt });
    }
}
