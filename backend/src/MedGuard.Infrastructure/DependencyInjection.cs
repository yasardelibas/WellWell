using System.Net.Http.Headers;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Ai;
using MedGuard.Application.Medications;
using MedGuard.Application.Safety;
using MedGuard.Infrastructure.Ai;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Drugs;
using MedGuard.Infrastructure.Extraction;
using MedGuard.Infrastructure.Notifications;
using MedGuard.Infrastructure.Persistence;
using MedGuard.Infrastructure.Security;
using MedGuard.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Resend;

namespace MedGuard.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddMedGuardInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration,
        bool isProduction)
    {
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<DrugDataOptions>(configuration.GetSection(DrugDataOptions.SectionName));
        services.Configure<AiOptions>(configuration.GetSection(AiOptions.SectionName));
        services.Configure<ScanOptions>(configuration.GetSection(ScanOptions.SectionName));
        services.Configure<EmergencyCardOptions>(configuration.GetSection(EmergencyCardOptions.SectionName));
        services.Configure<CaregiverOptions>(configuration.GetSection(CaregiverOptions.SectionName));
        services.Configure<DemoOptions>(configuration.GetSection(DemoOptions.SectionName));
        services.Configure<EmailOptions>(configuration.GetSection(EmailOptions.SectionName));

        services.AddSingleton<IFieldEncryptor>(provider => AesGcmFieldEncryptor.FromConfiguration(
            configuration["Security:FieldEncryptionKey"],
            isProduction,
            provider.GetRequiredService<ILogger<AesGcmFieldEncryptor>>()));

        AddPersistence(services, configuration);
        AddCaching(services, configuration);
        AddDrugProviders(services, configuration);
        AddExtraction(services);
        AddExplanations(services);

        services.AddSingleton<IIngredientNormalizer, IngredientNormalizer>();
        services.AddSingleton<IDateTimeProvider, SystemDateTimeProvider>();
        services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
        services.AddSingleton<IJwtTokenService, JwtTokenService>();
        AddNotifications(services, configuration, isProduction);

        services.AddScoped<IMedicationRepository, MedicationRepository>();
        services.AddScoped<IAuditLogger, AuditLogger>();
        services.AddScoped<IMedicationSafetyEngine, MedicationSafetyEngine>();
        services.AddScoped<MedicationVerificationService>();
        services.AddScoped<DemoDataSeeder>();

        return services;
    }

    private static void AddPersistence(IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Postgres");

        services.AddDbContext<MedGuardDbContext>((provider, options) =>
        {
            if (!string.IsNullOrWhiteSpace(connectionString))
            {
                options.UseNpgsql(connectionString, npgsql => npgsql.EnableRetryOnFailure(3));
            }

            options.EnableDetailedErrors(false);
            options.EnableSensitiveDataLogging(false);
        });
    }

    private static void AddCaching(IServiceCollection services, IConfiguration configuration)
    {
        var redisConnection = configuration.GetConnectionString("Redis");

        if (string.IsNullOrWhiteSpace(redisConnection))
        {
            services.AddDistributedMemoryCache();
        }
        else
        {
            services.AddStackExchangeRedisCache(options =>
            {
                options.Configuration = redisConnection;
                options.InstanceName = "medguard:";
            });
        }

        services.AddSingleton<ICacheStore, DistributedCacheStore>();
    }

    private static void AddDrugProviders(IServiceCollection services, IConfiguration configuration)
    {
        var options = configuration.GetSection(DrugDataOptions.SectionName).Get<DrugDataOptions>() ?? new DrugDataOptions();
        var timeout = TimeSpan.FromSeconds(Math.Clamp(options.TimeoutSeconds, 2, 30));

        services.AddSingleton<LocalDrugDataProvider>();

        services.AddHttpClient<RxNormDrugDataProvider>(client =>
        {
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.RxNormBaseUrl));
            client.Timeout = timeout;
            client.DefaultRequestHeaders.UserAgent.ParseAdd("MedGuard/1.0");
        });

        services.AddHttpClient<OpenFdaDrugDataProvider>(client =>
        {
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.OpenFdaBaseUrl));
            client.Timeout = timeout;
            client.DefaultRequestHeaders.UserAgent.ParseAdd("MedGuard/1.0");
        });

        // Registration order defines the lookup chain; the first confident match wins.
        foreach (var providerName in options.Providers.Select(name => name.Trim().ToLowerInvariant()).Distinct())
        {
            switch (providerName)
            {
                case "local":
                    services.AddTransient<IDrugDataProvider>(provider => provider.GetRequiredService<LocalDrugDataProvider>());
                    break;
                case "rxnorm":
                    services.AddTransient<IDrugDataProvider>(provider => provider.GetRequiredService<RxNormDrugDataProvider>());
                    break;
                case "openfda":
                    services.AddTransient<IDrugDataProvider>(provider => provider.GetRequiredService<OpenFdaDrugDataProvider>());
                    break;
            }
        }

        // No trustworthy interaction source ships with MedGuard, so the capability reports
        // itself as unavailable instead of returning an empty "nothing found" result.
        services.AddSingleton<IDrugInteractionProvider, UnavailableDrugInteractionProvider>();
    }

    /// <summary>
    /// A Resend API key switches on real delivery for password resets, caregiver invitations
    /// and email verification codes. Without one, every send is only written to the log, which
    /// keeps registration and password reset fully usable in local development.
    /// </summary>
    private static void AddNotifications(IServiceCollection services, IConfiguration configuration, bool isProduction)
    {
        var emailOptions = configuration.GetSection(EmailOptions.SectionName).Get<EmailOptions>() ?? new EmailOptions();

        if (string.IsNullOrWhiteSpace(emailOptions.ApiKey))
        {
            services.AddSingleton<INotificationSender>(provider => new LoggingNotificationSender(
                provider.GetRequiredService<ILogger<LoggingNotificationSender>>(),
                isProduction));
            return;
        }

        // AddResend registers IResend as a typed HttpClient, which is transient by design;
        // the facade follows the same lifetime instead of capturing it inside a singleton.
        services.AddResend(options => options.ApiToken = emailOptions.ApiKey);
        services.AddTransient<INotificationSender, ResendNotificationSender>();
    }

    private static void AddExtraction(IServiceCollection services)
    {
        services.AddSingleton<TextLabelExtractionService>();

        services.AddHttpClient<VisionLabelExtractionService>((provider, client) =>
        {
            var options = provider.GetRequiredService<IOptions<AiOptions>>().Value;
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.BaseUrl));
            client.Timeout = TimeSpan.FromSeconds(Math.Clamp(options.TimeoutSeconds, 5, 60));

            if (!string.IsNullOrWhiteSpace(options.ApiKey))
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", options.ApiKey);
            }
        });

        services.AddTransient<ILabelExtractionService>(provider => provider.GetRequiredService<VisionLabelExtractionService>());
    }

    private static void AddExplanations(IServiceCollection services)
    {
        services.AddSingleton<TemplateExplanationService>();

        services.AddHttpClient<OpenAiExplanationService>((provider, client) =>
        {
            var options = provider.GetRequiredService<IOptions<AiOptions>>().Value;
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.BaseUrl));
            client.Timeout = TimeSpan.FromSeconds(Math.Clamp(options.TimeoutSeconds, 5, 60));

            if (!string.IsNullOrWhiteSpace(options.ApiKey))
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", options.ApiKey);
            }
        });

        services.AddTransient<IMedicationExplanationService>(provider => provider.GetRequiredService<OpenAiExplanationService>());
    }

    private static string EnsureTrailingSlash(string url) => url.EndsWith('/') ? url : url + "/";
}
