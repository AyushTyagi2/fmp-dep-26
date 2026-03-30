using FmpBackend.Dtos;
using FmpBackend.Services;
using FmpBackend.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnalyticsController : ControllerBase
{
    private readonly AnalyticsService _analyticsService;
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly OrganizationRepository _orgs;
    private readonly FleetOwnerRepository _fleets;

    public AnalyticsController(
        AnalyticsService analyticsService,
        UserRepository users,
        DriverRepository drivers,
        OrganizationRepository orgs,
        FleetOwnerRepository fleets)
    {
        _analyticsService = analyticsService;
        _users = users;
        _drivers = drivers;
        _orgs = orgs;
        _fleets = fleets;
    }

    [HttpGet("sysadmin")]
    public async Task<ActionResult<SysAdminAnalyticsDto>> GetSysAdminAnalytics()
    {
        // Allowed roles: super_admin, admin
        var data = await _analyticsService.GetSysAdminAnalyticsAsync();
        return Ok(data);
    }

    [HttpGet("sender")]
    public async Task<ActionResult<SenderAnalyticsDto>> GetSenderAnalytics()
    {
        var phone = User.FindFirst("phone")?.Value;
        if (string.IsNullOrEmpty(phone)) return BadRequest("Authentication token does not contain a phone number.");

        var org = _orgs.GetByPhone(phone);
        if (org == null) return NotFound("Sender organization profile not found for the logged-in user.");

        var data = await _analyticsService.GetSenderAnalyticsAsync(org.Id);
        return Ok(data);
    }

    [HttpGet("driver")]
    public async Task<ActionResult<DriverAnalyticsDto>> GetDriverAnalytics()
    {
        var phone = User.FindFirst("phone")?.Value;
        if (string.IsNullOrEmpty(phone)) return BadRequest("Authentication token does not contain a phone number.");
        
        var user = _users.GetByPhone(phone);
        if (user == null) return NotFound("User account not found.");

        var driver = _drivers.GetByUserId(user.Id);
        if (driver == null) return NotFound("Driver profile not found for the logged-in user.");

        var data = await _analyticsService.GetDriverAnalyticsAsync(driver.Id);
        return Ok(data);
    }

    [HttpGet("union")]
    public async Task<ActionResult<UnionAnalyticsDto>> GetUnionAnalytics()
    {
        var phone = User.FindFirst("phone")?.Value;
        if (string.IsNullOrEmpty(phone)) return BadRequest("Authentication token does not contain a phone number.");
        
        var user = _users.GetByPhone(phone);
        if (user == null) return NotFound("User account not found.");

        var fleetOwner = _fleets.GetByUserId(user.Id);
        if (fleetOwner == null) return NotFound("Fleet Owner/Union profile not found for the logged-in user.");

        var data = await _analyticsService.GetUnionAnalyticsAsync(fleetOwner.Id);
        return Ok(data);
    }
}
