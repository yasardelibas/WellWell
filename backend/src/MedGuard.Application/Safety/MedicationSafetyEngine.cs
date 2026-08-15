using MedGuard.Application.Abstractions;
using MedGuard.Application.Telemetry;
using MedGuard.Domain.Drugs;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;
using MedGuard.Domain.Safety;
using Microsoft.Extensions.Logging;

namespace MedGuard.Application.Safety;

/// <summary>
/// Deterministic safety analysis. Given the same medications this engine always produces the
/// same findings, and it never calls a language model or invents a finding that the data
/// does not support.
/// </summary>
public sealed class MedicationSafetyEngine : IMedicationSafetyEngine
{
    private readonly IMedicationRepository _medications;
    private readonly IIngredientNormalizer _normalizer;
    private readonly IDrugInteractionProvider _interactionProvider;
    private readonly IDateTimeProvider _clock;
    private readonly ILogger<MedicationSafetyEngine> _logger;

    public MedicationSafetyEngine(
        IMedicationRepository medications,
        IIngredientNormalizer normalizer,
        IDrugInteractionProvider interactionProvider,
        IDateTimeProvider clock,
        ILogger<MedicationSafetyEngine> logger)
    {
        _medications = medications;
        _normalizer = normalizer;
        _interactionProvider = interactionProvider;
        _clock = clock;
        _logger = logger;
    }

    public async Task<SafetyAnalysisResult> AnalyzeAsync(
        Guid userId,
        Medication candidate,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(candidate);

        var saved = await _medications.GetActiveForUserAsync(userId, cancellationToken).ConfigureAwait(false);
        var scope = saved.Where(m => m.Id != candidate.Id).Append(candidate).ToList();

        return await AnalyzeScopeAsync(userId, scope, candidate.Id, cancellationToken).ConfigureAwait(false);
    }

    public async Task<SafetyAnalysisResult> AnalyzeUserAsync(Guid userId, CancellationToken cancellationToken)
    {
        var saved = await _medications.GetActiveForUserAsync(userId, cancellationToken).ConfigureAwait(false);
        return await AnalyzeScopeAsync(userId, saved.ToList(), focusMedicationId: null, cancellationToken).ConfigureAwait(false);
    }

    private async Task<SafetyAnalysisResult> AnalyzeScopeAsync(
        Guid userId,
        IReadOnlyList<Medication> medications,
        Guid? focusMedicationId,
        CancellationToken cancellationToken)
    {
        using var activity = MedGuardTelemetry.ActivitySource.StartActivity("safety.analyze");
        var now = _clock.UtcNow;

        var findings = new List<SafetyFinding>();
        var checks = new List<SafetyCheckOutcome>();

        var (duplicateFindings, duplicateOutcome) = RunDuplicateIngredientCheck(userId, medications, focusMedicationId, now);
        findings.AddRange(duplicateFindings);
        checks.Add(duplicateOutcome);

        var (verificationFinding, verificationOutcome) = RunVerificationCheck(userId, medications, focusMedicationId, now);
        if (verificationFinding is not null)
        {
            findings.Add(verificationFinding);
        }

        checks.Add(verificationOutcome);

        checks.Add(await RunInteractionCheckAsync(medications, cancellationToken).ConfigureAwait(false));

        var status = SafetyAnalysisResult.DeriveStatus(findings, checks);

        MedGuardTelemetry.SafetyAnalyses.Add(1, new KeyValuePair<string, object?>("status", status.ToString()));
        foreach (var finding in findings)
        {
            MedGuardTelemetry.SafetyFindings.Add(1, new KeyValuePair<string, object?>("type", finding.Type.ToString()));
        }

        _logger.LogInformation(
            "Safety analysis completed for user {UserId}: status={Status}, findings={FindingCount}, incompleteChecks={IncompleteChecks}",
            userId,
            status,
            findings.Count,
            checks.Count(c => c.State is SafetyCheckState.Unavailable or SafetyCheckState.NotConfigured));

        return new SafetyAnalysisResult(status, findings, checks, now);
    }

    /// <summary>
    /// Groups ingredient occurrences that share any canonical identifier and reports groups
    /// that span more than one medication.
    /// </summary>
    private (List<SafetyFinding> Findings, SafetyCheckOutcome Outcome) RunDuplicateIngredientCheck(
        Guid userId,
        IReadOnlyList<Medication> medications,
        Guid? focusMedicationId,
        DateTimeOffset now)
    {
        var occurrences = new List<IngredientOccurrence>();

        foreach (var medication in medications)
        {
            foreach (var ingredient in medication.Ingredients)
            {
                var normalizedName = string.IsNullOrWhiteSpace(ingredient.NormalizedName)
                    ? _normalizer.Normalize(ingredient.OriginalName)
                    : ingredient.NormalizedName;

                if (string.IsNullOrWhiteSpace(normalizedName) && string.IsNullOrWhiteSpace(ingredient.RxCui))
                {
                    continue;
                }

                occurrences.Add(new IngredientOccurrence(medication, ingredient, normalizedName));
            }
        }

        if (occurrences.Count == 0)
        {
            return (new List<SafetyFinding>(), new SafetyCheckOutcome(
                SafetyMessages.DuplicateCheckName,
                SafetyCheckState.Skipped,
                "No active ingredients are recorded yet, so no comparison was possible."));
        }

        var groups = GroupBySharedIdentifier(occurrences);
        var findings = new List<SafetyFinding>();

        foreach (var group in groups)
        {
            var distinctMedications = group
                .GroupBy(o => o.Medication.Id)
                .Select(g => g.First())
                .ToList();

            if (distinctMedications.Count < 2)
            {
                continue;
            }

            if (focusMedicationId.HasValue && distinctMedications.All(o => o.Medication.Id != focusMedicationId.Value))
            {
                continue;
            }

            var rxCui = group.Select(o => o.Ingredient.RxCui).FirstOrDefault(c => !string.IsNullOrWhiteSpace(c));
            var normalizedName = group.Select(o => o.NormalizedName).FirstOrDefault(n => !string.IsNullOrWhiteSpace(n)) ?? string.Empty;
            var allVerified = distinctMedications.All(o => o.Medication.VerificationStatus == MedicationVerificationStatus.Verified);

            var subjects = distinctMedications
                .OrderBy(o => o.Medication.CreatedAt)
                .Select(o => SafetyFindingSubject.Create(
                    o.Medication.Id,
                    o.Medication.DisplayName,
                    o.Ingredient.OriginalName,
                    o.Ingredient.DisplayStrength,
                    o.Medication.VerificationStatus == MedicationVerificationStatus.Verified))
                .ToList();

            findings.Add(SafetyFinding.Create(
                userId,
                SafetyFindingType.DuplicateActiveIngredient,
                SafetySeverity.Warning,
                SafetyMessages.DuplicateIngredientTitle,
                DescribeSource(distinctMedications.Select(o => o.Medication)),
                allVerified,
                now,
                ingredientNormalizedName: normalizedName,
                ingredientDisplayName: _normalizer.ToDisplayName(normalizedName),
                ingredientRxCui: rxCui,
                datasetVersion: distinctMedications
                    .Select(o => o.Medication.ProvenanceDatasetVersion)
                    .FirstOrDefault(v => !string.IsNullOrWhiteSpace(v)),
                subjects: subjects));
        }

        return (findings, new SafetyCheckOutcome(
            SafetyMessages.DuplicateCheckName,
            SafetyCheckState.Completed,
            $"Compared {occurrences.Count} active ingredient entries across {medications.Count} medications."));
    }

    private (SafetyFinding? Finding, SafetyCheckOutcome Outcome) RunVerificationCheck(
        Guid userId,
        IReadOnlyList<Medication> medications,
        Guid? focusMedicationId,
        DateTimeOffset now)
    {
        var scope = focusMedicationId.HasValue
            ? medications.Where(m => m.Id == focusMedicationId.Value).ToList()
            : medications.ToList();

        var unverified = scope
            .Where(m => m.VerificationStatus != MedicationVerificationStatus.Verified)
            .ToList();

        if (unverified.Count == 0)
        {
            return (null, new SafetyCheckOutcome(
                SafetyMessages.VerificationCheckName,
                SafetyCheckState.Completed,
                "Every medication in scope carries trusted provider provenance."));
        }

        var finding = SafetyFinding.Create(
            userId,
            SafetyFindingType.UnverifiedMedication,
            SafetySeverity.Info,
            SafetyMessages.UnverifiedTitle,
            "user-entered",
            sourceVerified: false,
            now,
            subjects: unverified.Select(m => SafetyFindingSubject.Create(
                m.Id,
                m.DisplayName,
                m.Ingredients.FirstOrDefault()?.OriginalName,
                m.Strength,
                medicationVerified: false)));

        var detail = unverified.Any(m => m.VerificationStatus == MedicationVerificationStatus.VerificationUnavailable)
            ? "A trusted medication database could not be reached for at least one medication."
            : "At least one medication has not been matched against a trusted medication database.";

        return (finding, new SafetyCheckOutcome(
            SafetyMessages.VerificationCheckName,
            SafetyCheckState.Completed,
            detail));
    }

    private async Task<SafetyCheckOutcome> RunInteractionCheckAsync(
        IReadOnlyList<Medication> medications,
        CancellationToken cancellationToken)
    {
        if (!_interactionProvider.IsConfigured)
        {
            return new SafetyCheckOutcome(
                SafetyMessages.InteractionCheckName,
                SafetyCheckState.NotConfigured,
                SafetyMessages.InteractionUnavailableBody);
        }

        var identifiers = medications
            .Select(m => m.RxCui)
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Select(id => id!)
            .Distinct()
            .ToList();

        if (identifiers.Count < 2)
        {
            return new SafetyCheckOutcome(
                SafetyMessages.InteractionCheckName,
                SafetyCheckState.Skipped,
                "Fewer than two medications carry a canonical identifier, so no interaction lookup was made.");
        }

        try
        {
            var result = await _interactionProvider
                .GetInteractionsAsync(identifiers, cancellationToken)
                .ConfigureAwait(false);

            return result.Status switch
            {
                DrugLookupStatus.Unavailable => new SafetyCheckOutcome(
                    SafetyMessages.InteractionCheckName,
                    SafetyCheckState.Unavailable,
                    "The interaction data source could not be reached. No interaction conclusion was drawn."),
                DrugLookupStatus.NotConfigured => new SafetyCheckOutcome(
                    SafetyMessages.InteractionCheckName,
                    SafetyCheckState.NotConfigured,
                    SafetyMessages.InteractionUnavailableBody),
                _ => new SafetyCheckOutcome(
                    SafetyMessages.InteractionCheckName,
                    SafetyCheckState.Completed,
                    $"Checked {identifiers.Count} identifiers against {_interactionProvider.Name}.")
            };
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // A provider failure is reported as an incomplete check, never as a clean result.
            _logger.LogWarning(exception, "Interaction provider {Provider} failed; reporting check as unavailable.", _interactionProvider.Name);

            return new SafetyCheckOutcome(
                SafetyMessages.InteractionCheckName,
                SafetyCheckState.Unavailable,
                "The interaction data source could not be reached. No interaction conclusion was drawn.");
        }
    }

    /// <summary>
    /// Union-find over ingredient occurrences. An occurrence contributes both its RxNorm
    /// identifier and its normalized name as keys, so a product identified by concept id and a
    /// product identified only by name still collapse into the same group.
    /// </summary>
    private static List<List<IngredientOccurrence>> GroupBySharedIdentifier(List<IngredientOccurrence> occurrences)
    {
        var parent = Enumerable.Range(0, occurrences.Count).ToArray();

        int Find(int index)
        {
            while (parent[index] != index)
            {
                parent[index] = parent[parent[index]];
                index = parent[index];
            }

            return index;
        }

        void Union(int left, int right)
        {
            var leftRoot = Find(left);
            var rightRoot = Find(right);
            if (leftRoot != rightRoot)
            {
                parent[rightRoot] = leftRoot;
            }
        }

        var keyOwners = new Dictionary<string, int>(StringComparer.Ordinal);

        for (var index = 0; index < occurrences.Count; index++)
        {
            foreach (var key in occurrences[index].Keys)
            {
                if (keyOwners.TryGetValue(key, out var owner))
                {
                    Union(owner, index);
                }
                else
                {
                    keyOwners[key] = index;
                }
            }
        }

        return occurrences
            .Select((occurrence, index) => (occurrence, root: Find(index)))
            .GroupBy(pair => pair.root)
            .Select(group => group.Select(pair => pair.occurrence).ToList())
            .ToList();
    }

    private static string DescribeSource(IEnumerable<Medication> medications)
    {
        var providers = medications
            .Select(m => m.ProvenanceProvider)
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .Select(p => p!)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        return providers.Count == 0 ? "user-entered" : string.Join(", ", providers);
    }

    private sealed record IngredientOccurrence(Medication Medication, MedicationIngredient Ingredient, string NormalizedName)
    {
        public IEnumerable<string> Keys
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(Ingredient.RxCui))
                {
                    yield return $"rxcui:{Ingredient.RxCui.Trim()}";
                }

                if (!string.IsNullOrWhiteSpace(NormalizedName))
                {
                    yield return $"name:{NormalizedName}";
                }
            }
        }
    }
}
