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
        _repo              = repo;
        _db                = db;
        _tripService       = tripService;
        _hub               = hub;
        _queueEventService = queueEventService;
    }

    // ─── List / GetById (unchanged) ──────────────────────────────────────────

    public async Task<object> GetWaitingAsync(int page, int pageSize)
    {
        var (items, total) = await _repo.GetWaitingAsync(page, pageSize);
        return new
        {
            page, pageSize, total,
            totalPages  = (int)Math.Ceiling(total / (double)pageSize),
            hasNextPage = page < (int)Math.Ceiling(total / (double)pageSize),
            hasPrevPage = page > 1,
            items       = items.Select(ToDto).ToList()
        };
    }

    public async Task<ShipmentQueueDto?> GetByIdAsync(Guid id)
    {
        var item = await _repo.GetByIdAsync(id);
        return item == null ? null : ToDto(item);
    }

    // ─── Enqueue ──────────────────────────────────────────────────────────────

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

        await _hub.Clients.All.SendAsync("NewShipmentAvailable", dto);

        // Rebuild lists so drivers who have no offers get this shipment appended
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent != null)
            await _queueEventService.BuildDriverListsAsync(activeEvent);

        return dto;
    }

    // ─── Accept ───────────────────────────────────────────────────────────────

    public async Task<(Guid? tripId, string? error)> AcceptAsync(Guid queueItemId, Guid driverId)
    {
        Console.WriteLine($"[Accept] queueItemId={queueItemId} driverId={driverId}");

        // Vehicle check (unchanged)
        var vehicle = await _db.Vehicles.FirstOrDefaultAsync(v => v.CurrentDriverId == driverId);
        if (vehicle == null)
            return (null, "No vehicle assigned. Contact your fleet manager.");

        if (vehicle.AvailabilityStatus == VehicleStatus.OnTrip)
        {
            var hasActiveTrip = await _db.Trips.AnyAsync(t =>
                t.DriverId == driverId && TripStatus.ActiveStatuses.Contains(t.CurrentStatus));
            if (hasActiveTrip)
                return (null, "You already have an active trip.");
            vehicle.AvailabilityStatus = VehicleStatus.Available;
            var driverReset = await _db.Drivers.FindAsync(driverId);
            if (driverReset?.AvailabilityStatus == DriverAvailabilityStatus.OnTrip)
                driverReset.AvailabilityStatus = DriverAvailabilityStatus.Available;
            await _db.SaveChangesAsync();
        }

        if (vehicle.AvailabilityStatus != VehicleStatus.Available)
            return (null, $"Vehicle not available (status: {vehicle.AvailabilityStatus}).");

        var driver = await _db.Drivers.FindAsync(driverId);
        if (driver == null)           return (null, "Driver record not found.");
        if (driver.CurrentFleetOwnerId == null) return (null, "Driver has no fleet owner.");

        // Validate via driver's slot — shipment must be within claimable range
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);

        if (activeEvent != null)
        {
            var entry = await _db.DriverQueueEntries
                .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id
                                       && e.DriverId     == driverId);
            if (entry != null)
            {
                if (entry.HasClaimed)
                    return (null, "You have already claimed a shipment in this queue event.");

                // Deserialise list — shipment must be in the claimable range
                var slots = DeserialiseSlots(entry.ShipmentListJson);
                var slotIdx = slots.FindIndex(s => s.ShipmentQueueId == queueItemId);
                if (slotIdx < 0)
                    return (null, "That shipment is not in your offer list.");
                if (slotIdx >= entry.ClaimableCount)
                    return (null, "That shipment's window hasn't opened for you yet.");
                if (slots[slotIdx].IsSkipped)
                    return (null, "You already passed that shipment.");
            }
        }

        // Race-safe accept (same transaction pattern as before)
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

                if (activeEvent != null)
                {
                    var entry = await _db.DriverQueueEntries
                        .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id
                                               && e.DriverId     == driverId);
                    if (entry != null)
                    {
                        entry.HasClaimed = true;
                    }

                    // Close winner's assignment
                    var winnerAssignment = await _db.ShipmentQueueAssignments
                        .FirstOrDefaultAsync(a => a.QueueEventId    == activeEvent.Id
                                               && a.ShipmentQueueId == queueItemId
                                               && a.DriverId        == driverId
                                               && a.Outcome         == AssignmentOutcome.Pending);
                    if (winnerAssignment != null)
                        winnerAssignment.Outcome = AssignmentOutcome.Accepted;

                    // Cancel all other Pending assignments on same shipment
                    var losingAssignments = await _db.ShipmentQueueAssignments
                        .Where(a => a.QueueEventId    == activeEvent.Id
                                 && a.ShipmentQueueId == queueItemId
                                 && a.DriverId        != driverId
                                 && a.Outcome         == AssignmentOutcome.Pending)
                        .ToListAsync();
                    foreach (var l in losingAssignments)
                        l.Outcome = AssignmentOutcome.Expired;
                }

                await _db.SaveChangesAsync();
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

                // Remove accepted shipment from ALL drivers' lists
                if (activeEvent != null)
                    await _queueEventService.OnShipmentAcceptedAsync(activeEvent.Id, queueItemId);

                await _hub.Clients.All.SendAsync("ShipmentAccepted", queueItemId);
                return (trip.Id, null);
            }
            catch (DbUpdateConcurrencyException) { await tx.RollbackAsync(); }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                return (null, $"Server error: {ex.Message}");
            }
        }
        return (null, "Concurrency conflict. Please try again.");
    }

    // ─── Pass ─────────────────────────────────────────────────────────────────

    public async Task<(bool success, string? error)> PassAsync(Guid queueItemId, Guid driverId)
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent == null) return (false, "No active queue event.");

        var entry = await _db.DriverQueueEntries
            .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);
        if (entry == null) return (false, "You are not part of this queue event.");

        var slots = DeserialiseSlots(entry.ShipmentListJson);
        var slotIdx = slots.FindIndex(s => s.ShipmentQueueId == queueItemId);
        if (slotIdx < 0)                      return (false, "That shipment is not in your offer list.");
        if (slotIdx >= entry.ClaimableCount)  return (false, "That shipment's window hasn't opened for you yet.");
        if (slots[slotIdx].IsSkipped)         return (false, "Already passed.");

        // Delegate all mutations to the service (updates lists for driver + next driver)
        await _queueEventService.OnDriverPassedAsync(activeEvent.Id, driverId, queueItemId);

        await _hub.Clients.All.SendAsync("OfferUpdated", driverId);
        return (true, null);
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

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

    private static List<DriverShipmentSlot> DeserialiseSlots(string json)
    {
        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<List<DriverShipmentSlot>>(
                json, new System.Text.Json.JsonSerializerOptions
                    { PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase })
                ?? new();
        }
        catch { return new(); }
    }
}