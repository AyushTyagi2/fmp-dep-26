using FmpBackend.Data;
using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Services;

public class ShipmentQueueService
{
    private readonly ShipmentQueueRepository _repo;
    private readonly AppDbContext _db;
    // Lazy to avoid circular DI: ShipmentService → ShipmentQueueService → TripService → ShipmentService
    private readonly Lazy<TripService> _tripService;

    public ShipmentQueueService(
        ShipmentQueueRepository repo,
        AppDbContext db,
        IServiceProvider sp)
    {
        _repo = repo;
        _db = db;
        _tripService = new Lazy<TripService>(() => sp.GetRequiredService<TripService>());
    }

    public async Task<PagedResult<ShipmentQueueDto>> GetWaitingAsync(int page, int pageSize)
    {
        var (items, total) = await _repo.GetWaitingAsync(page, pageSize);
        return new PagedResult<ShipmentQueueDto>
        {
            Items = items.Select(ToDto).ToList(),
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<ShipmentQueueDto?> GetByIdAsync(Guid id)
    {
        var item = await _repo.GetByIdAsync(id);
        return item == null ? null : ToDto(item);
    }

    public async Task<ShipmentQueueDto> EnqueueAsync(Guid shipmentId, string? vehicleType, Guid? zoneId)
    {
        var item = new ShipmentQueue
        {
            Id = Guid.NewGuid(),
            ShipmentId = shipmentId,
            RequiredVehicleType = vehicleType,
            ZoneId = zoneId,
            Status = "waiting",
            CreatedAt = DateTime.UtcNow
        };
        await _repo.AddAsync(item);
        return (await GetByIdAsync(item.Id))!;
    }

    /// <summary>
    /// Race-condition safe accept. On success, creates a Trip record automatically.
    /// Returns the new TripId on success, null if already taken.
    /// </summary>
    public async Task<Guid?> AcceptAsync(Guid queueItemId, Guid driverId)
    {
        for (int attempt = 0; attempt < 3; attempt++)
        {
            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {
                var item = await _repo.LockForAcceptAsync(queueItemId);
                if (item == null) { await tx.RollbackAsync(); return null; }

                item.Status = "accepted";
                item.CurrentDriverId = driverId;
                await _repo.SaveAsync();
                await tx.CommitAsync();

                // ✅ Create Trip so driver sees it on their dashboard immediately
                // VehicleId / FleetOwnerId are placeholders — real apps resolve from driver profile
                var trip = await _tripService.Value.CreateAsync(new CreateTripRequest(
                        ShipmentId: item.ShipmentId,
                        VehicleId: Guid.Parse("14037f26-fa8b-422d-b1a5-80bbf9eb3201"),
                        DriverId: driverId,
                        AssignedUnionId: null,
                        AssignedFleetOwnerId: Guid.Parse("538c0094-5e5c-4429-9f38-63d9ff9acbb9"),
                        AssignedBy: null,
                        PlannedStartTime: null,
                        PlannedEndTime: null,
                        EstimatedDistanceKm: null,
                        EstimatedDurationHours: null
                    ));

                return trip.Id;
            }
            catch (DbUpdateConcurrencyException) { await tx.RollbackAsync(); }
            catch { await tx.RollbackAsync(); throw; }
        }
        return null;
    }

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