namespace MedGuard.Application.Abstractions;

/// <summary>
/// Deterministic, authoritative drug classification resolved from RxClass (NLM RxNav).
/// <see cref="UsedFor"/> holds the conditions a drug "may treat" (MED-RT), and
/// <see cref="PharmacologicClass"/> a therapeutic/ATC class name. These are facts from a
/// trusted source — never AI guesses — used to ground and enrich medication education.
/// </summary>
public sealed record DrugClassification(
    IReadOnlyList<string> UsedFor,
    string? PharmacologicClass)
{
    public bool HasContent => UsedFor.Count > 0 || !string.IsNullOrWhiteSpace(PharmacologicClass);

    public static DrugClassification Empty { get; } = new(Array.Empty<string>(), null);
}

/// <summary>
/// Looks up a drug's classification by RxCUI. Like the other external providers, transport or
/// parsing failures must never throw; they return <see cref="DrugClassification.Empty"/> (or null)
/// so a lookup failure can never be mistaken for authoritative "no uses".
/// </summary>
public interface IDrugClassificationProvider
{
    Task<DrugClassification> GetByRxCuiAsync(string rxCui, CancellationToken cancellationToken);
}
