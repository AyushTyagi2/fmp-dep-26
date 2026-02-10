namespace FmpBackend.Models;


public class Organization
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string OrganizationType { get; set; } = null!;

    public string? RegistrationNumber { get; set; } = "PENDING";


    public string PrimaryContactName { get; set; } = null!;
    public string PanNumber { get; set; } = "PENDING";
    public string GstNumber { get; set; } = "PENDING";
    public string PrimaryContactPhone { get; set; } = null!;
    public string? PrimaryContactEmail { get; set; }

    public string? Industry { get; set; }
    public string? Description { get; set; }

    public string AddressLine1 { get; set; } = null!;
    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string PostalCode { get; set; } = null!;

    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; }
}
