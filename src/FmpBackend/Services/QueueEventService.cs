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

        var now        = DateTime.UtcNow;
        var expiresAt  = now.AddSeconds(queueEvent.WindowSeconds);

        var pairs = Math.Min(idleDriverEntries.Count, availableShipments.Count);
        var newAssignments = new List<ShipmentQueueAssignment>();

        for (int i = 0; i < pairs; i++)
        {
            var entry    = idleDriverEntries[i];
            var shipment = availableShipments[i];

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

        _db.ShipmentQueueAssignments.AddRange(newAssignments);
        await _db.SaveChangesAsync();
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
}