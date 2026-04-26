using FmpBackend.Dtos;

namespace FmpBackend.Services.Interfaces;

public interface IFleetTripService
{
    Task<IEnumerable<FleetTripDto>> GetTripsByFleetOwnerPhoneAsync(
        string phone,
        CancellationToken ct = default);
}