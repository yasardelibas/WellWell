namespace MedGuard.Contracts.Auth;

public sealed record RegisterRequest(string Email, string Password, string DisplayName, string? TimeZoneId);

public sealed record LoginRequest(string Email, string Password);

public sealed record RefreshTokenRequest(string RefreshToken);

public sealed record LogoutRequest(string? RefreshToken);

public sealed record ForgotPasswordRequest(string Email);

public sealed record ResetPasswordRequest(string Token, string NewPassword);

public sealed record VerifyEmailRequest(string Code);

public sealed record UserResponse(
    Guid Id,
    string Email,
    string DisplayName,
    string TimeZoneId,
    bool SafetyNoticeAcknowledged,
    bool PrivacyNotificationsEnabled,
    bool BiometricLockEnabled,
    bool IsDemoAccount,
    bool EmailVerified);

public sealed record AuthResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresInSeconds,
    UserResponse User);

public sealed record UpdateProfileRequest(
    string? DisplayName,
    string? TimeZoneId,
    bool? PrivacyNotificationsEnabled,
    bool? BiometricLockEnabled);
