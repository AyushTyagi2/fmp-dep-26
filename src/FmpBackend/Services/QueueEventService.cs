using FmpBackend.Data;
using FmpBackend.Repositories;
using FmpBackend.Models;
using FmpBackend.Dtos;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace FmpBackend.Services;

public class QueueEventService
{
    private readonly QueueEventRepository       _queueEventRepo;
    private readonly DriverEligibleRepository   _driverRepo;
    private readonly DriverQueueRepository      _driverQueueRepo;
    private readonly AppDbContext               _db;

    private static readonly JsonSerializerOptions _json =
        new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

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

    // ─── Create event ─────────────────────────────────────────────────────────

    public async Task<(QueueEvent? Event, string? ConflictMessage)> CreateQueueEventAsync(CreateQueueEventRequest request)
    {
        var existing = await _queueEventRepo.GetActiveEventAsync();
        if (existing != null)
            return (null, "A queue event is already active.");

        var startTime = DateTime.UtcNow;
        var queueEvent = new QueueEvent
        {
            Id            = Guid.NewGuid(),
            ZoneId        = request.ZoneId,
            StartTime     = startTime,
            EndTime       = startTime.AddHours(request.DurationHours),
            WindowSeconds = request.WindowSeconds,
            Status        = QueueEventStatus.Live,
            PriorityRule  = request.PriorityRule ?? "highest_trips"
        };
        await _queueEventRepo.CreateAsync(queueEvent);

        // 1. Assign positions to all eligible drivers
        await GenerateDriverQueue(queueEvent);

        // 2. Build each driver's initial shipment list and open first windows
        await BuildDriverListsAsync(queueEvent);

        return (queueEvent, null);
    }

    // ─── Step 1: Assign positions ─────────────────────────────────────────────

    private async Task GenerateDriverQueue(QueueEvent queueEvent)
    {
        var drivers = await _driverRepo.GetEligibleDriversAsync(queueEvent.PriorityRule);
        var now     = DateTime.UtcNow;

        var entries = drivers.Select((driver, i) => new DriverQueueEntry
        {
            Id               = Guid.NewGuid(),
            QueueEventId     = queueEvent.Id,
            DriverId         = driver.Id,
            Position         = i + 1,
            ClaimWindowStart = now,
            ClaimWindowEnd   = queueEvent.EndTime,
            HasClaimed       = false,
            ShipmentListJson = "[]",
            ClaimableCount   = 0
        }).ToList();

        await _driverQueueRepo.AddEntriesAsync(entries);
    }

    // ─── Step 2: Build / rebuild every driver's shipment list ────────────────
    //
    // Called on:  event start, new shipment enqueued, re-open event.
    // NOT called on: window expiry, accept, pass — those use targeted mutations.
    //
    // Algorithm:
    //   Fetch all unaccepted shipments ordered by CreatedAt.
    //   For each driver, build their slot array from those shipments.
    //   Preserve any existing per-slot state (IsExpired, IsSkipped, ExpiresAt)
    //   that was set by a previous mutation — merge rather than reset.
    //   Set ClaimableCount = 1 for position-1 driver (their first window is live),
    //   0 for everyone else unless they already had a higher count.

    public async Task BuildDriverListsAsync(QueueEvent queueEvent)
    {
        Console.WriteLine($"[BuildLists] START eventId={queueEvent.Id}");

        var shipments = await GetActiveShipmentsAsync(queueEvent);
        if (!shipments.Any())
        {
            Console.WriteLine("[BuildLists] no shipments → nothing to do");
            return;
        }

        var entries = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEvent.Id && !e.HasClaimed)
            .OrderBy(e => e.Position)
            .ToListAsync();

        if (!entries.Any()) { Console.WriteLine("[BuildLists] no entries"); return; }

        var now = DateTime.UtcNow;

        foreach (var entry in entries)
        {
            // Deserialise existing slot state so we can preserve mutations
            var existingSlots = DeserialiseSlots(entry.ShipmentListJson)
                .ToDictionary(s => s.ShipmentQueueId);

            var slots = shipments.Select(sq =>
            {
                if (existingSlots.TryGetValue(sq.Id, out var existing))
                    return existing;   // preserve IsExpired / IsSkipped / ExpiresAt

                return new DriverShipmentSlot
                {
                    ShipmentQueueId = sq.Id,
                    ExpiresAt       = null,
                    IsExpired       = false,
                    IsSkipped       = false
                };
            }).ToList();

            // For position-1 driver: if count is still 0, open first window
            if (entry.Position == 1 && entry.ClaimableCount == 0 && slots.Any())
            {
                var firstActive = slots.First(s => !s.IsSkipped && !s.IsExpired);
                firstActive.ExpiresAt = now.AddSeconds(queueEvent.WindowSeconds);
                entry.ClaimableCount  = 1;

                // Create the first assignment record so the worker can fire on expiry
                await CreateAssignmentAsync(queueEvent, entry, firstActive);
            }

            entry.ShipmentListJson = SerialiseSlots(slots);
            Console.WriteLine($"[BuildLists] driver pos={entry.Position} slots={slots.Count} claimable={entry.ClaimableCount}");
        }

        await _db.SaveChangesAsync();
        Console.WriteLine("[BuildLists] END");
    }

    // ─── Window expired: called by worker ────────────────────────────────────
    //
    // The worker found a ShipmentQueueAssignment with Outcome=Pending, ExpiresAt<now.
    // It calls this to perform the state mutation on both affected driver entries.

    public async Task OnWindowExpiredAsync(ShipmentQueueAssignment assignment)
    {
        Console.WriteLine($"[OnWindowExpired] assignmentId={assignment.Id} driver={assignment.DriverId} shipment={assignment.ShipmentQueueId}");

        var activeEvent = await _db.QueueEvents.FindAsync(assignment.QueueEventId);
        if (activeEvent == null) return;

        var shipments = await GetActiveShipmentsAsync(activeEvent);

        // ── 1. Update the driver whose window just expired ───────────────────
        var entry = await _db.DriverQueueEntries
            .FirstOrDefaultAsync(e => e.QueueEventId == assignment.QueueEventId
                                   && e.DriverId     == assignment.DriverId);
        if (entry == null) return;

        var slots = DeserialiseSlots(entry.ShipmentListJson);
        var expiredSlot = slots.FirstOrDefault(s => s.ShipmentQueueId == assignment.ShipmentQueueId);
        if (expiredSlot != null)
        {
            expiredSlot.IsExpired = true;
            expiredSlot.ExpiresAt = null;   // countdown gone, amber card
        }

        // Open the next unclaimable, un-skipped shipment for this driver
        var nextSlot = slots
            .Skip(entry.ClaimableCount)
            .FirstOrDefault(s => !s.IsSkipped);

        if (nextSlot != null)
        {
            nextSlot.ExpiresAt    = DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds);
            entry.ClaimableCount += 1;
            await CreateAssignmentAsync(activeEvent, entry, nextSlot);
        }

        entry.ShipmentListJson = SerialiseSlots(slots);

        // ── 2. Open the same shipment for the NEXT driver in position order ──
        var nextEntry = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == assignment.QueueEventId
                     && !e.HasClaimed
                     && e.Position     == entry.Position + 1)
            .FirstOrDefaultAsync();

        if (nextEntry != null)
        {
            var nextDriverSlots = DeserialiseSlots(nextEntry.ShipmentListJson);

            // Add the expired shipment to their list if not already there
            var targetSlot = nextDriverSlots.FirstOrDefault(s => s.ShipmentQueueId == assignment.ShipmentQueueId);
            if (targetSlot == null)
            {
                // Slot not in list yet — insert at correct position
                targetSlot = new DriverShipmentSlot { ShipmentQueueId = assignment.ShipmentQueueId };
                var insertIdx = shipments.FindIndex(s => s.Id == assignment.ShipmentQueueId);
                if (insertIdx >= 0 && insertIdx <= nextDriverSlots.Count)
                    nextDriverSlots.Insert(insertIdx, targetSlot);
                else
                    nextDriverSlots.Add(targetSlot);
            }

            // It becomes the NEW active window for nextEntry
            targetSlot.ExpiresAt  = DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds);
            targetSlot.IsExpired  = false;

            // ClaimableCount for next driver: the expired shipment's index + 1
            var slotIdx = nextDriverSlots.IndexOf(targetSlot);
            if (nextEntry.ClaimableCount <= slotIdx)
                nextEntry.ClaimableCount = slotIdx + 1;

            nextEntry.ShipmentListJson = SerialiseSlots(nextDriverSlots);
            await CreateAssignmentAsync(activeEvent, nextEntry, targetSlot);

            Console.WriteLine($"[OnWindowExpired] opened window for nextDriver pos={nextEntry.Position} shipment={assignment.ShipmentQueueId}");
        }

        await _db.SaveChangesAsync();
    }

    // ─── Shipment accepted: remove from all lists ─────────────────────────────

    public async Task OnShipmentAcceptedAsync(Guid queueEventId, Guid acceptedShipmentQueueId)
    {
        Console.WriteLine($"[OnAccepted] removing shipment={acceptedShipmentQueueId} from all lists");

        var entries = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEventId && !e.HasClaimed)
            .ToListAsync();

        foreach (var entry in entries)
        {
            var slots = DeserialiseSlots(entry.ShipmentListJson);
            var removedIdx = slots.FindIndex(s => s.ShipmentQueueId == acceptedShipmentQueueId);
            if (removedIdx < 0) continue;

            // Was this shipment within the claimable range?
            var wasClaimable = removedIdx < entry.ClaimableCount;
            slots.RemoveAt(removedIdx);

            if (wasClaimable)
            {
                // Decrement count since we removed a claimable item
                entry.ClaimableCount = Math.Max(0, entry.ClaimableCount - 1);

                // If count dropped to 0 and there are still shipments, open first window
                if (entry.ClaimableCount == 0 && slots.Any(s => !s.IsSkipped))
                {
                    var activeEvent = await _db.QueueEvents.FindAsync(queueEventId);
                    if (activeEvent != null)
                    {
                        var firstAvailable = slots.First(s => !s.IsSkipped);
                        firstAvailable.ExpiresAt = DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds);
                        entry.ClaimableCount     = 1;
                        await CreateAssignmentAsync(activeEvent, entry, firstAvailable);
                    }
                }
            }

            entry.ShipmentListJson = SerialiseSlots(slots);
        }

        await _db.SaveChangesAsync();
        Console.WriteLine($"[OnAccepted] done — updated {entries.Count} driver lists");
    }

    // ─── Driver passed a shipment ─────────────────────────────────────────────

    public async Task OnDriverPassedAsync(Guid queueEventId, Guid driverId, Guid passedShipmentQueueId)
    {
        Console.WriteLine($"[OnPassed] driver={driverId} passed shipment={passedShipmentQueueId}");

        var activeEvent = await _db.QueueEvents.FindAsync(queueEventId);
        if (activeEvent == null) return;

        // ── 1. Mark as skipped in driver's own list ─────────────────────────
        var entry = await _db.DriverQueueEntries
            .FirstOrDefaultAsync(e => e.QueueEventId == queueEventId && e.DriverId == driverId);
        if (entry == null) return;

        var slots    = DeserialiseSlots(entry.ShipmentListJson);
        var passedSlot = slots.FirstOrDefault(s => s.ShipmentQueueId == passedShipmentQueueId);
        if (passedSlot == null) return;

        var passedIdx = slots.IndexOf(passedSlot);

        // Cancel the running assignment timer for this slot
        var runningAssignment = await _db.ShipmentQueueAssignments
            .FirstOrDefaultAsync(a => a.QueueEventId    == queueEventId
                                   && a.DriverId        == driverId
                                   && a.ShipmentQueueId == passedShipmentQueueId
                                   && a.Outcome         == AssignmentOutcome.Pending);
        if (runningAssignment != null)
            runningAssignment.Outcome = AssignmentOutcome.Passed;

        passedSlot.IsSkipped  = true;
        passedSlot.ExpiresAt  = null;

        // If the passed slot was the active window (last in claimable range, not expired),
        // open the NEXT un-skipped, un-claimable slot for this driver immediately.
        var wasActiveWindow = passedIdx == entry.ClaimableCount - 1 && !passedSlot.IsExpired;
        if (wasActiveWindow)
        {
            var nextSlot = slots
                .Skip(entry.ClaimableCount)
                .FirstOrDefault(s => !s.IsSkipped);
            if (nextSlot != null)
            {
                nextSlot.ExpiresAt    = DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds);
                entry.ClaimableCount += 1;
                await CreateAssignmentAsync(activeEvent, entry, nextSlot);
            }
        }

        entry.ShipmentListJson = SerialiseSlots(slots);

        // ── 2. Immediately open passed shipment for the next driver in cascade ──
        // Find the next driver who doesn't yet have this shipment in their claimable range.
        var nextEntry = await _db.DriverQueueEntries
            .Where(e => e.QueueEventId == queueEventId
                     && !e.HasClaimed
                     && e.DriverId    != driverId)
            .OrderBy(e => e.Position)
            .ToListAsync();

        foreach (var candidate in nextEntry)
        {
            var cSlots = DeserialiseSlots(candidate.ShipmentListJson);
            var cSlot  = cSlots.FirstOrDefault(s => s.ShipmentQueueId == passedShipmentQueueId);

            if (cSlot == null)
            {
                // Not in their list yet — add it
                cSlot = new DriverShipmentSlot { ShipmentQueueId = passedShipmentQueueId };
                var insertAt = Math.Min(passedIdx, cSlots.Count);
                cSlots.Insert(insertAt, cSlot);
            }

            // Only open if it's not already claimable for them
            var cIdx = cSlots.IndexOf(cSlot);
            if (cIdx >= candidate.ClaimableCount)
            {
                cSlot.ExpiresAt      = DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds);
                cSlot.IsExpired      = false;
                candidate.ClaimableCount = cIdx + 1;
                candidate.ShipmentListJson = SerialiseSlots(cSlots);
                await CreateAssignmentAsync(activeEvent, candidate, cSlot);
                Console.WriteLine($"[OnPassed] opened passed shipment for next driver pos={candidate.Position}");
                break;  // only one driver gets the immediate pass cascade
            }
        }

        await _db.SaveChangesAsync();
    }

    // ─── GET active event slot for a driver ───────────────────────────────────

    public async Task<ActiveEventDto?> GetActiveEventForDriverAsync(Guid driverId)
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent == null) return null;

        var entry = await _db.DriverQueueEntries
            .FirstOrDefaultAsync(e => e.QueueEventId == activeEvent.Id
                                   && e.DriverId     == driverId);
        if (entry == null) return null;

        // Self-heal: driver finished their trip, reset so they can rejoin
        if (entry.HasClaimed)
        {
            var hasActiveTrip = await _db.Trips.AnyAsync(t =>
                t.DriverId == driverId &&
                TripStatus.ActiveStatuses.Contains(t.CurrentStatus));

            if (!hasActiveTrip)
            {
                entry.HasClaimed     = false;
                entry.ClaimableCount = 0;
                entry.ShipmentListJson = "[]";

                var driver = await _db.Drivers.FindAsync(driverId);
                if (driver?.AvailabilityStatus == DriverAvailabilityStatus.OnTrip)
                    driver.AvailabilityStatus = DriverAvailabilityStatus.Available;

                var vehicle = await _db.Vehicles.FirstOrDefaultAsync(
                    v => v.CurrentDriverId == driverId && v.AvailabilityStatus == VehicleStatus.OnTrip);
                if (vehicle != null)
                    vehicle.AvailabilityStatus = VehicleStatus.Available;

                await _db.SaveChangesAsync();

                // Rebuild their list so they get fresh offers
                await BuildDriverListsAsync(activeEvent);

                entry = await _db.DriverQueueEntries
                    .FirstAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);
            }
        }

        // Self-heal: if this driver has no shipments yet, trigger BuildDriverListsAsync
        // ONCE — but only if the driver's list is genuinely empty (not just claimableCount=0,
        // which is normal for drivers who are waiting their turn).
        // Guard: check if their JSON list is empty, not just claimableCount, to avoid
        // calling BuildDriverListsAsync on every poll for every locked driver.
        var slots = DeserialiseSlots(entry.ShipmentListJson);
        if (slots.Count == 0 && !entry.HasClaimed)
        {
            var hasShipments = await _db.ShipmentQueues
                .AnyAsync(s => (s.Status == ShipmentQueueStatus.Waiting
                             || s.Status == ShipmentQueueStatus.Offered)
                            && (s.ZoneId == null || s.ZoneId == activeEvent.ZoneId));
            if (hasShipments)
            {
                await BuildDriverListsAsync(activeEvent);
                entry = await _db.DriverQueueEntries
                    .FirstAsync(e => e.QueueEventId == activeEvent.Id && e.DriverId == driverId);
            }
        }

        return await BuildDtoAsync(activeEvent, entry);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    // BuildDto is async because it needs to await the shipment enrichment query.
    // The previous version used synchronous .ToDictionary() on an IQueryable which
    // caused the query to execute on the DbContext without being awaited — returning
    // empty results silently and causing claimableCount>0 but shipmentSlots=[] on
    // the Flutter side, which fell through to the "Queue is closed" widget.
    private async Task<ActiveEventDto> BuildDtoAsync(QueueEvent activeEvent, DriverQueueEntry entry)
    {
        var slots = DeserialiseSlots(entry.ShipmentListJson);

        var shipmentIds    = slots.Select(s => s.ShipmentQueueId).ToList();
        // FIXED: await the query so it runs asynchronously and actually returns results.
        var shipmentQueues = await _db.ShipmentQueues
            .Include(q => q.Shipment).ThenInclude(s => s.PickupAddress)
            .Include(q => q.Shipment).ThenInclude(s => s.DropAddress)
            .Where(q => shipmentIds.Contains(q.Id))
            .ToDictionaryAsync(q => q.Id);

        // Build the DTO list — exclude skipped items entirely
        var dtoSlots = slots
            .Where(s => !s.IsSkipped)
            .Select((s, idx) =>
            {
                if (!shipmentQueues.TryGetValue(s.ShipmentQueueId, out var sq))
                    return null;
                return new ShipmentSlotDto(
                    ShipmentQueueId : s.ShipmentQueueId,
                    ShipmentId      : sq.ShipmentId,
                    ShipmentNumber  : sq.Shipment.ShipmentNumber,
                    PickupLocation  : FormatAddress(sq.Shipment.PickupAddress),
                    DropLocation    : FormatAddress(sq.Shipment.DropAddress),
                    CargoType       : sq.Shipment.CargoType,
                    CargoWeightKg   : sq.Shipment.CargoWeightKg,
                    AgreedPrice     : sq.Shipment.AgreedPrice,
                    IsUrgent        : sq.Shipment.IsUrgent,
                    IsExpired       : s.IsExpired,
                    ExpiresAt       : s.ExpiresAt
                );
            })
            .Where(s => s != null)
            .Cast<ShipmentSlotDto>()
            .ToList();

        // ClaimableCount in the DTO must account for skipped items being removed
        // Recalculate: how many non-skipped items from the original slots
        // fall within the original ClaimableCount range?
        var effectiveClaimable = slots
            .Take(entry.ClaimableCount)
            .Count(s => !s.IsSkipped);

        return new ActiveEventDto(
            Active          : true,
            EventId         : activeEvent.Id,
            EventStatus     : activeEvent.Status,
            EventEndTime    : activeEvent.EndTime,
            Position        : entry.Position,
            HasClaimed      : entry.HasClaimed,
            ClaimableCount  : effectiveClaimable,
            ShipmentSlots   : dtoSlots
        );
    }

    private async Task<List<ShipmentQueue>> GetActiveShipmentsAsync(QueueEvent queueEvent) =>
        await _db.ShipmentQueues
            .Where(s => (s.Status == ShipmentQueueStatus.Waiting
                      || s.Status == ShipmentQueueStatus.Offered)
                     && (s.ZoneId == null || s.ZoneId == queueEvent.ZoneId))
            .OrderBy(s => s.CreatedAt)
            .ToListAsync();

    private async Task CreateAssignmentAsync(
        QueueEvent        activeEvent,
        DriverQueueEntry  entry,
        DriverShipmentSlot slot)
    {
        // Check if an active Pending assignment already exists to avoid duplicates
        var exists = await _db.ShipmentQueueAssignments
            .AnyAsync(a => a.QueueEventId    == activeEvent.Id
                        && a.DriverId        == entry.DriverId
                        && a.ShipmentQueueId == slot.ShipmentQueueId
                        && a.Outcome         == AssignmentOutcome.Pending);
        if (exists) return;

        _db.ShipmentQueueAssignments.Add(new ShipmentQueueAssignment
        {
            Id              = Guid.NewGuid(),
            QueueEventId    = activeEvent.Id,
            ShipmentQueueId = slot.ShipmentQueueId,
            DriverId        = entry.DriverId,
            DriverPosition  = entry.Position,
            OfferedAt       = DateTime.UtcNow,
            ExpiresAt       = slot.ExpiresAt ?? DateTime.UtcNow.AddSeconds(activeEvent.WindowSeconds),
            Outcome         = AssignmentOutcome.Pending
        });

        // Keep shipment_queue status as Offered so the existing Accept lock still works
        var sq = await _db.ShipmentQueues.FindAsync(slot.ShipmentQueueId);
        if (sq != null && sq.Status == ShipmentQueueStatus.Waiting)
        {
            sq.Status         = ShipmentQueueStatus.Offered;
            sq.CurrentDriverId = entry.DriverId;
            sq.OfferExpiresAt  = slot.ExpiresAt;
        }
    }

    private static List<DriverShipmentSlot> DeserialiseSlots(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<List<DriverShipmentSlot>>(json, _json)
                   ?? new List<DriverShipmentSlot>();
        }
        catch { return new List<DriverShipmentSlot>(); }
    }

    private static string SerialiseSlots(List<DriverShipmentSlot> slots) =>
        JsonSerializer.Serialize(slots, _json);

    private static string FormatAddress(Address? a) =>
        a == null ? "Unknown" : $"{a.City}, {a.State}";

    // ─── Other endpoints (unchanged logic) ───────────────────────────────────

    public async Task<object> GetLiveStatusAsync()
    {
        var activeEvent = await _db.QueueEvents
            .OrderByDescending(e => e.StartTime)
            .FirstOrDefaultAsync();

        if (activeEvent == null)
            return new { isLive = false, eventId = (Guid?)null, endTime = (DateTime?)null };

        return new
        {
            isLive  = activeEvent.Status == QueueEventStatus.Live && activeEvent.EndTime > DateTime.UtcNow,
            eventId = (Guid?)activeEvent.Id,
            endTime = (DateTime?)activeEvent.EndTime
        };
    }

    public async Task<object> ReassignOffersAsync()
    {
        var activeEvent = await _db.QueueEvents
            .FirstOrDefaultAsync(e => e.Status == QueueEventStatus.Live
                                   && e.EndTime > DateTime.UtcNow);
        if (activeEvent == null) return new { message = "No active event" };
        await BuildDriverListsAsync(activeEvent);
        return new { message = "Offers reassigned" };
    }

    // ─── GET all events (newest first) ───────────────────────────────────────

    public async Task<List<QueueEventSummaryDto>> GetAllEventsAsync()
    {
        var events = await _db.QueueEvents
            .OrderByDescending(e => e.StartTime)
            .ToListAsync();

        return events.Select(e => new QueueEventSummaryDto(
            Id            : e.Id,
            Status        : e.Status.ToString().ToLower(),
            StartTime     : e.StartTime,
            EndTime       : e.EndTime,
            WindowSeconds : e.WindowSeconds
        )).ToList();
    }

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
            if (queueEvent.EndTime <= DateTime.UtcNow)
                queueEvent.EndTime = DateTime.UtcNow.AddHours(2);
            queueEvent.Status = QueueEventStatus.Live;
            await BuildDriverListsAsync(queueEvent);
        }

        await _db.SaveChangesAsync();
        return new { eventId = queueEvent.Id, status = queueEvent.Status, endTime = queueEvent.EndTime };
    }
}