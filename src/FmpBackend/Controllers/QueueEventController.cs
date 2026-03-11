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

    // POST /api/queue-events
    [HttpPost]
    public async Task<IActionResult> CreateQueueEvent([FromBody] CreateQueueEventRequest request)
    {
        var result = await _service.CreateQueueEventAsync(request);
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
}