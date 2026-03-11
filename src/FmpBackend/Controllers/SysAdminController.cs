using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;

namespace FmpBackend.Controllers;

[ApiController]
[Route("sysadmin")]
public class SysAdminController : ControllerBase
{
    private readonly SysAdminService _sysAdminService;

    public SysAdminController(SysAdminService sysAdminService)
    {
        _sysAdminService = sysAdminService;
    }

    [HttpGet("metrics")]
    public IActionResult GetSystemMetrics()
    {
        try
        {
            var metrics = _sysAdminService.GetSystemMetrics();
            return Ok(metrics);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("logs")]
    public IActionResult GetRecentLogs()
    {
        try
        {
            var logs = _sysAdminService.GetRecentLogs();
            return Ok(new { logs });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("users")]
    public IActionResult GetActiveUsers()
    {
        try
        {
            var users = _sysAdminService.GetActiveUsers();
            return Ok(new { users });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}