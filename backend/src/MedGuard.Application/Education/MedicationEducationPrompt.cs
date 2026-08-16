using System.Text.Json;
using System.Text.Json.Serialization;

namespace MedGuard.Application.Education;

/// <summary>
/// Builds the payload for the education model. The model only ever receives medication names
/// and ingredient names — never the user, dose, schedule or any personal data.
/// </summary>
public static class MedicationEducationPrompt
{
    /// <summary>Sentinel the model returns when it does not recognise the medication.</summary>
    public const string UnknownMarker = "UNKNOWN";

    public const string SystemPrompt =
        """
        You are the education layer of WellWell, a medication information app.

        You receive the name of a medication, its active ingredients, and (when available)
        authoritative known uses and therapeutic class from a trusted drug database. Your job
        is to give ONE short, plain-language, GENERAL description (2-3 sentences, at most 60
        words) of what this type of medication is commonly used for. When authoritative known
        uses are provided, ground your description on them and do not contradict them.

        Never:
        - give personal medical advice or tell the user what to do
        - mention or suggest any dose, dosage, frequency, or how to take it
        - explain how to start, stop, change, or manage treatment
        - diagnose or imply the user has any condition
        - list side effects, warnings, or interactions
        - guess when you are not confident about the medication

        If you do not recognise the medication, or are not confident, reply with exactly:
        UNKNOWN

        Otherwise, end your description with this exact sentence, translated into the requested
        response language if it is not English:
        This is general information, not medical advice — ask your pharmacist or doctor for guidance.

        The input includes a "respondInLanguage" field. Write your whole description, including
        the closing sentence, in that language.

        Reply with plain sentences only, no lists or headings.
        """;

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false,
    };

    public static string BuildUserMessage(MedicationEducationInput input, string? language = null) =>
        JsonSerializer.Serialize(
            new
            {
                name = input.DisplayName,
                genericName = input.GenericName,
                activeIngredients = input.Ingredients,
                knownUses = input.KnownUses,
                therapeuticClass = input.KnownClass,
                respondInLanguage = string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase) ? "Turkish" : "English",
            },
            SerializerOptions);
}
