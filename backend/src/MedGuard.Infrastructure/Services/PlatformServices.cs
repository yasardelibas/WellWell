using System.Text.Json;
using MedGuard.Application.Abstractions;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;

namespace MedGuard.Infrastructure.Services;

public sealed class SystemDateTimeProvider : IDateTimeProvider
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}

/// <summary>
/// Cache facade over IDistributedCache. Redis is used when configured; otherwise the
/// in-memory distributed cache keeps behaviour identical for local development.
/// </summary>
public sealed class DistributedCacheStore : ICacheStore
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly IDistributedCache _cache;
    private readonly ILogger<DistributedCacheStore> _logger;

    public DistributedCacheStore(IDistributedCache cache, ILogger<DistributedCacheStore> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken) where T : class
    {
        try
        {
            var payload = await _cache.GetStringAsync(key, cancellationToken).ConfigureAwait(false);
            return payload is null ? null : JsonSerializer.Deserialize<T>(payload, SerializerOptions);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // A cache outage must never break a request path.
            _logger.LogWarning(exception, "Cache read failed for key prefix {Prefix}.", KeyPrefix(key));
            return null;
        }
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan ttl, CancellationToken cancellationToken) where T : class
    {
        try
        {
            await _cache.SetStringAsync(
                    key,
                    JsonSerializer.Serialize(value, SerializerOptions),
                    new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = ttl },
                    cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(exception, "Cache write failed for key prefix {Prefix}.", KeyPrefix(key));
        }
    }

    private static string KeyPrefix(string key) => key.Split(':').FirstOrDefault() ?? "unknown";
}

/// <summary>
/// Development notification sender. Tokens are written to the log only outside production,
/// where a real transactional email provider is expected.
/// </summary>
public sealed class LoggingNotificationSender : INotificationSender
{
    private readonly ILogger<LoggingNotificationSender> _logger;
    private readonly bool _isProduction;

    public LoggingNotificationSender(ILogger<LoggingNotificationSender> logger, bool isProduction)
    {
        _logger = logger;
        _isProduction = isProduction;
    }

    public Task SendCaregiverInvitationAsync(string email, string token, CancellationToken cancellationToken)
    {
        Log("caregiver-invitation", email, token);
        return Task.CompletedTask;
    }

    public Task SendPasswordResetAsync(string email, string token, CancellationToken cancellationToken)
    {
        Log("password-reset", email, token);
        return Task.CompletedTask;
    }

    public Task SendEmailVerificationAsync(string email, string code, CancellationToken cancellationToken)
    {
        Log("email-verification", email, code);
        return Task.CompletedTask;
    }

    private void Log(string kind, string email, string token)
    {
        if (_isProduction)
        {
            _logger.LogWarning(
                "No outbound email provider configured; {Kind} for recipient hash {Recipient} was not delivered.",
                kind,
                Security.TokenGenerator.Fingerprint(email));
            return;
        }

        _logger.LogInformation("[dev] {Kind} for {Email}: token={Token}", kind, email, token);
    }
}
