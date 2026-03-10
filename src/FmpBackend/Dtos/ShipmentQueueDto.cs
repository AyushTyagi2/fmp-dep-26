namespace FmpBackend.Dtos;

public record ShipmentQueueDto(
    Guid    Id,
    Guid    ShipmentId,
    string  ShipmentNumber,
    Guid?   ZoneId,
    string? RequiredVehicleType,
    string  Status,
    Guid?   CurrentDriverId,
    DateTime? OfferExpiresAt,
    DateTime  CreatedAt,
    string  CargoType,
    decimal CargoWeightKg,
    // ✅ Resolved human-readable strings e.g. "Delhi, UP" instead of raw GUIDs
    string  PickupLocation,
    string  DropLocation,
    decimal? AgreedPrice,
    bool    IsUrgent
);

public record AcceptQueueItemRequest(Guid DriverId);

// ✅ Accept now returns TripId so Flutter can navigate directly to the active trip
public record AcceptQueueItemResponse(bool Success, Guid? TripId, string? Message);

public record OfferQueueItemRequest(Guid DriverId, DateTime OfferExpiresAt);