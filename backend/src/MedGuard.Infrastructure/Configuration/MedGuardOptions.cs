namespace MedGuard.Infrastructure.Configuration;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "medguard";

    public string Audience { get; set; } = "medguard-app";

    /// <summary>Must be provided outside development; at least 32 characters.</summary>
    public string SigningKey { get; set; } = string.Empty;

    /// <summary>Short-lived access tokens; refresh tokens carry the long-lived session.</summary>
    public int AccessTokenMinutes { get; set; } = 15;

    public int RefreshTokenDays { get; set; } = 30;
}

public sealed class DrugDataOptions
{
    public const string SectionName = "DrugData";

    /// <summary>Ordered provider chain, e.g. ["local", "rxnorm", "openfda"].</summary>
    public string[] Providers { get; set; } = { "local" };

    public string RxNormBaseUrl { get; set; } = "https://rxnav.nlm.nih.gov/REST/";

    public string OpenFdaBaseUrl { get; set; } = "https://api.fda.gov/";

    /// <summary>RxClass (RxNav) endpoint used to enrich medication education with authoritative uses/class.</summary>
    public string RxClassBaseUrl { get; set; } = "https://rxnav.nlm.nih.gov/REST/rxclass/";

    public string? OpenFdaApiKey { get; set; }

    public int TimeoutSeconds { get; set; } = 8;

    /// <summary>Interaction data source. Empty means interaction checking is unavailable.</summary>
    public string? InteractionProvider { get; set; }
}

public sealed class AiOptions
{
    public const string SectionName = "Ai";

    /// <summary>When false, explanations use the deterministic template only.</summary>
    public bool ExplanationsEnabled { get; set; }

    /// <summary>When false, label extraction falls back to on-device OCR text parsing.</summary>
    public bool VisionEnabled { get; set; }

    public string BaseUrl { get; set; } = "https://api.openai.com/v1/";

    public string? ApiKey { get; set; }

    public string ExplanationModel { get; set; } = "gpt-4o-mini";

    public string VisionModel { get; set; } = "gpt-4o-mini";

    public int TimeoutSeconds { get; set; } = 20;
}

public sealed class EmailOptions
{
    public const string SectionName = "Email";

    /// <summary>When empty, outbound email falls back to logging only (development default).</summary>
    public string? ApiKey { get; set; }

    /// <summary>RFC 5322 "Name &lt;address&gt;" sender identity used for every outbound message.</summary>
    public string FromAddress { get; set; } = "MedGuard <onboarding@resend.dev>";

    public int VerificationCodeLifetimeMinutes { get; set; } = 10;
}

public sealed class ScanOptions
{
    public const string SectionName = "Scanning";

    /// <summary>How long an unconfirmed scan row survives before cleanup.</summary>
    public int RetentionHours { get; set; } = 24;

    public int MaxImageBytes { get; set; } = 6 * 1024 * 1024;

    /// <summary>Below this confidence the user must review the extraction manually.</summary>
    public double ManualReviewThreshold { get; set; } = 0.7d;
}

public sealed class EmergencyCardOptions
{
    public const string SectionName = "EmergencyCard";

    public string PublicBaseUrl { get; set; } = "https://medguard.app";

    /// <summary>Null means the token does not expire until it is regenerated.</summary>
    public int? TokenLifetimeDays { get; set; } = 365;
}

public sealed class CaregiverOptions
{
    public const string SectionName = "Caregivers";

    public int InvitationLifetimeHours { get; set; } = 72;

    /// <summary>
    /// Local and demo environments return the invitation token in the API response so the
    /// flow can be completed without an email provider. Never enable in production.
    /// </summary>
    public bool ExposeInvitationToken { get; set; }
}

public sealed class DemoOptions
{
    public const string SectionName = "Demo";

    public bool Enabled { get; set; } = true;

    public string Email { get; set; } = "demo@medguard.app";

    public string Password { get; set; } = "DemoPass123!";
}
