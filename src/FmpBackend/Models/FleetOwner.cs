using System;

namespace FmpBackend.Models;

public class FleetOwner
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public string? BusinessName { get; set; }
    public string? BusinessType { get; set; }

    public string? BusinessContactPhone { get; set; }
    public string? BusinessContactEmail { get; set; }

    public string Status { get; set; } = "active";
    public bool Verified { get; set; }
    public DateTime CreatedAt { get; set; }
}
