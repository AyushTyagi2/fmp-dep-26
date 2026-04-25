using FmpBackend.Dtos;
using FmpBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/shipment-queue")]
public class ShipmentQueueController : ControllerBase
{
    private readonly ShipmentQueueService _svc;
    private readonly QueueEventService   _queueEventSvc;

    public ShipmentQueueController(ShipmentQueueService svc, QueueEventService queueEventSvc)
    {
        _svc           = svc;
        _queueEventSvc = queueEventSvc;
    }

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

    [HttpPost("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, [FromBody] AcceptQueueItemRequest req)
    {
        var (tripId, error) = await _svc.AcceptAsync(id, req.DriverId);
        if (error != null)
        {
            if (error.Contains("already accepted") || error.Contains("already claimed"))
                return Conflict(new AcceptQueueItemResponse(false, null, error));
            return BadRequest(new AcceptQueueItemResponse(false, null, error));
        }
        return Ok(new AcceptQueueItemResponse(true, tripId, null));
    }

    [HttpPost("{id:guid}/pass")]
    public async Task<IActionResult> Pass(Guid id, [FromBody] PassQueueItemRequest req)
    {
        var (success, error) = await _svc.PassAsync(id, req.DriverId);
        if (!success)
            return Conflict(new PassOfferResponse(false, error, null));

        var nextSlot = await _queueEventSvc.GetActiveEventForDriverAsync(req.DriverId);
        return Ok(new PassOfferResponse(true, "Shipment passed.", nextSlot));
    }
}

public record EnqueueRequest(Guid ShipmentId, string? RequiredVehicleType, Guid? ZoneId);
public record PassQueueItemRequest(Guid DriverId);
// PassOfferResponse is defined in Dtos/QueueEventDto.cs (NextSlot: ActiveEventDto?)
// Do NOT redeclare it here — a local record shadows the Dto one and breaks serialisation.