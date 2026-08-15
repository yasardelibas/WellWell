using MedGuard.Domain.Enums;
using MedGuard.Domain.ValueObjects;

namespace MedGuard.Domain.Entities;

/// <summary>
/// A persisted safety finding. Domain Rule 2: findings are only ever produced by the
/// deterministic safety engine, never by a language model.
/// </summary>
public sealed class SafetyFinding
{
    private readonly List<SafetyFindingSubject> _subjects = new();

    private SafetyFinding()
    {
        Title = string.Empty;
        Source = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public SafetyFindingType Type { get; private set; }

    public SafetySeverity Severity { get; private set; }

    public string Title { get; private set; }

    public string? IngredientNormalizedName { get; private set; }

    public string? IngredientDisplayName { get; private set; }

    public string? IngredientRxCui { get; private set; }

    /// <summary>True when every medication involved carries trusted provider provenance.</summary>
    public bool SourceVerified { get; private set; }

    public string Source { get; private set; }

    public string? DatasetVersion { get; private set; }

    public DateTimeOffset DetectedAt { get; private set; }

    public DateTimeOffset? ResolvedAt { get; private set; }

    public IReadOnlyCollection<SafetyFindingSubject> Subjects => _subjects.AsReadOnly();

    public DataProvenance Provenance => new(Source, IngredientRxCui, DetectedAt, DatasetVersion);

    public static SafetyFinding Create(
        Guid userId,
        SafetyFindingType type,
        SafetySeverity severity,
        string title,
        string source,
        bool sourceVerified,
        DateTimeOffset detectedAt,
        string? ingredientNormalizedName = null,
        string? ingredientDisplayName = null,
        string? ingredientRxCui = null,
        string? datasetVersion = null,
        IEnumerable<SafetyFindingSubject>? subjects = null)
    {
        var finding = new SafetyFinding
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = type,
            Severity = severity,
            Title = title,
            Source = source,
            SourceVerified = sourceVerified,
            DetectedAt = detectedAt,
            IngredientNormalizedName = ingredientNormalizedName,
            IngredientDisplayName = ingredientDisplayName,
            IngredientRxCui = ingredientRxCui,
            DatasetVersion = datasetVersion
        };

        if (subjects is not null)
        {
            finding._subjects.AddRange(subjects);
        }

        return finding;
    }

    public void Resolve(DateTimeOffset now) => ResolvedAt = now;

    /// <summary>
    /// Stable identity for a finding so repeated analyses update instead of duplicating rows.
    /// </summary>
    public string DeduplicationKey =>
        string.Join('|',
            Type.ToString(),
            IngredientNormalizedName ?? IngredientRxCui ?? "-",
            string.Join(',', _subjects.Select(s => s.MedicationId.ToString()).OrderBy(s => s, StringComparer.Ordinal)));
}

public sealed class SafetyFindingSubject
{
    private SafetyFindingSubject()
    {
        MedicationName = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid SafetyFindingId { get; private set; }

    public Guid MedicationId { get; private set; }

    public string MedicationName { get; private set; }

    public string? IngredientOriginalName { get; private set; }

    public string? StrengthText { get; private set; }

    public bool MedicationVerified { get; private set; }

    public static SafetyFindingSubject Create(
        Guid medicationId,
        string medicationName,
        string? ingredientOriginalName,
        string? strengthText,
        bool medicationVerified) =>
        new()
        {
            Id = Guid.NewGuid(),
            MedicationId = medicationId,
            MedicationName = medicationName,
            IngredientOriginalName = ingredientOriginalName,
            StrengthText = strengthText,
            MedicationVerified = medicationVerified
        };
}
