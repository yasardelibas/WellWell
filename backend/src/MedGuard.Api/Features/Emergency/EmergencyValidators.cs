using FluentValidation;
using MedGuard.Contracts.Emergency;

namespace MedGuard.Api.Features.Emergency;

public sealed class UpdateEmergencyCardRequestValidator : AbstractValidator<UpdateEmergencyCardRequest>
{
    public UpdateEmergencyCardRequestValidator()
    {
        RuleFor(request => request.DisplayName).MaximumLength(120);
        RuleFor(request => request.Allergies).MaximumLength(500);
        RuleFor(request => request.EmergencyContactName).MaximumLength(120);
        RuleFor(request => request.EmergencyContactPhone).MaximumLength(40);
        RuleFor(request => request.Notes).MaximumLength(1000);
    }
}
