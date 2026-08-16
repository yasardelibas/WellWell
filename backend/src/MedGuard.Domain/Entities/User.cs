namespace MedGuard.Domain.Entities;

public sealed class User
{
    private User()
    {
        Email = string.Empty;
        NormalizedEmail = string.Empty;
        PasswordHash = string.Empty;
        DisplayName = string.Empty;
        TimeZoneId = "UTC";
        PreferredLanguage = "en";
    }

    public Guid Id { get; private set; }

    public string Email { get; private set; }

    public string NormalizedEmail { get; private set; }

    public string PasswordHash { get; private set; }

    public string DisplayName { get; private set; }

    public string TimeZoneId { get; private set; }

    /// <summary>ISO 639-1 code ("en", "tr") driving language for generated content: safety text,
    /// deterministic templates, and outbound email. Defaults to English.</summary>
    public string PreferredLanguage { get; private set; }

    public bool IsDemoAccount { get; private set; }

    public bool EmailVerified { get; private set; }

    public DateTimeOffset? EmailVerifiedAt { get; private set; }

    public bool SafetyNoticeAcknowledged { get; private set; }

    public DateTimeOffset? SafetyNoticeAcknowledgedAt { get; private set; }

    /// <summary>
    /// When enabled, reminder notifications omit medication names from the lock screen.
    /// Privacy-preserving default is <c>true</c>.
    /// </summary>
    public bool PrivacyNotificationsEnabled { get; private set; } = true;

    public bool BiometricLockEnabled { get; private set; }

    public DateTimeOffset CreatedAt { get; private set; }

    public DateTimeOffset UpdatedAt { get; private set; }

    public static User Create(
        string email,
        string passwordHash,
        string displayName,
        DateTimeOffset now,
        string timeZoneId = "UTC",
        bool isDemoAccount = false,
        string preferredLanguage = "en")
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        if (string.IsNullOrWhiteSpace(passwordHash))
        {
            throw new ArgumentException("Password hash is required.", nameof(passwordHash));
        }

        return new User
        {
            Id = Guid.NewGuid(),
            Email = email.Trim(),
            NormalizedEmail = NormalizeEmail(email),
            PasswordHash = passwordHash,
            DisplayName = string.IsNullOrWhiteSpace(displayName) ? email.Split('@')[0] : displayName.Trim(),
            TimeZoneId = string.IsNullOrWhiteSpace(timeZoneId) ? "UTC" : timeZoneId,
            PreferredLanguage = string.IsNullOrWhiteSpace(preferredLanguage) ? "en" : preferredLanguage,
            IsDemoAccount = isDemoAccount,
            // The demo account is a fixed, seeded identity with no real inbox behind it.
            EmailVerified = isDemoAccount,
            PrivacyNotificationsEnabled = true,
            CreatedAt = now,
            UpdatedAt = now
        };
    }

    public static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    public void ChangePassword(string passwordHash, DateTimeOffset now)
    {
        PasswordHash = passwordHash;
        UpdatedAt = now;
    }

    public void MarkEmailVerified(DateTimeOffset now)
    {
        EmailVerified = true;
        EmailVerifiedAt = now;
        UpdatedAt = now;
    }

    public void AcknowledgeSafetyNotice(DateTimeOffset now)
    {
        SafetyNoticeAcknowledged = true;
        SafetyNoticeAcknowledgedAt = now;
        UpdatedAt = now;
    }

    public void UpdatePreferences(
        string? displayName,
        string? timeZoneId,
        bool? privacyNotificationsEnabled,
        bool? biometricLockEnabled,
        DateTimeOffset now,
        string? preferredLanguage = null)
    {
        if (!string.IsNullOrWhiteSpace(displayName))
        {
            DisplayName = displayName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(timeZoneId))
        {
            TimeZoneId = timeZoneId;
        }

        if (!string.IsNullOrWhiteSpace(preferredLanguage))
        {
            PreferredLanguage = preferredLanguage;
        }

        if (privacyNotificationsEnabled.HasValue)
        {
            PrivacyNotificationsEnabled = privacyNotificationsEnabled.Value;
        }

        if (biometricLockEnabled.HasValue)
        {
            BiometricLockEnabled = biometricLockEnabled.Value;
        }

        UpdatedAt = now;
    }
}
