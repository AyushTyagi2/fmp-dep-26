using FmpBackend.Repositories;
using System.Text.RegularExpressions;

namespace FmpBackend.Services;

public class RoleService
{
    private readonly UserRepository         _users;
    private readonly DriverRepository       _drivers;
    private readonly OrganizationRepository _orgs;
    private readonly FleetOwnerRepository   _fleets;

    // These roles skip role-selection and go straight to their dashboard.
    // DRIVER and ORGANIZATION still go through role-selection.
    private static readonly HashSet<string> AutoRedirectRoles = new(StringComparer.OrdinalIgnoreCase)
{
    "FLEET_OWNER",
    "UNION_MANAGER",
    "ADMIN",
    "SUPER_ADMIN",
    "SENDER",      // ← Add this
    "RECEIVER",    // ← Add this
};

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

    /// <summary>
    /// Called inside verify-otp after OTP is confirmed.
    /// Returns (screen, roleForJwt, driverId).
    ///
    /// Fleet / Union / Admin / SuperAdmin  → their dashboard directly.
    /// Driver / Organisation / new user    → role_selection screen.
    /// </summary>
    public (string screen, string roleForJwt, string? driverId) ResolveAfterOtp(string phone, Guid userId)
    {
        var roles = _users.GetActiveRoles(userId);

        Console.WriteLine($"[RoleService] ResolveAfterOtp phone={phone} roles=[{string.Join(", ", roles)}]");

        // Auto-redirect roles → skip role-selection, go straight to dashboard
        var autoRole = roles.FirstOrDefault(r => AutoRedirectRoles.Contains(r));
        if (autoRole != null)
        {
            var (screen, driverId) = ResolveScreenForRole(phone, userId, autoRole);
            Console.WriteLine($"[RoleService] auto-redirect → {screen}");
            return (screen, autoRole, driverId);
        }

        // Driver, Organisation, or brand-new user → show role-selection
        Console.WriteLine($"[RoleService] → role_selection");
        return ("role_selection", "unresolved", null);
    }

    /// <summary>
    /// Called from the role-selection screen when the user explicitly picks a role.
    /// </summary>
    public string Resolve(string phone, string role)
    {
        Console.WriteLine($"[RoleService] Resolve phone={phone} role={role}");

        if (string.IsNullOrWhiteSpace(role)) return "login";

        // Normalise any format → UPPER_SNAKE_CASE
        role = Regex.Replace(role, "([a-z0-9])([A-Z])", "$1_$2");
        role = role.Replace('-', '_').ToUpperInvariant();

        Console.WriteLine($"[RoleService] normalised role={role}");

        var user = _users.GetByPhone(phone);
        if (user == null) return "login";

        return role switch
        {
            "DRIVER"                     => ResolveDriver(user.Id),
            "ORGANIZATION"               => ResolveOrganization(phone),
            "FLEET_OWNER"                => ResolveFleet(user.Id).screen,
            "UNION_MANAGER"              => "union_dashboard",
            "ADMIN" or "SUPER_ADMIN"     => "system_admin_dashboard",
            _                            => "unknown",
        };
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private (string screen, string? driverId) ResolveScreenForRole(string phone, Guid userId, string roleName)
    {
        return roleName.ToUpperInvariant() switch
        {
            "FLEET_OWNER"            => ResolveFleet(userId),
            "UNION_MANAGER"          => ("union_dashboard", null),
            "ADMIN" or "SUPER_ADMIN" => ("system_admin_dashboard", null),
            _                        => ("role_selection", null),
            
        };
    }

    private string ResolveDriver(Guid userId)
    {
        var driver = _drivers.GetByUserId(userId);
        return driver != null ? "driver_dashboard" : "driver_onboarding";
    }

    private string ResolveOrganization(string phone)
    {
        var org = _orgs.GetByPhone(phone);
        return org != null ? "sender_dashboard" : "sender_onboarding";
    }

    private (string screen, string? driverId) ResolveFleet(Guid userId)
    {
        var fleet = _fleets.GetByUserId(userId);
        return fleet != null
            ? ("fleet_dashboard", null)
            : ("fleet_onboarding", null);
    }
}