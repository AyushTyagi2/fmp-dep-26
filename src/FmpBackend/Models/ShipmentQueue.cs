namespace FmpBackend.Models;

public class ShipmentQueue
{
    public Guid    Id                  { get; set; }
    public Guid    ShipmentId          { get; set; }
    public Guid?   ZoneId              { get; set; }
    public string? RequiredVehicleType { get; set; }
    public string  Status              { get; set; } = "waiting"; // waiting, offered, accepted, expired
    public Guid?   CurrentDriverId     { get; set; }
    public DateTime? OfferExpiresAt    { get; set; }
    public DateTime  CreatedAt         { get; set; }

    // Navigation
    public Shipment Shipment { get; set; } = null!;
}