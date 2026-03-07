using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;
public class QueueEventRepository
{
    private readonly AppDbContext _db;

    public QueueEventRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<QueueEvent> CreateAsync(QueueEvent queueEvent)
    {
        _db.QueueEvents.Add(queueEvent);
        await _db.SaveChangesAsync();

        return queueEvent;
    }
    public async Task<QueueEvent?> GetActiveEventAsync()
{
    return await _db.QueueEvents
        .Where(x => x.Status == "live")
        .FirstOrDefaultAsync();
}
}