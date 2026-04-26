using System;

namespace FmpBackend.Dtos;

public class VehicleDto
{
    public Guid Id { get; set; }
    public string RegistrationNumber { get; set; } = null!;
    public string VehicleType { get; set; } = null!;
    public decimal? CapacityTons { get; set; }
    public decimal? MaxLoadWeightKg { get; set; }
    public string Status { get; set; } = "active";
    public string AvailabilityStatus { get; set; } = "available";
    public Guid? CurrentDriverId { get; set; }
    public string? CurrentDriverName { get; set; }
}
