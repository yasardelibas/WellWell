using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace MedGuard.Application.Telemetry;

/// <summary>
/// Telemetry primitives. Counters are tagged with outcomes only, never with medication
/// names, ingredients or any label content.
/// </summary>
public static class MedGuardTelemetry
{
    public const string ActivitySourceName = "MedGuard";
    public const string MeterName = "MedGuard";

    public static readonly ActivitySource ActivitySource = new(ActivitySourceName);

    private static readonly Meter Meter = new(MeterName);

    public static readonly Counter<long> ScansProcessed =
        Meter.CreateCounter<long>("medguard.scans.processed", description: "Label scans processed, tagged by outcome.");

    public static readonly Counter<long> DrugProviderCalls =
        Meter.CreateCounter<long>("medguard.drug_provider.calls", description: "External drug data provider calls, tagged by provider and outcome.");

    public static readonly Counter<long> SafetyAnalyses =
        Meter.CreateCounter<long>("medguard.safety.analyses", description: "Safety analyses performed, tagged by resulting status.");

    public static readonly Counter<long> SafetyFindings =
        Meter.CreateCounter<long>("medguard.safety.findings", description: "Safety findings produced, tagged by finding type.");

    public static readonly Counter<long> ExplanationRequests =
        Meter.CreateCounter<long>("medguard.explanations", description: "Explanation requests, tagged by source (ai or fallback).");

    public static readonly Histogram<double> DrugProviderLatency =
        Meter.CreateHistogram<double>("medguard.drug_provider.latency", unit: "ms", description: "External drug provider latency.");
}
