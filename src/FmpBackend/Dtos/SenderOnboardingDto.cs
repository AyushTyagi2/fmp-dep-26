namespace FmpBackend.Dtos;


public class SenderOnboardingDto
{
    public string OrgName { get; set; }
    public string OrgType { get; set; }
    public string ContactName { get; set; }
    public string Phone { get; set; }
    public string Email { get; set; }
    public string Industry { get; set; }
    public string Description { get; set; }

    public string AddressLine { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string PostalCode { get; set; }
}
