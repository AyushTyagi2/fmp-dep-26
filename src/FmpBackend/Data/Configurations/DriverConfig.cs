using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class DriverConfig : IEntityTypeConfiguration<Driver>
{
    public void Configure(EntityTypeBuilder<Driver> entity)
    {
    entity.ToTable("drivers");
    entity.HasKey(e => e.Id);

    entity.Property(e => e.Id).HasColumnName("id");
    entity.Property(e => e.UserId).HasColumnName("user_id");
    entity.Property(e => e.Status).HasColumnName("status");
    entity.Property(e => e.LicenseNumber)
          .HasColumnName("license_number");

    entity.Property(e => e.LicenseType)
          .HasColumnName("license_type");

    entity.Property(e => e.LicenseExpiryDate)
          .HasColumnName("license_expiry_date");

    entity.Property(e => e.AvailabilityStatus)
          .HasColumnName("availability_status");

    entity.Property(e => e.CurrentFleetOwnerId)
          .HasColumnName("current_fleet_owner_id");

    entity.Property(e => e.Verified)
          .HasColumnName("verified");

    entity.Property(e => e.AverageRating)
          .HasColumnName("average_rating");

    entity.Property(e => e.TotalTripsCompleted)
          .HasColumnName("total_trips_completed");

    entity.Property(e => e.CreatedAt)
          .HasColumnName("created_at")
          .HasDefaultValueSql("CURRENT_TIMESTAMP");
    }
}