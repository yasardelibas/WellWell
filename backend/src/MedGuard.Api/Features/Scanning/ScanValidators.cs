using FluentValidation;
using MedGuard.Api.Features.Medications;
using MedGuard.Contracts.Scanning;

namespace MedGuard.Api.Features.Scanning;

public sealed class ScanRequestValidator : AbstractValidator<ScanRequest>
{
    public ScanRequestValidator()
    {
        RuleFor(request => request)
            .Must(request => !string.IsNullOrWhiteSpace(request.ImageBase64) || !string.IsNullOrWhiteSpace(request.OcrText))
            .WithName("image")
            .WithMessage("Provide a captured image or label text.");

        RuleFor(request => request.MimeType).MaximumLength(60);
        RuleFor(request => request.OcrText).MaximumLength(8000);
    }
}

public sealed class ConfirmScanRequestValidator : AbstractValidator<ConfirmScanRequest>
{
    public ConfirmScanRequestValidator()
    {
        RuleFor(request => request.SelectedCandidateRxCui).MaximumLength(32);
        RuleFor(request => request.BrandName).MaximumLength(200);
        RuleFor(request => request.GenericName).MaximumLength(200);
        RuleFor(request => request.DosageForm).MaximumLength(80);
        RuleFor(request => request.Strength).MaximumLength(80);
        RuleFor(request => request.Route).MaximumLength(80);
        RuleFor(request => request.LabelDirections).MaximumLength(500);
        RuleForEach(request => request.Ingredients).SetValidator(new IngredientInputValidator());
    }
}
