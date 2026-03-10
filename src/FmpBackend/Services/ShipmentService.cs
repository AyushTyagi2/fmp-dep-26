using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class ShipmentService
{
    private readonly ShipmentRepository _ship;
    private readonly OrganizationRepository _orgRepo;
    private readonly UserRepository _userRepo;
    private readonly AddressRepository _addressRepo;
    private readonly ShipmentQueueService _queueService;

    public ShipmentService(
        ShipmentRepository ship,
        OrganizationRepository orgRepo,
        UserRepository userRepo,
        AddressRepository addressRepo,
        ShipmentQueueService queueService)
    {
        _ship = ship;
        _orgRepo = orgRepo;
        _userRepo = userRepo;
        _addressRepo = addressRepo;
        _queueService = queueService;
    }

    public async Task<Shipment> CreateShipmentAsync(CreateShipmentRequest request)
    {
        var shipmentNumber = $"SHP-{DateTime.UtcNow.Ticks}";

        var senderOrg = await _orgRepo.GetByPhoneAsync(request.SenderPhone);
        if (senderOrg == null)
            throw new Exception("Sender organization not found");

        var receiverOrg = await _orgRepo.GetByPhoneAsync(request.ReceiverPhone);
        if (receiverOrg == null)
            throw new Exception("Receiver organization not found");

        var user = await _userRepo.GetByPhoneAsync(request.SenderPhone);
        if (user == null)
            throw new Exception("User not found");

        var pickupAddress = await _addressRepo
            .GetDefaultByOwnerAsync(senderOrg.Id, "organization");
        if (pickupAddress == null)
            throw new Exception("Pickup address not found");

        var dropAddress = await _addressRepo
            .GetDefaultByOwnerAsync(receiverOrg.Id, "organization");
        if (dropAddress == null)
            throw new Exception("Drop address not found");

        var shipment = new Shipment
        {
            Id = Guid.NewGuid(),
            ShipmentNumber = shipmentNumber,
            SenderOrganizationId = senderOrg.Id,
            ReceiverOrganizationId = receiverOrg.Id,
            CreatedByUserId = user.Id,
            PickupAddressId = pickupAddress.Id,
            DropAddressId = dropAddress.Id,
            CargoType = request.CargoType,
            CargoDescription = request.CargoDescription,
            CargoWeightKg = request.CargoWeightKg,
            CargoVolumeCubicMeters = request.CargoVolumeCubicMeters,
            PackageCount = request.PackageCount,
            RequiresRefrigeration = request.RequiresRefrigeration,
            RequiresInsurance = request.RequiresInsurance,
            SpecialHandlingInstructions = request.SpecialHandlingInstructions,
            PreferredPickupDate = request.PreferredPickupDate.HasValue
    ? DateTime.SpecifyKind(request.PreferredPickupDate.Value, DateTimeKind.Utc)
    : null,
PreferredDeliveryDate = request.PreferredDeliveryDate.HasValue
    ? DateTime.SpecifyKind(request.PreferredDeliveryDate.Value, DateTimeKind.Utc)
    : null,
            IsUrgent = request.IsUrgent,
            AgreedPrice = request.AgreedPrice,
            PricePerUnit = request.PricePerUnit,
            LoadingCharges = request.LoadingCharges,
            UnloadingCharges = request.UnloadingCharges,
            OtherCharges = request.OtherCharges,
            Status = "pending_approval",
            CreatedAt = DateTime.UtcNow
        };

        return await _ship.CreateAsync(shipment);
    }

    public async Task<object> GetShipmentsByPhoneAsync(string phone)
    {
        var org = await _orgRepo.GetByPhoneAsync(phone);
        if (org == null)
            throw new Exception("Organization not found");

        var sent = await _ship.GetSentShipmentsAsync(org.Id);
        var received = await _ship.GetReceivedShipmentsAsync(org.Id);

        return new
        {
            sent = sent.Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.CreatedAt }),
            received = received.Select(s => new { s.Id, s.ShipmentNumber, s.CargoType, s.Status, s.CreatedAt })
        };
    }

    public async Task<List<object>> GetPendingShipmentsAsync()
    {
        var shipments = await _ship.GetByStatusAsync("pending_approval");
        return shipments.Select(s => new
        {
            s.Id,
            s.ShipmentNumber,
            s.CargoType,
            s.CargoWeightKg,
            s.Status,
            s.CreatedAt
        }).Cast<object>().ToList();
    }

    /// <summary>
    /// Approves a shipment and automatically enqueues it so drivers see it instantly.
    /// </summary>
    public async Task<bool> ApproveShipmentAsync(Guid shipmentId)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null)
            return false;

        if (shipment.Status != "pending_approval")
            throw new Exception("Shipment is not pending approval");

        shipment.Status = "approved";
        shipment.ApprovedAt = DateTime.UtcNow;
        await _ship.UpdateAsync(shipment);

        // ✅ KEY FIX: auto-enqueue so it appears on Union/Driver queue immediately
        await _queueService.EnqueueAsync(shipmentId, null, null);

        return true;
    }

    public async Task<bool> RejectShipmentAsync(Guid shipmentId, string reason)
    {
        var shipment = await _ship.GetByIdAsync(shipmentId);
        if (shipment == null)
            return false;

        shipment.Status = "rejected";
        shipment.RejectionReason = reason;
        await _ship.UpdateAsync(shipment);
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