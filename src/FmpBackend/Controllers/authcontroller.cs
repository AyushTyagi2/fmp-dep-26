using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;
using FmpBackend.Repositories;

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

    public AuthController(
        OtpService otpService,
        RoleService roleService,
        JwtService jwtService,
        DriverRepository drivers,
        UserRepository users)
    {
        _otpService  = otpService;
        _roleService = roleService;
        _jwtService  = jwtService;
        _drivers     = drivers;
        _users       = users;
    }

    // POST /auth/request-otp
    [HttpPost("request-otp")]
    public IActionResult RequestOtp([FromBody] RequestOtpDto dto)
    {
        _otpService.GenerateOtp(dto.Phone);
        return Ok(new { success = true });
    }

    // POST /auth/verify-otp
    // Verifies OTP, creates user if new, resolves destination screen, issues JWT.
    // Flutter navigates directly to the returned screen — no extra calls needed.
    [HttpPost("verify-otp")]
    public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
    {
        try
        {
            var user = _otpService.VerifyOtp(dto.Phone, dto.Otp);

            var (screen, roleForJwt, driverId) = _roleService.ResolveAfterOtp(dto.Phone, user.Id);

            var token = _jwtService.Generate(dto.Phone, roleForJwt);

            return Ok(new { success = true, screen, token, driverId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // POST /auth/resolve-role
    // Only called from the role-selection screen (driver / organisation path).
    [HttpPost("resolve-role")]
    public IActionResult ResolveRole([FromBody] ResolveRoleDto dto)
    {
        var screen = _roleService.Resolve(dto.Phone, dto.Role);
        var token  = _jwtService.Generate(dto.Phone, dto.Role);

        string? driverId = null;
        var user = _users.GetByPhone(dto.Phone);
        if (user != null)
        {
            var driver = _drivers.GetByUserId(user.Id);
            driverId = driver?.Id.ToString();
        }

        return Ok(new { screen, token, driverId });
    }
}