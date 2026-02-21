using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class VehicleConfig : IEntityTypeConfiguration<Vehicle>
{
    public void Configure(EntityTypeBuilder<Vehicle> entity)
    {
    entity.ToTable("vehicles");
    entity.HasKey(e => e.Id);

    entity.Property(e => e.Id)
          .HasColumnName("id");

    entity.Property(e => e.RegistrationNumber)
          .HasColumnName("registration_number");

    entity.Property(e => e.FleetOwnerId)
          .HasColumnName("fleet_owner_id");

    entity.Property(e => e.VehicleType)
          .HasColumnName("vehicle_type");

    entity.Property(e => e.CurrentDriverId)
          .HasColumnName("current_driver_id");

    // REQUIRED NOT NULL FIELDS
    entity.Property(e => e.CapacityTons)
          .HasColumnName("capacity_tons");

    entity.Property(e => e.MaxLoadWeightKg)
          .HasColumnName("max_load_weight_kg");

    // Good to map these too (they also have defaults / constraints)
    entity.Property(e => e.Status)
          .HasColumnName("status");

    entity.Property(e => e.AvailabilityStatus)
          .HasColumnName("availability_status");
    }
}