using System.Text.RegularExpressions;

namespace MedGuard.Application.Schedules;

/// <summary>
/// Suggested reminder times derived from label wording. These are a convenience only:
/// MedGuard never claims the times are medically optimal and nothing is scheduled
/// until the user confirms.
/// </summary>
public sealed record ScheduleSuggestion(
    string? LabelInstruction,
    int TimesPerDay,
    IReadOnlyList<TimeOnly> SuggestedTimes,
    string? DoseAmountText)
{
    public static ScheduleSuggestion None(string? instruction) =>
        new(instruction, 0, Array.Empty<TimeOnly>(), null);
}

/// <summary>
/// Deterministic reading of common dosing phrases. Anything unrecognised produces no
/// suggestion rather than a guess.
/// </summary>
public static class LabelDirectionsParser
{
    private static readonly Regex EveryNHoursPattern = new(
        @"every\s+(\d{1,2})\s*(?:hours|hrs|h)\b",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly Regex TimesPerDayPattern = new(
        @"(\d{1,2}|once|twice|thrice|one|two|three|four)\s*(?:x|times?)?\s*(?:per|a|each)?\s*(?:day|daily)",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly Regex DoseAmountPattern = new(
        @"\b(\d+(?:[.,]\d+)?|one|two|three|half)\s+(tablet|tablets|capsule|capsules|pill|pills|ml|millilitres|milliliters|drop|drops|puff|puffs|sachet|sachets|spray|sprays)\b",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    private static readonly IReadOnlyDictionary<int, TimeOnly[]> DefaultTimes = new Dictionary<int, TimeOnly[]>
    {
        [1] = new[] { new TimeOnly(9, 0) },
        [2] = new[] { new TimeOnly(8, 0), new TimeOnly(20, 0) },
        [3] = new[] { new TimeOnly(8, 0), new TimeOnly(14, 0), new TimeOnly(20, 0) },
        [4] = new[] { new TimeOnly(8, 0), new TimeOnly(13, 0), new TimeOnly(18, 0), new TimeOnly(22, 0) },
        [6] = new[]
        {
            new TimeOnly(6, 0), new TimeOnly(10, 0), new TimeOnly(14, 0),
            new TimeOnly(18, 0), new TimeOnly(22, 0), new TimeOnly(2, 0)
        }
    };

    public static ScheduleSuggestion Parse(string? directions)
    {
        if (string.IsNullOrWhiteSpace(directions))
        {
            return ScheduleSuggestion.None(directions);
        }

        var text = directions.ToLowerInvariant();
        var doseAmount = ReadDoseAmount(directions);
        var timesPerDay = ReadTimesPerDay(text);

        if (timesPerDay is null or 0)
        {
            return new ScheduleSuggestion(directions.Trim(), 0, Array.Empty<TimeOnly>(), doseAmount);
        }

        if (IsBedtimeOnly(text))
        {
            return new ScheduleSuggestion(directions.Trim(), 1, new[] { new TimeOnly(22, 0) }, doseAmount);
        }

        var times = DefaultTimes.TryGetValue(timesPerDay.Value, out var defaults)
            ? defaults
            : SpreadAcrossWakingHours(timesPerDay.Value);

        return new ScheduleSuggestion(directions.Trim(), timesPerDay.Value, times, doseAmount);
    }

    private static int? ReadTimesPerDay(string text)
    {
        var everyN = EveryNHoursPattern.Match(text);
        if (everyN.Success && int.TryParse(everyN.Groups[1].Value, out var hours) && hours is > 0 and <= 24)
        {
            return Math.Clamp(24 / hours, 1, 6);
        }

        if (text.Contains("bedtime", StringComparison.Ordinal) ||
            text.Contains(" qhs", StringComparison.Ordinal) ||
            text.Contains("at night", StringComparison.Ordinal))
        {
            return 1;
        }

        foreach (var (abbreviation, count) in new[] { (" bid", 2), (" tid", 3), (" qid", 4), (" qd", 1) })
        {
            if (text.Contains(abbreviation, StringComparison.Ordinal))
            {
                return count;
            }
        }

        var match = TimesPerDayPattern.Match(text);
        if (!match.Success)
        {
            return null;
        }

        var token = match.Groups[1].Value;
        return token switch
        {
            "once" or "one" => 1,
            "twice" or "two" => 2,
            "thrice" or "three" => 3,
            "four" => 4,
            _ => int.TryParse(token, out var parsed) && parsed is > 0 and <= 6 ? parsed : null
        };
    }

    private static bool IsBedtimeOnly(string text) =>
        text.Contains("bedtime", StringComparison.Ordinal) || text.Contains(" qhs", StringComparison.Ordinal);

    private static TimeOnly[] SpreadAcrossWakingHours(int timesPerDay)
    {
        var start = new TimeOnly(8, 0);
        var window = TimeSpan.FromHours(14);
        var step = window / Math.Max(timesPerDay - 1, 1);

        return Enumerable
            .Range(0, timesPerDay)
            .Select(index => start.Add(step * index))
            .ToArray();
    }

    private static string? ReadDoseAmount(string directions)
    {
        var match = DoseAmountPattern.Match(directions);
        return match.Success ? match.Value.Trim() : null;
    }
}
