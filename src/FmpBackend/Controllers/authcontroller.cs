using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;
using FmpBackend.Repositories;

namespace FmpBackend.Controllers;

[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly OtpService    _otpService;
    private readonly RoleService   _roleService;
    private readonly JwtService    _jwtService;
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

    [HttpPost("resolve-role")]
    public IActionResult ResolveRole([FromBody] ResolveRoleDto dto)
    {
        var screen = _roleService.Resolve(dto.Phone, dto.Role);
        var token  = _jwtService.Generate(dto.Phone, dto.Role);

        // Look up driverId if this is a driver
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