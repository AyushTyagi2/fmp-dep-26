using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FmpBackend.Data.Configurations;

public class QueueEventConfiguration : IEntityTypeConfiguration<QueueEvent>
{
    public void Configure(EntityTypeBuilder<QueueEvent> builder)
    {
        builder.ToTable("queue_events");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id).HasColumnName("id");
        builder.Property(e => e.ZoneId).HasColumnName("zone_id");
        builder.Property(e => e.StartTime).HasColumnName("start_time");
        builder.Property(e => e.EndTime).HasColumnName("end_time");
        builder.Property(e => e.WindowSeconds).HasColumnName("window_seconds");
        builder.Property(e => e.Status).HasColumnName("status").HasMaxLength(20).HasDefaultValue("live");
    }
}