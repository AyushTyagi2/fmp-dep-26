using FmpBackend.Data;
using FmpBackend.Dtos;
using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Repositories;

public class TripRepository : Interfaces.ITripRepository
{
    private readonly AppDbContext _db;

    private static readonly string[] _inactiveStatuses = ["completed", "delivered", "cancelled"];

    public TripRepository(AppDbContext db)
    {
        _db = db;
    }

    // ── Dashboard counters (existing) ─────────────────────────────────────────

    public int CountActiveTripsForFleetOwner(Guid fleetOwnerId)
    {
        return _db.Trips.Count(t =>
            t.AssignedFleetOwnerId == fleetOwnerId &&
            !_inactiveStatuses.Contains(t.CurrentStatus));
    }

    public int CountTripsWithIssuesForFleetOwner(Guid fleetOwnerId)
    {
        return _db.Trips.Count(t =>
            t.AssignedFleetOwnerId == fleetOwnerId &&
            t.HasIssues);
    }

    public async Task<int> CountActiveAsync()
    {
        return await _db.Trips.CountAsync(t =>
            t.CurrentStatus != "completed" &&
            t.CurrentStatus != "cancelled");
    }

    // ── Fleet manager trips list ──────────────────────────────────────────────

    /// <summary>
    /// Returns all trips assigned to the fleet owner identified by <paramref name="phone"/>.
    /// Uses explicit joins because FleetOwner, Trip, and Driver models do not
    /// declare navigation properties for their related User/Vehicle/Driver records.
    /// </summary>
    public async Task<IEnumerable<FleetTripDto>> GetTripsByFleetOwnerPhoneAsync(
        string phone,
        CancellationToken ct = default)
    {
        // Step 1: resolve fleet owner id via UserId → User.Phone join
        // FleetOwner has no User nav property and no DeletedAt, so join manually
        var fleetOwner = await (
            from fo in _db.FleetOwners
            join u  in _db.Users on fo.UserId equals u.Id
            where u.Phone == phone
            select new { fo.Id }
        ).FirstOrDefaultAsync(ct);

        if (fleetOwner is null)
            throw new KeyNotFoundException($"No fleet owner found for phone '{phone}'.");

        // Step 2: fetch trips with all required data via explicit joins
        // Trip has no Vehicle/Driver nav props; Driver has no User nav prop
        return await (
            from t  in _db.Trips
            join v  in _db.Vehicles  on t.VehicleId          equals v.Id
            join d  in _db.Drivers   on t.DriverId           equals d.Id
            join du in _db.Users     on d.UserId              equals du.Id
            join s  in _db.Shipments on t.ShipmentId          equals s.Id
            join pa in _db.Addresses on s.PickupAddressId     equals pa.Id
            join da in _db.Addresses on s.DropAddressId       equals da.Id
            where t.AssignedFleetOwnerId == fleetOwner.Id
            orderby t.CreatedAt descending
            select new FleetTripDto
            {
                TripId        = t.Id,
                TripNumber    = t.TripNumber,
                CurrentStatus = t.CurrentStatus,

                PlannedStartTime    = t.PlannedStartTime,
                ActualStartTime     = t.ActualStartTime,
                EstimatedDistanceKm = t.EstimatedDistanceKm,

                VehicleRegistrationNumber = v.RegistrationNumber,
                DriverName                = du.FullName,

                PickupCity = pa.City,
                DropCity   = da.City,

                CargoType     = s.CargoType,
                CargoWeightKg = s.CargoWeightKg,
            }
        ).ToListAsync(ct);
    }
}