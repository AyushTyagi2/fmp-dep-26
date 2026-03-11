using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using FmpBackend.Models;

namespace FmpBackend.Services;

/// <summary>
/// Issues JWT access tokens on successful OTP verification.
/// The token carries the userId, phone, and role as claims.
/// Flutter stores this token and sends it as "Authorization: Bearer ..." on every request.
/// </summary>
public class TokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config)
    {
        _config = config;
    }

    public string Issue(User user, string role)
    {
        var key   = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub,  user.Id.ToString()),
            new Claim("phone", user.Phone),
            new Claim(ClaimTypes.Role, role)         // "driver", "organization", "fleet_owner", "union", "sys_admin"
        };

        var token = new JwtSecurityToken(
            claims:   claims,
            expires:  DateTime.UtcNow.AddDays(30),  // long-lived — refresh on re-login
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}