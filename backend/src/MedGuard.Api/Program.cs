using FluentValidation;
using MedGuard.Api.Common;
using MedGuard.Api.Extensions;
using MedGuard.Api.Features.Adherence;
using MedGuard.Api.Features.Auth;
using MedGuard.Api.Features.Caregivers;
using MedGuard.Api.Features.Demo;
using MedGuard.Api.Features.Emergency;
using MedGuard.Api.Features.Medications;
using MedGuard.Api.Features.Safety;
using MedGuard.Api.Features.Scanning;
using MedGuard.Api.Features.Schedules;
using MedGuard.Infrastructure;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);
var isProduction = builder.Environment.IsProduction();

// Request logs carry a correlation id and never medication content.
builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Warning)
    .WriteTo.Console());

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<AuthTokenIssuer>();
builder.Services.AddScoped<MedicationBuilder>();
builder.Services.AddScoped<SafetyFindingStore>();
builder.Services.AddScoped<DoseEventService>();

builder.Services.AddValidatorsFromAssemblyContaining<Program>(includeInternalTypes: true);
builder.Services.AddMedGuardInfrastructure(builder.Configuration, isProduction);
builder.Services.AddMedGuardAuthentication(builder.Configuration, isProduction);
builder.Services.AddMedGuardRateLimiting();
builder.Services.AddMedGuardObservability(builder.Configuration);
builder.Services.AddMedGuardSwagger();
builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
{
    var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();

    if (origins.Length == 0)
    {
        // Expo development clients connect from changing LAN addresses.
        policy.SetIsOriginAllowed(_ => !isProduction).AllowAnyHeader().AllowAnyMethod();
    }
    else
    {
        policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
    }
}));

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    options.SerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.Never;
});

var app = builder.Build();

app.UseMedGuardExceptionHandling();
app.UseSerilogRequestLogging(options =>
{
    options.GetLevel = (httpContext, _, exception) =>
        exception is not null || httpContext.Response.StatusCode >= 500
            ? LogEventLevel.Error
            : LogEventLevel.Information;
});

// HTTPS is normally enforced in production, but a reverse proxy (e.g. Caddy) that terminates TLS
// can turn this off via Security:EnforceHttps=false to avoid redirecting already-secure traffic.
if (isProduction && app.Configuration.GetValue("Security:EnforceHttps", true))
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseCors();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

if (!isProduction)
{
    app.UseSwagger();
    app.UseSwaggerUI(options => options.SwaggerEndpoint("/swagger/v1/swagger.json", "MedGuard API v1"));
}

app.MapHealthChecks("/health").AllowAnonymous();

app.MapAuthEndpoints();
app.MapMedicationEndpoints();
app.MapScanEndpoints();
app.MapSafetyEndpoints();
app.MapScheduleEndpoints();
app.MapAdherenceEndpoints();
app.MapCaregiverEndpoints();
app.MapEmergencyEndpoints();
app.MapDemoEndpoints();

await InitialiseDatabaseAsync(app);

app.Run();

static async Task InitialiseDatabaseAsync(WebApplication app)
{
    if (!app.Configuration.GetValue("Database:AutoMigrate", true))
    {
        return;
    }

    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<MedGuardDbContext>();

    if (!dbContext.Database.IsRelational())
    {
        return;
    }

    try
    {
        await dbContext.Database.MigrateAsync();

        var seeder = scope.ServiceProvider.GetRequiredService<DemoDataSeeder>();
        await seeder.SeedAsync(CancellationToken.None);
    }
    catch (Exception exception)
    {
        app.Logger.LogError(exception, "Database initialisation failed. The API will start but data access will fail.");
    }
}

/// <summary>Exposed so the integration test host can reference the API assembly.</summary>
public partial class Program;
