using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;
using System.Text.Json;

namespace FmpBackend.Services;

public class ShipmentService
{
    private readonly ShipmentRepository    _ship;
    private readonly OrganizationRepository _orgRepo;
    private readonly UserRepository         _userRepo;
    private readonly AddressRepository      _addressRepo;
    private readonly ShipmentQueueService   _queueService;
    private readonly SystemLogService       _log;           // ← NEW

    public ShipmentService(
        ShipmentRepository    ship,
        OrganizationRepository orgRepo,
        UserRepository         userRepo,
        AddressRepository      addressRepo,
        ShipmentQueueService   queueService,
        SystemLogService       log)            // ← NEW
    {
        _ship         = ship;
        _orgRepo      = orgRepo;
        _userRepo     = userRepo;
        _addressRepo  = addressRepo;
        _queueService = queueService;
        _log          = log;
    }

    public async Task<Shipment> CreateShipmentAsync(CreateShipmentRequest request)
    {
        var shipmentNumber = $"SHP-{DateTime.UtcNow.Ticks}";

        var senderOrg = await _orgRepo.GetByEmailAsync(request.SenderPhone);
        if (senderOrg == null)
            throw new Exception("Sender organization not found");

        var receiverOrg = await _orgRepo.GetByPhoneAsync(request.ReceiverPhone);
        if (receiverOrg == null)
            throw new Exception("Receiver organization not found");

        var user = await _userRepo.GetByEmailAsync(request.SenderPhone);
        if (user == null)
            throw new Exception("User not found");

        var pickupAddress = await _addressRepo.GetDefaultByOwnerAsync(senderOrg.Id, "organization");

if (pickupAddress == null)
{
    Console.WriteLine("No DEFAULT pickup address found. Checking ANY active address...");

    var fallback = await _addressRepo.GetAnyActiveByOwnerAsync(senderOrg.Id, "organization");
    //vc
    if (fallback != null)
    {
        Console.WriteLine("Found NON-DEFAULT address: {0}", fallback.Id);
    }
    else
    {
        Console.WriteLine("No address at all found for OwnerId: {0}", senderOrg.Id);
    }

    throw new Exception("Pickup address not found");
}

        var dropAddress = await _addressRepo.GetDefaultByOwnerAsync(receiverOrg.Id, "organization");
        if (dropAddress == null)
            throw new Exception("Drop address not found");

        var shipment = new Shipment
        {
            Id                           = Guid.NewGuid(),
            ShipmentNumber               = shipmentNumber,
            SenderOrganizationId         = senderOrg.Id,
            ReceiverOrganizationId       = receiverOrg.Id,
            CreatedByUserId              = user.Id,
            PickupAddressId              = pickupAddress.Id,
            DropAddressId                = dropAddress.Id,
            CargoType                    = request.CargoType,
            CargoDescription             = request.CargoDescription,
            CargoWeightKg                = request.CargoWeightKg,
            CargoVolumeCubicMeters       = request.CargoVolumeCubicMeters,
            PackageCount                 = request.PackageCount,
            RequiresRefrigeration        = request.RequiresRefrigeration,
            RequiresInsurance            = request.RequiresInsurance,
            SpecialHandlingInstructions  = request.SpecialHandlingInstructions,
            PreferredPickupDate          = request.PreferredPickupDate.HasValue
                ? DateTime.SpecifyKind(request.PreferredPickupDate.Value, DateTimeKind.Utc) : null,
            PreferredDeliveryDate        = request.PreferredDeliveryDate.HasValue
                ? DateTime.SpecifyKind(request.PreferredDeliveryDate.Value, DateTimeKind.Utc) : null,
            IsUrgent                     = request.IsUrgent,
            AgreedPrice                  = request.AgreedPrice,
            PricePerUnit                 = request.PricePerUnit,
            LoadingCharges               = request.LoadingCharges,
            UnloadingCharges             = request.UnloadingCharges,
            OtherCharges                 = request.OtherCharges,
            Status                       = "pending_approval",
            CreatedAt                    = DateTime.UtcNow
        };

        return await _ship.CreateAsync(shipment);
    }

    public async Task<object> GetShipmentsByPhoneAsync(string phone)
    {
        var org = await _orgRepo.GetByEmailAsync(phone);
        if (org == null)
            throw new Exception("Organization not found");

        var sent     = await _ship.GetSentShipmentsAsync(org.Id);
        var received = await _ship.GetReceivedShipmentsAsync(org.Id);

        return new
        {
            sent     = sent.Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.CreatedAt }),
            received = received.Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.CreatedAt })
        };
    }

    /// <summary>
    /// Sender search: returns sent + received shipments filtered by q/status/cargoType/urgent.
    /// </summary>
    public async Task<object> SearchShipmentsAsync(
        string phone,
        string? q,
        string? status,
        string? cargoType,
        bool? urgent)
    {
        var org = await _orgRepo.GetByEmailAsync(phone);
        if (org == null) throw new Exception("Organization not found");

        var sent     = await _ship.GetSentShipmentsAsync(org.Id);
        var received = await _ship.GetReceivedShipmentsAsync(org.Id);

        IEnumerable<Shipment> FilterList(IEnumerable<Shipment> list)
        {
            if (!string.IsNullOrWhiteSpace(q))
            {
                var lower = q.ToLower();
                list = list.Where(s =>
                    (s.ShipmentNumber?.ToLower().Contains(lower) ?? false) ||
                    (s.CargoType?.ToLower().Contains(lower) ?? false) ||
                    (s.Status?.ToLower().Contains(lower) ?? false));
            }
            if (!string.IsNullOrWhiteSpace(status))
                list = list.Where(s => s.Status == status);
            if (!string.IsNullOrWhiteSpace(cargoType))
                list = list.Where(s => s.CargoType?.ToLower() == cargoType.ToLower());
            if (urgent == true)
                list = list.Where(s => s.IsUrgent);
            return list;
        }

        var filteredSent     = FilterList(sent).Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.IsUrgent, s.AgreedPrice, s.CreatedAt });
        var filteredReceived = FilterList(received).Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.IsUrgent, s.AgreedPrice, s.CreatedAt });

        return new { sent = filteredSent, received = filteredReceived };
    }

    /// <summary>
    /// Union queue search: full-text + optional status/cargoType/urgent filters across all shipments.
    /// </summary>
    public async Task<List<object>> SearchQueueShipmentsAsync(
        string? q,
        string? status,
        string? cargoType,
        bool? urgent)
    {
        // Get all shipments (or scoped to pending_approval queue if no status provided)
        var all = string.IsNullOrWhiteSpace(status)
            ? await _ship.GetAllAsync()
            : await _ship.GetByStatusAsync(status);

        IEnumerable<Shipment> result = all;

        if (!string.IsNullOrWhiteSpace(q))
        {
            var lower = q.ToLower();
            result = result.Where(s =>
                (s.ShipmentNumber?.ToLower().Contains(lower) ?? false) ||
                (s.CargoType?.ToLower().Contains(lower) ?? false));
        }
        if (!string.IsNullOrWhiteSpace(cargoType))
            result = result.Where(s => s.CargoType?.ToLower() == cargoType.ToLower());
        if (urgent == true)
            result = result.Where(s => s.IsUrgent);

        return result
            .Select(s => (object)new
            {
                s.Id,
                s.ShipmentNumber,
                s.CargoType,
                s.CargoWeightKg,
                s.Status,
                s.IsUrgent,
                s.CreatedAt
            })
            .ToList();
    }

    public async Task<List<object>> GetPendingShipmentsAsync()
    {
        var shipments = await _ship.GetByStatusAsync("pending_approval");
        return shipments.Select(s => (object)new
        {
            s.Id,
            s.ShipmentNumber,
            s.CargoType,
            s.CargoWeightKg,
            s.Status,
            s.CreatedAt
        }).ToList();
    }

    /// <summary>
    /// Returns shipments for any status. Used by admin to view all shipments.
    /// Pass null to get everything.
    /// </summary>
    public async Task<List<object>> GetShipmentsByStatusAsync(string? status)
    {
        var shipments = status == null
            ? await _ship.GetAllAsync()
            : await _ship.GetByStatusAsync(status);

        return shipments.Select(s => (object)new
        {
            s.Id,
            s.ShipmentNumber,
            s.CargoType,
            s.CargoWeightKg,
            s.Status,
            s.UpdatedByAdmin,
            s.CreatedAt,
            s.UpdatedAt
        }).ToList();
    }

    /// <summary>
    /// Approves a shipment and automatically enqueues it so drivers see it instantly.
    /// </summary>
    public async Task<bool> ApproveShipmentAsync(Guid shipmentId, Guid? adminUserId = null)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null) return false;

        if (shipment.Status != "pending_approval")
            throw new Exception("Shipment is not pending approval");

        var previousStatus = shipment.Status;
        shipment.Status      = "approved";
        shipment.ApprovedAt  = DateTime.UtcNow;

        if (adminUserId.HasValue)
        {
            shipment.UpdatedByAdmin  = true;
            shipment.AdminOverrideBy = adminUserId;
            shipment.AdminOverrideAt = DateTime.UtcNow;
        }

        await _ship.UpdateAsync(shipment);

        // Auto-enqueue so it appears on driver queue immediately
        await _queueService.EnqueueAsync(shipmentId, null, null);

        await _log.LogAsync("shipment.approved", adminUserId, adminUserId.HasValue ? "admin" : "system",
            "shipment", shipmentId, new { shipment.ShipmentNumber, from = previousStatus, to = "approved" });

        return true;
    }

    public async Task<bool> RejectShipmentAsync(Guid shipmentId, string reason, Guid? adminUserId = null)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null) return false;

        var previousStatus       = shipment.Status;
        shipment.Status          = "rejected";
        shipment.RejectionReason = reason;

        if (adminUserId.HasValue)
        {
            shipment.UpdatedByAdmin  = true;
            shipment.AdminOverrideBy = adminUserId;
            shipment.AdminOverrideAt = DateTime.UtcNow;
        }

        await _ship.UpdateAsync(shipment);

        await _log.LogAsync("shipment.rejected", adminUserId, adminUserId.HasValue ? "admin" : "system",
            "shipment", shipmentId, new { shipment.ShipmentNumber, from = previousStatus, reason });

        return true;
    }

    /// <summary>
    /// Admin-only: cancels a shipment regardless of its current status (except already delivered).
    /// </summary>
    public async Task<bool> CancelShipmentAsync(Guid shipmentId, Guid adminUserId, string reason)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null) return false;

        if (shipment.Status == "delivered")
            throw new Exception("Cannot cancel a delivered shipment");

        var previousStatus           = shipment.Status;
        shipment.Status              = "cancelled";
        shipment.CancellationReason  = reason;
        shipment.UpdatedByAdmin      = true;
        shipment.AdminOverrideBy     = adminUserId;
        shipment.AdminOverrideAt     = DateTime.UtcNow;

        await _ship.UpdateAsync(shipment);

        await _log.LogAsync("shipment.cancelled", adminUserId, "admin",
            "shipment", shipmentId,
            new { shipment.ShipmentNumber, from = previousStatus, to = "cancelled", reason });

        return true;
    }

    /// <summary>
    /// Updates shipment status when a trip progresses (in_transit, delivered).
    /// Called by TripService whenever trip status changes.
    /// </summary>
    public async Task SyncStatusFromTripAsync(Guid shipmentId, string tripStatus)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null) return;

        shipment.Status = tripStatus switch
        {
            "assigned"   => "assigned",
            "in_transit" => "in_transit",
            "delivered"  => "delivered",
            _            => shipment.Status
        };

        await _ship.UpdateAsync(shipment);
    }
}