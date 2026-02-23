using FmpBackend.Data;
using FmpBackend.Models;

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

    public Driver Create(Driver driver)
    {
        _db.Drivers.Add(driver);
        _db.SaveChanges();
        return driver;
    }
}
