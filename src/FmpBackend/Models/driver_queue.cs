namespace FmpBackend.Models;

public class DriverQueueEntry
{
    public Guid     Id                { get; set; }
    public Guid     QueueEventId      { get; set; }
    public Guid     DriverId          { get; set; }
    public int      Position          { get; set; }
    public DateTime ClaimWindowStart  { get; set; }
    public DateTime ClaimWindowEnd    { get; set; }
    public bool     HasClaimed        { get; set; } = false;

    // ── Parallel offer tracking ──────────────────────────────────────────────
    /// <summary>Which ShipmentQueue item is currently being offered to this driver.</summary>
    public Guid?    CurrentOfferedShipmentQueueId { get; set; }

    /// <summary>idle | pending | accepted | passed | expired</summary>
    public string   OfferStatus { get; set; } = DriverOfferStatus.Idle;

    // Navigation
    public ShipmentQueue? CurrentOfferedShipment { get; set; }
}

public static class DriverOfferStatus
{
    public const string Idle     = "idle";
    public const string Pending  = "pending";
    public const string Accepted = "accepted";
    public const string Passed   = "passed";
    public const string Expired  = "expired";
}