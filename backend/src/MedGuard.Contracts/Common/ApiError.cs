namespace MedGuard.Contracts.Common;

public sealed record ApiError(string Code, string Message, IReadOnlyDictionary<string, string[]>? Details = null);

public sealed record PagedResponse<T>(IReadOnlyCollection<T> Items, int Total, int Page, int PageSize);
