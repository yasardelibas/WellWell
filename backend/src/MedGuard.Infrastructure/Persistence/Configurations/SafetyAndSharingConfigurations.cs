using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MedGuard.Infrastructure.Persistence.Configurations;

public sealed class SafetyFindingConfiguration : IEntityTypeConfiguration<SafetyFinding>
{
    public void Configure(EntityTypeBuilder<SafetyFinding> builder)
    {
        builder.ToTable("SafetyFindings");
        builder.HasKey(finding => finding.Id);

        builder.Property(finding => finding.Type).HasConversion<string>().HasMaxLength(60).IsRequired();
        builder.Property(finding => finding.Severity).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(finding => finding.Title).HasMaxLength(200).IsRequired();
        builder.Property(finding => finding.IngredientNormalizedName).HasMaxLength(200);
        builder.Property(finding => finding.IngredientDisplayName).HasMaxLength(200);
        builder.Property(finding => finding.IngredientRxCui).HasMaxLength(32);
        builder.Property(finding => finding.Source).HasMaxLength(200).IsRequired();
        builder.Property(finding => finding.DatasetVersion).HasMaxLength(60);

        builder.Ignore(finding => finding.Provenance);
        builder.Ignore(finding => finding.DeduplicationKey);

        builder.Metadata
            .FindNavigation(nameof(SafetyFinding.Subjects))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);

        builder.HasMany(finding => finding.Subjects)
            .WithOne()
            .HasForeignKey(subject => subject.SafetyFindingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(finding => new { finding.UserId, finding.ResolvedAt });
    }
}

public sealed class SafetyFindingSubjectConfiguration : IEntityTypeConfiguration<SafetyFindingSubject>
{
    public void Configure(EntityTypeBuilder<SafetyFindingSubject> builder)
    {
        builder.ToTable("SafetyFindingSubjects");
        builder.HasKey(subject => subject.Id);

        builder.Property(subject => subject.MedicationName).HasMaxLength(200).IsRequired();
        builder.Property(subject => subject.IngredientOriginalName).HasMaxLength(200);
        builder.Property(subject => subject.StrengthText).HasMaxLength(80);
    }
}

public sealed class CaregiverConfiguration : IEntityTypeConfiguration<CaregiverRelationship>
{
    public void Configure(EntityTypeBuilder<CaregiverRelationship> builder)
    {
        builder.ToTable("CaregiverRelationships");
        builder.HasKey(relationship => relationship.Id);

        builder.Property(relationship => relationship.CaregiverEmail).HasMaxLength(320).IsRequired();
        builder.Property(relationship => relationship.CaregiverDisplayName).HasMaxLength(120);
        builder.Property(relationship => relationship.InvitationTokenHash).HasMaxLength(128).IsRequired();
        builder.Property(relationship => relationship.Status).HasConversion<string>().HasMaxLength(20).IsRequired();

        builder.Metadata
            .FindNavigation(nameof(CaregiverRelationship.Permissions))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);

        builder.HasMany(relationship => relationship.Permissions)
            .WithOne()
            .HasForeignKey(permission => permission.CaregiverRelationshipId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(relationship => relationship.InvitationTokenHash);
        builder.HasIndex(relationship => new { relationship.OwnerUserId, relationship.Status });
    }
}

public sealed class CaregiverPermissionConfiguration : IEntityTypeConfiguration<CaregiverPermissionGrant>
{
    public void Configure(EntityTypeBuilder<CaregiverPermissionGrant> builder)
    {
        builder.ToTable("CaregiverPermissions");
        builder.HasKey(permission => permission.Id);
        builder.Property(permission => permission.Permission).HasConversion<string>().HasMaxLength(60).IsRequired();
    }
}

public sealed class EmergencyCardConfiguration : IEntityTypeConfiguration<EmergencyCard>
{
    private readonly IFieldEncryptor _fieldEncryptor;

    public EmergencyCardConfiguration(IFieldEncryptor fieldEncryptor) => _fieldEncryptor = fieldEncryptor;

    public void Configure(EntityTypeBuilder<EmergencyCard> builder)
    {
        builder.ToTable("EmergencyCards");
        builder.HasKey(card => card.Id);

        builder.Property(card => card.TokenHash).HasMaxLength(128).IsRequired();
        builder.HasIndex(card => card.TokenHash).IsUnique();
        builder.HasIndex(card => card.UserId).IsUnique();

        // Everything printable on the card, plus the share token itself, is encrypted at rest.
        Encrypt(builder.Property(card => card.Token));
        Encrypt(builder.Property(card => card.DisplayName));
        Encrypt(builder.Property(card => card.Allergies));
        Encrypt(builder.Property(card => card.EmergencyContactName));
        Encrypt(builder.Property(card => card.EmergencyContactPhone));
        Encrypt(builder.Property(card => card.Notes));

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(card => card.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    private void Encrypt(PropertyBuilder<string?> property) =>
        property
            .HasMaxLength(2000)
            .HasConversion(
                value => _fieldEncryptor.Encrypt(value),
                value => _fieldEncryptor.Decrypt(value));
}

public sealed class EmergencyCardAccessLogConfiguration : IEntityTypeConfiguration<EmergencyCardAccessLog>
{
    public void Configure(EntityTypeBuilder<EmergencyCardAccessLog> builder)
    {
        builder.ToTable("EmergencyCardAccessLogs");
        builder.HasKey(log => log.Id);

        builder.Property(log => log.Outcome).HasMaxLength(60).IsRequired();
        builder.Property(log => log.ClientFingerprint).HasMaxLength(64);

        builder.HasIndex(log => new { log.EmergencyCardId, log.AccessedAt });
    }
}
