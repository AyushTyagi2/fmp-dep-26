namespace FmpBackend.Models;

public class Shipment
{
    public Guid Id { get; set; }
    public string ShipmentNumber { get; set; } = default!;

    public Guid SenderOrganizationId { get; set; }
    public Guid ReceiverOrganizationId { get; set; }
    public Guid CreatedByUserId { get; set; }

    public Guid PickupAddressId { get; set; }
    public Guid DropAddressId { get; set; }

    public string CargoType { get; set; } = default!;
    public string CargoDescription { get; set; } = default!;
    public decimal CargoWeightKg { get; set; }
    public decimal? CargoVolumeCubicMeters { get; set; }
    public int? PackageCount { get; set; }

    public bool RequiresRefrigeration { get; set; }
    public bool RequiresInsurance { get; set; }
    public string? SpecialHandlingInstructions { get; set; }

    public DateTime? PreferredPickupDate { get; set; }
    public DateTime? PreferredDeliveryDate { get; set; }
    public bool IsUrgent { get; set; }

    public decimal? AgreedPrice { get; set; }
    public string Currency { get; set; } = "INR";
    public string? PricePerUnit { get; set; }

    public decimal LoadingCharges { get; set; }
    public decimal UnloadingCharges { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal? TotalEstimatedPrice { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ApprovedAt { get; set; }
    public string? RejectionReason { get; set; }

    // ✅ Navigation properties for address resolution in queue DTO
    public Address? PickupAddress { get; set; }
    public Address? DropAddress { get; set; }

    public string Status { get; set; } = "pending_approval";
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}