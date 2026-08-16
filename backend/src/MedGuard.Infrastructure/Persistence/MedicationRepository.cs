using MedGuard.Application.Abstractions;
using MedGuard.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MedGuard.Infrastructure.Persistence;

public sealed class MedicationRepository : IMedicationRepository
{
    private readonly MedGuardDbContext _dbContext;

    public MedicationRepository(MedGuardDbContext dbContext) => _dbContext = dbContext;

    public async Task<IReadOnlyCollection<Medication>> GetActiveForUserAsync(Guid userId, CancellationToken cancellationToken) =>
        await _dbContext.Medications
            .Include(medication => medication.Ingredients)
            .Where(medication => medication.UserId == userId && !medication.IsArchived)
            .OrderBy(medication => medication.CreatedAt)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

    public async Task<Medication?> GetByIdAsync(Guid userId, Guid medicationId, CancellationToken cancellationToken) =>
        await _dbContext.Medications
            .Include(medication => medication.Ingredients)
            .FirstOrDefaultAsync(
                medication => medication.Id == medicationId && medication.UserId == userId,
                cancellationToken)
            .ConfigureAwait(false);
}
