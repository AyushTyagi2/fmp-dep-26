namespace FmpBackend.Models;

/// <summary>
/// ✅ FIX: Centralized status constants replace raw magic strings throughout the codebase.
/// Before: shipment.Status = "pending_approval"  (typo-prone, scattered)
/// After:  shipment.Status = ShipmentStatus.PendingApproval
/// </summary>

public static class ShipmentStatus
{
    public const string Draft           = "draft";
    public const string PendingApproval = "pending_approval";
    public const string Approved        = "approved";
    public const string Rejected        = "rejected";
    public const string Assigned        = "assigned";
    public const string InTransit       = "in_transit";
    public const string Delivered       = "delivered";
    public const string Cancelled       = "cancelled";
}

public static class TripStatus
{
    public const string Created       = "created";
    public const string Assigned      = "assigned";
    public const string Started       = "started";
    public const string ReachedPickup = "reached_pickup";
    public const string Loaded        = "loaded";
    public const string InTransit     = "in_transit";
    public const string ReachedDrop   = "reached_drop";
    public const string Unloaded      = "unloaded";
    public const string Delivered     = "delivered";
    public const string Completed     = "completed";
    public const string Cancelled     = "cancelled";

    public static readonly string[] ActiveStatuses =
        { Assigned, Started, ReachedPickup, Loaded, InTransit, ReachedDrop, Unloaded };

    public static readonly string[] InactiveStatuses = { Completed, Delivered, Cancelled };
}

public static class ShipmentQueueStatus
{
    public const string Waiting  = "waiting";
    public const string Offered  = "offered";
    public const string Accepted = "accepted";
    public const string Expired  = "expired";
}

public static class QueueEventStatus
{
    public const string Live   = "live";
    public const string Closed = "closed";
}

public static class DriverAvailabilityStatus
{
    public const string Available   = "available";
    public const string OnTrip      = "on_trip";
    public const string Unavailable = "unavailable";
}

public static class VehicleStatus
{
    public const string Available   = "available";
    public const string OnTrip      = "on_trip";
    public const string Maintenance = "maintenance";
}

public static class DriverPaymentStatus
{
    public const string Pending  = "pending";
    public const string Paid     = "paid";
    public const string Disputed = "disputed";
}