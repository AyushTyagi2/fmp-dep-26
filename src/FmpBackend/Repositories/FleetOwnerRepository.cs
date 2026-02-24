using System;
using System.Linq;
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
        if (string.IsNullOrWhiteSpace(phone)) return null;

        static string Normalize(string? s) => s == null ? string.Empty : new string(s.Where(char.IsDigit).ToArray());
        var norm = Normalize(phone);

        // Use AsEnumerable to perform normalization comparison client-side
        return _db.FleetOwners.AsEnumerable().FirstOrDefault(f => Normalize(f.BusinessContactPhone) == norm);
    }

    public FleetOwner Create(FleetOwner owner)
    {
        _db.FleetOwners.Add(owner);
        _db.SaveChanges();
        return owner;
    }
}
