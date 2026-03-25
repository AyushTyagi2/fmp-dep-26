using FmpBackend.Data;
using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
namespace FmpBackend.Repositories;

public class DriverRepository
{
    private readonly AppDbContext _db;

    public DriverRepository(AppDbContext db)
    {
        _db = db;
    }

    public Driver? GetByUserId(Guid userId)
    {
        return _db.Drivers.FirstOrDefault(d => d.UserId == userId);
    }

    public Driver? GetById(Guid id)
    {
        return _db.Drivers.FirstOrDefault(d => d.Id == id);
    }

    public IEnumerable<Driver> GetByFleetOwnerId(Guid fleetOwnerId)
    {
        return _db.Drivers.Where(d => d.CurrentFleetOwnerId == fleetOwnerId).ToList();
    }

    public Driver Create(Driver driver)
    {
        _db.Drivers.Add(driver);
        _db.SaveChanges();
        return driver;
    }
    public async Task<int> CountActiveAsync()
    {
        return await _db.Drivers.CountAsync(d => d.Status == "active");
    }
}
