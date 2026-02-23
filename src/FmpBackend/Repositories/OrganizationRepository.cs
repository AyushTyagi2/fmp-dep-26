using Microsoft.EntityFrameworkCore;
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

     public async Task<Organization?> GetByPhoneAsync(string phone)
    {
        return await _db.Organizations
            .FirstOrDefaultAsync(o => o.PrimaryContactPhone == phone);
    }

    public async Task<Organization> CreateAsync(Organization org)
    {
        _db.Organizations.Add(org);
        await _db.SaveChangesAsync();
        return org;
    }
    public Organization Create(Organization org)
    {
        _db.Organizations.Add(org);
        _db.SaveChanges();
        return org;
    }
}
