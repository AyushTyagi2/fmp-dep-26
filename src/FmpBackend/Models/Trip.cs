namespace FmpBackend.Models;

public class Trip
{
    public Guid    Id                      { get; set; }
    public string  TripNumber              { get; set; } = string.Empty;

    // References
    public Guid    ShipmentId              { get; set; }
    public Guid    VehicleId               { get; set; }
    public Guid    DriverId                { get; set; }
    public Guid?   AssignedUnionId         { get; set; }
    public Guid    AssignedFleetOwnerId    { get; set; }

    // Assignment
    public Guid?   AssignedBy              { get; set; }
    public DateTime AssignedAt             { get; set; }

    // Planned Schedule
    public DateTime? PlannedStartTime      { get; set; }
    public DateTime? PlannedEndTime        { get; set; }
    public decimal?  EstimatedDistanceKm   { get; set; }
    public decimal?  EstimatedDurationHours { get; set; }

    // Actual Execution
    public DateTime? ActualStartTime       { get; set; }
    public DateTime? ActualEndTime         { get; set; }
    public decimal?  ActualDistanceKm      { get; set; }

    // Status
    public string  CurrentStatus           { get; set; } = "created";

    // Current Location
    public decimal? CurrentLatitude        { get; set; }
    public decimal? CurrentLongitude       { get; set; }
    public DateTime? LastLocationUpdateAt  { get; set; }

    // Delivery Confirmation
    public DateTime? DeliveredAt           { get; set; }
    public string?  DeliveredToName        { get; set; }
    public string?  DeliveredToPhone       { get; set; }
    public string?  ProofOfDeliveryUrl     { get; set; }
    public string?  DeliveryNotes          { get; set; }

    // Ratings
    public int?    SenderRating            { get; set; }
    public string? SenderFeedback          { get; set; }
    public int?    ReceiverRating          { get; set; }
    public string? ReceiverFeedback        { get; set; }

    // Financials
    public decimal? DriverPaymentAmount    { get; set; }
    public string   DriverPaymentStatus    { get; set; } = "pending";
    public DateTime? DriverPaidAt          { get; set; }

    // Issues
    public bool    HasIssues               { get; set; }
    public string? IssueDescription        { get; set; }
    public string? DelayReason             { get; set; }

    // Metadata
    public DateTime CreatedAt              { get; set; }
    public DateTime UpdatedAt              { get; set; }
    public DateTime? CompletedAt           { get; set; }

    // Navigation
    public Shipment Shipment { get; set; } = null!;
}