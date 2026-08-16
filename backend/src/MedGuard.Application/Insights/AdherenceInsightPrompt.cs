using System.Text.Json;
using System.Text.Json.Serialization;

namespace MedGuard.Application.Insights;

/// <summary>
/// Builds the payload sent to the insight model. The model only ever receives anonymous
/// adherence counts — never medication names, dates or any personal data.
/// </summary>
public static class AdherenceInsightPrompt
{
    public const string SystemPrompt = """
        You are the encouragement layer of WellWell, a medication reminder application.

        You receive only anonymous adherence counts (doses taken, skipped, missed and pending).

        Your job is to rephrase them into ONE short, warm, encouraging sentence (at most 30 words).

        Never:
        - give medical advice
        - mention or guess any specific medication
        - suggest changing, stopping, increasing or decreasing a dose
        - diagnose anything
        - shame or blame the user for skipped or missed doses
        - invent numbers that are not in the input

        Stay positive, gentle and non-judgemental. Reply with a single plain sentence, no lists or headings.

        The input includes a "respondInLanguage" field. Write your sentence in that language.
        """;

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false,
    };

    private static string LanguageName(string? language) =>
        string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase) ? "Turkish" : "English";

    public static string BuildWeeklyMessage(AdherenceStats stats, string? language = null) =>
        JsonSerializer.Serialize(
            new
            {
                window = "last 7 days",
                taken = stats.TakenCount,
                skipped = stats.SkippedCount,
                missed = stats.MissedCount,
                pending = stats.PendingCount,
                adherencePercent = stats.AdherencePercent,
                respondInLanguage = LanguageName(language),
            },
            SerializerOptions);

    public static string BuildDailyMessage(DailyAdherenceStats stats, string? language = null) =>
        JsonSerializer.Serialize(
            new
            {
                window = "today",
                completed = stats.CompletedCount,
                remaining = stats.RemainingCount,
                total = stats.TotalCount,
                respondInLanguage = LanguageName(language),
            },
            SerializerOptions);

    public static string BuildInsightsMessage(AdherenceInsightsInput input, string? language = null) =>
        JsonSerializer.Serialize(
            new
            {
                window = "last 30 days",
                adherencePercent = input.AdherencePercent,
                onTimeStreakDays = input.StreakDays,
                weakestTimeOfDay = input.WeakestTimeOfDay,
                respondInLanguage = LanguageName(language),
            },
            SerializerOptions);
}
