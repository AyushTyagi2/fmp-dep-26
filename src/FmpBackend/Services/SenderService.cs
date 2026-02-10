using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class SenderService
{
    private readonly OrganizationRepository _orgs;

    public SenderService(OrganizationRepository orgs)
    {
        _orgs = orgs;
    }

    public void OnboardSender(SenderOnboardingDto dto)
    {
        var existing = _orgs.GetByPhone(dto.Phone);
        if (existing != null)
            throw new Exception("Organization already exists");

        var org = new Organization
        {
            Name = dto.OrgName,
            OrganizationType = dto.OrgType,

            PrimaryContactName = dto.ContactName,
            PrimaryContactPhone = dto.Phone,
            PrimaryContactEmail = dto.Email,

            Industry = dto.Industry,
            Description = dto.Description,

            AddressLine1 = dto.AddressLine,
            City = dto.City,
            State = dto.State,
            PostalCode = dto.PostalCode,

            Status = "active"
        };

        _orgs.Create(org);
    }
}
