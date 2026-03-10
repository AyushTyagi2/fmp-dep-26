namespace FmpBackend.Dtos;

public record CreateQueueEventRequest(
    Guid?  ZoneId,
    double DurationHours,
    int    WindowSeconds
);