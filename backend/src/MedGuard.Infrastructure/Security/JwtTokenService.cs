using System.Security.Claims;
using System.Text;
using MedGuard.Domain.Entities;
using MedGuard.Infrastructure.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;

namespace MedGuard.Infrastructure.Security;

public sealed record AccessToken(string Value, int ExpiresInSeconds);

public interface IJwtTokenService
{
    AccessToken CreateAccessToken(User user);
}

public sealed class JwtTokenService : IJwtTokenService
{
    private readonly JwtOptions _options;

    public JwtTokenService(IOptions<JwtOptions> options) => _options = options.Value;

    public AccessToken CreateAccessToken(User user)
    {
        var expiresIn = TimeSpan.FromMinutes(_options.AccessTokenMinutes);
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey)),
            SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Subject, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.JwtId, Guid.NewGuid().ToString()),
            new("demo", user.IsDemoAccount ? "1" : "0")
        };

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.Add(expiresIn),
            signingCredentials: credentials);

        return new AccessToken(new JwtSecurityTokenHandler().WriteToken(token), (int)expiresIn.TotalSeconds);
    }

    private static class JwtRegisteredClaimNames
    {
        public const string Subject = "sub";
        public const string Email = "email";
        public const string JwtId = "jti";
    }
}
