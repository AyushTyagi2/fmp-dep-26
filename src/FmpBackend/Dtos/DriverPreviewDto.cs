using System;

namespace FmpBackend.Dtos;

public record DriverPreviewDto(
    Guid DriverId,
    string FullName,
    int? Age,
    int TotalTripsCompleted,
    DateTime? LastTripDate
);
