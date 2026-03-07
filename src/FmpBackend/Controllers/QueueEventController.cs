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

    [HttpPost]
    public async Task<IActionResult> CreateQueueEvent(
        [FromBody] CreateQueueEventRequest request)
    {
        var result = await _service.CreateQueueEventAsync(request);

        return Ok(result);
    }
}