namespace FmpBackend.Models;

/// <summary>
/// One row per driver per QueueEvent.
/// Tracks the driver's ordered shipment list and how many from the top
/// they can currently act on (claimableCount).
///
/// ShipmentListJson is an ordered JSON array of DriverShipmentSlot items —
/// rebuilt on every mutation (window expiry, accept, pass, new shipment added).
/// The ShipmentQueueAssignment table is still the authoritative timer/history
/// record; this JSON is the derived read model that Flutter polls.
/// </summary>
public class DriverQueueEntry
{
    public Guid     Id               { get; set; }
    public Guid     QueueEventId     { get; set; }
    public Guid     DriverId         { get; set; }
    public int      Position         { get; set; }
    public DateTime ClaimWindowStart { get; set; }
    public DateTime ClaimWindowEnd   { get; set; }
    public bool     HasClaimed       { get; set; } = false;

    // ── New list model ────────────────────────────────────────────────────────

    /// <summary>
    /// JSON array of DriverShipmentSlot, ordered oldest shipment first.
    /// Rebuilt on every state mutation.
    /// </summary>
    public string ShipmentListJson { get; set; } = "[]";

    /// <summary>
    /// How many slots from the top of ShipmentListJson the driver can currently
    /// act on (Accept or still-claim).
    ///
    /// index &lt; ClaimableCount  → actionable (Accept button shown)
    ///   slot.IsExpired = false → active window, countdown running
    ///   slot.IsExpired = true  → timer gone, amber "Still Claimable"
    /// index ≥ ClaimableCount  → locked "Up Next"
    /// slot.IsSkipped = true   → driver passed it, hidden entirely
    /// </summary>
    public int ClaimableCount { get; set; } = 0;
}

/// <summary>
/// One entry in DriverQueueEntry.ShipmentListJson.
/// Serialised/deserialised with System.Text.Json.
/// </summary>
public class DriverShipmentSlot
{
    public Guid      ShipmentQueueId { get; set; }

    /// <summary>
    /// When this driver's window for this shipment expires.
    /// Null when the window hasn't opened yet OR has already expired.
    /// </summary>
    public DateTime? ExpiresAt       { get; set; }

    /// <summary>
    /// True once the timer fired — card turns amber "Still Claimable".
    /// Driver can still Accept until someone else takes it.
    /// </summary>
    public bool      IsExpired       { get; set; } = false;

    /// <summary>
    /// True when the driver explicitly passed this shipment.
    /// Hidden from their view; not passed to Flutter.
    /// Still present in the list so index positions stay stable for
    /// other drivers' count calculations.
    /// </summary>
    public bool      IsSkipped       { get; set; } = false;
}