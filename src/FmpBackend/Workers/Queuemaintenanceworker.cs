using FmpBackend.Data;
using FmpBackend.Models;
using FmpBackend.Services;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Workers;

/// <summary>
/// Background worker — ticks every 15 seconds (halved from 30 because the
/// new architecture doesn't do full table scans; each tick is cheaper).
///
/// 1. Find Pending assignments whose ExpiresAt has passed.
///    For each: flip outcome=Expired, call QueueEventService.OnWindowExpiredAsync.
///    OnWindowExpiredAsync handles all list mutations atomically.
///
/// 2. Close QueueEvents whose EndTime has passed.
/// </summary>
public class QueueMaintenanceWorker : BackgroundService
{
    private readonly IServiceScopeFactory            _scopeFactory;
    private readonly ILogger<QueueMaintenanceWorker> _logger;
    private static readonly TimeSpan _interval = TimeSpan.FromSeconds(15);

    public QueueMaintenanceWorker(IServiceScopeFactory scopeFactory, ILogger<QueueMaintenanceWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger       = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("QueueMaintenanceWorker started.");
        while (!stoppingToken.IsCancellationRequested)
        {
            try   { await RunMaintenanceAsync(); }
            catch (Exception ex) { _logger.LogError(ex, "Worker error: {Message}", ex.Message); }
            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task RunMaintenanceAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var db  = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var svc = scope.ServiceProvider.GetRequiredService<QueueEventService>();
        var now = DateTime.UtcNow;

        Console.WriteLine($"[Worker] TICK {now:O}");

        // ── 1. Process expired assignment windows ──────────────────────────────
        var expired = await db.ShipmentQueueAssignments
            .Where(a => a.Outcome == AssignmentOutcome.Pending && a.ExpiresAt < now)
            .ToListAsync();

        Console.WriteLine($"[Worker] expired assignments: {expired.Count}");

        foreach (var assignment in expired)
        {
            // Flip outcome first so a double-tick doesn't process it twice
            assignment.Outcome = AssignmentOutcome.Expired;
            await db.SaveChangesAsync();

            // Delegate all list mutations to the service
            await svc.OnWindowExpiredAsync(assignment);
            _logger.LogInformation("Window expired: driver={D} shipment={S}", assignment.DriverId, assignment.ShipmentQueueId);
        }

        // ── 2. Close expired events ────────────────────────────────────────────
        var closed = await db.QueueEvents
            .Where(e => e.Status == QueueEventStatus.Live && e.EndTime <= now)
            .ExecuteUpdateAsync(s => s.SetProperty(e => e.Status, QueueEventStatus.Closed));

        if (closed > 0)
            _logger.LogInformation("Closed {N} expired queue events.", closed);
    }
}