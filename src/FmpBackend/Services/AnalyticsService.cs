using FmpBackend.Data;
using FmpBackend.Dtos;
using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using System.Globalization;

namespace FmpBackend.Services;

public class AnalyticsService
{
    private readonly AppDbContext _context;

    public AnalyticsService(AppDbContext context)
    {
        _context = context;
    }

    // ── SYS ADMIN ──
    public async Task<SysAdminAnalyticsDto> GetSysAdminAnalyticsAsync()
    {
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        // Platform Activity (Trips per day)
        var tripsPerDay = await _context.Trips
            .Where(t => t.CreatedAt >= sevenDaysAgo)
            .GroupBy(t => t.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        var platformActivity = Enumerable.Range(0, 7)
            .Select(offset => DateTime.UtcNow.Date.AddDays(-offset))
            .OrderBy(d => d)
            .Select(d => new TimePointDto(
                d.ToString("MMM dd", CultureInfo.InvariantCulture),
                tripsPerDay.FirstOrDefault(x => x.Date == d)?.Count ?? 0))
            .ToList();

        // Shipment Status Breakdown
        var statusCounts = await _context.Shipments
            .GroupBy(s => s.Status)
            .Select(g => new PieSliceDto(g.Key, g.Count()))
            .ToListAsync();

        // Key Metrics
        var totalUsers = await _context.Users.CountAsync();
        var totalTrips = await _context.Trips.CountAsync();
        var totalRevenue = await _context.Shipments.SumAsync(s => s.AgreedPrice ?? 0);

        var keyMetrics = new List<MetricCardDto>
        {
            new("Total Users", totalUsers.ToString("N0")),
            new("Total Trips", totalTrips.ToString("N0")),
            new("Total Revenue Volume", $"₹{totalRevenue:N0}")
        };

        return new SysAdminAnalyticsDto(platformActivity, statusCounts, keyMetrics);
    }

    // ── SENDER ──
    public async Task<SenderAnalyticsDto> GetSenderAnalyticsAsync(Guid senderOrganizationId)
    {
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        // Logistics Spend
        var dailySpend = await _context.Shipments
            .Where(s => s.SenderOrganizationId == senderOrganizationId && s.CreatedAt >= sevenDaysAgo)
            .GroupBy(s => s.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Total = g.Sum(x => x.AgreedPrice ?? 0) })
            .ToListAsync();

        var spendOverTime = Enumerable.Range(0, 7)
            .Select(offset => DateTime.UtcNow.Date.AddDays(-offset))
            .OrderBy(d => d)
            .Select(d => new TimePointDto(
                d.ToString("MMM dd", CultureInfo.InvariantCulture),
                dailySpend.FirstOrDefault(x => x.Date == d)?.Total ?? 0))
            .ToList();

        // Status Breakdown
        var statusCounts = await _context.Shipments
            .Where(s => s.SenderOrganizationId == senderOrganizationId)
            .GroupBy(s => s.Status)
            .Select(g => new PieSliceDto(g.Key, g.Count()))
            .ToListAsync();

        // Key Metrics
        var totalShipments = await _context.Shipments.CountAsync(s => s.SenderOrganizationId == senderOrganizationId);
        var activeShipments = await _context.Shipments.CountAsync(s => s.SenderOrganizationId == senderOrganizationId && s.Status == "in_transit");
        var totalSpend = await _context.Shipments.Where(s => s.SenderOrganizationId == senderOrganizationId).SumAsync(s => s.AgreedPrice ?? 0);

        var keyMetrics = new List<MetricCardDto>
        {
            new("Total Shipments", totalShipments.ToString("N0")),
            new("Active (In Transit)", activeShipments.ToString("N0")),
            new("Total Logistics Spend", $"₹{totalSpend:N0}")
        };

        return new SenderAnalyticsDto(spendOverTime, statusCounts, keyMetrics);
    }

    // ── DRIVER ──
    public async Task<DriverAnalyticsDto> GetDriverAnalyticsAsync(Guid driverId)
    {
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        // Daily Earnings
        var dailyEarnings = await _context.Trips
            .Where(t => t.DriverId == driverId && t.CreatedAt >= sevenDaysAgo)
            .GroupBy(t => t.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Total = g.Sum(x => x.DriverPaymentAmount ?? 0) })
            .ToListAsync();

        var earningsOverTime = Enumerable.Range(0, 7)
            .Select(offset => DateTime.UtcNow.Date.AddDays(-offset))
            .OrderBy(d => d)
            .Select(d => new TimePointDto(
                d.ToString("MMM dd", CultureInfo.InvariantCulture),
                dailyEarnings.FirstOrDefault(x => x.Date == d)?.Total ?? 0))
            .ToList();

        // Key Metrics
        var totalTripsCompleted = await _context.Trips.CountAsync(t => t.DriverId == driverId && t.CurrentStatus == "completed");
        var totalDistance = await _context.Trips.Where(t => t.DriverId == driverId).SumAsync(t => t.ActualDistanceKm ?? 0);
        var totalEarned = await _context.Trips.Where(t => t.DriverId == driverId).SumAsync(t => t.DriverPaymentAmount ?? 0);

        var keyMetrics = new List<MetricCardDto>
        {
            new("Trips Completed", totalTripsCompleted.ToString("N0")),
            new("Total Distance (Km)", totalDistance.ToString("N0")),
            new("Total Earned", $"₹{totalEarned:N0}")
        };

        return new DriverAnalyticsDto(earningsOverTime, keyMetrics);
    }

    // ── UNION / FLEET ──
    public async Task<UnionAnalyticsDto> GetUnionAnalyticsAsync(Guid fleetOwnerId)
    {
        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

        // Daily Trips Managed
        var dailyTrips = await _context.Trips
            .Where(t => t.AssignedFleetOwnerId == fleetOwnerId && t.CreatedAt >= sevenDaysAgo)
            .GroupBy(t => t.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        var tripsOverTime = Enumerable.Range(0, 7)
            .Select(offset => DateTime.UtcNow.Date.AddDays(-offset))
            .OrderBy(d => d)
            .Select(d => new TimePointDto(
                d.ToString("MMM dd", CultureInfo.InvariantCulture),
                dailyTrips.FirstOrDefault(x => x.Date == d)?.Count ?? 0))
            .ToList();

        // Fleet Status
        var statusCounts = await _context.Vehicles
            .Where(v => v.FleetOwnerId == fleetOwnerId)
            .GroupBy(v => v.Status)
            .Select(g => new PieSliceDto(g.Key, g.Count()))
            .ToListAsync();
            
        // Key Metrics
        var totalVehicles = await _context.Vehicles.CountAsync(v => v.FleetOwnerId == fleetOwnerId);
        var activeTrips = await _context.Trips.CountAsync(t => t.AssignedFleetOwnerId == fleetOwnerId && t.CurrentStatus == "in_transit");

        var keyMetrics = new List<MetricCardDto>
        {
            new("Total Vehicles", totalVehicles.ToString("N0")),
            new("Active Trips", activeTrips.ToString("N0"))
        };

        return new UnionAnalyticsDto(tripsOverTime, statusCounts, keyMetrics);
    }
}
