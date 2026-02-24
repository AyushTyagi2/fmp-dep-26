using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class VehicleRepository
{
    private readonly AppDbContext _db;

    public VehicleRepository(AppDbContext db)
    {
        _db = db;
    }

    public Vehicle? GetByRegistration(string reg)
    {
        return _db.Vehicles.FirstOrDefault(v => v.RegistrationNumber == reg);
    }

    public Vehicle? GetByCurrentDriverId(Guid driverId)
    {
        return _db.Vehicles.FirstOrDefault(v => v.CurrentDriverId == driverId);
    }

    public Vehicle Create(Vehicle vehicle)
    {
        _db.Vehicles.Add(vehicle);
        _db.SaveChanges();
        return vehicle;
    }

    public void Update(Vehicle vehicle)
    {
        _db.Vehicles.Update(vehicle);
        _db.SaveChanges();
    }

    public int CountVehiclesWithIssuesForFleetOwner(System.Guid fleetOwnerId)
    {
        // Treat non-active status or not-available as issues
        return _db.Vehicles.Count(v => v.FleetOwnerId == fleetOwnerId && (v.Status != "active" || v.AvailabilityStatus != "available"));
    }
}
