using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class ShipmentQueueRepository
{
    private readonly AppDbContext _db;
    public ShipmentQueueRepository(AppDbContext db) => _db = db;

    // ✅ Include addresses so ToDto can resolve "Delhi, UP" instead of raw GUIDs
    private IQueryable<ShipmentQueue> WithIncludes() =>
        _db.ShipmentQueues
           .Include(x => x.Shipment)
               .ThenInclude(s => s.PickupAddress)
           .Include(x => x.Shipment)
               .ThenInclude(s => s.DropAddress);

    public async Task<(List<ShipmentQueue> items, int total)> GetWaitingAsync(int page, int pageSize)
    {
        var q = WithIncludes()
                    .Where(x => x.Status == "waiting")
                    .OrderBy(x => x.CreatedAt);
        var total = await q.CountAsync();
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return (items, total);
    }

    public async Task<List<ShipmentQueue>> GetActiveQueuesAsync()
    {
        // For SysAdmin: fetch all queues that are currently processing, waiting, or failed
        var activeStatuses = new[] { "waiting", "offered", "accepted" };
        return await WithIncludes()
            .Where(x => activeStatuses.Contains(x.Status))
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<ShipmentQueue?> GetByIdAsync(Guid id) =>
        await WithIncludes().FirstOrDefaultAsync(x => x.Id == id);

    public async Task<ShipmentQueue?> LockForAcceptAsync(Guid id) =>
        await _db.ShipmentQueues
            .FromSqlRaw("SELECT * FROM shipment_queue WHERE id={0} AND status='waiting' FOR UPDATE SKIP LOCKED", id)
            .FirstOrDefaultAsync();

    public async Task AddAsync(ShipmentQueue item)
    {
        _db.ShipmentQueues.Add(item);
        await _db.SaveChangesAsync();
    }

    public async Task SaveAsync() => await _db.SaveChangesAsync();
}