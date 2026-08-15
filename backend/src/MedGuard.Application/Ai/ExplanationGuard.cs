using System.Text.RegularExpressions;

namespace MedGuard.Application.Ai;

public sealed record GuardResult(bool IsAllowed, string? ViolatedRule);

/// <summary>
/// Output guardrail for the explanation layer. Any generated text that drifts into
/// clinical advice is rejected and the deterministic fallback is used instead, so a model
/// failure can never turn into medical instruction.
/// </summary>
public static class ExplanationGuard
{
    private static readonly (string Rule, Regex Pattern)[] ForbiddenPatterns =
    {
        ("recommends stopping medication", new Regex(@"\b(stop|quit|discontinue|cease)\s+(taking|using|the|your|this|that|one)\b", Options)),
        ("changes a dose", new Regex(@"\b(increas|decreas|reduc|lower|rais|doubl|halv|adjust)(e|es|ed|ing)?\s+(the\s+|your\s+)?(dose|dosage|amount|strength)\b", Options)),
        ("prescribes or substitutes", new Regex(@"\b(you should take|switch to|replace .* with|instead of taking|i recommend taking|take \d)\b", Options)),
        ("claims safety", new Regex(@"\b(safe to (take|combine)|are safe together|is safe together|no risk|perfectly fine|harmless)\b", Options)),
        // "you have" on its own is ordinary phrasing ("you have two products containing
        // acetaminophen"), so only diagnostic constructions are rejected.
        ("diagnoses", new Regex(
            @"\b(you (likely|probably|may|might|could|must) have" +
            @"|you are suffering from" +
            @"|this (means|suggests|indicates)( that)? you" +
            @"|you have (a|an)[\w\s]{0,20}?(condition|disease|disorder|infection|syndrome|deficiency|illness)" +
            @"|diagnos(is|e|ed|ing))\b",
            Options)),
        ("dismisses the finding", new Regex(@"\b(ignore (this|the) (warning|finding)|nothing to worry about|no need to worry|disregard)\b", Options)),
        ("states a maximum daily dose", new Regex(@"\b\d+\s*(mg|milligrams|g|grams)\s*(per|a|each)\s*day\b", Options))
    };

    private const RegexOptions Options = RegexOptions.Compiled | RegexOptions.IgnoreCase;

    public static GuardResult Inspect(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return new GuardResult(false, "empty response");
        }

        foreach (var (rule, pattern) in ForbiddenPatterns)
        {
            if (pattern.IsMatch(text))
            {
                return new GuardResult(false, rule);
            }
        }

        return new GuardResult(true, null);
    }
}
