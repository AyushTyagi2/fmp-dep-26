using FmpBackend.Repositories;
using System.Text.RegularExpressions;

namespace FmpBackend.Services;

public class RoleService
{
    private readonly UserRepository         _users;
    private readonly DriverRepository       _drivers;
    private readonly OrganizationRepository _orgs;
    private readonly FleetOwnerRepository   _fleets;

    public RoleService(
        UserRepository users,
        DriverRepository drivers,
        OrganizationRepository orgs,
        FleetOwnerRepository fleets)
    {
        _users   = users;
        _drivers = drivers;
        _orgs    = orgs;
        _fleets  = fleets;
    }

    public string Resolve(string email, string role)
    {
        Console.WriteLine("=== ROLE RESOLUTION ===");
        Console.WriteLine($"Email: {email}, Role: {role}");

        if (role == null) role = string.Empty;
        role = Regex.Replace(role, "([a-z0-9])([A-Z])", "$1_$2");
        role = role.Replace('-', '_').ToLowerInvariant();

        var user = _users.GetByEmail(email);
        if (user == null) return "login";

        // Fetch actual roles from DB
        var userRoles = _users.GetRolesByUserId(user.Id)
                              .Select(r => r.ToLowerInvariant())
                              .ToList();

        Console.WriteLine($"User DB roles: {string.Join(", ", userRoles)}");

        if (role == "super_admin" || role == "admin")
            return userRoles.Contains(role) ? "admin_dashboard" : "unauthorized";

        if (role == "union_manager")
            return userRoles.Contains(role) ? "union_dashboard" : "unauthorized";

        if (role == "driver")
        {
            var driver = _drivers.GetByUserId(user.Id);
            return driver != null ? "driver_dashboard" : "driver_onboarding";
        }

        if (role == "organization")
        {
            var org = _orgs.GetByEmail(email);
            return org != null ? "sender_dashboard" : "sender_onboarding";
        }

        if (role == "fleet_owner")
        {
            var fleet = _fleets.GetByUserId(user.Id);
            return fleet != null ? "fleet_dashboard" : "fleet_onboarding";
        }

        return "unknown";
    }
}