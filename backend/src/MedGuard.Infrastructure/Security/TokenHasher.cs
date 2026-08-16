using System.Security.Cryptography;
using System.Text;

namespace MedGuard.Infrastructure.Security;

/// <summary>
/// Opaque high-entropy tokens for refresh tokens, caregiver invitations and emergency cards.
/// Only the hash is persisted, so a database leak cannot be replayed against the API.
/// </summary>
public static class TokenGenerator
{
    /// <summary>256 bits of entropy, URL-safe.</summary>
    public static string CreateToken(int byteLength = 32) =>
        Base64UrlEncode(RandomNumberGenerator.GetBytes(byteLength));

    /// <summary>A zero-padded numeric code (e.g. "042917") for a human to type into an app.</summary>
    public static string CreateNumericCode(int digits = 6)
    {
        var maxExclusive = (int)Math.Pow(10, digits);
        var value = RandomNumberGenerator.GetInt32(0, maxExclusive);
        return value.ToString(new string('0', digits));
    }

    public static string Hash(string token) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token))).ToLowerInvariant();

    /// <summary>Short, non-reversible client hint used in access logs instead of an IP address.</summary>
    public static string Fingerprint(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "unknown";
        }

        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)))[..12].ToLowerInvariant();
    }

    private static string Base64UrlEncode(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
