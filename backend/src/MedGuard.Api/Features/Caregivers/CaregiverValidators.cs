using FluentValidation;
using MedGuard.Contracts.Caregivers;

namespace MedGuard.Api.Features.Caregivers;

public sealed class InviteCaregiverRequestValidator : AbstractValidator<InviteCaregiverRequest>
{
    public InviteCaregiverRequestValidator()
    {
        RuleFor(request => request.Email).NotEmpty().EmailAddress();
        RuleFor(request => request.Permissions).NotNull();
    }
}

public sealed class AcceptCaregiverInvitationRequestValidator
    : AbstractValidator<AcceptCaregiverInvitationRequest>
{
    public AcceptCaregiverInvitationRequestValidator() =>
        RuleFor(request => request.Token).NotEmpty().MaximumLength(200);
}

public sealed class UpdateCaregiverPermissionsRequestValidator
    : AbstractValidator<UpdateCaregiverPermissionsRequest>
{
    public UpdateCaregiverPermissionsRequestValidator() =>
        RuleFor(request => request.Permissions).NotNull();
}
