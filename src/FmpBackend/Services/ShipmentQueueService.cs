using FmpBackend.Data;
using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Services;

public class ShipmentQueueService
{
    private readonly ShipmentQueueRepository       _repo;
    private readonly AppDbContext                  _db;
    private readonly TripService                   _tripService;
    private readonly IHubContext<ShipmentQueueHub> _hub;
    private readonly QueueEventService             _queueEventService;

    public ShipmentQueueService(
        ShipmentQueueRepository       repo,
        AppDbContext                  db,
        TripService                   tripService,
        IHubContext<ShipmentQueueHub> hub,
        QueueEventService             queueEventService)
    {
        _repo               = repo;
        _db                 = db;
        _tripService        = tripService;
        _hub                = hub;
        _queueEventService  = queueEventService;
    }

    // ─── List ────────────────────────────────────────────────────────────────

    public async Task<object> GetWaitingAsync(int page, int pageSize)
    {
        var (items, total) = await _repo.GetWaitingAsync(page, pageSize);
        var totalPages     = (int)Math.Ceiling(total / (double)pageSize);

        return new
        {
            page,
            pageSize,
            total,
            totalPages,
            hasNextPage = page < totalPages,
            hasPrevPage = page > 1,
            items       = items.Select(ToDto).ToList()
        };
    }

    public async Task<ShipmentQueueDto?> GetByIdAsync(Guid id)
    {
        var item = await _repo.GetByIdAsync(id);
        return item == null ? null : ToDto(item);
    }

    // ─── Enqueue ─────────────────────────────────────────────────────────────

    public async Task<ShipmentQueueDto> EnqueueAsync(Guid shipmentId, string? vehicleType, Guid? zoneId)
    {
        var item = new ShipmentQueue
        {
            Id                  = Guid.NewGuid(),
            ShipmentId          = shipmentId,
            RequiredVehicleType = vehicleType,
            ZoneId              = zoneId,
            Status              = ShipmentQueueStatus.Waiting,
            CreatedAt           = DateTime.UtcNow
        };
        await _repo.AddAsync(item);
        var dto = (await GetByIdAsync(item.Id))!;

        // Broadcast new shipment
        await _hub.Clients.All.SendAsync("NewShipmentAvailable", dto);

        // Try to assign this shipment to an idle driver in the live event
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);

        if (activeEvent != null)
        {
            await _queueEventService.AssignOffersAsync(activeEvent);
        }

        return dto;
    }

    // ─── Accept ──────────────────────────────────────────────────────────────

    /// <summary>
    /// Validates that the driver is accepting their currently-offered shipment.
    /// A driver cannot accept a shipment offered to someone else.
    /// </summary>
    public async Task<(Guid? tripId, string? error)> AcceptAsync(Guid queueItemId, Guid driverId)
    {
        Console.WriteLine($"[Accept] ── START queueItemId={queueItemId} driverId={driverId}");

        // Find any vehicle assigned to this driver, regardless of current status.
        // We self-heal the on_trip → available transition here in case the queue
        // self-heal in GetActiveEventForDriverAsync hasn't fired yet (race between
        // the poll cycle and the driver tapping Accept immediately after re-entering).
        var vehicle = await _db.Vehicles
            .FirstOrDefaultAsync(v => v.CurrentDriverId == driverId);
        if (vehicle == null)
            return (null, "No vehicle is assigned to you. Please contact your fleet manager.");

        if (vehicle.AvailabilityStatus == VehicleStatus.OnTrip)
        {
            // Check whether the trip is genuinely still active.
            var hasActiveTrip = await _db.Trips.AnyAsync(t =>
                t.DriverId == driverId &&
                TripStatus.ActiveStatuses.Contains(t.CurrentStatus));

            if (hasActiveTrip)
                return (null, "You already have an active trip in progress.");

            // Trip is done but status wasn't reset — fix it inline so Accept can proceed.
            vehicle.AvailabilityStatus = VehicleStatus.Available;
            // Also reset the driver record in the same save.
            var driverToReset = await _db.Drivers.FindAsync(driverId);
            if (driverToReset != null && driverToReset.AvailabilityStatus == DriverAvailabilityStatus.OnTrip)
                driverToReset.AvailabilityStatus = DriverAvailabilityStatus.Available;
            await _db.SaveChangesAsync();
        }

        if (vehicle.AvailabilityStatus != VehicleStatus.Available)
        {
            Console.WriteLine($"[Accept] REJECTED: vehicle not available — status={vehicle.AvailabilityStatus}");
            return (null, $"Your vehicle is not available (status: {vehicle.AvailabilityStatus}).");
        }
        Console.WriteLine($"[Accept] vehicle ok: id={vehicle.Id} status={vehicle.AvailabilityStatus}");

        var driver = await _db.Drivers.FindAsync(driverId);
        if (driver == null) { Console.WriteLine("[Accept] REJECTED: driver record not found"); return (null, "Driver record not found."); }
        if (driver.CurrentFleetOwnerId == null) { Console.WriteLine("[Accept] REJECTED: driver has no fleet owner"); return (null, "Driver is not assigned to a fleet owner."); }
        Console.WriteLine($"[Accept] driver ok: availabilityStatus={driver.AvailabilityStatus} fleetOwnerId={driver.CurrentFleetOwnerId}");

        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);

        if (activeEvent != null)
        {
            var entry = await _db.DriverQueueEntries
                .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);

            if (entry != null)
            {
                if (entry.HasClaimed)
                    return (null, "You have already claimed a shipment in this queue event.");

                // ── OFFER VALIDATION ──────────────────────────────────────────
                // The driver must only accept the shipment currently offered to them.
                if (entry.CurrentOfferedShipmentQueueId == null)
                    return (null, "You have no active offer. Wait for a shipment to be assigned to you.");

                if (entry.CurrentOfferedShipmentQueueId != queueItemId)
                    return (null, "You can only accept the shipment currently offered to you.");

                Console.WriteLine($"[Accept] entry: offerStatus={entry.OfferStatus} hasClaimed={entry.HasClaimed} currentOfferedId={entry.CurrentOfferedShipmentQueueId}");
                // Allow Pending (active window) AND Expired (Still Claimable — window closed
                // but shipment not yet taken by another driver, per the cascade spec).
                if (entry.OfferStatus != DriverOfferStatus.Pending
                 && entry.OfferStatus != DriverOfferStatus.Expired)
                {
                    Console.WriteLine($"[Accept] REJECTED: offer status not active — {entry.OfferStatus}");
                    return (null, $"Your offer is no longer active (status: {entry.OfferStatus}).");
                }
                Console.WriteLine("[Accept] offer validation PASSED");
            }
        }

        // ── Race-safe accept ──────────────────────────────────────────────────
        var losingDriverIds = new List<Guid>();
        for (int attempt = 0; attempt < 3; attempt++)
        {
            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {
                var queueItem = await _repo.LockForAcceptAsync(queueItemId);
                if (queueItem == null)
                {
                    await tx.RollbackAsync();
                    return (null, "This shipment was already accepted by another driver.");
                }

                queueItem.Status          = ShipmentQueueStatus.Accepted;
                queueItem.CurrentDriverId = driverId;
                await _repo.SaveAsync();

                driver.AvailabilityStatus = DriverAvailabilityStatus.OnTrip;
                await _db.SaveChangesAsync();

                if (activeEvent != null)
                {
                    // Mark driver entry
                    var entry = await _db.DriverQueueEntries
                        .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);
                    if (entry != null)
                    {
                        entry.HasClaimed   = true;
                        entry.OfferStatus  = DriverOfferStatus.Accepted;
                        await _db.SaveChangesAsync();
                    }

                    // Close the winning assignment record
                    var assignment = await _db.ShipmentQueueAssignments
                        .FirstOrDefaultAsync(a => a.QueueEventId    == activeEvent.Id
                                               && a.ShipmentQueueId == queueItemId
                                               && a.DriverId        == driverId
                                               && a.Outcome         == AssignmentOutcome.Pending);
                    if (assignment != null)
                    {
                        assignment.Outcome = AssignmentOutcome.Accepted;
                        await _db.SaveChangesAsync();
                    }

                    // Cancel all OTHER pending assignments on the same shipment.
                    // With parallel offers multiple drivers may hold a Pending assignment
                    // on the same shipment simultaneously.  Once one driver wins, the
                    // others' assignments must be cancelled so their next poll clears
                    // the "Taken" card and re-matches them to a new shipment.
                    var losingAssignments = await _db.ShipmentQueueAssignments
                        .Where(a => a.QueueEventId    == activeEvent.Id
                                 && a.ShipmentQueueId == queueItemId
                                 && a.DriverId        != driverId
                                 && a.Outcome         == AssignmentOutcome.Pending)
                        .ToListAsync();
                    foreach (var loser in losingAssignments)
                        loser.Outcome = AssignmentOutcome.Expired;

                    // Reset those drivers to Idle so AssignOffersAsync can re-match them.
                    losingDriverIds = losingAssignments.Select(a => a.DriverId).ToList();
                    if (losingDriverIds.Any())
                    {
                        var losingEntries = await _db.DriverQueueEntries
                            .Where(e => e.QueueEventId == activeEvent.Id
                                     && losingDriverIds.Contains(e.DriverId)
                                     && e.OfferStatus  == DriverOfferStatus.Pending)
                            .ToListAsync();
                        foreach (var loser in losingEntries)
                        {
                            loser.OfferStatus                   = DriverOfferStatus.Idle;
                            loser.CurrentOfferedShipmentQueueId = null;
                        }
                    }
                    await _db.SaveChangesAsync();
                }

                await tx.CommitAsync();

                var trip = await _tripService.CreateAsync(new CreateTripRequest(
                    ShipmentId:             queueItem.ShipmentId,
                    VehicleId:              vehicle.Id,
                    DriverId:               driverId,
                    AssignedUnionId:        null,
                    AssignedFleetOwnerId:   driver.CurrentFleetOwnerId!.Value,
                    AssignedBy:             null,
                    PlannedStartTime:       null,
                    PlannedEndTime:         null,
                    EstimatedDistanceKm:    null,
                    EstimatedDurationHours: null
                ));

                await _hub.Clients.All.SendAsync("ShipmentAccepted", queueItemId);

                // Re-match any drivers whose pending assignments were just cancelled
                // (those who lost the race) so they get a new offer immediately.
                if (losingDriverIds.Any())
                    await _queueEventService.AssignOffersAsync(activeEvent);

                return (trip.Id, null);
            }
            catch (DbUpdateConcurrencyException) { await tx.RollbackAsync(); }
            catch (Exception ex)
            {
                Console.WriteLine($"[Accept] EXCEPTION on attempt {attempt}: {ex.GetType().Name}: {ex.Message}\n{ex.StackTrace}");
                await tx.RollbackAsync();
                // Don't rethrow — return a clean error tuple so Flutter always
                // receives a 400 response and can reset the Accept button.
                // Rethrowing causes an unhandled 500 which bypasses Flutter's
                // setState(() => _accepting = false) and locks the button forever.
                return (null, $"Server error: {ex.Message}");
            }
        }

        return (null, "Could not complete the request due to a concurrency conflict. Please try again.");
    }

    // ─── Pass ────────────────────────────────────────────────────────────────

    /// <summary>
    /// Driver explicitly passes on their current offer.
    /// The shipment slides to the next available driver.
    /// The passing driver becomes idle (eligible for the next available shipment).
    /// </summary>
    public async Task<(bool success, string? error)> PassAsync(Guid queueItemId, Guid driverId)
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent == null) return (false, "No active queue event.");

        var entry = await _db.DriverQueueEntries
            .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);
        if (entry == null) return (false, "You are not part of this queue event.");

        if (entry.CurrentOfferedShipmentQueueId != queueItemId)
            return (false, "That shipment is not your current offer.");

        // Allow passing from Pending (active window) or Expired (Still Claimable).
        // Drivers in the expired state can still see the card and may choose to pass.
        if (entry.OfferStatus != DriverOfferStatus.Pending
         && entry.OfferStatus != DriverOfferStatus.Expired)
            return (false, $"Offer already resolved (status: {entry.OfferStatus}).");

        // Mark the assignment as passed.
        // When passing from Expired status the worker has already set the assignment
        // outcome to Expired — in that case we don't need another record, just clear
        // the driver entry below.  When passing from Pending we flip it to Passed.
        var assignment = await _db.ShipmentQueueAssignments
            .FirstOrDefaultAsync(a => a.QueueEventId    == activeEvent.Id
                                   && a.ShipmentQueueId == queueItemId
                                   && a.DriverId        == driverId
                                   && (a.Outcome == AssignmentOutcome.Pending
                                    || a.Outcome == AssignmentOutcome.Expired));
        if (assignment != null && assignment.Outcome == AssignmentOutcome.Pending)
        {
            assignment.Outcome = AssignmentOutcome.Passed;
            await _db.SaveChangesAsync();
        }

        // Only revert the shipment to Waiting if no other driver still holds a
        // live Pending assignment on it.  With parallel offers another driver may
        // still be in their active window — reverting would pull the rug out from
        // their offer card.
        var otherPending = await _db.ShipmentQueueAssignments
            .AnyAsync(a => a.ShipmentQueueId == queueItemId
                        && a.DriverId        != driverId
                        && a.Outcome         == AssignmentOutcome.Pending);

        var shipment = await _db.ShipmentQueues.FindAsync(queueItemId);
        if (shipment != null && !otherPending)
        {
            shipment.Status          = ShipmentQueueStatus.Waiting;
            shipment.CurrentDriverId = null;
            shipment.OfferExpiresAt  = null;
            await _db.SaveChangesAsync();
        }

        // Clear driver's current offer so they become idle for the next available shipment
        // Bug 4 fix: reset to Idle (not Passed) so AssignOffersAsync will re-match this driver
        entry.CurrentOfferedShipmentQueueId = null;
        entry.OfferStatus                   = DriverOfferStatus.Idle;
        await _db.SaveChangesAsync();

        // Bug 2 fix: use the injected QueueEventService instead of newing it with null! deps
        await _queueEventService.AssignOffersAsync(activeEvent);

        await _hub.Clients.All.SendAsync("OfferUpdated", driverId);
        return (true, null);
    }

    // ─── Mapping ─────────────────────────────────────────────────────────────

    private static ShipmentQueueDto ToDto(ShipmentQueue q) => new(
        q.Id, q.ShipmentId, q.Shipment.ShipmentNumber, q.ZoneId,
        q.RequiredVehicleType, q.Status, q.CurrentDriverId,
        q.OfferExpiresAt, q.CreatedAt,
        q.Shipment.CargoType, q.Shipment.CargoWeightKg,
        FormatAddress(q.Shipment.PickupAddress),
        FormatAddress(q.Shipment.DropAddress),
        q.Shipment.AgreedPrice, q.Shipment.IsUrgent);

    private static string FormatAddress(Address? a) =>
        a == null ? "Unknown" : $"{a.City}, {a.State}";
}