namespace MedGuard.Contracts.Emergency;

public sealed record UpdateEmergencyCardRequest(
    bool IsEnabled,
    bool ShareName,
    bool ShareAllergies,
    bool ShareMedications,
    bool ShareEmergencyContact,
    bool ShareNotes,
    string? DisplayName,
    string? Allergies,
    string? EmergencyContactName,
    string? EmergencyContactPhone,
    string? Notes);

public sealed record EmergencyCardResponse(
    bool IsEnabled,
    bool ShareName,
    bool ShareAllergies,
    bool ShareMedications,
    bool ShareEmergencyContact,
    bool ShareNotes,
    string? DisplayName,
    string? Allergies,
    string? EmergencyContactName,
    string? EmergencyContactPhone,
    string? Notes,
    string ShareUrl,
    DateTimeOffset TokenIssuedAt,
    DateTimeOffset? TokenExpiresAt,
    DateTimeOffset UpdatedAt);

public sealed record PublicEmergencyMedication(string Name, string? StrengthText, string? Directions);

public sealed record PublicEmergencyCardResponse(
    string? Name,
    string? Allergies,
    IReadOnlyCollection<PublicEmergencyMedication> Medications,
    string? EmergencyContactName,
    string? EmergencyContactPhone,
    string? Notes,
    DateTimeOffset LastUpdated,
    string Disclaimer);
