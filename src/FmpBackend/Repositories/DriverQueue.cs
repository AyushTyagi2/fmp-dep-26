using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;
public class DriverQueueRepository
{
    private readonly AppDbContext _db;

    public DriverQueueRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task AddEntriesAsync(List<DriverQueueEntry> entries)
    {
        _db.DriverQueueEntries.AddRange(entries);
        await _db.SaveChangesAsync();
    }
}