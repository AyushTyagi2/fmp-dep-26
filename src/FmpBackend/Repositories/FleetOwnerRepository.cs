using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class FleetOwnerRepository
{
    private readonly AppDbContext _db;

    public FleetOwnerRepository(AppDbContext db)
    {
        _db = db;
    }

    public FleetOwner? GetByUserId(Guid userId)
    {
        return _db.FleetOwners.FirstOrDefault(f => f.UserId == userId);
    }

    public FleetOwner? GetByPhone(string phone)
    {
        return _db.FleetOwners.FirstOrDefault(f => f.BusinessContactPhone == phone);
    }

    public FleetOwner Create(FleetOwner owner)
    {
        _db.FleetOwners.Add(owner);
        _db.SaveChanges();
        return owner;
    }
}
