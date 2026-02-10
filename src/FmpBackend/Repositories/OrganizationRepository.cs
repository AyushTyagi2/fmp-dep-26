using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class OrganizationRepository
{
    private readonly AppDbContext _db;

    public OrganizationRepository(AppDbContext db)
    {
        _db = db;
    }

    public Organization? GetByPhone(string phone)
    {
        return _db.Organizations
            .FirstOrDefault(o => o.PrimaryContactPhone == phone);
    }

    public Organization Create(Organization org)
    {
        _db.Organizations.Add(org);
        _db.SaveChanges();
        return org;
    }
}
