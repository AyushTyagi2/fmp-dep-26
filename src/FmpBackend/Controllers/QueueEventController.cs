using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/queue-events")]
public class QueueEventsController : ControllerBase
{
    private readonly QueueEventService _service;

    public QueueEventsController(QueueEventService service)
    {
        _service = service;
    }

    // GET /api/queue-events  — list all events, newest first
    [HttpGet]
    public async Task<IActionResult> GetAllEvents()
    {
        var result = await _service.GetAllEventsAsync();
        return Ok(result);
    }

    // POST /api/queue-events  — create a new event
    [HttpPost]
    public async Task<IActionResult> CreateQueueEvent([FromBody] CreateQueueEventRequest request)
    {
        var (result, conflict) = await _service.CreateQueueEventAsync(request);
        if (conflict != null)
            return Conflict(new { message = conflict });
        return Ok(result);
    }

    // GET /api/queue-events/active?driverId={id}
    // Flutter calls this every time the queue screen loads.
    // Returns the driver's current offer (if any) so Flutter can show the pinned card + countdown.
    [HttpGet("active")]
    public async Task<IActionResult> GetActive([FromQuery] Guid driverId)
    {
        var result = await _service.GetActiveEventForDriverAsync(driverId);
        if (result == null)
            return Ok(new { active = false });
        return Ok(result);
    }
    // POST /api/queue-events/reassign
    [HttpPost("reassign")]
    public async Task<IActionResult> Reassign()
    {
        var result = await _service.ReassignOffersAsync();
        return Ok(result);
    }

    // GET /api/queue-events/live-status
    // Returns whether a queue event is currently live (for Flutter to poll).
    [HttpGet("live-status")]
    public async Task<IActionResult> GetLiveStatus()
    {
        var result = await _service.GetLiveStatusAsync();
        return Ok(result);
    }

    // POST /api/queue-events/{id}/toggle
    // Toggles the queue event between live and closed.
    [HttpPost("{id}/toggle")]
    public async Task<IActionResult> ToggleQueueEvent(Guid id)
    {
        var result = await _service.ToggleQueueEventAsync(id);
        if (result == null) return NotFound(new { message = "Queue event not found." });
        return Ok(result);
    }
}