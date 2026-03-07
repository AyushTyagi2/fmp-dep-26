using Microsoft.EntityFrameworkCore;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class ShipmentRepository
{
    private readonly AppDbContext _db;

    public ShipmentRepository(AppDbContext db)
    {
        _db = db;
    }

     public async Task<Shipment?> GetByShipmentAsync(string shipmentNo)
    {
        return await _db.Shipments
            .FirstOrDefaultAsync(s => s.ShipmentNumber == shipmentNo);
    }

    public async Task<Shipment> CreateAsync(Shipment shipment)
    {
        await _db.Shipments.AddAsync(shipment);
        await _db.SaveChangesAsync();
        return shipment;
    }

    public async Task UpdateAsync(Shipment shipment)
    {
        _db.Shipments.Update(shipment);
        await _db.SaveChangesAsync();
    }

    public async Task<List<Shipment>> GetSentShipmentsAsync(Guid orgId)
    {
        return await _db.Shipments
            .Where(s => s.SenderOrganizationId == orgId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();
    }

    // ✅ NEW METHOD
    public async Task<List<Shipment>> GetReceivedShipmentsAsync(Guid orgId)
    {
        return await _db.Shipments
            .Where(s => s.ReceiverOrganizationId == orgId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();
    }
    public async Task<Shipment?> GetByIdAsync(Guid id)
    {
    return await _db.Shipments
        .FirstOrDefaultAsync(s => s.Id == id);
    }

    public async Task<List<Shipment>> GetByStatusAsync(string status)
    {
    return await _db.Shipments
        .Where(s => s.Status == status)
        .OrderByDescending(s => s.CreatedAt)
        .ToListAsync();
    }

    public async Task<List<Shipment>> GetApprovedShipmentsAsync()
    {
    return await _db.Shipments
        .Where(s => s.Status == "approved")
        .OrderByDescending(s => s.CreatedAt)
        .ToListAsync();
    }
}