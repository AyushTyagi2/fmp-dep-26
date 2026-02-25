using System.Linq;
using FmpBackend.Data;
using FmpBackend.Models;

namespace FmpBackend.Repositories;

public class TripRepository
{
    private readonly AppDbContext _db;

    public TripRepository(AppDbContext db)
    {
        _db = db;
    }

    public int CountActiveTripsForFleetOwner(System.Guid fleetOwnerId)
    {
        // Active means not completed, not delivered, not cancelled
        var inactive = new[] { "completed", "delivered", "cancelled" };
        return _db.Trips.Count(t => t.AssignedFleetOwnerId == fleetOwnerId && !inactive.Contains(t.CurrentStatus));
    }

    public int CountTripsWithIssuesForFleetOwner(System.Guid fleetOwnerId)
    {
        return _db.Trips.Count(t => t.AssignedFleetOwnerId == fleetOwnerId && t.HasIssues);
    }
}
