using FmpBackend.Data;
using FmpBackend.Models;
using FmpBackend.Services;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Workers;

/// <summary>
/// Background worker running every 30 seconds.
///
/// 1. Detect expired ShipmentQueueAssignments → mark expired, revert shipment
///    to "waiting", clear driver's offer, re-run AssignOffersAsync to cascade
///    the shipment to the next driver in line.
///
/// 2. Close QueueEvents whose EndTime has passed.
///
/// 3. Revert any still-"offered" shipments back to "waiting" on event close.
/// </summary>
public class QueueMaintenanceWorker : BackgroundService
{
    private readonly IServiceScopeFactory            _scopeFactory;
    private readonly ILogger<QueueMaintenanceWorker> _logger;
    private static readonly TimeSpan _interval = TimeSpan.FromSeconds(30);

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
            catch (Exception ex) { _logger.LogError(ex, "QueueMaintenanceWorker error: {Message}", ex.Message); }
            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task RunMaintenanceAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var db          = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now         = DateTime.UtcNow;

        // ── 1. Cascade expired offer assignments ─────────────────────────────
        var expiredAssignments = await db.ShipmentQueueAssignments
            .Where(a => a.Outcome == AssignmentOutcome.Pending && a.ExpiresAt < now)
            .ToListAsync();

        if (expiredAssignments.Any())
        {
            foreach (var assignment in expiredAssignments)
            {
                assignment.Outcome = AssignmentOutcome.Expired;

                // Revert shipment to waiting
                var shipment = await db.ShipmentQueues.FindAsync(assignment.ShipmentQueueId);
                if (shipment is { Status: ShipmentQueueStatus.Offered })
                {
                    shipment.Status          = ShipmentQueueStatus.Waiting;
                    shipment.CurrentDriverId = null;
                    shipment.OfferExpiresAt  = null;
                }

                // Clear driver entry so they become idle for next offer
                var driverEntry = await db.DriverQueueEntries
                    .FirstOrDefaultAsync(e => e.QueueEventId == assignment.QueueEventId
                                           && e.DriverId     == assignment.DriverId);
                if (driverEntry != null)
                {
                    driverEntry.CurrentOfferedShipmentQueueId = null;
                    driverEntry.OfferStatus                   = DriverOfferStatus.Expired;
                }
            }

            await db.SaveChangesAsync();
            _logger.LogInformation("Expired {Count} offer assignments.", expiredAssignments.Count);

            // Re-run matching for each affected live event to cascade shipments
            var affectedEventIds = expiredAssignments.Select(a => a.QueueEventId).Distinct();
            foreach (var eventId in affectedEventIds)
            {
                var evt = await db.QueueEvents.FindAsync(eventId);
                if (evt is { Status: QueueEventStatus.Live })
                {
                    // Resolve QueueEventService from DI so it has all its dependencies
                    var svc = scope.ServiceProvider.GetRequiredService<QueueEventService>();
                    await svc.AssignOffersAsync(evt);
                    _logger.LogInformation("Re-assigned offers for event {EventId}.", eventId);
                }
            }
        }

        // ── 2. Unconditional matching pass ───────────────────────────────────
var liveEvents = await db.QueueEvents
    .Where(e => e.Status == QueueEventStatus.Live && e.EndTime > now)
    .ToListAsync();

foreach (var liveEvent in liveEvents)
{
    var hasIdleDrivers = await db.DriverQueueEntries
        .AnyAsync(e => e.QueueEventId == liveEvent.Id
                    && !e.HasClaimed
                    && (e.OfferStatus == DriverOfferStatus.Idle
                     || e.OfferStatus == DriverOfferStatus.Passed
                     || e.OfferStatus == DriverOfferStatus.Expired));

    var hasWaitingShipments = await db.ShipmentQueues
        .AnyAsync(s => s.Status == ShipmentQueueStatus.Waiting
                    && (s.ZoneId == null || s.ZoneId == liveEvent.ZoneId));

    if (hasIdleDrivers && hasWaitingShipments)
    {
        var svc = scope.ServiceProvider.GetRequiredService<QueueEventService>();
        await svc.AssignOffersAsync(liveEvent);
    }
}

        // ── 2. Close expired QueueEvents ─────────────────────────────────────
        var closedEvents = await db.QueueEvents
            .Where(e => e.Status == QueueEventStatus.Live && e.EndTime <= now)
            .ExecuteUpdateAsync(s => s.SetProperty(e => e.Status, QueueEventStatus.Closed));

        if (closedEvents > 0)
            _logger.LogInformation("Closed {Count} expired queue events.", closedEvents);

        // ── 3. Revert any orphaned "offered" shipments back to waiting ────────
        var reverted = await db.ShipmentQueues
            .Where(q => q.Status == ShipmentQueueStatus.Offered
                     && q.OfferExpiresAt < now)
            .ExecuteUpdateAsync(s => s
                .SetProperty(q => q.Status,          ShipmentQueueStatus.Waiting)
                .SetProperty(q => q.CurrentDriverId, (Guid?)null)
                .SetProperty(q => q.OfferExpiresAt,  (DateTime?)null));

        if (reverted > 0)
            _logger.LogInformation("Reverted {Count} orphaned offered shipments to waiting.", reverted);
    }
}