using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class SystemLogRepository
{
    private readonly AppDbContext _db;

    public SystemLogRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(SystemLog log)
    {
        _db.SystemLogs.Add(log);
        await _db.SaveChangesAsync();
    }

    public async Task<List<SystemLog>> GetRecentAsync(int limit)
    {
        return await _db.SystemLogs
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit)
            .ToListAsync();
    }
}