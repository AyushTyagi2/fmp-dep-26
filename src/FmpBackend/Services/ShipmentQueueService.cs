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

    public ShipmentQueueService(
        ShipmentQueueRepository       repo,
        AppDbContext                  db,
        TripService                   tripService,
        IHubContext<ShipmentQueueHub> hub)
    {
        _repo        = repo;
        _db          = db;
        _tripService = tripService;
        _hub         = hub;
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
            // Resolve circular dep via DI scope — QueueEventService is injected separately
            // to avoid circular dependency; caller (controller) handles this.
            // Signal the hub so the matching worker can pick it up.
            await _hub.Clients.All.SendAsync("NewShipmentQueued", item.Id);
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
        Console.WriteLine($"=== ACCEPT === QueueItemId:{queueItemId} DriverId:{driverId}");

        var vehicle = await _db.Vehicles
            .FirstOrDefaultAsync(v => v.CurrentDriverId == driverId
                                   && v.AvailabilityStatus == VehicleStatus.Available);
        if (vehicle == null) return (null, "No available vehicle assigned to this driver.");

        var driver = await _db.Drivers.FindAsync(driverId);
        if (driver == null) return (null, "Driver record not found.");
        if (driver.CurrentFleetOwnerId == null) return (null, "Driver is not assigned to a fleet owner.");

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

                if (entry.OfferStatus != DriverOfferStatus.Pending)
                    return (null, $"Your offer is no longer active (status: {entry.OfferStatus}).");
            }
        }

        // ── Race-safe accept ──────────────────────────────────────────────────
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

                    // Close the assignment record
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
                return (trip.Id, null);
            }
            catch (DbUpdateConcurrencyException) { await tx.RollbackAsync(); }
            catch (Exception ex)
            {
                Console.WriteLine($"Exception: {ex.Message}\n{ex.StackTrace}");
                await tx.RollbackAsync();
                throw;
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

        if (entry.OfferStatus != DriverOfferStatus.Pending)
            return (false, $"Offer already resolved (status: {entry.OfferStatus}).");

        // Mark the assignment as passed
        var assignment = await _db.ShipmentQueueAssignments
            .FirstOrDefaultAsync(a => a.QueueEventId    == activeEvent.Id
                                   && a.ShipmentQueueId == queueItemId
                                   && a.DriverId        == driverId
                                   && a.Outcome         == AssignmentOutcome.Pending);
        if (assignment != null)
        {
            assignment.Outcome = AssignmentOutcome.Passed;
            await _db.SaveChangesAsync();
        }

        // Revert shipment to waiting so it can be re-offered
        var shipment = await _db.ShipmentQueues.FindAsync(queueItemId);
        if (shipment != null)
        {
            shipment.Status          = ShipmentQueueStatus.Waiting;
            shipment.CurrentDriverId = null;
            shipment.OfferExpiresAt  = null;
            await _db.SaveChangesAsync();
        }

        // Clear driver's current offer so they become idle
        entry.CurrentOfferedShipmentQueueId = null;
        entry.OfferStatus                   = DriverOfferStatus.Passed;
        await _db.SaveChangesAsync();

        // Re-run matching to cascade this shipment to the next driver
        // and potentially assign a new shipment to this driver
        var queueEventService = new QueueEventService(
            null!, null!, null!, _db);   // only AssignOffersAsync uses _db
        await queueEventService.AssignOffersAsync(activeEvent);

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