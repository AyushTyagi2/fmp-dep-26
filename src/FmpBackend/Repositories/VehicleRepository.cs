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
}
