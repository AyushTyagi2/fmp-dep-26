using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class TripService
{
    private readonly TripCrudRepository _repo;
    private readonly ShipmentRepository _shipmentRepo;

    public TripService(TripCrudRepository repo, ShipmentRepository shipmentRepo)
    {
        _repo = repo;
        _shipmentRepo = shipmentRepo;
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

        if (req.Status == "delivered")
        {
            trip.ActualEndTime = DateTime.UtcNow;
            trip.DeliveredAt = DateTime.UtcNow;
            trip.CompletedAt = DateTime.UtcNow;
        }

        trip.UpdatedAt = DateTime.UtcNow;
        await _repo.SaveAsync();

        // ✅ Sync shipment status whenever trip moves forward
        await _shipmentRepo.UpdateStatusAsync(trip.ShipmentId, req.Status);

        return true;
    }

    public async Task<List<TripDto>> GetByDriverAsync(Guid driverId) =>
        (await _repo.GetByDriverAsync(driverId)).Select(ToDto).ToList();

    private static TripDto ToDto(Trip t) => new(
        t.Id, t.TripNumber, t.ShipmentId, t.Shipment?.ShipmentNumber ?? "",
        t.VehicleId, t.DriverId, t.AssignedUnionId, t.AssignedFleetOwnerId,
        t.PlannedStartTime, t.PlannedEndTime, t.EstimatedDistanceKm, t.EstimatedDurationHours,
        t.ActualStartTime, t.ActualEndTime, t.ActualDistanceKm, t.CurrentStatus,
        t.CurrentLatitude, t.CurrentLongitude, t.LastLocationUpdateAt,
        t.DeliveredAt, t.DeliveredToName, t.ProofOfDeliveryUrl, t.DeliveryNotes,
        t.SenderRating, t.ReceiverRating, t.DriverPaymentAmount, t.DriverPaymentStatus,
        t.HasIssues, t.IssueDescription, t.CreatedAt, t.UpdatedAt, t.CompletedAt);
}