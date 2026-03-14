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
    public async Task<IActionResult> GetSystemMetrics()
    {
        try
        {
            var metrics = await _sysAdminService.GetSystemMetricsAsync();
            return Ok(metrics);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("logs")]
    public async Task<IActionResult> GetRecentLogs()
    {
        try
        {
            var logs = await _sysAdminService.GetRecentLogsAsync();
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
            // Users endpoint is still synchronous for now
            var users = _sysAdminService.GetActiveUsers();
            return Ok(new { users });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("rules")]
    public async Task<IActionResult> GetSystemRules()
    {
        try
        {
            var rules = await _sysAdminService.GetSystemRulesAsync();
            return Ok(new { rules });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("rules/{key}")]
    public async Task<IActionResult> UpdateSystemRule(string key, [FromBody] UpdateRuleRecord req)
    {
        try
        {
            var updated = await _sysAdminService.UpdateSystemRuleAsync(key, req.IsEnabled, req.Value);
            return Ok(new { rule = updated });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("queues")]
    public async Task<IActionResult> GetActiveQueues([FromServices] FmpBackend.Repositories.ShipmentQueueRepository queueRepo)
    {
        try
        {
            var queues = await _sysAdminService.GetActiveQueuesAsync(queueRepo);
            return Ok(new { queues });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public record UpdateRuleRecord(bool IsEnabled, string? Value);