using FmpBackend.Data;
using FmpBackend.Repositories;
using FmpBackend.Models;
using FmpBackend.Dtos;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Services;

public class QueueEventService
{
    private readonly QueueEventRepository       _queueEventRepo;
    private readonly DriverEligibleRepository   _driverRepo;
    private readonly DriverQueueRepository      _driverQueueRepo;
    private readonly AppDbContext               _db;

    public QueueEventService(
        QueueEventRepository     queueEventRepo,
        DriverEligibleRepository driverRepo,
        DriverQueueRepository    driverQueueRepo,
        AppDbContext             db)
    {
        _queueEventRepo  = queueEventRepo;
        _driverRepo      = driverRepo;
        _driverQueueRepo = driverQueueRepo;
        _db              = db;
    }

    // ─── Create event ────────────────────────────────────────────────────────

    public async Task<QueueEvent> CreateQueueEventAsync(CreateQueueEventRequest request)
    {
        var existing = await _queueEventRepo.GetActiveEventAsync();
        if (existing != null)
            throw new Exception("A queue event is already active.");

        var startTime = DateTime.UtcNow;
        var endTime   = startTime.AddHours(request.DurationHours);

        var queueEvent = new QueueEvent
        {
            Id            = Guid.NewGuid(),
            ZoneId        = request.ZoneId,
            StartTime     = startTime,
            EndTime       = endTime,
            WindowSeconds = request.WindowSeconds,
            Status        = QueueEventStatus.Live
        };

        await _queueEventRepo.CreateAsync(queueEvent);

        // Build driver queue first (position assignment, no sequential windows)
        await GenerateDriverQueue(queueEvent);

        // Then pair drivers ↔ shipments in parallel
        await AssignOffersAsync(queueEvent);

        return queueEvent;
    }

    // ─── Step 1: Build the driver queue (positions only) ────────────────────

    private async Task GenerateDriverQueue(QueueEvent queueEvent)
    {
        var drivers = await _driverRepo.GetEligibleDriversAsync();
        var now     = DateTime.UtcNow;

        var entries = drivers.Select((driver, index) => new DriverQueueEntry
        {
            Id               = Guid.NewGuid(),
            QueueEventId     = queueEvent.Id,
            DriverId         = driver.Id,
            Position         = index + 1,
            // Window spans the entire event duration — drivers are offered one
            // shipment at a time, so the window just guards overall event membership
            ClaimWindowStart = now,
            ClaimWindowEnd   = queueEvent.EndTime,
            HasClaimed       = false,
            OfferStatus      = DriverOfferStatus.Idle
        }).ToList();

        await _driverQueueRepo.AddEntriesAsync(entries);
    }

    // ─── Step 2: Pair drivers ↔ shipments (parallel sliding window) ─────────

    /// <summary>
    /// Core matching algorithm:
    ///   Sort unclaimed shipments by CreatedAt (oldest first).
    ///   Sort available drivers by Position.
    ///   Pair them N:N simultaneously.
    ///   Create a ShipmentQueueAssignment per pair and set window timers.
    /// 
    /// Called on event start AND whenever a new shipment enters the queue
    /// mid-event (to pick up any driver that currently has no offer).
    /// </summary>
    public async Task AssignOffersAsync(QueueEvent queueEvent)
    {
        // Drivers without a current pending offer, ordered by position
        var idleDriverEntries = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEvent.Id
                     && !e.HasClaimed
                     && (e.OfferStatus == DriverOfferStatus.Idle
                      || e.OfferStatus == DriverOfferStatus.Passed
                      || e.OfferStatus == DriverOfferStatus.Expired))
            .OrderBy(e => e.Position)
            .ToListAsync();

        if (!idleDriverEntries.Any()) return;

        // Shipments not yet in a pending assignment for this event
        var pendingShipmentIds = await _db.ShipmentQueueAssignments
            .Where(a => a.QueueEventId == queueEvent.Id && a.Outcome == AssignmentOutcome.Pending)
            .Select(a => a.ShipmentQueueId)
            .ToListAsync();

        var availableShipments = await _db.ShipmentQueues
            .Where(s => s.Status == ShipmentQueueStatus.Waiting
                     && !pendingShipmentIds.Contains(s.Id)
                     && (s.ZoneId == null || s.ZoneId == queueEvent.ZoneId))
            .OrderBy(s => s.CreatedAt)
            .ToListAsync();

        if (!availableShipments.Any()) return;

        // Build a lookup of (driverId, shipmentQueueId) pairs that have already
        // been offered and rejected/expired.  A shipment cascades to the next
        // driver in position order, but if EVERY eligible driver has already
        // passed/expired on a shipment it gets re-circulated from the top so
        // it is never permanently stuck.
        var allHistory = await _db.ShipmentQueueAssignments
            .Where(a => a.QueueEventId == queueEvent.Id
                     && (a.Outcome == AssignmentOutcome.Passed
                      || a.Outcome == AssignmentOutcome.Expired))
            .Select(a => new { a.DriverId, a.ShipmentQueueId })
            .ToListAsync();

        // Per-shipment: set of driver IDs that have already rejected it
        var rejectedByShipment = allHistory
            .GroupBy(p => p.ShipmentQueueId)
            .ToDictionary(g => g.Key, g => g.Select(p => p.DriverId).ToHashSet());

        // All eligible (non-claimed) driver IDs in this event
        var allEligibleDriverIds = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEvent.Id && !e.HasClaimed)
            .Select(e => e.DriverId)
            .ToListAsync();

        // A shipment is "exhausted" only if every eligible driver has already
        // passed/expired on it — in that case, reset its rejection history so
        // it re-circulates from the top of the queue.
        var exhaustedShipmentIds = rejectedByShipment
            .Where(kv => allEligibleDriverIds.All(id => kv.Value.Contains(id)))
            .Select(kv => kv.Key)
            .ToHashSet();

        // For exhausted shipments, clear their history so they are re-offerable
        if (exhaustedShipmentIds.Any())
        {
            var staleRecords = await _db.ShipmentQueueAssignments
                .Where(a => a.QueueEventId == queueEvent.Id
                         && exhaustedShipmentIds.Contains(a.ShipmentQueueId)
                         && (a.Outcome == AssignmentOutcome.Passed
                          || a.Outcome == AssignmentOutcome.Expired))
                .ToListAsync();
            _db.ShipmentQueueAssignments.RemoveRange(staleRecords);
            await _db.SaveChangesAsync();

            // Rebuild without the exhausted entries
            allHistory = allHistory
                .Where(p => !exhaustedShipmentIds.Contains(p.ShipmentQueueId))
                .ToList();
            foreach (var id in exhaustedShipmentIds)
                rejectedByShipment.Remove(id);
        }

        var seenSet = allHistory
            .Select(p => (p.DriverId, p.ShipmentQueueId))
            .ToHashSet();

        var now        = DateTime.UtcNow;
        var expiresAt  = now.AddSeconds(queueEvent.WindowSeconds);
        var newAssignments = new List<ShipmentQueueAssignment>();

        // Track which shipments have been matched in this pass so we don't
        // double-assign the same shipment to two drivers.
        var matchedShipmentIds = new HashSet<Guid>();

        foreach (var entry in idleDriverEntries)
        {
            // Find the oldest waiting shipment this driver hasn't already
            // passed on or let expire.
            var shipment = availableShipments.FirstOrDefault(s =>
                !matchedShipmentIds.Contains(s.Id) &&
                !seenSet.Contains((entry.DriverId, s.Id)));

            if (shipment == null) continue; // no eligible shipment for this driver right now

            matchedShipmentIds.Add(shipment.Id);

            // Mark the driver as having a pending offer
            entry.CurrentOfferedShipmentQueueId = shipment.Id;
            entry.OfferStatus                   = DriverOfferStatus.Pending;

            // Mark the shipment as offered
            shipment.Status          = ShipmentQueueStatus.Offered;
            shipment.CurrentDriverId = entry.DriverId;
            shipment.OfferExpiresAt  = expiresAt;

            newAssignments.Add(new ShipmentQueueAssignment
            {
                Id              = Guid.NewGuid(),
                QueueEventId    = queueEvent.Id,
                ShipmentQueueId = shipment.Id,
                DriverId        = entry.DriverId,
                DriverPosition  = entry.Position,
                OfferedAt       = now,
                ExpiresAt       = expiresAt,
                Outcome         = AssignmentOutcome.Pending
            });
        }

        if (newAssignments.Any())
        {
            _db.ShipmentQueueAssignments.AddRange(newAssignments);
            await _db.SaveChangesAsync();
        }
    }

    // ─── GET active event slot for a driver ──────────────────────────────────

    public async Task<ActiveEventDto?> GetActiveEventForDriverAsync(Guid driverId)
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);

        if (activeEvent == null) return null;

        var entry = await _db.DriverQueueEntries
            .Include(e => e.CurrentOfferedShipment)
                .ThenInclude(s => s!.Shipment)
                    .ThenInclude(s => s.PickupAddress)
            .Include(e => e.CurrentOfferedShipment)
                .ThenInclude(s => s!.Shipment)
                    .ThenInclude(s => s.DropAddress)
            .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id
                                   && e.DriverId == driverId);

        if (entry == null) return null;

        // ── Self-heal: if the entry says "accepted" but the driver has no
        //    active trip (they finished it), reset to idle so they can
        //    participate in the queue again without waiting for a restart.
        if (entry.OfferStatus == DriverOfferStatus.Accepted || entry.HasClaimed)
        {
            var hasActiveTrip = await _db.Trips.AnyAsync(t =>
                t.DriverId == driverId &&
                TripStatus.ActiveStatuses.Contains(t.CurrentStatus));

            if (!hasActiveTrip)
            {
                entry.OfferStatus  = DriverOfferStatus.Idle;
                entry.HasClaimed   = false;
                entry.CurrentOfferedShipmentQueueId = null;
                await _db.SaveChangesAsync();

                // ── Immediately try to match this now-idle driver with a
                //    waiting shipment. Without this call the driver would sit
                //    on "Waiting for offer" indefinitely until the background
                //    worker next fires, even though shipments may be queued.
                await AssignOffersAsync(activeEvent);

                // Re-fetch the entry so the offer fields reflect the new match.
                entry = await _db.DriverQueueEntries
                    .Include(e => e.CurrentOfferedShipment)
                        .ThenInclude(s => s!.Shipment)
                            .ThenInclude(s => s.PickupAddress)
                    .Include(e => e.CurrentOfferedShipment)
                        .ThenInclude(s => s!.Shipment)
                            .ThenInclude(s => s.DropAddress)
                    .FirstAsync(e => e.QueueEventId == activeEvent.Id
                                  && e.DriverId == driverId);
            }
        }

        // ── Self-heal: if the pending offer has already expired (background
        //    worker hasn't cleaned it up yet), mark it expired and re-match
        //    immediately so the driver doesn't see a permanently-expired card.
        if (entry.OfferStatus == DriverOfferStatus.Pending
         && entry.CurrentOfferedShipment?.OfferExpiresAt != null
         && entry.CurrentOfferedShipment.OfferExpiresAt < DateTime.UtcNow)
        {
            var staleShipment = entry.CurrentOfferedShipment;
            entry.OfferStatus                   = DriverOfferStatus.Expired;
            entry.CurrentOfferedShipmentQueueId = null;
            staleShipment.Status                = ShipmentQueueStatus.Waiting;
            staleShipment.CurrentDriverId       = null;
            staleShipment.OfferExpiresAt        = null;
            await _db.SaveChangesAsync();

            await AssignOffersAsync(activeEvent);

            entry = await _db.DriverQueueEntries
                .Include(e => e.CurrentOfferedShipment)
                    .ThenInclude(s => s!.Shipment)
                        .ThenInclude(s => s.PickupAddress)
                .Include(e => e.CurrentOfferedShipment)
                    .ThenInclude(s => s!.Shipment)
                        .ThenInclude(s => s.DropAddress)
                .FirstAsync(e => e.QueueEventId == activeEvent.Id
                              && e.DriverId == driverId);
        }

        // ── Self-heal: driver is idle/passed/expired with no pending offer.
        //    Try to match them immediately so they don't wait up to 30s for
        //    the background worker when a shipment is already waiting.
        if (entry.CurrentOfferedShipmentQueueId == null
         && (entry.OfferStatus == DriverOfferStatus.Idle
          || entry.OfferStatus == DriverOfferStatus.Passed
          || entry.OfferStatus == DriverOfferStatus.Expired)
         && !entry.HasClaimed)
        {
            await AssignOffersAsync(activeEvent);

            entry = await _db.DriverQueueEntries
                .Include(e => e.CurrentOfferedShipment)
                    .ThenInclude(s => s!.Shipment)
                        .ThenInclude(s => s.PickupAddress)
                .Include(e => e.CurrentOfferedShipment)
                    .ThenInclude(s => s!.Shipment)
                        .ThenInclude(s => s.DropAddress)
                .FirstAsync(e => e.QueueEventId == activeEvent.Id
                              && e.DriverId == driverId);
        }

        CurrentOfferDto? currentOffer = null;
        if (entry.CurrentOfferedShipmentQueueId != null
         && entry.OfferStatus == DriverOfferStatus.Pending
         && entry.CurrentOfferedShipment != null)
        {
            var sq = entry.CurrentOfferedShipment;
            currentOffer = new CurrentOfferDto(
                ShipmentQueueId : sq.Id,
                ShipmentId      : sq.ShipmentId,
                ShipmentNumber  : sq.Shipment.ShipmentNumber,
                PickupLocation  : FormatAddress(sq.Shipment.PickupAddress),
                DropLocation    : FormatAddress(sq.Shipment.DropAddress),
                CargoType       : sq.Shipment.CargoType,
                CargoWeightKg   : sq.Shipment.CargoWeightKg,
                AgreedPrice     : sq.Shipment.AgreedPrice,
                IsUrgent        : sq.Shipment.IsUrgent,
                ExpiresAt       : sq.OfferExpiresAt
            );
        }

        return new ActiveEventDto(
            Active          : true,
            EventId         : activeEvent.Id,
            EventStatus     : activeEvent.Status,
            EventEndTime    : activeEvent.EndTime,
            Position        : entry.Position,
            HasClaimed      : entry.HasClaimed,
            OfferStatus     : entry.OfferStatus,
            CurrentOffer    : currentOffer
        );
    }

    private static string FormatAddress(Address? a) =>
        a == null ? "Unknown" : $"{a.City}, {a.State}";


    public async Task<object> ReassignOffersAsync()
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent != null)
        {
            await AssignOffersAsync(activeEvent);
        }
        if (activeEvent == null) return new { message = "No active event" };
        await AssignOffersAsync(activeEvent);
        return new { message = "Offers reassigned" };
    }

    // ─── GET live status (for Flutter to poll) ───────────────────────────────

    public async Task<object> GetLiveStatusAsync()
    {
        var activeEvent = await _db.QueueEvents
            .Where(e => e.Status == QueueEventStatus.Live && e.EndTime > DateTime.UtcNow)
            .OrderByDescending(e => e.StartTime)
            .FirstOrDefaultAsync();

        if (activeEvent == null)
            return new { isLive = false, eventId = (Guid?)null, endTime = (DateTime?)null };

        return new
        {
            isLive  = true,
            eventId = (Guid?)activeEvent.Id,
            endTime = (DateTime?)activeEvent.EndTime
        };
    }

    // ─── TOGGLE queue event live / closed ────────────────────────────────────

    public async Task<object?> ToggleQueueEventAsync(Guid id)
    {
        var queueEvent = await _db.QueueEvents.FindAsync(id);
        if (queueEvent == null) return null;

        if (queueEvent.Status == QueueEventStatus.Live)
        {
            queueEvent.Status = QueueEventStatus.Closed;
        }
        else
        {
            // Re-open: extend end time to 2 hours from now if it has passed
            if (queueEvent.EndTime <= DateTime.UtcNow)
                queueEvent.EndTime = DateTime.UtcNow.AddHours(2);
            queueEvent.Status = QueueEventStatus.Live;
            // Re-assign offers for any waiting shipments
            await AssignOffersAsync(queueEvent);
        }

        await _db.SaveChangesAsync();

        return new
        {
            eventId = queueEvent.Id,
            status  = queueEvent.Status,
            endTime = queueEvent.EndTime
        };
    }

}