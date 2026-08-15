namespace MedGuard.Domain;

public sealed class DomainException : Exception
{
    public DomainException(string message, string code = "domain_rule_violation")
        : base(message)
    {
        Code = code;
    }

    public string Code { get; }
}
