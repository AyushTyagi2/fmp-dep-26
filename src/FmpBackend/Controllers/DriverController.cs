using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;

namespace FmpBackend.Controllers;

[ApiController]
[Route("drivers")]
public class DriverController : ControllerBase
{
    private readonly DriverService _driverService;

    public DriverController(DriverService driverService)
    {
        _driverService = driverService;
    }

    [HttpPost("driver-details")]
    public IActionResult SubmitBasicDetails([FromBody] DriverBasicDetailsDto dto)
    {
        try
        {
            _driverService.SaveBasicDetails(dto);
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("fleetowners/{id}/drivers")]
    public IActionResult GetDriversForFleetOwner([FromRoute] Guid id)
    {
        try
        {
            var list = _driverService.GetDriversForFleetOwner(id);
            return Ok(list);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("fleetowners/phone/{phone}/drivers")]
    public IActionResult GetDriversForFleetOwnerByPhone([FromRoute] string phone)
    {
        try
        {
            var list = _driverService.GetDriversForFleetOwnerByPhone(phone);
            return Ok(list);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Fleet Manager driver search — GET /drivers/fleetowners/phone/{phone}/drivers/search?q=&amp;status=
    /// </summary>
    [HttpGet("fleetowners/phone/{phone}/drivers/search")]
    public IActionResult SearchDriversForFleetOwner(
        [FromRoute] string phone,
        [FromQuery] string? q = null,
        [FromQuery] string? status = null)
    {
        try
        {
            var result = _driverService.SearchDriversForFleetOwnerByPhone(phone, q, status);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("fleetowners/phone/{phone}/dashboard")]
    public IActionResult GetDashboardForFleetOwnerByPhone([FromRoute] string phone)
    {
        try
        {
            var dto = _driverService.GetFleetDashboardByPhone(phone);
            return Ok(dto);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public IActionResult GetDriver([FromRoute] Guid id)
    {
        try
        {
            var dto = _driverService.GetDriverDetails(id);
            if (dto == null) return NotFound();
            return Ok(dto);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
