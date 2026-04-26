using System;
using System.Collections.Generic;
using System.Linq;
using FmpBackend.Data;
using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class VehicleService
{
    private readonly AppDbContext _db;
    private readonly FleetOwnerRepository _fleetOwnerRepository;

    public VehicleService(AppDbContext db, FleetOwnerRepository fleetOwnerRepository)
    {
        _db = db;
        _fleetOwnerRepository = fleetOwnerRepository;
    }

    public IEnumerable<VehicleDto> GetVehiclesByFleetOwnerPhone(string phone)
    {
        var fleetOwner = _fleetOwnerRepository.GetByPhone(phone);
        if (fleetOwner == null) return Enumerable.Empty<VehicleDto>();

        var query = from v in _db.Vehicles
                    where v.FleetOwnerId == fleetOwner.Id
                    join d in _db.Drivers on v.CurrentDriverId equals d.Id into dGroup
                    from d in dGroup.DefaultIfEmpty()
                    join u in _db.Users on d.UserId equals u.Id into uGroup
                    from u in uGroup.DefaultIfEmpty()
                    select new VehicleDto
                    {
                        Id = v.Id,
                        RegistrationNumber = v.RegistrationNumber,
                        VehicleType = v.VehicleType,
                        CapacityTons = v.CapacityTons,
                        MaxLoadWeightKg = v.MaxLoadWeightKg,
                        Status = v.Status,
                        AvailabilityStatus = v.AvailabilityStatus,
                        CurrentDriverId = v.CurrentDriverId,
                        CurrentDriverName = u != null ? u.FullName : null
                    };

        return query.ToList();
    }

    public VehicleDto AddVehicle(string phone, VehicleDto dto)
    {
        var fleetOwner = _fleetOwnerRepository.GetByPhone(phone);
        if (fleetOwner == null) throw new Exception("Fleet owner not found");

        var vehicle = new Vehicle
        {
            Id = Guid.NewGuid(),
            FleetOwnerId = fleetOwner.Id,
            RegistrationNumber = dto.RegistrationNumber,
            VehicleType = dto.VehicleType,
            CapacityTons = dto.CapacityTons,
            MaxLoadWeightKg = dto.MaxLoadWeightKg,
            Status = string.IsNullOrWhiteSpace(dto.Status) ? "active" : dto.Status,
            AvailabilityStatus = string.IsNullOrWhiteSpace(dto.AvailabilityStatus) ? "available" : dto.AvailabilityStatus
        };

        _db.Vehicles.Add(vehicle);
        _db.SaveChanges();

        dto.Id = vehicle.Id;
        return dto;
    }

    public BulkAddResult AddVehiclesBulk(string phone, List<VehicleDto> dtos)
    {
        var fleetOwner = _fleetOwnerRepository.GetByPhone(phone);
        if (fleetOwner == null) throw new Exception("Fleet owner not found");

        int successCount = 0;
        int errorCount = 0;

        foreach (var dto in dtos)
        {
            try
            {
                var vehicle = new Vehicle
                {
                    Id = Guid.NewGuid(),
                    FleetOwnerId = fleetOwner.Id,
                    RegistrationNumber = dto.RegistrationNumber,
                    VehicleType = dto.VehicleType,
                    CapacityTons = dto.CapacityTons,
                    MaxLoadWeightKg = dto.MaxLoadWeightKg,
                    Status = string.IsNullOrWhiteSpace(dto.Status) ? "active" : dto.Status,
                    AvailabilityStatus = string.IsNullOrWhiteSpace(dto.AvailabilityStatus) ? "available" : dto.AvailabilityStatus
                };

                _db.Vehicles.Add(vehicle);
                successCount++;
            }
            catch
            {
                errorCount++;
            }
        }

        if (successCount > 0)
        {
            _db.SaveChanges();
        }

        return new BulkAddResult
        {
            SuccessCount = successCount,
            ErrorCount = errorCount
        };
    }

    public void DeleteVehicles(string phone, DeleteVehiclesDto request)
    {
        var fleetOwner = _fleetOwnerRepository.GetByPhone(phone);
        if (fleetOwner == null) throw new Exception("Fleet owner not found");

        var vehiclesToDelete = _db.Vehicles
            .Where(v => v.FleetOwnerId == fleetOwner.Id && request.VehicleIds.Contains(v.Id))
            .ToList();

        _db.Vehicles.RemoveRange(vehiclesToDelete);
        _db.SaveChanges();
    }
}

public class BulkAddResult
{
    public int SuccessCount { get; set; }
    public int ErrorCount { get; set; }
}

public class DeleteVehiclesDto
{
    public List<Guid> VehicleIds { get; set; } = new();
}
