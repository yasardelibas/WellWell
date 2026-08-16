using MedGuard.Infrastructure.Http;
using Xunit;

namespace MedGuard.UnitTests;

public sealed class HttpClientResilienceTests
{
    [Fact]
    public void ForDrugData_ShouldKeepAttemptsInsideTheTotalBudget()
    {
        var profile = HttpClientResilience.ForDrugData(TimeSpan.FromSeconds(8));

        Assert.Equal(TimeSpan.FromSeconds(8), profile.TotalRequestTimeout);
        Assert.Equal(2, profile.MaxRetryAttempts);
        Assert.True(profile.AttemptTimeout < profile.TotalRequestTimeout);
        Assert.True(profile.CircuitBreakerSamplingDuration >= TimeSpan.FromTicks(profile.AttemptTimeout.Ticks * 2));
        Assert.Equal(0.5d, profile.FailureRatio);
        Assert.True(profile.MinimumThroughput >= 2);
    }

    [Fact]
    public void ForAi_ShouldGiveMostOfTheBudgetToTheFirstAttempt()
    {
        var profile = HttpClientResilience.ForAi(TimeSpan.FromSeconds(40));

        Assert.Equal(TimeSpan.FromSeconds(40), profile.TotalRequestTimeout);
        Assert.Equal(1, profile.MaxRetryAttempts);
        Assert.True(profile.AttemptTimeout >= TimeSpan.FromSeconds(20));
        Assert.True(profile.AttemptTimeout < profile.TotalRequestTimeout);
        Assert.True(profile.CircuitBreakerSamplingDuration >= TimeSpan.FromTicks(profile.AttemptTimeout.Ticks * 2));
    }

    [Theory]
    [InlineData(2)]
    [InlineData(8)]
    [InlineData(20)]
    [InlineData(60)]
    public void Profiles_ShouldSatisfyStandardHandlerValidation_WhenTimeoutVaries(int seconds)
    {
        var total = TimeSpan.FromSeconds(seconds);
        AssertValid(HttpClientResilience.ForDrugData(total));
        AssertValid(HttpClientResilience.ForAi(total));
    }

    private static void AssertValid(HttpResilienceProfile profile)
    {
        Assert.True(profile.TotalRequestTimeout > profile.AttemptTimeout);
        Assert.True(profile.CircuitBreakerSamplingDuration >= TimeSpan.FromTicks(profile.AttemptTimeout.Ticks * 2));
        Assert.True(profile.MaxRetryAttempts >= 1);
        Assert.True(profile.RetryDelay > TimeSpan.Zero);
        Assert.InRange(profile.FailureRatio, 0.1d, 1d);
        Assert.True(profile.MinimumThroughput >= 2);
    }
}
