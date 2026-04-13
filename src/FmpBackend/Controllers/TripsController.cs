using FmpBackend.Dtos;
using FmpBackend.Services;
using Microsoft.AspNetCore.Mvc;

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/trips")]
public class TripsController : ControllerBase
{
    private readonly TripService _svc;
    public TripsController(TripService svc) => _svc = svc;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int page=1, [FromQuery] int pageSize=20, [FromQuery] string? status=null)
        => Ok(await _svc.GetAllAsync(page, pageSize, status));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var trip = await _svc.GetByIdAsync(id);
        return trip == null ? NotFound() : Ok(trip);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTripRequest req)
    {
        var result = await _svc.CreateAsync(req);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateTripStatusRequest req)
    {
        var ok = await _svc.UpdateStatusAsync(id, req);
        return ok ? NoContent() : NotFound();
    }

    [HttpGet("driver/{driverId:guid}")]
    public async Task<IActionResult> GetByDriver(Guid driverId)
        => Ok(await _svc.GetByDriverAsync(driverId));

    /// <summary>
    /// Driver trip search — GET /api/trips/search?driverId=&amp;q=&amp;status=
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> SearchTrips(
        [FromQuery] Guid driverId,
        [FromQuery] string? q = null,
        [FromQuery] string? status = null)
    {
        var result = await _svc.SearchByDriverAsync(driverId, q, status);
        return Ok(result);
    }
}
