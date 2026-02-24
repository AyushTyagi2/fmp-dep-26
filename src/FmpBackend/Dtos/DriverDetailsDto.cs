using System;

namespace FmpBackend.Dtos;

public class VehicleBriefDto
{
    public Guid Id { get; set; }
    public string RegistrationNumber { get; set; } = null!;
    public string VehicleType { get; set; } = null!;
}

public class DriverDetailsDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FullName { get; set; } = null!;
    public string Phone { get; set; } = null!;

    public string LicenseNumber { get; set; } = null!;
    public string LicenseType { get; set; } = null!;
    public DateTime LicenseExpiryDate { get; set; }

    public string Status { get; set; } = null!;

    public VehicleBriefDto? CurrentVehicle { get; set; }

    public decimal AverageRating { get; set; }
    public int TotalTripsCompleted { get; set; }
}
