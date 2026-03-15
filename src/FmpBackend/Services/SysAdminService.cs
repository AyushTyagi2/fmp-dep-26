using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class SysAdminService
{
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly TripRepository _trips;
    private readonly ShipmentRepository _shipments;
    private readonly SystemLogRepository _logs;
    private readonly SystemRuleRepository _rules;

    public SysAdminService(
        UserRepository users, 
        DriverRepository drivers, 
        TripRepository trips, 
        ShipmentRepository shipments,
        SystemLogRepository logs,
        SystemRuleRepository rules)
    {
        _users = users;
        _drivers = drivers;
        _trips = trips;
        _shipments = shipments;
        _logs = logs;
        _rules = rules;
    }

    public async Task<object> GetSystemMetricsAsync()
    {
        var activeDrivers = _drivers.CountTotalActiveDrivers();
        var pendingShipments = await _shipments.CountPendingShipmentsAsync();
        var activeTrips = _trips.CountAllActiveTrips();
        
        return new
        {
            activeDrivers,
            pendingShipments,
            activeTrips,
            alerts = 3 // To be implemented with dynamic alert aggregation
        };
    }

    public async Task<IEnumerable<object>> GetRecentLogsAsync()
    {
        var recentLogs = await _logs.GetRecentLogsAsync(50);
        return recentLogs.Select(l => new 
        {
            id = l.Id,
            timestamp = l.Timestamp,
            level = l.Level,
            message = l.Message,
            component = l.Component
        });
    }

    public async Task<IEnumerable<object>> GetActiveUsersAsync()
    {
        var users = await _users.GetAllUsersAsync();
        return users.Select(u => new 
        {
            id = u.Id,
            name = u.FullName,
            phone = u.Phone,
            role = u.Role,
            status = u.IsActive ? "Active" : "Suspended",
            provider = u.AuthProvider,
            createdAt = u.CreatedAt
        });
    }

    public async Task<bool> UpdateUserRoleAsync(Guid id, string role)
    {
        var user = _users.GetById(id);
        if (user == null) return false;

        user.Role = role;
        _users.Update(user);
        await _logs.AddLogAsync("INFO", $"User {id} role updated to {role}", "user-management");
        return true;
    }

    public async Task<bool> ToggleUserStatusAsync(Guid id, bool isActive)
    {
        var user = _users.GetById(id);
        if (user == null) return false;

        user.IsActive = isActive;
        _users.Update(user);
        await _logs.AddLogAsync("INFO", $"User {id} status updated to Active={isActive}", "user-management");
        return true;
    }

    public async Task<bool> ResetUserPasswordAsync(Guid id, string newPasswordHash)
    {
        var user = _users.GetById(id);
        if (user == null) return false;

        user.PasswordHash = newPasswordHash;
        _users.Update(user);
        await _logs.AddLogAsync("INFO", $"User {id} password reset", "user-management");
        return true;
    }

    public async Task<bool> DeleteUserAsync(Guid id)
    {
        var success = await _users.DeleteUserAsync(id);
        if (success)
        {
            await _logs.AddLogAsync("INFO", $"User {id} deleted", "user-management");
        }
        return success;
    }

    public async Task<IEnumerable<object>> GetSystemRulesAsync()
    {
        var rules = await _rules.GetAllRulesAsync();
        return rules.Select(r => new 
        {
            id = r.Id,
            ruleKey = r.RuleKey,
            description = r.Description,
            isEnabled = r.IsEnabled,
            value = r.Value
        });
    }

    public async Task<object> UpdateSystemRuleAsync(string key, bool isEnabled, string? value = null)
    {
        var updated = await _rules.UpdateRuleAsync(key, isEnabled, value);
        await _logs.AddLogAsync("INFO", $"System rule '{key}' updated to {isEnabled}", "rule-engine");
        
        return new 
        {
            id = updated.Id,
            ruleKey = updated.RuleKey,
            isEnabled = updated.IsEnabled,
            value = updated.Value
        };
    }

    public async Task<IEnumerable<object>> GetActiveQueuesAsync(ShipmentQueueRepository queueRepo)
    {
        var queues = await queueRepo.GetActiveQueuesAsync();
        
        return queues.Select(q => new
        {
            queueId = $"Q-{q.Id.ToString().Substring(0, 4).ToUpper()}-{q.Shipment.CargoType?.Substring(0, 3).ToUpper() ?? "GEN"}",
            title = $"Shipment {q.Shipment.ShipmentNumber} ({q.Shipment.PickupAddress?.City ?? "Unknown"} to {q.Shipment.DropAddress?.City ?? "Unknown"})",
            status = q.Status == "waiting" ? "queued" 
                   : q.Status == "offered" ? "processing" 
                   : q.Status == "accepted" ? "completed" : "failed",
            progress = q.Status == "accepted" ? 1.0 : q.Status == "offered" ? 0.5 : 0.0,
            itemsProcessed = q.Status == "accepted" ? 1 : 0,
            totalItems = 1
        });
    }
}