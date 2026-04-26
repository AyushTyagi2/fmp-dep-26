using FmpBackend.Dtos;
using FmpBackend.Repositories.Interfaces;
using FmpBackend.Services.Interfaces;

namespace FmpBackend.Services;

public class FleetTripService : IFleetTripService
{
    private readonly ITripRepository _repo;

    public FleetTripService(ITripRepository repo)
    {
        _repo = repo;
    }

    public Task<IEnumerable<FleetTripDto>> GetTripsByFleetOwnerPhoneAsync(
        string phone,
        CancellationToken ct = default)
        => _repo.GetTripsByFleetOwnerPhoneAsync(phone, ct);
}