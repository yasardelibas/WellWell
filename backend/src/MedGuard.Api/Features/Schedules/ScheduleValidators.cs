using FluentValidation;
using MedGuard.Contracts.Schedules;

namespace MedGuard.Api.Features.Schedules;

public sealed class CreateScheduleRequestValidator : AbstractValidator<CreateScheduleRequest>
{
    public CreateScheduleRequestValidator()
    {
        RuleFor(request => request.MedicationId).NotEmpty();
        RuleFor(request => request.Times).NotEmpty().WithMessage("Choose at least one reminder time.");
        RuleFor(request => request.LabelInstruction).MaximumLength(500);
        RuleFor(request => request.DoseAmountText).MaximumLength(120);
    }
}

public sealed class UpdateScheduleRequestValidator : AbstractValidator<UpdateScheduleRequest>
{
    public UpdateScheduleRequestValidator()
    {
        RuleFor(request => request.Time).MaximumLength(8);
        RuleFor(request => request.DoseAmountText).MaximumLength(120);
    }
}
