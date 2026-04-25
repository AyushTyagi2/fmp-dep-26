namespace FmpBackend.Dtos;

// ─── Queue event list summary (GET /api/queue-events) ────────────────────────

public record QueueEventSummaryDto(
    Guid     Id,
    string   Status,        // "live" | "closed"
    DateTime StartTime,
    DateTime EndTime,
    int      WindowSeconds
);


// ─── Active event response (GET /api/queue-events/active?driverId=) ──────────

/// <summary>
/// Returned by GET /api/queue-events/active?driverId={id}
///
/// ShipmentSlots is the driver's full ordered shipment list.
/// ClaimableCount tells Flutter how many from the top are actionable:
///   index &lt; ClaimableCount  → Accept button shown
///   index ≥ ClaimableCount  → locked "Up Next" preview
/// Skipped slots are excluded before sending to Flutter.
/// </summary>
public record ActiveEventDto(
    bool                    Active,
    Guid                    EventId,
    string                  EventStatus,
    DateTime                EventEndTime,
    int                     Position,
    bool                    HasClaimed,
    int                     ClaimableCount,
    List<ShipmentSlotDto>   ShipmentSlots   // ordered, skipped items removed
);

/// <summary>
/// One shipment in the driver's ordered list.
///
/// isExpired = false, expiresAt != null  → active window, show countdown
/// isExpired = true,  expiresAt = null   → amber "Still Claimable", no timer
/// index >= claimableCount               → locked, show as "Up Next"
/// </summary>
public record ShipmentSlotDto(
    Guid     ShipmentQueueId,
    Guid     ShipmentId,
    string   ShipmentNumber,
    string   PickupLocation,
    string   DropLocation,
    string   CargoType,
    decimal  CargoWeightKg,
    decimal? AgreedPrice,
    bool     IsUrgent,
    bool     IsExpired,
    DateTime? ExpiresAt   // null when window not active or already expired
);

// ─── Pass response ────────────────────────────────────────────────────────────

/// <summary>
/// Response body for POST /api/shipment-queue/{id}/pass
/// NextSlot is the driver's rebuilt ActiveEventDto — applied inline by Flutter
/// so the UI updates immediately without waiting for the next poll.
/// </summary>
public record PassOfferResponse(
    bool            Success,
    string?         Message,
    ActiveEventDto? NextSlot = null
);