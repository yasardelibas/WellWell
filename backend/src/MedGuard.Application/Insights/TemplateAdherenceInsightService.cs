namespace MedGuard.Application.Insights;

/// <summary>
/// Deterministic insight text used when no model is configured, when the model is
/// unreachable, or when generated text fails the output guard. The tone is intentionally
/// encouraging and never shaming: counts describe what happened, not how "good" the user is.
/// </summary>
public sealed class TemplateAdherenceInsightService : IAdherenceInsightService
{
    public const string SourceName = "medguard-template";

    public Task<AdherenceInsight> SummarizeWeekAsync(AdherenceStats stats, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return Task.FromResult(new AdherenceInsight(BuildWeekly(stats, language), GeneratedByAi: false, SourceName));
    }

    public Task<AdherenceInsight> DailyNudgeAsync(DailyAdherenceStats stats, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(stats);
        return Task.FromResult(new AdherenceInsight(BuildDaily(stats, language), GeneratedByAi: false, SourceName));
    }

    public Task<AdherenceInsight> SummarizeInsightsAsync(AdherenceInsightsInput input, string? language, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        return Task.FromResult(new AdherenceInsight(BuildInsights(input, language), GeneratedByAi: false, SourceName));
    }

    public static string BuildInsights(AdherenceInsightsInput input, string? language = null)
    {
        var tr = IsTurkish(language);
        var parts = new List<string>();

        if (tr)
        {
            parts.Add(input.StreakDays switch
            {
                0 => "Yeni başlıyorsun — bugünün dozlarını kaydetmek yeni bir seriye başlar.",
                1 => "1 günlük zamanında seri yakaladın. Güzel bir başlangıç!",
                >= 14 => $"Harika — {input.StreakDays} günlük zamanında serideysin!",
                >= 7 => $"{input.StreakDays} günlük zamanında seridesin. Çok tutarlısın!",
                _ => $"{input.StreakDays} günlük zamanında seridesin. Böyle devam et!",
            });
            parts.Add($"Son 30 günde kayıtlı dozlarının %{input.AdherencePercent}'ini aldın.");
            if (!string.IsNullOrWhiteSpace(input.WeakestTimeOfDay))
            {
                parts.Add($"{input.WeakestTimeOfDay} dozlarını unutman daha kolay oluyor — o saatlerde bir hatırlatma yardımcı olabilir.");
            }
        }
        else
        {
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
        }

        return string.Join(" ", parts);
    }

    public static string BuildWeekly(AdherenceStats stats, string? language = null)
    {
        var tr = IsTurkish(language);

        if (stats.TotalCount == 0)
        {
            return tr
                ? "Son 7 günde planlanmış doz yoktu. Hatırlatma eklediğinde haftalık özetin burada görünecek."
                : "No doses were scheduled in the last 7 days. When you add reminders, your weekly summary will appear here.";
        }

        if (tr)
        {
            var encouragementTr = stats.ResolvedCount == 0
                ? "Planlanmış dozların bu hafta henüz gelmedi."
                : stats.AdherencePercent switch
                {
                    >= 90 => "Bu gerçekten tutarlı bir hafta — böyle devam et.",
                    >= 70 => "İstikrarlı bir rutin sürdürüyorsun.",
                    >= 40 => "Kaydettiğin her doz kendi düzenini görmene yardımcı oluyor.",
                    _ => "Küçük adımlar önemli, her dozu kaydetmek yolunda kalmana yardımcı olur.",
                };

            var bodyTr = stats.ResolvedCount == 0
                ? $"Son 7 günde {stats.TotalCount} planlanmış dozun var."
                : $"Son 7 günde {stats.ResolvedCount} planlanmış dozdan {stats.TakenCount} tanesini aldın (%{stats.AdherencePercent}).";

            var tailTr = stats.PendingCount > 0 && stats.ResolvedCount > 0
                ? $" {stats.PendingCount} tanesi daha bekleniyor."
                : string.Empty;

            return $"{bodyTr} {encouragementTr}{tailTr}";
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

    public static string BuildDaily(DailyAdherenceStats stats, string? language = null)
    {
        var tr = IsTurkish(language);

        if (stats.TotalCount == 0)
        {
            return tr ? "Bugün için planlanmış dozun yok." : "You have no doses scheduled today.";
        }

        if (stats.CompletedCount >= stats.TotalCount)
        {
            return tr
                ? $"Bugünün {stats.TotalCount} dozunun tamamı bitti — harika iş!"
                : $"All {stats.TotalCount} of today's dose{Plural(stats.TotalCount)} are done — nice work staying on track!";
        }

        if (stats.CompletedCount == 0)
        {
            return tr
                ? $"Bugün için {stats.TotalCount} doz planlandı. Başarabilirsin."
                : $"You have {stats.TotalCount} dose{Plural(stats.TotalCount)} scheduled today. You've got this.";
        }

        return tr
            ? $"Bugün {stats.TotalCount} dozdan {stats.CompletedCount} tanesini aldın — {stats.RemainingCount} tane kaldı. Böyle devam et!"
            : $"You've taken {stats.CompletedCount} of {stats.TotalCount} doses today — {stats.RemainingCount} to go. Keep it up!";
    }

    private static bool IsTurkish(string? language) => string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);

    private static string Plural(int count) => count == 1 ? string.Empty : "s";
}
