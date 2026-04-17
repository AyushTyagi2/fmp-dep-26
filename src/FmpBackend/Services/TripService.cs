using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;
using FmpBackend.Data;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Services;

public class TripService
{
    private readonly TripCrudRepository _repo;
    private readonly ShipmentRepository _shipmentRepo;
    private readonly AppDbContext       _db;

    public TripService(TripCrudRepository repo, ShipmentRepository shipmentRepo, AppDbContext db)
    {
        _repo         = repo;
        _shipmentRepo = shipmentRepo;
        _db           = db;
    }

    public async Task<PagedResult<TripDto>> GetAllAsync(int page, int pageSize, string? status)
    {
        var (items, total) = await _repo.GetAllAsync(page, pageSize, status);
        return new PagedResult<TripDto>
        {
            Items = items.Select(ToDto).ToList(),
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<TripDto?> GetByIdAsync(Guid id)
    {
        var t = await _repo.GetByIdAsync(id);
        return t == null ? null : ToDto(t);
    }

    public async Task<TripDto> CreateAsync(CreateTripRequest req)
    {
        var trip = new Trip
        {
            Id = Guid.NewGuid(),
            TripNumber = $"TRP-{DateTime.UtcNow:yyyy}-{Random.Shared.Next(100000, 999999)}",
            ShipmentId = req.ShipmentId,
            VehicleId = req.VehicleId,
            DriverId = req.DriverId,
            AssignedUnionId = req.AssignedUnionId,
            AssignedFleetOwnerId = req.AssignedFleetOwnerId,
            AssignedBy = req.AssignedBy,
            AssignedAt = DateTime.UtcNow,
            PlannedStartTime = req.PlannedStartTime,
            PlannedEndTime = req.PlannedEndTime,
            EstimatedDistanceKm = req.EstimatedDistanceKm,
            EstimatedDurationHours = req.EstimatedDurationHours,
            CurrentStatus = "assigned",
            DriverPaymentStatus = "pending",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _repo.AddAsync(trip);

        // ✅ Sync shipment status → "assigned"
        await _shipmentRepo.UpdateStatusAsync(req.ShipmentId, "assigned");

        return (await GetByIdAsync(trip.Id))!;
    }

    public async Task<bool> UpdateStatusAsync(Guid id, UpdateTripStatusRequest req)
    {
        var trip = await _repo.GetByIdAsync(id);
        if (trip == null) return false;

        trip.CurrentStatus = req.Status;

        if (req.Latitude.HasValue)
        {
            trip.CurrentLatitude = req.Latitude;
            trip.CurrentLongitude = req.Longitude;
            trip.LastLocationUpdateAt = DateTime.UtcNow;
        }

        if (req.DelayReason != null) trip.DelayReason = req.DelayReason;
        if (req.IssueDescription != null)
        {
            trip.HasIssues = true;
            trip.IssueDescription = req.IssueDescription;
        }

        if (req.Status == "in_transit")
            trip.ActualStartTime = DateTime.UtcNow;

        var terminalStatuses = new[] { "delivered", "completed", "cancelled" };
        bool isTerminal = terminalStatuses.Contains(req.Status);

        if (req.Status == "delivered")
        {
            trip.ActualEndTime = DateTime.UtcNow;
            trip.DeliveredAt   = DateTime.UtcNow;
            trip.CompletedAt   = DateTime.UtcNow;
        }

        trip.UpdatedAt = DateTime.UtcNow;
        await _repo.SaveAsync();

        // ✅ Sync shipment status whenever trip moves forward
        await _shipmentRepo.UpdateStatusAsync(trip.ShipmentId, req.Status);

        // ✅ When a trip reaches a terminal state, free up the driver so they
        //    can re-enter the queue for future shipments in the same event.
        if (isTerminal && trip.DriverId != Guid.Empty)
        {
            var driver = await _db.Drivers.FindAsync(trip.DriverId);
            if (driver != null)
            {
                driver.AvailabilityStatus = DriverAvailabilityStatus.Available;
                await _db.SaveChangesAsync();
            }

            // Also reset any accepted DriverQueueEntry for the driver so they
            // appear as "idle" again on the queue screen instead of "accepted".
            var staleEntry = await _db.DriverQueueEntries
                .Where(e => e.DriverId     == trip.DriverId
                         && e.OfferStatus  == DriverOfferStatus.Accepted)
                .OrderByDescending(e => e.ClaimWindowStart)
                .FirstOrDefaultAsync();

            if (staleEntry != null)
            {
                staleEntry.OfferStatus  = DriverOfferStatus.Idle;
                staleEntry.HasClaimed   = false;
                staleEntry.CurrentOfferedShipmentQueueId = null;
                await _db.SaveChangesAsync();
            }
        }

        return true;
    }

    public async Task<List<TripDto>> GetByDriverAsync(Guid driverId) =>
        (await _repo.GetByDriverAsync(driverId)).Select(ToDto).ToList();

    /// <summary>
    /// Driver trip search: filters a driver's own trips by free-text (tripNumber, shipmentNumber)
    /// and optionally by status.
    /// </summary>
    public async Task<List<TripDto>> SearchByDriverAsync(Guid driverId, string? q, string? status)
    {
        var trips = await _repo.GetByDriverAsync(driverId);

        IEnumerable<Trip> result = trips;

        if (!string.IsNullOrWhiteSpace(q))
        {
            var lower = q.ToLower();
            result = result.Where(t =>
                t.TripNumber.ToLower().Contains(lower) ||
                (t.Shipment?.ShipmentNumber?.ToLower().Contains(lower) ?? false));
        }

        if (!string.IsNullOrWhiteSpace(status))
            result = result.Where(t => t.CurrentStatus == status);

        return result.Select(ToDto).ToList();
    }

    private static TripDto ToDto(Trip t) => new(
        t.Id, t.TripNumber, t.ShipmentId, t.Shipment?.ShipmentNumber ?? "",
        t.VehicleId, t.DriverId, t.AssignedUnionId, t.AssignedFleetOwnerId,
        t.PlannedStartTime, t.PlannedEndTime, t.EstimatedDistanceKm, t.EstimatedDurationHours,
        t.ActualStartTime, t.ActualEndTime, t.ActualDistanceKm, t.CurrentStatus,
        t.CurrentLatitude, t.CurrentLongitude, t.LastLocationUpdateAt,
        t.DeliveredAt, t.DeliveredToName, t.ProofOfDeliveryUrl, t.DeliveryNotes,
        t.SenderRating, t.ReceiverRating, t.DriverPaymentAmount, t.DriverPaymentStatus,
        t.HasIssues, t.IssueDescription, t.CreatedAt, t.UpdatedAt, t.CompletedAt, 
        t.Shipment?.SenderOrganization?.Name ?? "",
        t.Shipment?.ReceiverOrganization?.Name ?? "");
}