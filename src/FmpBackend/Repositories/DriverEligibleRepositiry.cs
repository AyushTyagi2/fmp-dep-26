using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;
public class DriverEligibleRepository
{
    private readonly AppDbContext _db;

    public DriverEligibleRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<Driver>> GetEligibleDriversAsync()
    {
        return await _db.Drivers
            .Where(d =>
                d.Status == "active" &&
                d.AvailabilityStatus == "available" &&
                d.Verified == true)
            .OrderByDescending(d => d.TotalTripsCompleted)
            .ToListAsync();
    }
}