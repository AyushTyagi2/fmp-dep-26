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
        var userId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    var senderOrgId = Guid.Parse(
        "50d2194e-a86b-4aba-919a-e01fba1c0c39"
    );
        var shipment = await _service.CreateShipmentAsync(
            request,
            userId,
            senderOrgId);

        return Ok(new
        {
            shipment.Id,
            shipment.ShipmentNumber
        });
    }
}
