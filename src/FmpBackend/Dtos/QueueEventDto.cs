namespace FmpBackend.Dtos;

/// <summary>
/// Returned by GET /api/queue-events/active?driverId={id}
/// Contains the driver's slot AND their current highlighted offer.
/// </summary>
public record ActiveEventDto(
    bool             Active,
    Guid             EventId,
    string           EventStatus,
    DateTime         EventEndTime,
    int              Position,
    bool             HasClaimed,
    string           OfferStatus,
    CurrentOfferDto? CurrentOffer,   // null when driver has no pending offer
    List<UpcomingShipmentDto> UpcomingShipments
);
public record UpcomingShipmentDto(
    Guid     ShipmentQueueId,
    string   ShipmentNumber,
    string   PickupLocation,
    string   DropLocation,
    decimal? AgreedPrice,
    bool     IsUrgent
);
/// <summary>
/// The one shipment currently offered to this driver — pinned at top in Flutter.
/// </summary>
public record CurrentOfferDto(
    Guid     ShipmentQueueId,
    Guid     ShipmentId,
    string   ShipmentNumber,
    string   PickupLocation,
    string   DropLocation,
    string   CargoType,
    decimal  CargoWeightKg,
    decimal? AgreedPrice,
    bool     IsUrgent,
    DateTime? ExpiresAt
);

/// <summary>Response body for Pass action.</summary>
/// NextSlot is the driver's updated queue slot returned inline after the pass.
/// Flutter applies it immediately so the UI jumps straight to the next offer
/// without a "Waiting for offer" spinner flash.
public record PassOfferResponse(bool Success, string? Message, ActiveEventDto? NextSlot = null);