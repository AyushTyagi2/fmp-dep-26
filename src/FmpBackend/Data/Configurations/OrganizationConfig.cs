using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class OrganizationConfig : IEntityTypeConfiguration<Organization>
{
    public void Configure(EntityTypeBuilder<Organization> entity)
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
    }
}