using System;

namespace FmpBackend.Models;

public class Trip
{
    public Guid Id { get; set; }
    public Guid ShipmentId { get; set; }
    public Guid VehicleId { get; set; }
    public Guid DriverId { get; set; }
    public Guid AssignedFleetOwnerId { get; set; }
    public string CurrentStatus { get; set; } = "created";
    public bool HasIssues { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
