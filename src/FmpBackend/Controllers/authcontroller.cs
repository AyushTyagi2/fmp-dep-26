using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;

namespace FmpBackend.Controllers;

[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly OtpService _otpService;
    private readonly RoleService _roleService;

    public AuthController(OtpService otpService, RoleService roleService)
    {
        _otpService = otpService;
        _roleService = roleService;
    }

    [HttpPost("request-otp")]
    public IActionResult RequestOtp([FromBody] RequestOtpDto dto)
    {
        _otpService.GenerateOtp(dto.Phone);
        return Ok(new { success = true });
    }

    [HttpPost("verify-otp")]
    public IActionResult VerifyOtp([FromBody] VerifyOtpDto dto)
    {
        try
        {
            _otpService.VerifyOtp(dto.Phone, dto.Otp);
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // NEW
    [HttpPost("resolve-role")]
    public IActionResult ResolveRole([FromBody] ResolveRoleDto dto)
    {
        var screen = _roleService.Resolve(dto.Phone, dto.Role);
        Console.WriteLine($"screen does exist: {screen}");
        return Ok(new { screen });
    }
}
