using MedGuard.Application.Abstractions;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Resend;

namespace MedGuard.Infrastructure.Notifications;

/// <summary>
/// Sends real transactional email through Resend. A delivery failure is logged and swallowed
/// rather than thrown, the same way a cache outage never breaks a request in
/// <c>DistributedCacheStore</c> &mdash; a user must still be able to register or reset a
/// password when the email provider is briefly unavailable.
/// </summary>
public sealed class ResendNotificationSender : INotificationSender
{
    private readonly IResend _resend;
    private readonly EmailOptions _options;
    private readonly ILogger<ResendNotificationSender> _logger;

    public ResendNotificationSender(IResend resend, IOptions<EmailOptions> options, ILogger<ResendNotificationSender> logger)
    {
        _resend = resend;
        _options = options.Value;
        _logger = logger;
    }

    public Task SendCaregiverInvitationAsync(string email, string token, CancellationToken cancellationToken) =>
        SendAsync(
            "caregiver-invitation",
            email,
            "You've been invited as a MedGuard caregiver",
            $"""
            <p>You've been invited to help keep track of someone's medication routine in MedGuard.</p>
            <p>Enter this invitation code in the app to accept:</p>
            <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
            <p style="color:#64748B;font-size:13px;">If you did not expect this invitation, you can ignore this email.</p>
            """,
            cancellationToken);

    public Task SendPasswordResetAsync(string email, string token, CancellationToken cancellationToken) =>
        SendAsync(
            "password-reset",
            email,
            "Reset your MedGuard password",
            $"""
            <p>Use this code to reset your MedGuard password:</p>
            <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
            <p style="color:#64748B;font-size:13px;">This code expires in 30 minutes. If you did not request a password reset, you can ignore this email.</p>
            """,
            cancellationToken);

    public Task SendEmailVerificationAsync(string email, string code, CancellationToken cancellationToken) =>
        SendAsync(
            "email-verification",
            email,
            "Confirm your email for MedGuard",
            $"""
            <p>Your MedGuard verification code is:</p>
            <p style="font-size:32px;font-weight:700;letter-spacing:6px;">{System.Net.WebUtility.HtmlEncode(code)}</p>
            <p style="color:#64748B;font-size:13px;">This code expires in {_options.VerificationCodeLifetimeMinutes} minutes. If you did not create a MedGuard account, you can ignore this email.</p>
            """,
            cancellationToken);

    private async Task SendAsync(string kind, string email, string subject, string htmlBody, CancellationToken cancellationToken)
    {
        var message = new EmailMessage
        {
            From = _options.FromAddress,
            Subject = subject,
            HtmlBody = htmlBody,
        };
        message.To.Add(email);

        try
        {
            var response = await _resend.EmailSendAsync(message, cancellationToken).ConfigureAwait(false);

            if (!response.Success)
            {
                _logger.LogWarning(
                    response.Exception,
                    "Resend failed to deliver a {Kind} email to recipient hash {Recipient}.",
                    kind,
                    TokenGenerator.Fingerprint(email));
            }
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            _logger.LogWarning(
                exception,
                "Resend threw while delivering a {Kind} email to recipient hash {Recipient}.",
                kind,
                TokenGenerator.Fingerprint(email));
        }
    }
}
