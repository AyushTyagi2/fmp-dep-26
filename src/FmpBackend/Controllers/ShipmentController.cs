using Microsoft.AspNetCore.Mvc;
using FmpBackend.Services;
using FmpBackend.Dtos;
using Microsoft.AspNetCore.Authorization;

namespace FmpBackend.Controllers;


[ApiController]
[Route("api/[controller]")]
public class ShipmentsController : ControllerBase
{
    private readonly ShipmentService _service;

    public ShipmentsController(ShipmentService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<IActionResult> CreateShipment(
        [FromBody] CreateShipmentRequest request)
    {
        // Extract user ID from JWT
        //var userId = Guid.Parse(User.FindFirst("sub")!.Value);
        // You must fetch sender org from user
        //var senderOrgId = Guid.Parse(User.FindFirst("orgId")!.Value);
        //var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    //var senderOrgId = Guid.Parse(        "50d2194e-a86b-4aba-919a-e01fba1c0c39");
        var shipment = await _service.CreateShipmentAsync(request);

        return Ok(new
        {
            shipment.Id,
            shipment.ShipmentNumber
        });
    }

    [HttpGet("by-phone/{phone}")]
    public async Task<IActionResult> GetByPhone(string phone)
    {
        var result = await _service.GetShipmentsByPhoneAsync(phone);
        return Ok(result);
    }

    [HttpGet("pending")]
public async Task<IActionResult> GetPendingShipments()
{
    var shipments = await _service.GetPendingShipmentsAsync();

    Console.WriteLine("===== PENDING SHIPMENTS =====");
    Console.WriteLine(System.Text.Json.JsonSerializer.Serialize(shipments));
    Console.WriteLine("=============================");

    return Ok(shipments);
}

    [HttpPost("{id}/approve")]
    public async Task<IActionResult> ApproveShipment(Guid id)
    {
        var result = await _service.ApproveShipmentAsync(id);

        if (!result)
            return NotFound("Shipment not found or invalid state");

        return Ok(new { message = "Shipment approved" });
    }

    [HttpPost("{id}/reject")]
    public async Task<IActionResult> RejectShipment(Guid id)
    {
        var result = await _service.RejectShipmentAsync(id, "bad bad");

        if (!result)
            return NotFound();

        return Ok(new { message = "Shipment rejected" });
    }
}
