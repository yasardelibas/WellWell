using FluentValidation;
using MedGuard.Contracts.Medications;

namespace MedGuard.Api.Features.Medications;

public sealed class IngredientInputValidator : AbstractValidator<IngredientInput>
{
    public IngredientInputValidator()
    {
        RuleFor(ingredient => ingredient.Name).NotEmpty().MaximumLength(200);
        RuleFor(ingredient => ingredient.Strength).GreaterThan(0).When(ingredient => ingredient.Strength.HasValue);
        RuleFor(ingredient => ingredient.Unit).MaximumLength(20);
        RuleFor(ingredient => ingredient.RxCui).MaximumLength(32);
    }
}

public sealed class CreateMedicationRequestValidator : AbstractValidator<CreateMedicationRequest>
{
    public CreateMedicationRequestValidator()
    {
        RuleFor(request => request)
            .Must(request => !string.IsNullOrWhiteSpace(request.BrandName) || !string.IsNullOrWhiteSpace(request.GenericName))
            .WithName("name")
            .WithMessage("Enter at least a brand name or a generic name.");

        RuleFor(request => request.BrandName).MaximumLength(200);
        RuleFor(request => request.GenericName).MaximumLength(200);
        RuleFor(request => request.DosageForm).MaximumLength(80);
        RuleFor(request => request.Strength).MaximumLength(80);
        RuleFor(request => request.Route).MaximumLength(80);
        RuleFor(request => request.LabelDirections).MaximumLength(500);
        RuleFor(request => request.Notes).MaximumLength(2000);
        RuleFor(request => request.Ingredients).NotNull();
        RuleForEach(request => request.Ingredients).SetValidator(new IngredientInputValidator());
    }
}

public sealed class UpdateMedicationRequestValidator : AbstractValidator<UpdateMedicationRequest>
{
    public UpdateMedicationRequestValidator()
    {
        RuleFor(request => request.BrandName).MaximumLength(200);
        RuleFor(request => request.GenericName).MaximumLength(200);
        RuleFor(request => request.DosageForm).MaximumLength(80);
        RuleFor(request => request.Strength).MaximumLength(80);
        RuleFor(request => request.Route).MaximumLength(80);
        RuleFor(request => request.LabelDirections).MaximumLength(500);
        RuleFor(request => request.Notes).MaximumLength(2000);
        RuleForEach(request => request.Ingredients).SetValidator(new IngredientInputValidator());
    }
}
