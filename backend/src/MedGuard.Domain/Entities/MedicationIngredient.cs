using MedGuard.Domain.ValueObjects;

namespace MedGuard.Domain.Entities;

public sealed class MedicationIngredient
{
    private MedicationIngredient()
    {
        NormalizedName = string.Empty;
        OriginalName = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid MedicationId { get; private set; }

    /// <summary>Canonical name used for comparisons.</summary>
    public string NormalizedName { get; private set; }

    /// <summary>Exactly what the label said, preserved for transparency.</summary>
    public string OriginalName { get; private set; }

    public decimal? Strength { get; private set; }

    public string? Unit { get; private set; }

    public string? RxCui { get; private set; }

    public static MedicationIngredient FromValue(ActiveIngredient ingredient) =>
        new()
        {
            Id = Guid.NewGuid(),
            NormalizedName = ingredient.NormalizedName,
            OriginalName = ingredient.OriginalName,
            Strength = ingredient.Strength,
            Unit = ingredient.Unit,
            RxCui = ingredient.RxCui
        };

    public ActiveIngredient ToValue() => new(NormalizedName, OriginalName, Strength, Unit, RxCui);

    public string ComparisonKey => ToValue().ComparisonKey;

    public string DisplayStrength =>
        Strength is null ? string.Empty : $"{Strength.Value.ToString("0.##", System.Globalization.CultureInfo.InvariantCulture)} {Unit}".Trim();
}
