using FmpBackend.Repositories;
using System.Text.RegularExpressions;

namespace FmpBackend.Services;

public class RoleService
{
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly OrganizationRepository _orgs;
    private readonly FleetOwnerRepository _fleets;

    public RoleService(
        UserRepository users,
        DriverRepository drivers,
        OrganizationRepository orgs,
        FleetOwnerRepository fleets)
    {
        _users = users;
        _drivers = drivers;
        _orgs = orgs;
        _fleets = fleets;
    }

    public string Resolve(string phone, string role)
    {
        Console.WriteLine("=== ROLE RESOLUTION ===");
        Console.WriteLine($"Phone: {phone}");
        Console.WriteLine($"Role: {role}");

        // Normalize role input: accept camelCase, kebab-case, snake_case, etc.
        if (role == null) role = string.Empty;
        // Convert camelCase to snake_case (e.g., fleetOwner -> fleet_owner)
        role = Regex.Replace(role, "([a-z0-9])([A-Z])", "$1_$2");
        // Replace dashes with underscores and lowercase
        role = role.Replace('-', '_').ToLowerInvariant();

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

        // 4. Fleet owner role
        if (role == "fleet_owner")
        {
            var fleet = _fleets.GetByUserId(user.Id);
            return fleet != null
                ? "fleet_dashboard"
                : "fleet_onboarding";
        }

        return "unknown";
    }
}
