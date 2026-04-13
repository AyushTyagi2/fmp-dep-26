using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class SysAdminService
{
    private readonly ShipmentService     _shipmentService;
    private readonly TripService         _tripService;
    private readonly SystemLogService    _log;
    private readonly DriverRepository    _drivers;
    private readonly VehicleRepository   _vehicles;
    private readonly TripRepository      _tripRepo;
    private readonly ShipmentRepository  _shipRepo;
    private readonly UserRepository      _users;

    public SysAdminService(
        ShipmentService     shipmentService,
        TripService         tripService,
        SystemLogService    log,
        DriverRepository    drivers,
        VehicleRepository   vehicles,
        TripRepository      tripRepo,
        ShipmentRepository  shipRepo,
        UserRepository      users)
    {
        _shipmentService = shipmentService;
        _tripService     = tripService;
        _log             = log;
        _drivers         = drivers;
        _vehicles        = vehicles;
        _tripRepo        = tripRepo;
        _shipRepo        = shipRepo;
        _users           = users;
    }

    // ── Metrics ──────────────────────────────────────────────────────────────

    public async Task<object> GetSystemMetricsAsync()
    {
        var activeDrivers    = await _drivers.CountActiveAsync();
        var pendingShipments = await _shipRepo.CountByStatusAsync("pending_approval");
        var activeTrips      = await _tripRepo.CountActiveAsync();
        var adminOverrides   = await _shipRepo.CountAdminOverridesAsync();

        return new { activeDrivers, pendingShipments, activeTrips, adminOverrides };
    }

    // ── Logs ─────────────────────────────────────────────────────────────────

    public async Task<IEnumerable<object>> GetRecentLogsAsync(int limit = 50)
    {
        var logs = await _log.GetRecentAsync(limit);
        return logs.Select(l => (object)new
        {
            l.Id,
            l.EventType,
            l.ActorType,
            l.EntityType,
            l.EntityId,
            l.Metadata,
            l.CreatedAt
        });
    }

    // ── Users ─────────────────────────────────────────────────────────────────

    public async Task<IEnumerable<object>> GetActiveUsersAsync()
    {
        var users = await _users.GetAllAsync();
        return users.Select(u => (object)new
        {
            u.Id,
            u.FullName,
            u.Phone,
            u.CreatedAt
        });
    }

    /// <summary>
    /// Search users by free-text (name/phone) and optionally filter by role.
    /// Role lookup uses the user_roles join table.
    /// </summary>
    public async Task<IEnumerable<object>> SearchUsersAsync(string? q, string? role)
    {
        var users = await _users.SearchAsync(q, role);
        return users.Select(u => (object)new
        {
            u.Id,
            u.FullName,
            u.Phone,
            Role = role ?? "",   // echo back filtered role for display
            u.CreatedAt
        });
    }

    // ── Shipments ─────────────────────────────────────────────────────────────

    public async Task<List<object>> GetShipmentsAsync(string? status)
        => await _shipmentService.GetShipmentsByStatusAsync(status);

    public async Task<bool> ApproveShipmentAsync(Guid shipmentId, Guid adminUserId)
        => await _shipmentService.ApproveShipmentAsync(shipmentId, adminUserId);

    public async Task<bool> RejectShipmentAsync(Guid shipmentId, string reason, Guid adminUserId)
        => await _shipmentService.RejectShipmentAsync(shipmentId, reason, adminUserId);

    public async Task<bool> CancelShipmentAsync(Guid shipmentId, Guid adminUserId, string reason)
        => await _shipmentService.CancelShipmentAsync(shipmentId, adminUserId, reason);

    // ── Force-assign ──────────────────────────────────────────────────────────

    /// <summary>
    /// Admin bypasses the driver queue and directly creates a trip for the given
    /// shipment + driver + vehicle. The shipment must be approved or pending_approval.
    /// </summary>
    public async Task<TripDto> ForceAssignDriverAsync(
        Guid shipmentId,
        Guid driverId,
        Guid vehicleId,
        Guid adminUserId)
    {
        var shipment = await _shipRepo.GetByIdAsync(shipmentId)
            ?? throw new Exception("Shipment not found");

        if (shipment.Status is not ("approved" or "pending_approval"))
            throw new Exception($"Cannot force-assign: shipment status is '{shipment.Status}'");

        var driver = _drivers.GetById(driverId)
            ?? throw new Exception("Driver not found");

        var vehicle = _vehicles.GetById(vehicleId)
            ?? throw new Exception("Vehicle not found");

        // Reuse TripService.CreateAsync — it also flips shipment → "assigned"
        var tripDto = await _tripService.CreateAsync(new CreateTripRequest(
            ShipmentId:              shipmentId,
            VehicleId:               vehicleId,
            DriverId:                driverId,
            AssignedUnionId:         null,
            AssignedFleetOwnerId:    driver.CurrentFleetOwnerId ?? vehicle.FleetOwnerId,
            AssignedBy:              adminUserId,
            PlannedStartTime:        null,
            PlannedEndTime:          null,
            EstimatedDistanceKm:     null,
            EstimatedDurationHours:  null
        ));

        // Stamp the admin override fields via the repository
        await _shipRepo.SetAdminOverrideAsync(shipmentId, adminUserId);

        await _log.LogAsync("shipment.force_assigned", adminUserId, "admin",
            "shipment", shipmentId,
            new { shipment.ShipmentNumber, driverId, vehicleId, tripId = tripDto.Id });

        return tripDto;
    }
}