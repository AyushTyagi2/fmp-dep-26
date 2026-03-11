using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FmpBackend.Data.Configurations;

public class ShipmentQueueAssignmentConfiguration : IEntityTypeConfiguration<ShipmentQueueAssignment>
{
    public void Configure(EntityTypeBuilder<ShipmentQueueAssignment> builder)
    {
        builder.ToTable("shipment_queue_assignments");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id).HasColumnName("id");
        builder.Property(e => e.QueueEventId).HasColumnName("queue_event_id");
        builder.Property(e => e.ShipmentQueueId).HasColumnName("shipment_queue_id");
        builder.Property(e => e.DriverId).HasColumnName("driver_id");
        builder.Property(e => e.DriverPosition).HasColumnName("driver_position");
        builder.Property(e => e.OfferedAt).HasColumnName("offered_at");
        builder.Property(e => e.ExpiresAt).HasColumnName("expires_at");
        builder.Property(e => e.Outcome)
               .HasColumnName("outcome")
               .HasMaxLength(20)
               .HasDefaultValue(AssignmentOutcome.Pending);

        builder.HasOne(e => e.ShipmentQueue)
               .WithMany()
               .HasForeignKey(e => e.ShipmentQueueId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.QueueEvent)
               .WithMany()
               .HasForeignKey(e => e.QueueEventId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(e => e.QueueEventId);
        builder.HasIndex(e => e.ShipmentQueueId);
        builder.HasIndex(e => e.DriverId);
    }
}