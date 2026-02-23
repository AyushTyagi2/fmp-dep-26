using System;

namespace FmpBackend.Models;

public class Address
{
    public Guid Id { get; set; }

    public string OwnerType { get; set; } = null!;
    public Guid OwnerId { get; set; }

    public string? Label { get; set; }
    public string? ContactPersonName { get; set; }
    public string? ContactPhone { get; set; }

    public string AddressLine1 { get; set; } = null!;
    public string? AddressLine2 { get; set; }
    public string? Landmark { get; set; }

    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string PostalCode { get; set; } = null!;
    public string Country { get; set; } = "India";

    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }

    public string? AccessInstructions { get; set; }
    public string? OperatingHours { get; set; }

    public bool IsDefault { get; set; }
    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}