using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Http.Resilience;
using Polly;

namespace MedGuard.Infrastructure.Http;

/// <summary>
/// Sized Polly pipelines for outbound HTTP. The standard handler already retries
/// only transient failures (timeouts, connection errors, 408/429/5xx); 404 from
/// openFDA stays a genuine no-match and is never retried.
/// </summary>
public static class HttpClientResilience
{
    public static HttpResilienceProfile ForDrugData(TimeSpan totalTimeout) =>
        Build(
            totalTimeout,
            maxRetryAttempts: 2,
            retryDelay: TimeSpan.FromMilliseconds(200),
            attemptBudgetFraction: 1d / 3.5d,
            breakDuration: TimeSpan.FromSeconds(30),
            minimumThroughput: 5);

    public static HttpResilienceProfile ForAi(TimeSpan totalTimeout) =>
        Build(
            totalTimeout,
            maxRetryAttempts: 1,
            retryDelay: TimeSpan.FromSeconds(1),
            attemptBudgetFraction: 0.7d,
            breakDuration: TimeSpan.FromSeconds(45),
            minimumThroughput: 4);

    public static IHttpClientBuilder AddDrugDataResilience(this IHttpClientBuilder builder, TimeSpan totalTimeout)
    {
        builder.AddStandardResilienceHandler(options => ForDrugData(totalTimeout).Apply(options));
        return builder;
    }

    public static IHttpClientBuilder AddAiResilience(this IHttpClientBuilder builder, TimeSpan totalTimeout)
    {
        builder.AddStandardResilienceHandler(options => ForAi(totalTimeout).Apply(options));
        return builder;
    }

    private static HttpResilienceProfile Build(
        TimeSpan totalTimeout,
        int maxRetryAttempts,
        TimeSpan retryDelay,
        double attemptBudgetFraction,
        TimeSpan breakDuration,
        int minimumThroughput)
    {
        if (totalTimeout < TimeSpan.FromSeconds(2))
        {
            totalTimeout = TimeSpan.FromSeconds(2);
        }

        var attemptTimeout = TimeSpan.FromMilliseconds(totalTimeout.TotalMilliseconds * attemptBudgetFraction);
        var floor = TimeSpan.FromMilliseconds(500);
        if (attemptTimeout < floor)
        {
            attemptTimeout = floor;
        }

        if (attemptTimeout >= totalTimeout)
        {
            attemptTimeout = TimeSpan.FromMilliseconds(totalTimeout.TotalMilliseconds * 0.6d);
        }

        return new HttpResilienceProfile(
            totalTimeout,
            attemptTimeout,
            TimeSpan.FromTicks(attemptTimeout.Ticks * 2),
            breakDuration,
            maxRetryAttempts,
            retryDelay,
            0.5d,
            minimumThroughput);
    }
}

public sealed record HttpResilienceProfile(
    TimeSpan TotalRequestTimeout,
    TimeSpan AttemptTimeout,
    TimeSpan CircuitBreakerSamplingDuration,
    TimeSpan CircuitBreakerBreakDuration,
    int MaxRetryAttempts,
    TimeSpan RetryDelay,
    double FailureRatio,
    int MinimumThroughput)
{
    internal void Apply(HttpStandardResilienceOptions options)
    {
        options.TotalRequestTimeout.Timeout = TotalRequestTimeout;
        options.AttemptTimeout.Timeout = AttemptTimeout;
        options.Retry.MaxRetryAttempts = MaxRetryAttempts;
        options.Retry.Delay = RetryDelay;
        options.Retry.BackoffType = DelayBackoffType.Exponential;
        options.Retry.UseJitter = true;
        options.CircuitBreaker.SamplingDuration = CircuitBreakerSamplingDuration;
        options.CircuitBreaker.BreakDuration = CircuitBreakerBreakDuration;
        options.CircuitBreaker.FailureRatio = FailureRatio;
        options.CircuitBreaker.MinimumThroughput = MinimumThroughput;
    }
}
