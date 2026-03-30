namespace FmpBackend.Dtos;

public record TimePointDto(string DateStr, decimal Value);
public record PieSliceDto(string Label, int Count);
public record MetricCardDto(string Title, string Value, string? Subtitle = null);

// Admins
public record SysAdminAnalyticsDto(
    List<TimePointDto> PlatformActivity, // e.g. Daily Trips Created
    List<PieSliceDto> ShipmentStatusBreakdown,
    List<MetricCardDto> KeyMetrics
);

// Senders
public record SenderAnalyticsDto(
    List<TimePointDto> LogisticsSpend, // Daily Estimated/Agreed Price sum
    List<PieSliceDto> ShipmentStatusBreakdown,
    List<MetricCardDto> KeyMetrics
);

// Drivers
public record DriverAnalyticsDto(
    List<TimePointDto> DailyEarnings, // Daily payment sums
    List<MetricCardDto> KeyMetrics
);

// Unions
public record UnionAnalyticsDto(
    List<TimePointDto> DailyTripsManaged,
    List<PieSliceDto> FleetStatusBreakdown,
    List<MetricCardDto> KeyMetrics
);
