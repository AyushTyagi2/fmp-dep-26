using FmpBackend.Models;
using FmpBackend.Repositories;
using System.Text.Json;

namespace FmpBackend.Services;

public class SystemLogService
{
    private readonly SystemLogRepository _repo;

    public SystemLogService(SystemLogRepository repo)
    {
        _repo = repo;
    }

    /// <summary>
    /// Write one row to system_logs.
    /// Call this inside the same unit of work as your business logic change
    /// so both commit or roll back together.
    /// </summary>
    public async Task LogAsync(
        string   eventType,
        Guid?    userId,
        string   actorType,      // "admin" | "driver" | "system"
        string?  entityType  = null,
        Guid?    entityId    = null,
        object?  metadata    = null)
    {
        var log = new SystemLog
        {
            Id         = Guid.NewGuid(),
            EventType  = eventType,
            UserId     = userId,
            ActorType  = actorType,
            EntityType = entityType,
            EntityId   = entityId,
            Metadata   = metadata == null
                ? "{}"
                : JsonSerializer.Serialize(metadata),
            CreatedAt  = DateTime.UtcNow
        };

        await _repo.AddAsync(log);
    }

    public async Task<List<SystemLog>> GetRecentAsync(int limit = 50)
        => await _repo.GetRecentAsync(limit);
}