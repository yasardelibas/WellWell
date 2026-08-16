using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using MedGuard.Application.Abstractions;
using MedGuard.Contracts.Auth;
using MedGuard.Infrastructure.Persistence;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Xunit;

namespace MedGuard.IntegrationTests;

/// <summary>
/// Hosts the real API pipeline against an in-memory database and the offline drug dataset,
/// so the tests exercise routing, authorisation, validation and persistence without network access.
/// </summary>
public sealed class MedGuardApiFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName = $"medguard-{Guid.NewGuid():N}";
    private int _clientCounter;

    /// <summary>
    /// Host settings rather than an extra configuration source: the API reads several of these
    /// while it composes its service graph, which happens before test configuration sources apply.
    /// </summary>
    private static readonly Dictionary<string, string> Settings = new()
    {
        ["ConnectionStrings:Postgres"] = string.Empty,
        ["ConnectionStrings:Redis"] = string.Empty,
        ["Database:AutoMigrate"] = "false",
        ["Jwt:SigningKey"] = "medguard-integration-tests-signing-key-0123456789",
        ["Security:FieldEncryptionKey"] = Convert.ToBase64String(Enumerable.Range(1, 32).Select(i => (byte)i).ToArray()),
        // Only the offline dataset: the tests must never depend on RxNorm or openFDA availability.
        ["DrugData:Providers:0"] = "local",
        ["DrugData:Providers:1"] = "local",
        ["DrugData:Providers:2"] = "local",
        ["Ai:ExplanationsEnabled"] = "false",
        ["Ai:VisionEnabled"] = "false",
        ["Caregivers:ExposeInvitationToken"] = "true",
        ["EmergencyCard:PublicBaseUrl"] = "https://test.medguard.app",
        ["Demo:Enabled"] = "true",
        ["OpenTelemetry:OtlpEndpoint"] = string.Empty
    };

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        foreach (var (key, value) in Settings)
        {
            builder.UseSetting(key, value);
        }

        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<DbContextOptions<MedGuardDbContext>>();
            services.RemoveAll<DbContextOptions>();

            services.AddDbContext<MedGuardDbContext>(options => options
                .UseInMemoryDatabase(_databaseName)
                .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning)));

            services.AddSingleton<IStartupFilter, TestClientAddressStartupFilter>();

            services.RemoveAll<INotificationSender>();
            services.AddSingleton<INotificationSender, CapturingNotificationSender>();
        });
    }

    /// <summary>The most recent email verification code sent to this address, if any.</summary>
    public string? LastVerificationCodeFor(string email) =>
        CapturingNotificationSender.LastVerificationCodesByEmail.TryGetValue(
            email.Trim().ToLowerInvariant(), out var code)
            ? code
            : null;

    /// <summary>
    /// Each client presents a distinct address so the production rate limits stay enabled
    /// without one test consuming another test's budget.
    /// </summary>
    public HttpClient CreateApiClient()
    {
        var client = CreateClient();
        var index = Interlocked.Increment(ref _clientCounter);
        client.DefaultRequestHeaders.Add(
            TestClientAddressStartupFilter.HeaderName,
            $"10.{index / 65536 % 256}.{index / 256 % 256}.{index % 256}");

        return client;
    }

    public async Task<TestUser> RegisterAsync(string? email = null, string timeZoneId = "UTC")
    {
        var client = CreateApiClient();
        var address = email ?? $"user-{Guid.NewGuid():N}@example.com";

        var response = await client.PostJsonAsync(
            "/api/auth/register",
            new RegisterRequest(address, "StrongPass123!", "Test Person", timeZoneId));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var auth = await response.ReadAsync<AuthResponse>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        return new TestUser(client, address, auth);
    }

    public async Task<T> WithDbContextAsync<T>(Func<MedGuardDbContext, Task<T>> action)
    {
        using var scope = Services.CreateScope();
        return await action(scope.ServiceProvider.GetRequiredService<MedGuardDbContext>());
    }
}

public sealed record TestUser(HttpClient Client, string Email, AuthResponse Auth);

/// <summary>Records outbound messages in memory instead of sending real email during tests.</summary>
internal sealed class CapturingNotificationSender : INotificationSender
{
    public static readonly ConcurrentDictionary<string, string> LastVerificationCodesByEmail = new();

    public Task SendCaregiverInvitationAsync(string email, string token, string? language, CancellationToken cancellationToken) =>
        Task.CompletedTask;

    public Task SendPasswordResetAsync(string email, string token, string? language, CancellationToken cancellationToken) =>
        Task.CompletedTask;

    public Task SendEmailVerificationAsync(string email, string code, string? language, CancellationToken cancellationToken)
    {
        LastVerificationCodesByEmail[email.Trim().ToLowerInvariant()] = code;
        return Task.CompletedTask;
    }
}

internal sealed class TestClientAddressStartupFilter : IStartupFilter
{
    public const string HeaderName = "X-Test-Client-Address";

    public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next) =>
        app =>
        {
            app.Use(async (context, continuation) =>
            {
                if (context.Request.Headers.TryGetValue(HeaderName, out var value) &&
                    IPAddress.TryParse(value.ToString(), out var address))
                {
                    context.Connection.RemoteIpAddress = address;
                }

                await continuation();
            });

            next(app);
        };
}

internal static class HttpTestExtensions
{
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public static Task<HttpResponseMessage> PostJsonAsync<TBody>(this HttpClient client, string url, TBody body) =>
        client.PostAsJsonAsync(url, body, Json);

    public static Task<HttpResponseMessage> PutJsonAsync<TBody>(this HttpClient client, string url, TBody body) =>
        client.PutAsJsonAsync(url, body, Json);

    public static async Task<T> ReadAsync<T>(this HttpResponseMessage response)
    {
        var value = await response.Content.ReadFromJsonAsync<T>(Json);
        Assert.NotNull(value);
        return value!;
    }

    public static async Task<T> GetAsync<T>(this HttpClient client, string url)
    {
        var response = await client.GetAsync(url);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.ReadAsync<T>();
    }
}
