namespace FmpBackend.Dtos;
public class CreateShipmentRequest
{
    public string SenderPhone { get; set; } = null!;
    public string ReceiverPhone { get; set; } = null!;

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
    public string? PricePerUnit { get; set; }

    public decimal LoadingCharges { get; set; }
    public decimal UnloadingCharges { get; set; }
    public decimal OtherCharges { get; set; }

    public string? InvoiceNumber { get; set; }
    public decimal? InvoiceValue { get; set; }
    public string? EwayBillNumber { get; set; }
}
