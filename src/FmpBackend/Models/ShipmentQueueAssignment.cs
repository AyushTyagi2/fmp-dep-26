namespace FmpBackend.Models;

/// <summary>
/// Tracks which driver was offered which shipment and what happened.
/// Provides full history of offer routing for a given QueueEvent.
/// </summary>
public class ShipmentQueueAssignment
{
    public Guid     Id               { get; set; }
    public Guid     QueueEventId     { get; set; }

    /// <summary>The ShipmentQueue row being offered.</summary>
    public Guid     ShipmentQueueId  { get; set; }

    public Guid     DriverId         { get; set; }

    /// <summary>Driver's position in the QueueEvent.</summary>
    public int      DriverPosition   { get; set; }

    public DateTime OfferedAt        { get; set; }
    public DateTime ExpiresAt        { get; set; }

    /// <summary>pending | accepted | passed | expired</summary>
    public string   Outcome          { get; set; } = AssignmentOutcome.Pending;

    // Navigations
    public ShipmentQueue?  ShipmentQueue { get; set; }
    public QueueEvent?     QueueEvent    { get; set; }
}

public static class AssignmentOutcome
{
    public const string Pending  = "pending";
    public const string Accepted = "accepted";
    public const string Passed   = "passed";
    public const string Expired  = "expired";
}