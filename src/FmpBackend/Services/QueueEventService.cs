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
        Console.WriteLine($"[AssignOffers] ── START eventId={queueEvent.Id}");

        // Drivers without a current pending offer, ordered by position.
        // Exclude Expired drivers who still hold a CurrentOfferedShipmentQueueId —
        // their offer card is still showing ("Still Claimable") and they should NOT
        // be re-matched to a new shipment until they pass, accept, or someone else
        // accepts the same shipment (which clears their entry via the accept path).
        var idleDriverEntries = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEvent.Id
                     && !e.HasClaimed
                     && (e.OfferStatus == DriverOfferStatus.Idle
                      || e.OfferStatus == DriverOfferStatus.Passed
                      || (e.OfferStatus == DriverOfferStatus.Expired
                          && e.CurrentOfferedShipmentQueueId == null)))
            .OrderBy(e => e.Position)
            .ToListAsync();

        Console.WriteLine($"[AssignOffers] idleDriverEntries count={idleDriverEntries.Count}");
        foreach (var d in idleDriverEntries)
            Console.WriteLine($"[AssignOffers]   driver pos={d.Position} id={d.DriverId} status={d.OfferStatus} currentOfferedId={d.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");

        if (!idleDriverEntries.Any())
        {
            Console.WriteLine("[AssignOffers] No idle drivers → returning early");
            return;
        }

        // Shipments not yet in a pending assignment for this event
        var pendingShipmentIds = await _db.ShipmentQueueAssignments
            .Where(a => a.QueueEventId == queueEvent.Id && a.Outcome == AssignmentOutcome.Pending)
            .Select(a => a.ShipmentQueueId)
            .ToListAsync();

        // Include both Waiting AND Offered shipments.
        // The pendingShipmentIds exclusion (built from the assignments table) is the
        // real guard against duplicate assignments: a shipment already assigned to
        // *this* driver in a Pending assignment will be in pendingShipmentIds and is
        // excluded, but a shipment currently Offered to a *different* driver is still
        // eligible so that idle driver #1 is never starved when all shipments happen
        // to be in the Offered state (e.g. assigned to drivers 2, 3, 4 in a prior pass).
        var availableShipments = await _db.ShipmentQueues
            .Where(s => (s.Status == ShipmentQueueStatus.Waiting
                      || s.Status == ShipmentQueueStatus.Offered)
                     && !pendingShipmentIds.Contains(s.Id)
                     && (s.ZoneId == null || s.ZoneId == queueEvent.ZoneId))
            .OrderBy(s => s.CreatedAt)
            .ToListAsync();

        Console.WriteLine($"[AssignOffers] pendingShipmentIds (already assigned)={string.Join(",", pendingShipmentIds)}");
        Console.WriteLine($"[AssignOffers] availableShipments count={availableShipments.Count}");
        foreach (var s in availableShipments)
            Console.WriteLine($"[AssignOffers]   shipment id={s.Id} status={s.Status} currentDriverId={s.CurrentDriverId?.ToString() ?? "NULL"} expiresAt={s.OfferExpiresAt?.ToString("O") ?? "NULL"}");

        if (!availableShipments.Any())
        {
            Console.WriteLine("[AssignOffers] No available shipments → returning early");
            return;
        }

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

            // ── Per-driver exhaustion fallback ────────────────────────────────
            // If this driver has already seen every available shipment (all blocked
            // by seenSet), re-offer the oldest one that isn't already matched this
            // pass.  This prevents a driver from being permanently stuck when all
            // shipments have cycled through and none is "new" to them.
            if (shipment == null)
            {
                var blockedByMatched = availableShipments.Where(s => matchedShipmentIds.Contains(s.Id)).Select(s => s.Id.ToString()).ToList();
                var blockedBySeen    = availableShipments.Where(s => seenSet.Contains((entry.DriverId, s.Id))).Select(s => s.Id.ToString()).ToList();
                Console.WriteLine($"[AssignOffers] driver pos={entry.Position} id={entry.DriverId}: no fresh shipment — alreadyMatchedThisPass=[{string.Join(",", blockedByMatched)}] seenByDriver=[{string.Join(",", blockedBySeen)}] totalAvailable={availableShipments.Count}");

                // All available shipments have been seen by this driver.
                // Re-offer the oldest one not already matched this pass.
                shipment = availableShipments.FirstOrDefault(s => !matchedShipmentIds.Contains(s.Id));
                if (shipment == null)
                {
                    Console.WriteLine($"[AssignOffers] driver pos={entry.Position} id={entry.DriverId}: all shipments matched this pass — skipping");
                    continue;
                }

                // Clear the stale history records for this driver+shipment pair so
                // the new assignment isn't immediately blocked by the old seenSet.
                var staleForDriver = await _db.ShipmentQueueAssignments
                    .Where(a => a.QueueEventId    == queueEvent.Id
                             && a.DriverId        == entry.DriverId
                             && a.ShipmentQueueId == shipment.Id
                             && (a.Outcome == AssignmentOutcome.Passed
                              || a.Outcome == AssignmentOutcome.Expired))
                    .ToListAsync();
                if (staleForDriver.Any())
                {
                    _db.ShipmentQueueAssignments.RemoveRange(staleForDriver);
                    await _db.SaveChangesAsync();
                    Console.WriteLine($"[AssignOffers] driver pos={entry.Position} id={entry.DriverId}: cleared {staleForDriver.Count} stale history records for shipment={shipment.Id} — re-offering");
                }
            }
            Console.WriteLine($"[AssignOffers] driver pos={entry.Position} id={entry.DriverId}: MATCHED shipment={shipment.Id} status={shipment.Status}");

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
        Console.WriteLine($"[GetActiveSlot] ── START driverId={driverId} utcNow={DateTime.UtcNow:O}");

        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);

        if (activeEvent == null)
        {
            Console.WriteLine("[GetActiveSlot] No live event found → returning null");
            return null;
        }
        Console.WriteLine($"[GetActiveSlot] Event found: id={activeEvent.Id} endTime={activeEvent.EndTime:O}");

        var entry = await _db.DriverQueueEntries
            .Include(e => e.CurrentOfferedShipment)
                .ThenInclude(s => s!.Shipment)
                    .ThenInclude(s => s.PickupAddress)
            .Include(e => e.CurrentOfferedShipment)
                .ThenInclude(s => s!.Shipment)
                    .ThenInclude(s => s.DropAddress)
            .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id
                                   && e.DriverId == driverId);

        if (entry == null)
        {
            Console.WriteLine("[GetActiveSlot] No DriverQueueEntry found for this driver in the event → returning null");
            return null;
        }

        Console.WriteLine($"[GetActiveSlot] Entry loaded: pos={entry.Position} offerStatus={entry.OfferStatus} hasClaimed={entry.HasClaimed} currentOfferedShipmentQueueId={entry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");
        Console.WriteLine($"[GetActiveSlot] CurrentOfferedShipment null? {entry.CurrentOfferedShipment == null}");
        if (entry.CurrentOfferedShipment != null)
            Console.WriteLine($"[GetActiveSlot]   → shipment status={entry.CurrentOfferedShipment.Status} offerExpiresAt={entry.CurrentOfferedShipment.OfferExpiresAt?.ToString("O") ?? "NULL"} currentDriverId={entry.CurrentOfferedShipment.CurrentDriverId?.ToString() ?? "NULL"}");

        // ── Self-heal: if the entry says "accepted" but the driver has no
        //    active trip (they finished it), reset to idle so they can
        //    participate in the queue again without waiting for a restart.
        if (entry.OfferStatus == DriverOfferStatus.Accepted || entry.HasClaimed)
        {
            Console.WriteLine("[GetActiveSlot] SELF-HEAL-1: entry is Accepted/HasClaimed — checking for active trip");
            var hasActiveTrip = await _db.Trips.AnyAsync(t =>
                t.DriverId == driverId &&
                TripStatus.ActiveStatuses.Contains(t.CurrentStatus));

            Console.WriteLine($"[GetActiveSlot] SELF-HEAL-1: hasActiveTrip={hasActiveTrip}");
            if (!hasActiveTrip)
            {
                Console.WriteLine("[GetActiveSlot] SELF-HEAL-1: no active trip → resetting entry to Idle");
                entry.OfferStatus  = DriverOfferStatus.Idle;
                entry.HasClaimed   = false;
                entry.CurrentOfferedShipmentQueueId = null;

                var driver = await _db.Drivers.FindAsync(driverId);
                Console.WriteLine($"[GetActiveSlot] SELF-HEAL-1: driver.AvailabilityStatus={driver?.AvailabilityStatus ?? "NULL"}");
                if (driver != null && driver.AvailabilityStatus == DriverAvailabilityStatus.OnTrip)
                {
                    driver.AvailabilityStatus = DriverAvailabilityStatus.Available;
                    Console.WriteLine("[GetActiveSlot] SELF-HEAL-1: reset driver → Available");
                }

                var vehicle = await _db.Vehicles
                    .FirstOrDefaultAsync(v => v.CurrentDriverId == driverId
                                           && v.AvailabilityStatus == VehicleStatus.OnTrip);
                Console.WriteLine($"[GetActiveSlot] SELF-HEAL-1: vehicle found with OnTrip? {vehicle != null}");
                if (vehicle != null)
                {
                    vehicle.AvailabilityStatus = VehicleStatus.Available;
                    Console.WriteLine("[GetActiveSlot] SELF-HEAL-1: reset vehicle → Available");
                }

                await _db.SaveChangesAsync();
                Console.WriteLine("[GetActiveSlot] SELF-HEAL-1: saved — calling AssignOffersAsync");
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
                Console.WriteLine($"[GetActiveSlot] SELF-HEAL-1: re-fetched entry: offerStatus={entry.OfferStatus} currentOfferedShipmentQueueId={entry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");
            }
        }

        // ── Self-heal: if the pending offer has already expired (background
        //    worker hasn't cleaned it up yet), flip to Expired so the Flutter
        //    card shows the "Still Claimable" amber state.
        if (entry.OfferStatus == DriverOfferStatus.Pending
         && entry.CurrentOfferedShipment?.OfferExpiresAt != null
         && entry.CurrentOfferedShipment.OfferExpiresAt < DateTime.UtcNow)
        {
            Console.WriteLine($"[GetActiveSlot] SELF-HEAL-2: Pending offer expired (expiresAt={entry.CurrentOfferedShipment.OfferExpiresAt:O}) → flipping to Expired, keeping shipment ref");
            entry.OfferStatus = DriverOfferStatus.Expired;
            await _db.SaveChangesAsync();
            Console.WriteLine("[GetActiveSlot] SELF-HEAL-2: saved");
        }

        // ── Self-heal: driver is idle/passed/expired with no pending offer.
        if (entry.CurrentOfferedShipmentQueueId == null
         && (entry.OfferStatus == DriverOfferStatus.Idle
          || entry.OfferStatus == DriverOfferStatus.Passed
          || entry.OfferStatus == DriverOfferStatus.Expired)
         && !entry.HasClaimed)
        {
            Console.WriteLine($"[GetActiveSlot] SELF-HEAL-3: driver has no offer (status={entry.OfferStatus}, currentOfferedShipmentQueueId=NULL) → calling AssignOffersAsync");
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
            Console.WriteLine($"[GetActiveSlot] SELF-HEAL-3: re-fetched: offerStatus={entry.OfferStatus} currentOfferedShipmentQueueId={entry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"}");
        }

        // ── Build currentOffer DTO ───────────────────────────────────────────
        Console.WriteLine($"[GetActiveSlot] BUILD-OFFER check: currentOfferedShipmentQueueId={entry.CurrentOfferedShipmentQueueId?.ToString() ?? "NULL"} offerStatus={entry.OfferStatus} currentOfferedShipment null?={entry.CurrentOfferedShipment == null}");

        CurrentOfferDto? currentOffer = null;
        if (entry.CurrentOfferedShipmentQueueId != null
         && (entry.OfferStatus == DriverOfferStatus.Pending || entry.OfferStatus == DriverOfferStatus.Expired)
         && entry.CurrentOfferedShipment != null)
        {
            var sq = entry.CurrentOfferedShipment;
            Console.WriteLine($"[GetActiveSlot] BUILD-OFFER: building DTO for shipment={sq.Id} status={sq.Status} expiresAt={sq.OfferExpiresAt?.ToString("O") ?? "NULL"}");
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
        else
        {
            Console.WriteLine($"[GetActiveSlot] BUILD-OFFER: SKIPPED — currentOffer will be NULL. Reasons: hasShipmentQueueId={entry.CurrentOfferedShipmentQueueId != null}, statusOk={(entry.OfferStatus == DriverOfferStatus.Pending || entry.OfferStatus == DriverOfferStatus.Expired)}, hasNavProp={entry.CurrentOfferedShipment != null}");
        }

        var upcoming = await _db.ShipmentQueues
    .Include(s => s.Shipment).ThenInclude(s => s.PickupAddress)
    .Include(s => s.Shipment).ThenInclude(s => s.DropAddress)
    .Where(s => s.Status == ShipmentQueueStatus.Waiting
             || s.Status == ShipmentQueueStatus.Offered)
    .Where(s => s.Id != entry.CurrentOfferedShipmentQueueId)
    .OrderBy(s => s.CreatedAt)
    .Take(3)
    .Select(s => new UpcomingShipmentDto(
        s.Id, s.Shipment.ShipmentNumber,
        FormatAddress(s.Shipment.PickupAddress),
        FormatAddress(s.Shipment.DropAddress),
        s.Shipment.AgreedPrice, s.Shipment.IsUrgent))
    .ToListAsync();

        Console.WriteLine($"[GetActiveSlot] RESPONSE: offerStatus={entry.OfferStatus} currentOffer={( currentOffer == null ? "NULL" : currentOffer.ShipmentQueueId.ToString())} upcoming={upcoming.Count}");
        Console.WriteLine($"[GetActiveSlot] ── END");

        return new ActiveEventDto(
            Active          : true,
            EventId         : activeEvent.Id,
            EventStatus     : activeEvent.Status,
            EventEndTime    : activeEvent.EndTime,
            Position        : entry.Position,
            HasClaimed      : entry.HasClaimed,
            OfferStatus     : entry.OfferStatus,
            CurrentOffer    : currentOffer,
            UpcomingShipments : upcoming
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
    // Fetch the most recent event regardless of status
    var activeEvent = await _db.QueueEvents
        .OrderByDescending(e => e.StartTime)
        .FirstOrDefaultAsync();

    if (activeEvent == null)
        return new { isLive = false, eventId = (Guid?)null, endTime = (DateTime?)null };

    return new
    {
        isLive  = activeEvent.Status == QueueEventStatus.Live && activeEvent.EndTime > DateTime.UtcNow,
        eventId = (Guid?)activeEvent.Id,   // ← always returned, even when offline
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