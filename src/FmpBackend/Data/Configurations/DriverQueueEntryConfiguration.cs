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
        builder.Property(e => e.HasClaimed)
               .HasColumnName("has_claimed")
               .HasDefaultValue(false);

        // ── New list model ────────────────────────────────────────────────────
        builder.Property(e => e.ShipmentListJson)
               .HasColumnName("shipment_list_json")
               .HasColumnType("jsonb")
               .HasDefaultValue("[]")
               .IsRequired();

        builder.Property(e => e.ClaimableCount)
               .HasColumnName("claimable_count")
               .HasDefaultValue(0);

        // ── Removed columns (old single-offer tracking) ───────────────────────
        // current_offered_shipment_queue_id  → dropped
        // offer_status                       → dropped
        // still_claimable_expires_at         → dropped (never needed with new model)
    }
}