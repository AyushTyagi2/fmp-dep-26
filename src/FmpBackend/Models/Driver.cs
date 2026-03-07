public class Driver
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? CurrentFleetOwnerId { get; set; }

    public string LicenseNumber { get; set; } = "PENDING";
    public string LicenseType { get; set; } = "PENDING";
    public DateTime LicenseExpiryDate { get; set; } = DateTime.UtcNow.AddYears(1);

    public string Status { get; set; } = "active";

    // ADD THESE
    public string AvailabilityStatus { get; set; } = "available";
    public bool Verified { get; set; } = false;

    public DateTime CreatedAt { get; set; }

    public decimal AverageRating { get; set; }
    public int TotalTripsCompleted { get; set; }
}