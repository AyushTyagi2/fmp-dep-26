using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;

namespace FmpBackend.Controllers;

[ApiController]
[Route("vehicles")]
public class VehiclesController : ControllerBase
{
    private readonly VehicleService _vehicleService;

    public VehiclesController(VehicleService vehicleService)
    {
        _vehicleService = vehicleService;
    }

    [HttpGet("fleetowners/phone/{phone}/vehicles")]
    public IActionResult GetVehiclesByFleetOwnerPhone([FromRoute] string phone)
    {
        try
        {
            var result = _vehicleService.GetVehiclesByFleetOwnerPhone(phone);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("fleetowners/phone/{phone}/vehicles")]
    public IActionResult AddVehicle([FromRoute] string phone, [FromBody] VehicleDto dto)
    {
        try
        {
            var result = _vehicleService.AddVehicle(phone, dto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("fleetowners/phone/{phone}/vehicles/bulk")]
    public IActionResult AddVehiclesBulk([FromRoute] string phone, [FromBody] List<VehicleDto> dtos)
    {
        try
        {
            var result = _vehicleService.AddVehiclesBulk(phone, dtos);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpDelete("fleetowners/phone/{phone}/vehicles")]
    public IActionResult DeleteVehicles([FromRoute] string phone, [FromBody] DeleteVehiclesDto request)
    {
        try
        {
            _vehicleService.DeleteVehicles(phone, request);
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
