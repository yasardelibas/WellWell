using MedGuard.Domain.Drugs;

namespace MedGuard.Application.Medications;

/// <summary>
/// Deterministic scoring of how well a provider result matches what was read from the label.
/// The score expresses match confidence only; it never expresses anything about safety.
/// </summary>
public static class MatchScoring
{
    public static double Score(
        DrugSearchRequest request,
        string? brandName,
        string? genericName,
        IEnumerable<string> ingredientNames)
    {
        var signals = new List<double>();

        var brandSignal = Similarity(request.BrandName, brandName);
        if (brandSignal is not null)
        {
            signals.Add(brandSignal.Value * 1.0);
        }

        var genericSignal = Similarity(request.GenericName, genericName);
        if (genericSignal is not null)
        {
            signals.Add(genericSignal.Value * 0.9);
        }

        var requestedIngredients = request.IngredientNames.Select(Tokenize).ToList();
        var resultIngredients = ingredientNames.Select(Tokenize).ToList();

        if (requestedIngredients.Count > 0 && resultIngredients.Count > 0)
        {
            var matched = requestedIngredients.Count(requested =>
                resultIngredients.Any(result => Jaccard(requested, result) >= 0.6));

            signals.Add((double)matched / requestedIngredients.Count);
        }

        if (signals.Count == 0)
        {
            return 0d;
        }

        // The strongest single signal drives the score, with a small bonus for corroboration.
        var best = signals.Max();
        var corroboration = signals.Count > 1 ? signals.OrderByDescending(s => s).Skip(1).Average() * 0.15 : 0d;

        return Math.Round(Math.Min(1d, best * 0.9 + corroboration), 3);
    }

    private static double? Similarity(string? left, string? right)
    {
        if (string.IsNullOrWhiteSpace(left) || string.IsNullOrWhiteSpace(right))
        {
            return null;
        }

        return Jaccard(Tokenize(left), Tokenize(right));
    }

    private static HashSet<string> Tokenize(string value) =>
        value
            .ToLowerInvariant()
            .Split(new[] { ' ', '-', '/', ',', '.', '(', ')', '\t' }, StringSplitOptions.RemoveEmptyEntries)
            .Where(token => token.Length > 1)
            .ToHashSet(StringComparer.Ordinal);

    private static double Jaccard(HashSet<string> left, HashSet<string> right)
    {
        if (left.Count == 0 || right.Count == 0)
        {
            return 0d;
        }

        var intersection = left.Intersect(right, StringComparer.Ordinal).Count();
        var union = left.Union(right, StringComparer.Ordinal).Count();

        return union == 0 ? 0d : (double)intersection / union;
    }
}
