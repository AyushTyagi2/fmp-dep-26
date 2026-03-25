using FmpBackend.Dtos;
using FmpBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/shipment-queue")]
public class ShipmentQueueController : ControllerBase
{
    private readonly ShipmentQueueService _svc;
    public ShipmentQueueController(ShipmentQueueService svc) => _svc = svc;

    [HttpGet]
    public async Task<IActionResult> GetWaiting(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _svc.GetWaitingAsync(page, pageSize));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var item = await _svc.GetByIdAsync(id);
        return item == null ? NotFound() : Ok(item);
    }

    [HttpPost("enqueue")]
    public async Task<IActionResult> Enqueue([FromBody] EnqueueRequest req)
    {
        var result = await _svc.EnqueueAsync(req.ShipmentId, req.RequiredVehicleType, req.ZoneId);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    // Returns { success, tripId } so Flutter can navigate to active trip
    [HttpPost("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, [FromBody] AcceptQueueItemRequest req)
    {
        var result = await _svc.AcceptAsync(id, req.DriverId);

        if (result.error != null)
            return Conflict(new AcceptQueueItemResponse(false, null, result.error));

        return Ok(new AcceptQueueItemResponse(true, result.tripId, "Shipment accepted."));
    }

    // Bug 1 fix: wired up the missing pass endpoint
    [HttpPost("{id:guid}/pass")]
    public async Task<IActionResult> Pass(Guid id, [FromBody] PassQueueItemRequest req)
    {
        var result = await _svc.PassAsync(id, req.DriverId);

        if (!result.success)
            return Conflict(new PassOfferResponse(false, result.error));

        return Ok(new PassOfferResponse(true, "Shipment passed."));
    }
}

public record EnqueueRequest(Guid ShipmentId, string? RequiredVehicleType, Guid? ZoneId);
public record PassQueueItemRequest(Guid DriverId);