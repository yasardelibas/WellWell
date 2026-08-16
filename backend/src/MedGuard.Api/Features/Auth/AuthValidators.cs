using FluentValidation;
using MedGuard.Contracts.Auth;

namespace MedGuard.Api.Features.Auth;

public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(request => request.Email).NotEmpty().EmailAddress().MaximumLength(320);
        RuleFor(request => request.Password).NotEmpty().MinimumLength(10).MaximumLength(128)
            .Must(ContainsMixedCharacters)
            .WithMessage("Use at least 10 characters with a mix of letters and numbers.");
        RuleFor(request => request.DisplayName).NotEmpty().MaximumLength(120);
        RuleFor(request => request.TimeZoneId).MaximumLength(80);
    }

    private static bool ContainsMixedCharacters(string password) =>
        password.Any(char.IsLetter) && password.Any(char.IsDigit);
}

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(request => request.Email).NotEmpty().EmailAddress();
        RuleFor(request => request.Password).NotEmpty();
    }
}

public sealed class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator() => RuleFor(request => request.RefreshToken).NotEmpty().MaximumLength(200);
}

public sealed class ForgotPasswordRequestValidator : AbstractValidator<ForgotPasswordRequest>
{
    public ForgotPasswordRequestValidator() => RuleFor(request => request.Email).NotEmpty().EmailAddress();
}

public sealed class ResetPasswordRequestValidator : AbstractValidator<ResetPasswordRequest>
{
    public ResetPasswordRequestValidator()
    {
        RuleFor(request => request.Token).NotEmpty().MaximumLength(200);
        RuleFor(request => request.NewPassword).NotEmpty().MinimumLength(10).MaximumLength(128);
    }
}

public sealed class VerifyEmailRequestValidator : AbstractValidator<VerifyEmailRequest>
{
    public VerifyEmailRequestValidator() =>
        RuleFor(request => request.Code).NotEmpty().Length(6).Matches("^[0-9]{6}$")
            .WithMessage("Enter the 6-digit code from your email.");
}

public sealed class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(request => request.DisplayName).MaximumLength(120);
        RuleFor(request => request.TimeZoneId).MaximumLength(80);
    }
}
