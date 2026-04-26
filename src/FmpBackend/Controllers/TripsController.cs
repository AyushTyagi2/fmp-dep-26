using FmpBackend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FmpBackend.Controllers;

[ApiController]
[Route("trips")]
public class TripsController : ControllerBase
{
    private readonly IFleetTripService _fleetTripService;
    private readonly ILogger<TripsController> _logger;

    public TripsController(IFleetTripService fleetTripService, ILogger<TripsController> logger)
    {
        _fleetTripService = fleetTripService;
        _logger           = logger;
    }

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
}