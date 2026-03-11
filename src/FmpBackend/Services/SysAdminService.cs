using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class SysAdminService
{
    private readonly UserRepository _users;

    public SysAdminService(UserRepository users)
    {
        _users = users;
    }

    public object GetSystemMetrics()
    {
        // Mocking metrics data as there is no robust metric repository yet
        return new
        {
            activeDrivers = 42,
            pendingShipments = 15,
            activeTrips = 8,
            openDisputes = 2
        };
    }

    public IEnumerable<object> GetRecentLogs()
    {
        // Mocking recent log events 
        var logs = new List<object>
        {
            new { id = 1, timestamp = DateTime.UtcNow.AddMinutes(-10), level = "INFO", message = "System configuration updated" },
            new { id = 2, timestamp = DateTime.UtcNow.AddMinutes(-45), level = "WARNING", message = "Failed login attempt from IP 192.168.1.100" },
            new { id = 3, timestamp = DateTime.UtcNow.AddHours(-2), level = "ERROR", message = "Database connection timeout in billing module" },
            new { id = 4, timestamp = DateTime.UtcNow.AddHours(-3), level = "INFO", message = "New fleet owner registered: 'TransCore Logistics'" }
        };

        return logs;
    }

    public IEnumerable<object> GetActiveUsers()
    {
        // Fetching real user data leveraging the UserRepository if needed, or returning mock list.
        // For simplicity and error-free compilation right now, returning a static structure.
        var users = new List<object>
        {
            new { id = Guid.NewGuid(), name = "Super Admin Profile", role = "SUPER_ADMIN", status = "Active", lastActive = DateTime.UtcNow.AddMinutes(-5) },
            new { id = Guid.NewGuid(), name = "John Doe", role = "DRIVER", status = "On Trip", lastActive = DateTime.UtcNow.AddMinutes(-1) },
            new { id = Guid.NewGuid(), name = "Acme Inc", role = "ORGANIZATION", status = "Active", lastActive = DateTime.UtcNow.AddHours(-1) }
        };

        return users;
    }
}