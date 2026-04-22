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

        Console.WriteLine($"[Worker] ── TICK utcNow={now:O}");

        // ── 1. Cascade expired offer assignments ─────────────────────────────
        var expiredAssignments = await db.ShipmentQueueAssignments
            .Where(a => a.Outcome == AssignmentOutcome.Pending && a.ExpiresAt < now)
            .ToListAsync();

        Console.WriteLine($"[Worker] expiredAssignments count={expiredAssignments.Count}");

        if (expiredAssignments.Any())
        {
            foreach (var assignment in expiredAssignments)
            {
                assignment.Outcome = AssignmentOutcome.Expired;

                // Only revert the shipment to Waiting if no other driver still has a
                // live Pending assignment on it.  With the parallel-offer design a
                // shipment may be simultaneously offered to multiple drivers; expiring
                // one driver's window must not pull the rug out from the others.
                var otherPending = await db.ShipmentQueueAssignments
                    .AnyAsync(a => a.ShipmentQueueId == assignment.ShipmentQueueId
                                && a.Id              != assignment.Id
                                && a.Outcome         == AssignmentOutcome.Pending);

                var shipment = await db.ShipmentQueues.FindAsync(assignment.ShipmentQueueId);
                if (shipment is { Status: ShipmentQueueStatus.Offered } && !otherPending)
                {
                    shipment.Status          = ShipmentQueueStatus.Waiting;
                    shipment.CurrentDriverId = null;
                    shipment.OfferExpiresAt  = null;
                }

                // Mark driver entry as Expired — but intentionally DO NOT clear
                // CurrentOfferedShipmentQueueId here.  The "Still Claimable" spec
                // requires the offer card to remain visible after the timer expires so
                // the driver can still accept it until someone else takes it.
                // CurrentOfferedShipmentQueueId is only cleared on Pass, Accept, or
                // when the shipment itself is accepted by another driver (race-loss).
                var driverEntry = await db.DriverQueueEntries
                    .FirstOrDefaultAsync(e => e.QueueEventId == assignment.QueueEventId
                                           && e.DriverId     == assignment.DriverId);
                if (driverEntry != null)
                {
                    Console.WriteLine($"[Worker] driverEntry before: driverId={driverEntry.DriverId} pos={driverEntry.Position} offerStatus={driverEntry.OfferStatus} currentOfferedShipmentQueueId={driverEntry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");
                    // Only flip to Expired — preserve CurrentOfferedShipmentQueueId
                    // so GetActiveEventForDriverAsync can still build the currentOffer DTO.
                    driverEntry.OfferStatus = DriverOfferStatus.Expired;
                    Console.WriteLine($"[Worker] driverEntry after: offerStatus={driverEntry.OfferStatus} currentOfferedShipmentQueueId={driverEntry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");
                }
                else
                {
                    Console.WriteLine($"[Worker] WARNING: no driverEntry found for driverId={assignment.DriverId} eventId={assignment.QueueEventId}");
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

    // Include Offered shipments: an idle driver should still be matched even
    // if all current shipments are already offered to other drivers.
    var hasAvailableShipments = await db.ShipmentQueues
        .AnyAsync(s => (s.Status == ShipmentQueueStatus.Waiting
                     || s.Status == ShipmentQueueStatus.Offered)
                    && (s.ZoneId == null || s.ZoneId == liveEvent.ZoneId));

    if (hasIdleDrivers && hasAvailableShipments)
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
        // An "offered" shipment is orphaned only when its OfferExpiresAt has passed
        // AND there are no remaining Pending assignments in the assignments table.
        // If another driver's Pending assignment is still live, we must not revert
        // the shipment — their window is still open.
        var activelyAssignedShipmentIds = await db.ShipmentQueueAssignments
            .Where(a => a.Outcome == AssignmentOutcome.Pending)
            .Select(a => a.ShipmentQueueId)
            .Distinct()
            .ToListAsync();

        var reverted = await db.ShipmentQueues
            .Where(q => q.Status == ShipmentQueueStatus.Offered
                     && q.OfferExpiresAt < now
                     && !activelyAssignedShipmentIds.Contains(q.Id))
            .ExecuteUpdateAsync(s => s
                .SetProperty(q => q.Status,          ShipmentQueueStatus.Waiting)
                .SetProperty(q => q.CurrentDriverId, (Guid?)null)
                .SetProperty(q => q.OfferExpiresAt,  (DateTime?)null));

        if (reverted > 0)
            _logger.LogInformation("Reverted {Count} orphaned offered shipments to waiting.", reverted);
    }
}