using FmpBackend.Models;
using FmpBackend.Data;
using Microsoft.EntityFrameworkCore;

namespace FmpBackend.Repositories;

public class AddressRepository
{
    private readonly AppDbContext _context;

    public AddressRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Address?> GetDefaultByOwnerAsync(Guid ownerId, string ownerType)
    {
        return await _context.Addresses
            .Where(a =>
                a.OwnerId == ownerId &&
                a.OwnerType == ownerType &&
                a.IsDefault &&
                a.IsActive)
            .FirstOrDefaultAsync();
    }
      public async Task<Address?> GetAnyActiveByOwnerAsync(Guid ownerId, string ownerType)
{
    return await _context.Addresses
        .Where(a => a.OwnerId == ownerId && a.OwnerType == ownerType && a.IsActive)
        .FirstOrDefaultAsync();
}
}