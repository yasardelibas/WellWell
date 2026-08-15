namespace MedGuard.Application.Insights;

/// <summary>
/// Deterministic insight text used when no model is configured, when the model is
/// unreachable, or when generated text fails the output guard. The tone is intentionally
/// encouraging and never shaming: counts describe what happened, not how "good" the user is.
/// </summary>
public sealed class TemplateAdherenceInsightService : IAdherenceInsightService
{
    public const string SourceName = "medguard-template";

    public Task<AdherenceInsight> SummarizeWeekAsync(AdherenceStats stats, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return Task.FromResult(new AdherenceInsight(BuildWeekly(stats), GeneratedByAi: false, SourceName));
    }

    public Task<AdherenceInsight> DailyNudgeAsync(DailyAdherenceStats stats, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return Task.FromResult(new AdherenceInsight(BuildDaily(stats), GeneratedByAi: false, SourceName));
    }

    public Task<AdherenceInsight> SummarizeInsightsAsync(AdherenceInsightsInput input, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        return Task.FromResult(new AdherenceInsight(BuildInsights(input), GeneratedByAi: false, SourceName));
    }

    public static string BuildInsights(AdherenceInsightsInput input)
    {
        var parts = new List<string>();

        parts.Add(input.StreakDays switch
        {
            0 => "You're just getting started — logging today's doses begins a new streak.",
            1 => "You're on a 1-day on-time streak. Nice start!",
            >= 14 => $"Amazing — you're on a {input.StreakDays}-day on-time streak!",
            >= 7 => $"You're on a {input.StreakDays}-day on-time streak. Great consistency!",
            _ => $"You're on a {input.StreakDays}-day on-time streak. Keep it going!",
        });

        parts.Add($"Over the last 30 days you've taken {input.AdherencePercent}% of your resolved doses on record.");

        if (!string.IsNullOrWhiteSpace(input.WeakestTimeOfDay))
        {
            parts.Add($"Your {input.WeakestTimeOfDay} doses are the easiest to forget — a reminder around then may help.");
        }

        return string.Join(" ", parts);
    }

    public static string BuildWeekly(AdherenceStats stats)
    {
        if (stats.TotalCount == 0)
        {
            return "No doses were scheduled in the last 7 days. When you add reminders, your weekly summary will appear here.";
        }

        var encouragement = stats.ResolvedCount == 0
            ? "Your scheduled doses are still coming up this week."
            : stats.AdherencePercent switch
            {
                >= 90 => "That's a really consistent week — keep it up.",
                >= 70 => "You're keeping a steady routine going.",
                >= 40 => "Every dose you log helps you see your own pattern.",
                _ => "Small steps count, and logging each dose helps you stay on track.",
            };

        var body = stats.ResolvedCount == 0
            ? $"You have {stats.TotalCount} scheduled dose{Plural(stats.TotalCount)} coming up in the last 7 days."
            : $"Over the last 7 days you took {stats.TakenCount} of {stats.ResolvedCount} scheduled dose{Plural(stats.ResolvedCount)} ({stats.AdherencePercent}%).";

        var tail = stats.PendingCount > 0 && stats.ResolvedCount > 0
            ? $" {stats.PendingCount} more {(stats.PendingCount == 1 ? "is" : "are")} still upcoming."
            : string.Empty;

        return $"{body} {encouragement}{tail}";
    }

    public static string BuildDaily(DailyAdherenceStats stats)
    {
        if (stats.TotalCount == 0)
        {
            return "You have no doses scheduled today.";
        }

        if (stats.CompletedCount >= stats.TotalCount)
        {
            return $"All {stats.TotalCount} of today's dose{Plural(stats.TotalCount)} are done — nice work staying on track!";
        }

        if (stats.CompletedCount == 0)
        {
            return $"You have {stats.TotalCount} dose{Plural(stats.TotalCount)} scheduled today. You've got this.";
        }

        return $"You've taken {stats.CompletedCount} of {stats.TotalCount} doses today — {stats.RemainingCount} to go. Keep it up!";
    }

    private static string Plural(int count) => count == 1 ? string.Empty : "s";
}
