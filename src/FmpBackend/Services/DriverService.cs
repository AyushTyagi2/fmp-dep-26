using FmpBackend.Dtos;
using FmpBackend.Repositories;
using FmpBackend.Models;

namespace FmpBackend.Services;

public class DriverService
{
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly VehicleRepository _vehicles;
    private readonly FleetOwnerRepository _fleets;
    private readonly TripRepository _trips;

    public DriverService(
        UserRepository users,
        DriverRepository drivers,
        VehicleRepository vehicles,
        FleetOwnerRepository fleets,
        TripRepository trips)
    {
        _users = users;
        _drivers = drivers;
        _vehicles = vehicles;
        _fleets = fleets;
        _trips = trips;
    }


    public IEnumerable<DriverDetailsDto> GetDriversForFleetOwner(Guid fleetOwnerId)
    {
        var list = new List<DriverDetailsDto>();
        var drivers = _drivers.GetByFleetOwnerId(fleetOwnerId);
        foreach (var d in drivers)
        {
            var user = _users.GetById(d.UserId);
            var vehicle = _vehicles.GetByCurrentDriverId(d.Id);

            var dto = new DriverDetailsDto
            {
                Id = d.Id,
                UserId = d.UserId,
                FullName = user?.FullName ?? "",
                Phone = user?.Phone ?? "",
                LicenseNumber = d.LicenseNumber,
                LicenseType = d.LicenseType,
                LicenseExpiryDate = d.LicenseExpiryDate,
                Status = d.Status,
                AverageRating = d.AverageRating,
                TotalTripsCompleted = d.TotalTripsCompleted,
                CurrentVehicle = vehicle != null ? new VehicleBriefDto
                {
                    Id = vehicle.Id,
                    RegistrationNumber = vehicle.RegistrationNumber,
                    VehicleType = vehicle.VehicleType
                } : null
            };
            list.Add(dto);
        }
        return list;
    }

    public DriverDetailsDto? GetDriverDetails(Guid driverId)
    {
        var d = _drivers.GetById(driverId);
        if (d == null) return null;
        var user = _users.GetById(d.UserId);
        var vehicle = _vehicles.GetByCurrentDriverId(d.Id);

        var dto = new DriverDetailsDto
        {
            Id = d.Id,
            UserId = d.UserId,
            FullName = user?.FullName ?? "",
            Phone = user?.Phone ?? "",
            LicenseNumber = d.LicenseNumber,
            LicenseType = d.LicenseType,
            LicenseExpiryDate = d.LicenseExpiryDate,
            Status = d.Status,
            AverageRating = d.AverageRating,
            TotalTripsCompleted = d.TotalTripsCompleted,
            CurrentVehicle = vehicle != null ? new VehicleBriefDto
            {
                Id = vehicle.Id,
                RegistrationNumber = vehicle.RegistrationNumber,
                VehicleType = vehicle.VehicleType
            } : null
        };

        return dto;
    }

    public IEnumerable<DriverDetailsDto> GetDriversForFleetOwnerByPhone(string phone)
    {
        var f = _fleets.GetByPhone(phone);
        if (f == null) return new List<DriverDetailsDto>();
        return GetDriversForFleetOwner(f.Id);
    }

    /// <summary>
    /// Fleet Manager driver search: filters drivers by free-text (name, phone) and optional status.
    /// </summary>
    public IEnumerable<DriverDetailsDto> SearchDriversForFleetOwnerByPhone(
        string phone,
        string? q,
        string? status)
    {
        var f = _fleets.GetByPhone(phone);
        if (f == null) return Enumerable.Empty<DriverDetailsDto>();

        var drivers = GetDriversForFleetOwner(f.Id);

        if (!string.IsNullOrWhiteSpace(q))
        {
            var lower = q.ToLower();
            drivers = drivers.Where(d =>
                d.FullName.ToLower().Contains(lower) ||
                d.Phone.ToLower().Contains(lower) ||
                d.Id.ToString().Contains(lower));
        }

        if (!string.IsNullOrWhiteSpace(status))
            drivers = drivers.Where(d => d.Status?.ToLower() == status.ToLower());

        return drivers;
    }

    public FleetDashboardDto GetFleetDashboardByPhone(string phone)
    {
        var f = _fleets.GetByPhone(phone);
        if (f == null) return new FleetDashboardDto();

        var drivers = _drivers.GetByFleetOwnerId(f.Id);
        var activeDrivers = drivers.Count(d => d.Status == "active");

        var activeTrips = _trips.CountActiveTripsForFleetOwner(f.Id);
        var tripsWithIssues = _trips.CountTripsWithIssuesForFleetOwner(f.Id);

        var vehicleIssues = _vehicles.CountVehiclesWithIssuesForFleetOwner(f.Id);

        return new FleetDashboardDto
        {
            FleetOwnerId = f.Id,
            FleetOwnerName = f.BusinessName ?? string.Empty,
            ActiveDrivers = activeDrivers,
            ActiveTrips = activeTrips,
            VehicleIssues = vehicleIssues,
            TripsWithIssues = tripsWithIssues
        };
    }

    public void SaveBasicDetails(DriverBasicDetailsDto dto)
    {
        // 1. User must exist
        var user = _users.GetByEmail(dto.Phone);
        if (user == null)
            throw new Exception("User not found");

        // 2. Get or create driver
        var driver = _drivers.GetByUserId(user.Id);
        if (driver == null)
        {
           driver = new Driver
            {
    UserId = user.Id,
    Status = "active",   // important

    // PLACEHOLDERS
    LicenseNumber = "PENDING",
    LicenseType = "PENDING",
    LicenseExpiryDate = DateTime.UtcNow.AddYears(1)
        };

            driver = _drivers.Create(driver);
        }

        // 3. Get or create vehicle
        var vehicle = _vehicles.GetByRegistration(dto.VehicleNumber);
        if (vehicle == null)
        {
            vehicle = new Vehicle
            {
                RegistrationNumber = dto.VehicleNumber,
                VehicleType = dto.vehicleType,
                CurrentDriverId = driver.Id,
                FleetOwnerId = Guid.Parse("00000000-0000-0000-0000-000000000002"),
                CapacityTons = 0.0m,              // placeholder
                MaxLoadWeightKg = 0.0m            // if also NOT NULL
            };
            _vehicles.Create(vehicle);
        }
        else
        {
            vehicle.CurrentDriverId = driver.Id;
            _vehicles.Update(vehicle);
        }
    }
}
