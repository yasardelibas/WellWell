using MedGuard.Domain.ValueObjects;

namespace MedGuard.Application.Abstractions;

public interface IIngredientNormalizer
{
    /// <summary>Canonical, comparable form of a raw ingredient name read from a label.</summary>
    string Normalize(string rawName);

    /// <summary>Human-friendly display form of a normalized ingredient name.</summary>
    string ToDisplayName(string normalizedName);

    ActiveIngredient Normalize(string rawName, decimal? strength, string? unit, string? rxCui);
}
