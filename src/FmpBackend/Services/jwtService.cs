using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace FmpBackend.Services;

public class JwtService
{
    private readonly string _secret;

    public JwtService(IConfiguration config)
    {
        _secret = config["Jwt:Key"] ?? "super-secret-key-change-in-production";
    }

    public string Generate(string email, string role)
    {
        var key   = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims:
            [
                new Claim("email", email),
                new Claim("role",  role),
                // ClaimTypes.Role is what [Authorize(Roles = "...")] reads
                new Claim(ClaimTypes.Role, role.ToUpperInvariant()),
            ],
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}