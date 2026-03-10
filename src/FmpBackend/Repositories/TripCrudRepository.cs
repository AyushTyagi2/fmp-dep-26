using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class TripCrudRepository
{
    private readonly AppDbContext _db;
    public TripCrudRepository(AppDbContext db) => _db = db;

    public async Task<(List<Trip> items, int total)> GetAllAsync(int page, int pageSize, string? status)
    {
        var q = _db.Trips.Include(t => t.Shipment).AsQueryable();
        if (status != null) q = q.Where(t => t.CurrentStatus == status);
        q = q.OrderByDescending(t => t.CreatedAt);
        var total = await q.CountAsync();
        var items = await q.Skip((page-1)*pageSize).Take(pageSize).ToListAsync();
        return (items, total);
    }

    public async Task<Trip?> GetByIdAsync(Guid id) =>
        await _db.Trips.Include(t => t.Shipment).FirstOrDefaultAsync(t => t.Id == id);

    public async Task<List<Trip>> GetByDriverAsync(Guid driverId) =>
        await _db.Trips.Include(t => t.Shipment)
                  .Where(t => t.DriverId == driverId)
                  .OrderByDescending(t => t.CreatedAt).ToListAsync();

    public async Task AddAsync(Trip trip)
        { _db.Trips.Add(trip); await _db.SaveChangesAsync(); }

    public async Task SaveAsync() => await _db.SaveChangesAsync();
}
