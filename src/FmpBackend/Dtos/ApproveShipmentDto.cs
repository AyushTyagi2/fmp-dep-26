namespace FmpBackend.Dtos;

public class ApproveShipmentRequest
{
    public Guid ShipmentId { get; set; }
    public string DriverPhoneNumber { get; set; } = default!;
}