using FmpBackend.Dtos;
using FmpBackend.Repositories;
using FmpBackend.Models;

namespace FmpBackend.Services;

public class DriverService
{
    private readonly UserRepository _users;
    private readonly DriverRepository _drivers;
    private readonly VehicleRepository _vehicles;

    public DriverService(
        UserRepository users,
        DriverRepository drivers,
        VehicleRepository vehicles)
    {
        _users = users;
        _drivers = drivers;
        _vehicles = vehicles;
    }

    public void SaveBasicDetails(DriverBasicDetailsDto dto)
    {
        // 1. User must exist
        var user = _users.GetByPhone(dto.Phone);
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
