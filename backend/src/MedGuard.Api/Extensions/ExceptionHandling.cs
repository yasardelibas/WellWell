using MedGuard.Contracts.Common;
using MedGuard.Domain;
using Microsoft.AspNetCore.Diagnostics;

namespace MedGuard.Api.Extensions;

public static class ExceptionHandling
{
    private const int ClientClosedRequest = 499;

    /// <summary>
    /// Global error boundary. Responses stay generic so that internal details, medication
    /// data or stack traces never reach a client.
    /// </summary>
    public static IApplicationBuilder UseMedGuardExceptionHandling(this WebApplication app)
    {
        app.UseExceptionHandler(builder => builder.Run(async context =>
        {
            var feature = context.Features.Get<IExceptionHandlerFeature>();
            var exception = feature?.Error;

            var (statusCode, error) = exception switch
            {
                UnauthorizedAccessException => (
                    StatusCodes.Status401Unauthorized,
                    new ApiError("unauthorized", "Authentication is required.")),
                DomainException domainException => (
                    StatusCodes.Status400BadRequest,
                    new ApiError(domainException.Code, domainException.Message)),
                BadHttpRequestException => (
                    StatusCodes.Status400BadRequest,
                    new ApiError("invalid_request", "The request could not be read.")),
                OperationCanceledException => (
                    ClientClosedRequest,
                    new ApiError("request_cancelled", "The request was cancelled.")),
                _ => (
                    StatusCodes.Status500InternalServerError,
                    new ApiError("unexpected_error", "Something went wrong. Please try again."))
            };

            if (statusCode == StatusCodes.Status500InternalServerError)
            {
                app.Logger.LogError(exception, "Unhandled exception on {Method} {Path}", context.Request.Method, context.Request.Path);
            }

            context.Response.StatusCode = statusCode;
            await context.Response.WriteAsJsonAsync(error);
        }));

        return app;
    }
}
