using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FmpBackend.Data.Configurations;

public class ShipmentQueueConfiguration : IEntityTypeConfiguration<ShipmentQueue>
{
    public void Configure(EntityTypeBuilder<ShipmentQueue> builder)
    {
        builder.ToTable("shipment_queue");
        builder.HasKey(q => q.Id);

        builder.Property(q => q.Id).HasColumnName("id");
        builder.Property(q => q.ShipmentId).HasColumnName("shipment_id");
        builder.Property(q => q.ZoneId).HasColumnName("zone_id");
        builder.Property(q => q.RequiredVehicleType).HasColumnName("required_vehicle_type").HasMaxLength(50);
        builder.Property(q => q.Status).HasColumnName("status").HasMaxLength(30).HasDefaultValue("waiting");
        builder.Property(q => q.CurrentDriverId).HasColumnName("current_driver_id");
        builder.Property(q => q.OfferExpiresAt).HasColumnName("offer_expires_at");
        builder.Property(q => q.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.HasOne(q => q.Shipment)
               .WithMany()
               .HasForeignKey(q => q.ShipmentId)
               .OnDelete(DeleteBehavior.Restrict);
    }
}