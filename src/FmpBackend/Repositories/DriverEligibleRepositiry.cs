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

    public IQueryable<Driver> GetEligibleDriversQuery(string priorityRule = "highest_trips")
    {
        var query = _db.Drivers
            .Where(d =>
                d.Status == "active" &&
                d.AvailabilityStatus == "available" &&
                d.Verified == true);

        if (priorityRule == "youngest_drivers")
        {
            // Null DateOfBirth means we sort them last by making it DateTime.MinValue
            query = query.OrderByDescending(d => _db.Users
                .Where(u => u.Id == d.UserId)
                .Select(u => u.DateOfBirth)
                .FirstOrDefault() ?? DateTime.MinValue);
        }
        else if (priorityRule == "least_recently_active")
        {
            query = query.OrderBy(d => _db.Trips
                .Where(t => t.DriverId == d.Id && t.CompletedAt != null)
                .Max(t => t.CompletedAt) ?? DateTime.MinValue);
        }
        else // default to highest_trips
        {
            query = query.OrderByDescending(d => d.TotalTripsCompleted);
        }

        return query;
    }

    public async Task<List<Driver>> GetEligibleDriversAsync(string priorityRule = "highest_trips")
    {
        return await GetEligibleDriversQuery(priorityRule).ToListAsync();
    }
}