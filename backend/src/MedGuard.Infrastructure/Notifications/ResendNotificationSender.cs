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

    private static bool IsTurkish(string? language) => string.Equals(language, "tr", StringComparison.OrdinalIgnoreCase);

    public Task SendCaregiverInvitationAsync(string email, string token, string? language, CancellationToken cancellationToken) =>
        SendAsync(
            "caregiver-invitation",
            email,
            IsTurkish(language) ? "WellWell'da bakıcı olarak davet edildiniz" : "You've been invited as a WellWell caregiver",
            IsTurkish(language)
                ? $"""
                  <p>Birinin WellWell'daki ilaç düzenini takip etmenize yardımcı olmanız için davet edildiniz.</p>
                  <p>Kabul etmek için bu davet kodunu uygulamaya girin:</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
                  <p style="color:#64748B;font-size:13px;">Bu daveti beklemiyorsanız, bu e-postayı yok sayabilirsiniz.</p>
                  """
                : $"""
                  <p>You've been invited to help keep track of someone's medication routine in WellWell.</p>
                  <p>Enter this invitation code in the app to accept:</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
                  <p style="color:#64748B;font-size:13px;">If you did not expect this invitation, you can ignore this email.</p>
                  """,
            cancellationToken);

    public Task SendPasswordResetAsync(string email, string token, string? language, CancellationToken cancellationToken) =>
        SendAsync(
            "password-reset",
            email,
            IsTurkish(language) ? "WellWell şifrenizi sıfırlayın" : "Reset your WellWell password",
            IsTurkish(language)
                ? $"""
                  <p>WellWell şifrenizi sıfırlamak için bu kodu kullanın:</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
                  <p style="color:#64748B;font-size:13px;">Bu kod 30 dakika içinde geçerliliğini yitirir. Şifre sıfırlama talebinde bulunmadıysanız, bu e-postayı yok sayabilirsiniz.</p>
                  """
                : $"""
                  <p>Use this code to reset your WellWell password:</p>
                  <p style="font-size:28px;font-weight:700;letter-spacing:2px;">{System.Net.WebUtility.HtmlEncode(token)}</p>
                  <p style="color:#64748B;font-size:13px;">This code expires in 30 minutes. If you did not request a password reset, you can ignore this email.</p>
                  """,
            cancellationToken);

    public Task SendEmailVerificationAsync(string email, string code, string? language, CancellationToken cancellationToken) =>
        SendAsync(
            "email-verification",
            email,
            IsTurkish(language) ? "WellWell için e-postanızı onaylayın" : "Confirm your email for WellWell",
            IsTurkish(language)
                ? $"""
                  <p>WellWell doğrulama kodunuz:</p>
                  <p style="font-size:32px;font-weight:700;letter-spacing:6px;">{System.Net.WebUtility.HtmlEncode(code)}</p>
                  <p style="color:#64748B;font-size:13px;">Bu kod {_options.VerificationCodeLifetimeMinutes} dakika içinde geçerliliğini yitirir. Bir WellWell hesabı oluşturmadıysanız, bu e-postayı yok sayabilirsiniz.</p>
                  """
                : $"""
                  <p>Your WellWell verification code is:</p>
                  <p style="font-size:32px;font-weight:700;letter-spacing:6px;">{System.Net.WebUtility.HtmlEncode(code)}</p>
                  <p style="color:#64748B;font-size:13px;">This code expires in {_options.VerificationCodeLifetimeMinutes} minutes. If you did not create a WellWell account, you can ignore this email.</p>
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
