using System;

namespace FmpBackend.Dtos;

public class FleetDashboardDto
{
    public Guid FleetOwnerId { get; set; }
    public string FleetOwnerName { get; set; } = string.Empty;
    public int ActiveDrivers { get; set; }
    public int ActiveTrips { get; set; }
    public int VehicleIssues { get; set; }
    public int TripsWithIssues { get; set; }
}
