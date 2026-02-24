public class Vehicle
{
    public Guid Id { get; set; }

    public Guid FleetOwnerId { get; set; }
    public Guid? CurrentDriverId { get; set; }

    public string RegistrationNumber { get; set; } = null!;
    public string VehicleType { get; set; } = null!;

    // These may be null in the DB for some rows — make nullable to avoid cast errors
    public decimal? CapacityTons { get; set; }
    public decimal? MaxLoadWeightKg { get; set; }

    public string Status { get; set; } = "active";
    public string AvailabilityStatus { get; set; } = "available";
}
