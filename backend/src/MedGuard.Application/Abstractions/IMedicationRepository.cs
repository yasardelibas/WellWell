using MedGuard.Domain.Entities;

namespace MedGuard.Application.Abstractions;

/// <summary>
/// Read access used by the safety engine. Kept narrow so the engine stays unit-testable
/// without a database.
/// </summary>
public interface IMedicationRepository
{
    Task<IReadOnlyCollection<Medication>> GetActiveForUserAsync(Guid userId, CancellationToken cancellationToken);

    Task<Medication?> GetByIdAsync(Guid userId, Guid medicationId, CancellationToken cancellationToken);
}
