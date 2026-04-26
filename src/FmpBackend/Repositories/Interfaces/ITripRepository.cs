using FmpBackend.Dtos;

namespace FmpBackend.Repositories.Interfaces
{
    public interface ITripRepository
    {
        /// <summary>
        /// Returns all trips whose <c>assigned_fleet_owner_id</c> belongs to
        /// the fleet owner identified by <paramref name="phone"/>.
        /// Returns an empty list (never null) when no trips exist.
        /// Throws <see cref="KeyNotFoundException"/> when the phone number does
        /// not match any fleet owner.
        /// </summary>
        Task<IEnumerable<FleetTripDto>> GetTripsByFleetOwnerPhoneAsync(
            string phone,
            CancellationToken ct = default);
    }
}