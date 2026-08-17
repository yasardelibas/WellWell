using System.Net.Http.Headers;
using MedGuard.Application.Abstractions;
using MedGuard.Application.Ai;
using MedGuard.Application.Education;
using MedGuard.Application.Insights;
using MedGuard.Application.Medications;
using MedGuard.Application.Safety;
using MedGuard.Infrastructure.Ai;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Drugs;
using MedGuard.Infrastructure.Extraction;
using MedGuard.Infrastructure.Http;
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
        AddExtraction(services, configuration);
        AddExplanations(services, configuration);

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
            // HttpClient.Timeout is not coordinated with retries; Polly owns the budget.
            client.Timeout = Timeout.InfiniteTimeSpan;
            client.DefaultRequestHeaders.UserAgent.ParseAdd("MedGuard/1.0");
        }).AddDrugDataResilience(timeout);

        services.AddHttpClient<OpenFdaDrugDataProvider>(client =>
        {
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.OpenFdaBaseUrl));
            client.Timeout = Timeout.InfiniteTimeSpan;
            client.DefaultRequestHeaders.UserAgent.ParseAdd("MedGuard/1.0");
        }).AddDrugDataResilience(timeout);

        // RxClass powers deterministic drug classification (uses + therapeutic class) for the
        // education card. It is an enrichment, not part of the identity lookup chain.
        services.AddHttpClient<IDrugClassificationProvider, RxClassDrugClassificationProvider>(client =>
        {
            client.BaseAddress = new Uri(EnsureTrailingSlash(options.RxClassBaseUrl));
            client.Timeout = Timeout.InfiniteTimeSpan;
            client.DefaultRequestHeaders.UserAgent.ParseAdd("MedGuard/1.0");
        }).AddDrugDataResilience(timeout);

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

    private static void AddExtraction(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<TextLabelExtractionService>();

        services.AddHttpClient<VisionLabelExtractionService>(ConfigureAiClient)
            .AddAiResilience(AiTimeout(configuration));

        services.AddTransient<ILabelExtractionService>(provider => provider.GetRequiredService<VisionLabelExtractionService>());
    }

    private static void AddExplanations(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<TemplateExplanationService>();
        services.AddSingleton<TemplateAdherenceInsightService>();
        services.AddSingleton<TemplateMedicationEducationService>();

        var timeout = AiTimeout(configuration);
        services.AddHttpClient<OpenAiExplanationService>(ConfigureAiClient).AddAiResilience(timeout);
        services.AddHttpClient<OpenAiAdherenceInsightService>(ConfigureAiClient).AddAiResilience(timeout);
        services.AddHttpClient<OpenAiMedicationEducationService>(ConfigureAiClient).AddAiResilience(timeout);

        services.AddTransient<IMedicationExplanationService>(provider => provider.GetRequiredService<OpenAiExplanationService>());
        services.AddTransient<IAdherenceInsightService>(provider => provider.GetRequiredService<OpenAiAdherenceInsightService>());
        // Education is stable per drug, so cache successful model output and serve known
        // medications from the shared cache instead of calling the model on every view.
        services.AddTransient<IMedicationEducationService>(provider => new CachingMedicationEducationService(
            provider.GetRequiredService<OpenAiMedicationEducationService>(),
            provider.GetRequiredService<ICacheStore>(),
            provider.GetRequiredService<ILogger<CachingMedicationEducationService>>()));
    }

    private static void ConfigureAiClient(IServiceProvider provider, HttpClient client)
    {
        var options = provider.GetRequiredService<IOptions<AiOptions>>().Value;
        client.BaseAddress = new Uri(EnsureTrailingSlash(options.BaseUrl));
        client.Timeout = Timeout.InfiniteTimeSpan;

        if (!string.IsNullOrWhiteSpace(options.ApiKey))
        {
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", options.ApiKey);
        }
    }

    private static TimeSpan AiTimeout(IConfiguration configuration)
    {
        var seconds = configuration.GetSection(AiOptions.SectionName).Get<AiOptions>()?.TimeoutSeconds ?? 20;
        return TimeSpan.FromSeconds(Math.Clamp(seconds, 5, 60));
    }

    private static string EnsureTrailingSlash(string url) => url.EndsWith('/') ? url : url + "/";
}
