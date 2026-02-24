using Microsoft.EntityFrameworkCore;
using FmpBackend.Models;

namespace FmpBackend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) {}

    public DbSet<User> Users { get; set; }
    public DbSet<Driver> Drivers { get; set; }
    public DbSet<Vehicle> Vehicles { get; set; }
    public DbSet<Organization> Organizations { get; set; }
      public DbSet<FleetOwner> FleetOwners { get; set; }

    public DbSet<Shipment> Shipments {get; set;}
      public DbSet<Trip> Trips { get; set; }
    public DbSet<Address> Addresses { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // OTP table
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // USERS table
        /*modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Phone).HasColumnName("phone");
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash");
            entity.Property(e => e.FullName).HasColumnName("full_name");

            entity.Property(e => e.AuthProvider).HasColumnName("auth_provider");
            entity.Property(e => e.CreatedAt)
                  .HasColumnName("created_at")
                  .HasDefaultValueSql("CURRENT_TIMESTAMP");
        });*/
    // DRIVERS
    modelBuilder.Entity<Driver>(entity =>
    {
        entity.ToTable("drivers");
        entity.HasKey(e => e.Id);

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.UserId).HasColumnName("user_id");
        entity.Property(e => e.CurrentFleetOwnerId).HasColumnName("current_fleet_owner_id");
        entity.Property(e => e.Status).HasColumnName("status");

        entity.Property(e => e.LicenseNumber)
              .HasColumnName("license_number");

        entity.Property(e => e.LicenseType)
              .HasColumnName("license_type");

        entity.Property(e => e.LicenseExpiryDate)
              .HasColumnName("license_expiry_date");

        entity.Property(e => e.AverageRating)
              .HasColumnName("average_rating");

        entity.Property(e => e.TotalTripsCompleted)
              .HasColumnName("total_trips_completed");

        entity.Property(e => e.CreatedAt)
              .HasColumnName("created_at")
              .HasDefaultValueSql("CURRENT_TIMESTAMP");
    });

      // TRIPS (minimal mapping)
      modelBuilder.Entity<Trip>(entity =>
      {
            entity.ToTable("trips");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ShipmentId).HasColumnName("shipment_id");
            entity.Property(e => e.VehicleId).HasColumnName("vehicle_id");
            entity.Property(e => e.DriverId).HasColumnName("driver_id");
            entity.Property(e => e.AssignedFleetOwnerId).HasColumnName("assigned_fleet_owner_id");
            entity.Property(e => e.CurrentStatus).HasColumnName("current_status");
            entity.Property(e => e.HasIssues).HasColumnName("has_issues");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
      });


// VEHICLES
    modelBuilder.Entity<Vehicle>(entity =>
    {
        entity.ToTable("vehicles");
        entity.HasKey(e => e.Id);

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.RegistrationNumber).HasColumnName("registration_number");
        entity.Property(e => e.FleetOwnerId).HasColumnName("fleet_owner_id");
        entity.Property(e => e.VehicleType).HasColumnName("vehicle_type");
        entity.Property(e => e.CurrentDriverId).HasColumnName("current_driver_id");

        entity.Property(e => e.CapacityTons).HasColumnName("capacity_tons");
        entity.Property(e => e.MaxLoadWeightKg).HasColumnName("max_load_weight_kg");

        entity.Property(e => e.Status).HasColumnName("status");
        entity.Property(e => e.AvailabilityStatus).HasColumnName("availability_status");
    });


// FLEET OWNERS
modelBuilder.Entity<FleetOwner>(entity =>
{
      entity.ToTable("fleet_owners");
      entity.HasKey(e => e.Id);

      entity.Property(e => e.Id).HasColumnName("id");
      entity.Property(e => e.UserId).HasColumnName("user_id");

      entity.Property(e => e.BusinessName).HasColumnName("business_name");
      entity.Property(e => e.BusinessType).HasColumnName("business_type");

      entity.Property(e => e.BusinessContactPhone).HasColumnName("business_contact_phone");
      entity.Property(e => e.BusinessContactEmail).HasColumnName("business_contact_email");

      entity.Property(e => e.Status).HasColumnName("status");
      entity.Property(e => e.Verified).HasColumnName("verified");
      entity.Property(e => e.CreatedAt)
              .HasColumnName("created_at")
              .HasDefaultValueSql("CURRENT_TIMESTAMP");
});


 modelBuilder.Entity<Organization>(entity =>
//  /*modelBuilder.Entity<Organization>(entity =>
    {
        entity.ToTable("organizations");
        entity.HasKey(e => e.Id);

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.Name).HasColumnName("name");
        entity.Property(e => e.OrganizationType).HasColumnName("organization_type");

        entity.Property(e => e.PrimaryContactName).HasColumnName("primary_contact_name");
        entity.Property(e => e.PrimaryContactPhone).HasColumnName("primary_contact_phone");
        entity.Property(e => e.PrimaryContactEmail).HasColumnName("primary_contact_email");
         entity.Property(e => e.RegistrationNumber)
          .HasColumnName("registration_number");
        entity.Property(e => e.PanNumber)
          .HasColumnName("pan_number");

    entity.Property(e => e.GstNumber)
          .HasColumnName("gst_number");
        entity.Property(e => e.AddressLine1).HasColumnName("address_line1");
        entity.Property(e => e.City).HasColumnName("city");
        entity.Property(e => e.State).HasColumnName("state");
        entity.Property(e => e.PostalCode).HasColumnName("postal_code");

        entity.Property(e => e.Industry).HasColumnName("industry");
        entity.Property(e => e.Description).HasColumnName("description");

        entity.Property(e => e.Status).HasColumnName("status");
        entity.Property(e => e.CreatedAt)
              .HasColumnName("created_at")
              .HasDefaultValueSql("CURRENT_TIMESTAMP");
    });
}
    
}
