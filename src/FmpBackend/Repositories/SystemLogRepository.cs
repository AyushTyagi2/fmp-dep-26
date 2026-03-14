using FmpBackend.Data;
using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Repositories;

public class SystemLogRepository
{
    private readonly AppDbContext _context;

    public SystemLogRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddLogAsync(string level, string message, string component = "system", string? sourceIp = null)
    {
        var log = new SystemLog
        {
            Level = level,
            Message = message,
            Component = component,
            SourceIp = sourceIp
        };
        _context.SystemLogs.Add(log);
        await _context.SaveChangesAsync();
    }

    public async Task<List<SystemLog>> GetRecentLogsAsync(int count = 50)
    {
        return await _context.SystemLogs
            .OrderByDescending(l => l.Timestamp)
            .Take(count)
            .ToListAsync();
    }
}
