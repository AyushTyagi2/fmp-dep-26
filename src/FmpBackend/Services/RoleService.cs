using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class RoleService
{
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly OrganizationRepository _orgs;

    public RoleService(
        UserRepository users,
        DriverRepository drivers,
        OrganizationRepository orgs)
    {
        _users = users;
        _drivers = drivers;
        _orgs = orgs;
    }

    public string Resolve(string phone, string role)
    {
        Console.WriteLine("=== ROLE RESOLUTION ===");
        Console.WriteLine($"Phone: {phone}");
        Console.WriteLine($"Role: {role}");

        // 1. User must exist (OTP already verified)
        var user = _users.GetByPhone(phone);
        if (user == null)
        {
            Console.WriteLine("User not found");
            return "login";
        }

        // 2. Driver role
        if (role == "driver")
        {
            var driver = _drivers.GetByUserId(user.Id);
            return driver != null
                ? "driver_dashboard"
                : "driver_onboarding";
        }

        // 3. Sender / Receiver role
        if (role == "organization")
        {
            var org = _orgs.GetByPhone(phone);
            return org != null
                ? "sender_dashboard"
                : "sender_onboarding";
        }

        return "unknown";
    }
}
