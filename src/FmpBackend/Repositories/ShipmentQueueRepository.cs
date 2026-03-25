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
        // Bug 3 fix: include 'offered' so shipments don't vanish from the list
        // once AssignOffersAsync flips their status — they're still unaccepted.
        var q = WithIncludes()
                    .Where(x => x.Status == ShipmentQueueStatus.Waiting
                             || x.Status == ShipmentQueueStatus.Offered)
                    .OrderBy(x => x.CreatedAt);
        var total = await q.CountAsync();
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return (items, total);
    }

    public async Task<ShipmentQueue?> GetByIdAsync(Guid id) =>
        await WithIncludes().FirstOrDefaultAsync(x => x.Id == id);

    public async Task<ShipmentQueue?> LockForAcceptAsync(Guid id) =>
        await _db.ShipmentQueues
            // Bug 5 fix: shipments are flipped to 'offered' by AssignOffersAsync before
            // a driver can accept — the old query for status='waiting' always returned null.
            .FromSqlRaw("SELECT * FROM shipment_queue WHERE id={0} AND status IN ('waiting','offered') FOR UPDATE SKIP LOCKED", id)
            .FirstOrDefaultAsync();

    public async Task AddAsync(ShipmentQueue item)
    {
        _db.ShipmentQueues.Add(item);
        await _db.SaveChangesAsync();
    }

    public async Task SaveAsync() => await _db.SaveChangesAsync();
}