using System.Text;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Safety;
using MedGuard.Domain.Entities;
using MedGuard.Domain.Enums;

namespace MedGuard.Application.Ai;

/// <summary>
/// Deterministic explanation used when no model is configured, when the model is
/// unreachable, or when generated text fails the output guard. Explanations are an
/// enhancement: safety findings must remain fully usable without them.
/// </summary>
public sealed class TemplateExplanationService : IMedicationExplanationService
{
    public const string SourceName = "medguard-template";

    public Task<MedicationExplanation> ExplainAsync(SafetyFinding finding, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(finding);
        return Task.FromResult(new MedicationExplanation(Build(finding), GeneratedByAi: false, SourceName));
    }

    public static string Build(SafetyFinding finding)
    {
        var builder = new StringBuilder();

        switch (finding.Type)
        {
            case SafetyFindingType.DuplicateActiveIngredient:
                var ingredient = finding.IngredientDisplayName ?? finding.IngredientNormalizedName ?? "the same active ingredient";
                var products = finding.Subjects.Select(s => s.MedicationName).ToList();

                builder.Append("An active ingredient is the part of a medicine that produces its effect. ");
                builder.Append(products.Count switch
                {
                    >= 2 => $"MedGuard read {string.Join(" and ", products)} and found that each one lists {ingredient} as an active ingredient. ",
                    _ => $"MedGuard found {ingredient} listed more than once across your saved medications. "
                });
                builder.Append("Because the same ingredient appears in more than one product, the amount you take can add up without it being obvious from the product names. ");
                builder.Append("MedGuard is not telling you to change anything. ");
                builder.Append("Check the labels of both products and, if you are unsure whether they are meant to be taken together, ask a pharmacist or your healthcare professional.");
                break;

            case SafetyFindingType.UnverifiedMedication:
                builder.Append("MedGuard could not match this medication against a trusted medication database. ");
                builder.Append("That does not mean anything is wrong with it: it means the details you see came from the label reading or from what was entered manually, and they have not been independently confirmed. ");
                builder.Append("Please compare the details with the printed label, and correct them if they differ.");
                break;

            case SafetyFindingType.InteractionCheckUnavailable:
                builder.Append("MedGuard did not check for interactions between your medications because no interaction data source is available. ");
                builder.Append("This is not a statement that there are no interactions. ");
                builder.Append("A pharmacist can review your full medication list if you would like an interaction check.");
                break;

            default:
                builder.Append("MedGuard flagged this item based on the medications currently saved in your list. ");
                builder.Append("Review the medication labels and ask a pharmacist or healthcare professional if anything is unclear.");
                break;
        }

        builder.Append(' ');
        builder.Append(SafetyMessages.GeneralDisclaimer);

        return builder.ToString();
    }
}
