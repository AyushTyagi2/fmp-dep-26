namespace FmpBackend.Dtos;

public record TripDto(
    Guid    Id,
    string  TripNumber,
    Guid    ShipmentId,
    string  ShipmentNumber,
    Guid    VehicleId,
    Guid    DriverId,
    Guid?   AssignedUnionId,
    Guid    AssignedFleetOwnerId,
    DateTime? PlannedStartTime,
    DateTime? PlannedEndTime,
    decimal? EstimatedDistanceKm,
    decimal? EstimatedDurationHours,
    DateTime? ActualStartTime,
    DateTime? ActualEndTime,
    decimal? ActualDistanceKm,
    string  CurrentStatus,
    decimal? CurrentLatitude,
    decimal? CurrentLongitude,
    DateTime? LastLocationUpdateAt,
    DateTime? DeliveredAt,
    string? DeliveredToName,
    string? ProofOfDeliveryUrl,
    string? DeliveryNotes,
    int?   SenderRating,
    int?   ReceiverRating,
    decimal? DriverPaymentAmount,
    string  DriverPaymentStatus,
    bool   HasIssues,
    string? IssueDescription,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    DateTime? CompletedAt,

    string SenderName,
    string ReceiverName
);

public record CreateTripRequest(
    Guid    ShipmentId,
    Guid    VehicleId,
    Guid    DriverId,
    Guid?   AssignedUnionId,
    Guid    AssignedFleetOwnerId,
    Guid?   AssignedBy,
    DateTime? PlannedStartTime,
    DateTime? PlannedEndTime,
    decimal? EstimatedDistanceKm,
    decimal? EstimatedDurationHours
);

public record UpdateTripStatusRequest(
    string  Status,
    decimal? Latitude,
    decimal? Longitude,
    string? DelayReason,
    string? IssueDescription
);

public record CompleteDeliveryRequest(
    string  DeliveredToName,
    string  DeliveredToPhone,
    string? ProofOfDeliveryUrl,
    string? DeliveryNotes
);

public record UpdateLocationRequest(
    decimal Latitude,
    decimal Longitude
);

public record RateShipmentRequest(
    int    Rating,
    string? Feedback,
    string  RaterRole  // "sender" or "receiver"
);
