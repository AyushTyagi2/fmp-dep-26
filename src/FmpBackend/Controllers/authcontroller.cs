using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;
using FmpBackend.Repositories;
using FmpBackend.Models;

namespace FmpBackend.Controllers;

[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly OtpService       _otpService;
    private readonly RoleService      _roleService;
    private readonly JwtService       _jwtService;
    private readonly DriverRepository _drivers;
    private readonly UserRepository   _users;
    private readonly GoogleAuthService _googleAuth;

    public AuthController(
        OtpService otpService,
        RoleService roleService,
        JwtService jwtService,
        DriverRepository drivers,
        UserRepository users,
        GoogleAuthService googleAuth)
    {
        _otpService  = otpService;
        _roleService = roleService;
        _jwtService  = jwtService;
        _drivers     = drivers;
        _users       = users;
        _googleAuth  = googleAuth;
    }

    // ── Email OTP endpoints (unchanged) ──────────────────────────────────────

    [HttpPost("request-otp")]
    public IActionResult RequestOtp([FromBody] RequestOtpDto dto)
    {
        _otpService.GenerateOtp(dto.Email);
        return Ok(new { success = true });
    }

    [HttpPost("verify-otp")]
    public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
    {
        try
        {
            _otpService.VerifyOtp(dto.Email, dto.Otp);
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // ── Google Sign-In endpoint ───────────────────────────────────────────────

    /// <summary>
    /// Validates a Google ID token from the Flutter app.
    /// If the email is new, creates a user record (auth_provider = "google").
    /// If the email already exists (phone-registered users whose email was
    /// populated by an admin migration), just returns their token.
    /// Returns: { email, token, driverId? }
    /// </summary>
    [HttpPost("google")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginDto dto)
    {
        try
        {
            var payload = await _googleAuth.ValidateAsync(dto.IdToken);

            var user = _users.GetByEmail(payload.Email);
            if (user == null)
            {
                // New user — create record (same as OTP flow)
                var id = Guid.NewGuid();
                user = new User
                {
                    Id             = id,
                    Email          = payload.Email,
                    FullName       = payload.Name ?? $"user_{id.ToString()[..8]}",
                    PasswordHash   = string.Empty,
                    AuthProvider   = "google",
                    AuthProviderId = payload.Subject,   // Google's unique "sub" field
                    CreatedAt      = DateTime.UtcNow,
                };
                _users.Create(user);
                Console.WriteLine($"[GOOGLE] New user created: {payload.Email}");
            }
            else
            {
                // Existing user — update provider info if they first used OTP
                if (user.AuthProvider == "email_otp" || user.AuthProvider == null)
                {
                    user.AuthProvider   = "google";
                    user.AuthProviderId = payload.Subject;
                    _users.Update(user);
                    Console.WriteLine($"[GOOGLE] Existing user linked to Google: {payload.Email}");
                }
                else
                {
                    Console.WriteLine($"[GOOGLE] Existing Google user signed in: {payload.Email}");
                }
            }

            // Look up driverId if this is a driver
            var driver = _drivers.GetByUserId(user.Id);

            // Issue a short-lived "pending" JWT — the client will call /auth/resolve-role next
            var token = _jwtService.Generate(user.Email, "PENDING");

            return Ok(new
            {
                email    = user.Email,
                token,
                driverId = driver?.Id.ToString()
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GOOGLE] Token validation failed: {ex.Message}");
            return BadRequest(new { error = "Invalid Google token." });
        }
    }

    // ── Resolve role (unchanged) ──────────────────────────────────────────────

    [HttpPost("resolve-role")]
    public IActionResult ResolveRole([FromBody] ResolveRoleDto dto)
    {
        var screen = _roleService.Resolve(dto.Email, dto.Role);
        var token  = _jwtService.Generate(dto.Email, dto.Role);

        string? driverId = null;
        var user = _users.GetByEmail(dto.Email);
        if (user != null)
        {
            var driver = _drivers.GetByUserId(user.Id);
            driverId = driver?.Id.ToString();
        }

        return Ok(new { screen, token, driverId });
    }
}