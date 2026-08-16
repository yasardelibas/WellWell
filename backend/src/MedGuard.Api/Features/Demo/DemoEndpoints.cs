using MedGuard.Api.Features.Auth;
using MedGuard.Contracts.Common;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Demo;

/// <summary>
/// One-tap access to the walkthrough account. Only available when the demo account is
/// explicitly enabled by configuration.
/// </summary>
public static class DemoEndpoints
{
    public static IEndpointRouteBuilder MapDemoEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/demo/login", LoginAsync)
            .WithTags("Demo")
            .AllowAnonymous()
            .RequireRateLimiting("auth");

        return app;
    }

    private static async Task<IResult> LoginAsync(
        MedGuardDbContext dbContext,
        DemoDataSeeder seeder,
        AuthTokenIssuer tokenIssuer,
        IOptions<DemoOptions> options,
        CancellationToken cancellationToken)
    {
        if (!options.Value.Enabled)
        {
            return Results.NotFound(new ApiError("demo_disabled", "The demo account is not available."));
        }

        var userId = await seeder.SeedAsync(cancellationToken);
        if (userId is null)
        {
            return Results.NotFound(new ApiError("demo_disabled", "The demo account is not available."));
        }

        var user = await dbContext.Users.FirstAsync(item => item.Id == userId.Value, cancellationToken);
        var response = await tokenIssuer.IssueAsync(user, familyId: null, cancellationToken);

        return Results.Ok(response);
    }
}
