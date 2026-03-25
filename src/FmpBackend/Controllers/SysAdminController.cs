using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using System.Security.Claims;

namespace FmpBackend.Controllers;

[ApiController]
[Route("sysadmin")]
[Authorize(Roles = "SUPER_ADMIN,ADMIN")]   // ← blocks unauthenticated callers
public class SysAdminController : ControllerBase
{
    private readonly SysAdminService _svc;

    public SysAdminController(SysAdminService svc)
    {
        _svc = svc;
    }

    // Helper: pull admin's user ID from JWT claims
    private Guid CurrentAdminId =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? User.FindFirstValue("sub"), out var id)
            ? id
            : Guid.Empty;

    // ── Dashboard ─────────────────────────────────────────────────────────────

    [HttpGet("metrics")]
    public async Task<IActionResult> GetSystemMetrics()
    {
        var metrics = await _svc.GetSystemMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet("logs")]
    public async Task<IActionResult> GetRecentLogs([FromQuery] int limit = 50)
    {
        var logs = await _svc.GetRecentLogsAsync(limit);
        return Ok(new { logs });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetActiveUsers()
    {
        var users = await _svc.GetActiveUsersAsync();
        return Ok(new { users });
    }

    // ── Shipment management ───────────────────────────────────────────────────

    /// <summary>List shipments. ?status=pending_approval|approved|cancelled|… (omit for all)</summary>
    [HttpGet("shipments")]
    public async Task<IActionResult> GetShipments([FromQuery] string? status = null)
    {
        var shipments = await _svc.GetShipmentsAsync(status);
        return Ok(new { shipments });
    }

    [HttpPost("shipments/{id:guid}/approve")]
    public async Task<IActionResult> ApproveShipment(Guid id)
    {
        var ok = await _svc.ApproveShipmentAsync(id, CurrentAdminId);
        if (!ok) return NotFound(new { error = "Shipment not found or invalid state" });
        return Ok(new { message = "Shipment approved" });
    }

    [HttpPost("shipments/{id:guid}/reject")]
    public async Task<IActionResult> RejectShipment(Guid id, [FromBody] ReasonRequest req)
    {
        var ok = await _svc.RejectShipmentAsync(id, req.Reason, CurrentAdminId);
        if (!ok) return NotFound(new { error = "Shipment not found" });
        return Ok(new { message = "Shipment rejected" });
    }

    [HttpPost("shipments/{id:guid}/cancel")]
    public async Task<IActionResult> CancelShipment(Guid id, [FromBody] ReasonRequest req)
    {
        var ok = await _svc.CancelShipmentAsync(id, CurrentAdminId, req.Reason);
        if (!ok) return NotFound(new { error = "Shipment not found" });
        return Ok(new { message = "Shipment cancelled" });
    }

    // ── Force-assign ──────────────────────────────────────────────────────────

    [HttpPost("shipments/{id:guid}/force-assign")]
    public async Task<IActionResult> ForceAssign(Guid id, [FromBody] ForceAssignRequest req)
    {
        var trip = await _svc.ForceAssignDriverAsync(id, req.DriverId, req.VehicleId, CurrentAdminId);
        return Ok(new { message = "Driver force-assigned", trip });
    }
}

// ── Request bodies ────────────────────────────────────────────────────────────

public record ReasonRequest(string Reason);

public record ForceAssignRequest(Guid DriverId, Guid VehicleId);