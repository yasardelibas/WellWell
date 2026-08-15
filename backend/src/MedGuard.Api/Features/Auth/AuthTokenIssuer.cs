using MedGuard.Api.Common;
using MedGuard.Application.Abstractions;
using MedGuard.Contracts.Auth;
using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Configuration;
using MedGuard.Infrastructure.Persistence;
using MedGuard.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace MedGuard.Api.Features.Auth;

/// <summary>
/// Issues access and refresh token pairs. Refresh tokens rotate on every use and are
/// stored only as hashes; reusing a rotated token revokes the entire family.
/// </summary>
public sealed class AuthTokenIssuer
{
    private readonly MedGuardDbContext _dbContext;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly IDateTimeProvider _clock;
    private readonly JwtOptions _options;

    public AuthTokenIssuer(
        MedGuardDbContext dbContext,
        IJwtTokenService jwtTokenService,
        IDateTimeProvider clock,
        IOptions<JwtOptions> options)
    {
        _dbContext = dbContext;
        _jwtTokenService = jwtTokenService;
        _clock = clock;
        _options = options.Value;
    }

    public async Task<AuthResponse> IssueAsync(User user, Guid? familyId, CancellationToken cancellationToken)
    {
        var accessToken = _jwtTokenService.CreateAccessToken(user);
        var refreshTokenValue = TokenGenerator.CreateToken();

        var refreshToken = RefreshToken.Issue(
            user.Id,
            TokenGenerator.Hash(refreshTokenValue),
            _clock.UtcNow,
            TimeSpan.FromDays(_options.RefreshTokenDays),
            familyId);

        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return new AuthResponse(accessToken.Value, refreshTokenValue, accessToken.ExpiresInSeconds, user.ToResponse());
    }

    public async Task<(RefreshToken? Token, bool ReuseDetected)> ResolveAsync(string rawToken, CancellationToken cancellationToken)
    {
        var hash = TokenGenerator.Hash(rawToken);

        var token = await _dbContext.RefreshTokens
            .FirstOrDefaultAsync(candidate => candidate.TokenHash == hash, cancellationToken)
            .ConfigureAwait(false);

        if (token is null)
        {
            return (null, false);
        }

        if (token.IsActive(_clock.UtcNow))
        {
            return (token, false);
        }

        // A revoked token being presented again means the chain may be compromised.
        var family = await _dbContext.RefreshTokens
            .Where(candidate => candidate.FamilyId == token.FamilyId && candidate.RevokedAt == null)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var member in family)
        {
            member.Revoke(_clock.UtcNow, "reuse-detected");
        }

        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return (null, true);
    }

    public async Task RevokeAsync(RefreshToken token, string reason, CancellationToken cancellationToken)
    {
        token.Revoke(_clock.UtcNow, reason);
        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    public async Task RevokeAllForUserAsync(Guid userId, string reason, CancellationToken cancellationToken)
    {
        var tokens = await _dbContext.RefreshTokens
            .Where(token => token.UserId == userId && token.RevokedAt == null)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var token in tokens)
        {
            token.Revoke(_clock.UtcNow, reason);
        }

        await _dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }
}