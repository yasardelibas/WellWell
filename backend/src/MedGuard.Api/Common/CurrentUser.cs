using System.Security.Claims;

namespace MedGuard.Api.Common;

public interface ICurrentUser
{
    Guid? UserId { get; }

    bool IsAuthenticated { get; }

    Guid RequireUserId();
}

public sealed class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUser(IHttpContextAccessor accessor) => _accessor = accessor;

    public Guid? UserId
    {
        get
        {
            var value = _accessor.HttpContext?.User.FindFirstValue("sub")
                        ?? _accessor.HttpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier);

            return Guid.TryParse(value, out var userId) ? userId : null;
        }
    }

    public bool IsAuthenticated => UserId is not null;

    public Guid RequireUserId() => UserId ?? throw new UnauthorizedAccessException("Authentication is required.");
}
