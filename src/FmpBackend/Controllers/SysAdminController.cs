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
    public async Task<IActionResult> GetActiveUsers()
    {
        try
        {
            var users = await _sysAdminService.GetActiveUsersAsync();
            return Ok(new { users });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("users/{id}/role")]
    public async Task<IActionResult> UpdateUserRole(Guid id, [FromBody] UpdateRoleRequest req)
    {
        try
        {
            var success = await _sysAdminService.UpdateUserRoleAsync(id, req.Role);
            if (!success) return NotFound(new { error = "User not found" });
            return Ok(new { message = "Role updated successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("users/{id}/status")]
    public async Task<IActionResult> ToggleUserStatus(Guid id, [FromBody] ToggleStatusRequest req)
    {
        try
        {
            var success = await _sysAdminService.ToggleUserStatusAsync(id, req.IsActive);
            if (!success) return NotFound(new { error = "User not found" });
            return Ok(new { message = "Status updated successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("users/{id}/reset-password")]
    public async Task<IActionResult> ResetUserPassword(Guid id, [FromBody] ResetPasswordRequest req)
    {
        try
        {
            var success = await _sysAdminService.ResetUserPasswordAsync(id, req.NewPasswordHash);
            if (!success) return NotFound(new { error = "User not found" });
            return Ok(new { message = "Password reset successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        try
        {
            var success = await _sysAdminService.DeleteUserAsync(id);
            if (!success) return NotFound(new { error = "User not found" });
            return Ok(new { message = "User deleted successfully" });
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
public record UpdateRoleRequest(string Role);
public record ToggleStatusRequest(bool IsActive);
public record ResetPasswordRequest(string NewPasswordHash);