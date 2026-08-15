namespace MedGuard.Domain.Entities;

/// <summary>
/// Opt-in emergency card. The QR code carries only an opaque random token; the card content
/// stays on the server and only the fields the user explicitly enabled are ever returned.
/// </summary>
public sealed class EmergencyCard
{
    private EmergencyCard()
    {
        TokenHash = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public bool IsEnabled { get; private set; }

    /// <summary>SHA-256 of the public token; used for constant lookup without storing it in the clear.</summary>
    public string TokenHash { get; private set; }

    /// <summary>
    /// The token itself, encrypted at rest, so the owner's app can re-render the QR code
    /// at any time without the server ever holding it in plaintext.
    /// </summary>
    public string? Token { get; private set; }

    public DateTimeOffset TokenIssuedAt { get; private set; }

    public DateTimeOffset? TokenExpiresAt { get; private set; }

    public bool ShareName { get; private set; }

    public bool ShareAllergies { get; private set; }

    public bool ShareMedications { get; private set; }

    public bool ShareEmergencyContact { get; private set; }

    public bool ShareNotes { get; private set; }

    public string? DisplayName { get; private set; }

    public string? Allergies { get; private set; }

    public string? EmergencyContactName { get; private set; }

    public string? EmergencyContactPhone { get; private set; }

    public string? Notes { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public bool IsTokenUsable(DateTimeOffset now) =>
        IsEnabled && (TokenExpiresAt is null || TokenExpiresAt > now);

    public static EmergencyCard Create(Guid userId, string token, string tokenHash, DateTimeOffset now, TimeSpan? tokenLifetime) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            IsEnabled = false,
            Token = token,
            TokenHash = tokenHash,
            TokenIssuedAt = now,
            TokenExpiresAt = tokenLifetime.HasValue ? now.Add(tokenLifetime.Value) : null,
            CreatedAt = now,
            UpdatedAt = now
        };

    public void Update(
        bool isEnabled,
        bool shareName,
        bool shareAllergies,
        bool shareMedications,
        bool shareEmergencyContact,
        bool shareNotes,
        string? displayName,
        string? allergies,
        string? emergencyContactName,
        string? emergencyContactPhone,
        string? notes,
        DateTimeOffset now)
    {
        IsEnabled = isEnabled;
        ShareName = shareName;
        ShareAllergies = shareAllergies;
        ShareMedications = shareMedications;
        ShareEmergencyContact = shareEmergencyContact;
        ShareNotes = shareNotes;
        DisplayName = displayName;
        Allergies = allergies;
        EmergencyContactName = emergencyContactName;
        EmergencyContactPhone = emergencyContactPhone;
        Notes = notes;
        UpdatedAt = now;
    }

    /// <summary>Invalidates every previously printed or shared QR code.</summary>
    public void RegenerateToken(string token, string tokenHash, DateTimeOffset now, TimeSpan? tokenLifetime)
    {
        Token = token;
        TokenHash = tokenHash;
        TokenIssuedAt = now;
        TokenExpiresAt = tokenLifetime.HasValue ? now.Add(tokenLifetime.Value) : null;
        UpdatedAt = now;
    }
}

public sealed class EmergencyCardAccessLog
{
    private EmergencyCardAccessLog()
    {
        Outcome = string.Empty;
    }

    public Guid Id { get; private set; }

    public Guid? EmergencyCardId { get; private set; }

    public DateTimeOffset AccessedAt { get; private set; }

    /// <summary>Truncated / hashed client hint. No raw IP addresses are stored.</summary>
    public string? ClientFingerprint { get; private set; }

    public string Outcome { get; private set; }

    public static EmergencyCardAccessLog Record(
        Guid? emergencyCardId,
        string outcome,
        string? clientFingerprint,
        DateTimeOffset now) =>
        new()
        {
            Id = Guid.NewGuid(),
            EmergencyCardId = emergencyCardId,
            Outcome = outcome,
            ClientFingerprint = clientFingerprint,
            AccessedAt = now
        };
}
