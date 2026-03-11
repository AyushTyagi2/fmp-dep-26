using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FmpBackend.Data.Configurations;

public class DriverQueueEntryConfiguration : IEntityTypeConfiguration<DriverQueueEntry>
{
    public void Configure(EntityTypeBuilder<DriverQueueEntry> builder)
    {
        builder.ToTable("driver_queue_entries");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id).HasColumnName("id");
        builder.Property(e => e.QueueEventId).HasColumnName("queue_event_id");
        builder.Property(e => e.DriverId).HasColumnName("driver_id");
        builder.Property(e => e.Position).HasColumnName("position");
        builder.Property(e => e.ClaimWindowStart).HasColumnName("claim_window_start");
        builder.Property(e => e.ClaimWindowEnd).HasColumnName("claim_window_end");
        builder.Property(e => e.HasClaimed).HasColumnName("has_claimed").HasDefaultValue(false);

        // ── Parallel offer columns ──────────────────────────────────────────
        builder.Property(e => e.CurrentOfferedShipmentQueueId)
               .HasColumnName("current_offered_shipment_queue_id");

        builder.Property(e => e.OfferStatus)
               .HasColumnName("offer_status")
               .HasMaxLength(20)
               .HasDefaultValue(DriverOfferStatus.Idle);

        builder.HasOne(e => e.CurrentOfferedShipment)
               .WithMany()
               .HasForeignKey(e => e.CurrentOfferedShipmentQueueId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.SetNull);
    }
}