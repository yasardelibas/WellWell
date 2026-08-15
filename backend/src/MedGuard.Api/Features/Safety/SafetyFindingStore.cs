using MedGuard.Application.Abstractions;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Safety;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Api.Features.Safety;

/// <summary>
/// Persists engine output. Findings are matched on a stable deduplication key so a repeated
/// analysis keeps the same finding id, which means an explanation stays linked to the same
/// warning across sessions.
/// </summary>
public sealed class SafetyFindingStore
{
    private readonly MedGuardDbContext _dbContext;
    private readonly IDateTimeProvider _clock;

    public SafetyFindingStore(MedGuardDbContext dbContext, IDateTimeProvider clock)
    {
        _dbContext = dbContext;
        _clock = clock;
    }

    public async Task<SafetyAnalysisResult> SyncAsync(
        Guid userId,
        SafetyAnalysisResult result,
        Guid? scopeMedicationId,
        CancellationToken cancellationToken)
    {
        var existing = await _dbContext.SafetyFindings
            .Include(finding => finding.Subjects)
            .Where(finding => finding.UserId == userId && finding.ResolvedAt == null)
            .ToListAsync(cancellationToken);

        var existingByKey = existing
            .GroupBy(finding => finding.DeduplicationKey)
            .ToDictionary(group => group.Key, group => group.First());

        var persisted = new List<SafetyFinding>();
        var seenKeys = new HashSet<string>(StringComparer.Ordinal);

        foreach (var finding in result.Findings)
        {
            var key = finding.DeduplicationKey;
            seenKeys.Add(key);

            if (existingByKey.TryGetValue(key, out var stored))
            {
                persisted.Add(stored);
                continue;
            }

            _dbContext.SafetyFindings.Add(finding);
            persisted.Add(finding);
        }

        // Only retire findings that this analysis actually covered.
        foreach (var stale in existing.Where(finding => !seenKeys.Contains(finding.DeduplicationKey)))
        {
            var inScope = scopeMedicationId is null ||
                          stale.Subjects.Any(subject => subject.MedicationId == scopeMedicationId.Value);

            if (inScope)
            {
                stale.Resolve(_clock.UtcNow);
            }
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return result with { Findings = persisted };
    }

    public async Task<IReadOnlyList<SafetyFinding>> GetOpenFindingsAsync(Guid userId, CancellationToken cancellationToken) =>
        await _dbContext.SafetyFindings
            .Include(finding => finding.Subjects)
            .Where(finding => finding.UserId == userId && finding.ResolvedAt == null)
            .OrderByDescending(finding => finding.Severity)
            .ThenByDescending(finding => finding.DetectedAt)
            .ToListAsync(cancellationToken);
}
