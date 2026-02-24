using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class AddressConfig : IEntityTypeConfiguration<Address>
{
    public void Configure(EntityTypeBuilder<Address> entity)
    {
        entity.ToTable("addresses");
        entity.HasKey(e => e.Id);

        entity.Property(e => e.Id).HasColumnName("id");

        entity.Property(e => e.OwnerType)
              .HasColumnName("owner_type");

        entity.Property(e => e.OwnerId)
              .HasColumnName("owner_id");

        entity.Property(e => e.Label)
              .HasColumnName("label");

        entity.Property(e => e.ContactPersonName)
              .HasColumnName("contact_person_name");

        entity.Property(e => e.ContactPhone)
              .HasColumnName("contact_phone");

        entity.Property(e => e.AddressLine1)
              .HasColumnName("address_line1");

        entity.Property(e => e.AddressLine2)
              .HasColumnName("address_line2");

        entity.Property(e => e.Landmark)
              .HasColumnName("landmark");

        entity.Property(e => e.City)
              .HasColumnName("city");

        entity.Property(e => e.State)
              .HasColumnName("state");

        entity.Property(e => e.PostalCode)
              .HasColumnName("postal_code");

        entity.Property(e => e.Country)
              .HasColumnName("country")
              .HasDefaultValue("India");

        entity.Property(e => e.Latitude)
              .HasColumnName("latitude");

        entity.Property(e => e.Longitude)
              .HasColumnName("longitude");

        entity.Property(e => e.AccessInstructions)
              .HasColumnName("access_instructions");

        entity.Property(e => e.OperatingHours)
              .HasColumnName("operating_hours");

        entity.Property(e => e.IsDefault)
              .HasColumnName("is_default");

        entity.Property(e => e.IsActive)
              .HasColumnName("is_active");

        entity.Property(e => e.CreatedAt)
              .HasColumnName("created_at")
              .HasDefaultValueSql("CURRENT_TIMESTAMP");

        entity.Property(e => e.UpdatedAt)
              .HasColumnName("updated_at")
              .HasDefaultValueSql("CURRENT_TIMESTAMP");

        entity.HasCheckConstraint(
            "valid_owner_type",
            "owner_type IN ('user', 'organization')");
    }
}