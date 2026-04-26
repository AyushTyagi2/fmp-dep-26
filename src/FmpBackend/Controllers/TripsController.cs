using FmpBackend.Services;
using FmpBackend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using FmpBackend.Dtos; // or the correct namespace where UpdateTripStatusRequest is defined

namespace FmpBackend.Controllers;

[ApiController]
[Route("api/trips")]   // was "trips" — must match the /api/trips/... calls from Flutter
public class TripsController : ControllerBase
{
    private readonly IFleetTripService _fleetTripService;
    private readonly TripService       _tripService;
    private readonly ILogger<TripsController> _logger;

    public TripsController(
        IFleetTripService fleetTripService,
        TripService tripService,
        ILogger<TripsController> logger)
    {
        _fleetTripService = fleetTripService;
        _tripService      = tripService;
        _logger           = logger;
    }

    // ── Fleet owner trips ─────────────────────────────────────────────────────
    // GET /api/trips/fleetowners/phone/{phone}/trips

    [HttpGet("fleetowners/phone/{phone}/trips")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTripsByFleetOwnerPhone(
        [FromRoute] string phone,
        CancellationToken ct)
    {
        var decoded = Uri.UnescapeDataString(phone);
        try
        {
            var trips = await _fleetTripService.GetTripsByFleetOwnerPhoneAsync(decoded, ct);
            return Ok(trips);
        }
        catch (KeyNotFoundException ex)
        {
            _logger.LogWarning("Fleet owner not found: {Message}", ex.Message);
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error fetching trips for phone {Phone}", decoded);
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An unexpected error occurred." });
        }
    }

    // ── Driver trips list ─────────────────────────────────────────────────────
    // GET /api/trips/driver/{driverId}
    // Called by: TripApiService.getDriverTrips()

    [HttpGet("driver/{driverId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTripsByDriver([FromRoute] Guid driverId)
    {
        try
        {
            var trips = await _tripService.GetByDriverAsync(driverId);
            return Ok(trips);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching trips for driver {DriverId}", driverId);
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An unexpected error occurred." });
        }
    }

    // ── Single trip by ID ─────────────────────────────────────────────────────
    // GET /api/trips/{tripId}
    // Called by: TripApiService.getTripById()

    [HttpGet("{tripId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetTripById([FromRoute] Guid tripId)
    {
        try
        {
            var trip = await _tripService.GetByIdAsync(tripId);
            if (trip is null)
                return NotFound(new { message = $"Trip {tripId} not found." });
            return Ok(trip);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching trip {TripId}", tripId);
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An unexpected error occurred." });
        }
    }

    // ── Update trip status ────────────────────────────────────────────────────
    // PATCH /api/trips/{tripId}/status
    // Called by: TripApiService.updateStatus()

    [HttpPatch("{tripId:guid}/status")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateTripStatus(
        [FromRoute] Guid tripId,
        [FromBody] UpdateTripStatusRequest req)
    {
        try
        {
            var ok = await _tripService.UpdateStatusAsync(tripId, req);
            if (!ok)
                return NotFound(new { message = $"Trip {tripId} not found." });
            return Ok(new { message = "Status updated." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating status for trip {TripId}", tripId);
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An unexpected error occurred." });
        }
    }
}