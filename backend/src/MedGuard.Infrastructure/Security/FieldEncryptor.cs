using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Security;

public interface IFieldEncryptor
{
    string? Encrypt(string? plaintext);

    string? Decrypt(string? ciphertext);
}

/// <summary>
/// AES-GCM column encryption for the most sensitive free-text fields (emergency card
/// content, medication notes). Values are stored as "v1:nonce:tag:ciphertext" in base64.
/// </summary>
public sealed class AesGcmFieldEncryptor : IFieldEncryptor
{
    private const string Prefix = "v1";
    private const int NonceSize = 12;
    private const int TagSize = 16;

    private readonly byte[] _key;

    public AesGcmFieldEncryptor(byte[] key)
    {
        if (key.Length != 32)
        {
            throw new ArgumentException("Field encryption key must be 32 bytes.", nameof(key));
        }

        _key = key;
    }

    public static AesGcmFieldEncryptor FromConfiguration(string? base64Key, bool isProduction, ILogger logger)
    {
        if (!string.IsNullOrWhiteSpace(base64Key))
        {
            return new AesGcmFieldEncryptor(Convert.FromBase64String(base64Key));
        }

        if (isProduction)
        {
            throw new InvalidOperationException(
                "Security:FieldEncryptionKey must be configured in production. Provide a base64-encoded 32-byte key.");
        }

        logger.LogWarning(
            "No Security:FieldEncryptionKey configured. Falling back to a development-only key. Never use this outside local development.");

        return new AesGcmFieldEncryptor(SHA256.HashData(Encoding.UTF8.GetBytes("medguard-development-only-key")));
    }

    public string? Encrypt(string? plaintext)
    {
        if (plaintext is null)
        {
            return null;
        }

        if (plaintext.Length == 0)
        {
            return string.Empty;
        }

        var nonce = RandomNumberGenerator.GetBytes(NonceSize);
        var plainBytes = Encoding.UTF8.GetBytes(plaintext);
        var cipherBytes = new byte[plainBytes.Length];
        var tag = new byte[TagSize];

        using var aes = new AesGcm(_key, TagSize);
        aes.Encrypt(nonce, plainBytes, cipherBytes, tag);

        return string.Join(':', Prefix, Convert.ToBase64String(nonce), Convert.ToBase64String(tag), Convert.ToBase64String(cipherBytes));
    }

    public string? Decrypt(string? ciphertext)
    {
        if (string.IsNullOrEmpty(ciphertext))
        {
            return ciphertext;
        }

        var parts = ciphertext.Split(':');
        if (parts.Length != 4 || parts[0] != Prefix)
        {
            // Value predates encryption or was seeded in plaintext; return as-is.
            return ciphertext;
        }

        try
        {
            var nonce = Convert.FromBase64String(parts[1]);
            var tag = Convert.FromBase64String(parts[2]);
            var cipherBytes = Convert.FromBase64String(parts[3]);
            var plainBytes = new byte[cipherBytes.Length];

            using var aes = new AesGcm(_key, TagSize);
            aes.Decrypt(nonce, cipherBytes, tag, plainBytes);

            return Encoding.UTF8.GetString(plainBytes);
        }
        catch (CryptographicException)
        {
            return null;
        }
    }
}
