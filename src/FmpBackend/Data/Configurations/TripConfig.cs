using FmpBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FmpBackend.Data.Configurations;

public class TripConfiguration : IEntityTypeConfiguration<Trip>
{
    public void Configure(EntityTypeBuilder<Trip> builder)
    {
        builder.ToTable("trips");
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Id).HasColumnName("id");
        builder.Property(t => t.TripNumber).HasColumnName("trip_number").HasMaxLength(50).IsRequired();
        builder.Property(t => t.ShipmentId).HasColumnName("shipment_id");
        builder.Property(t => t.VehicleId).HasColumnName("vehicle_id");
        builder.Property(t => t.DriverId).HasColumnName("driver_id");
        builder.Property(t => t.AssignedUnionId).HasColumnName("assigned_union_id");
        builder.Property(t => t.AssignedFleetOwnerId).HasColumnName("assigned_fleet_owner_id");
        builder.Property(t => t.AssignedBy).HasColumnName("assigned_by");
        builder.Property(t => t.AssignedAt).HasColumnName("assigned_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        builder.Property(t => t.PlannedStartTime).HasColumnName("planned_start_time");
        builder.Property(t => t.PlannedEndTime).HasColumnName("planned_end_time");
        builder.Property(t => t.EstimatedDistanceKm).HasColumnName("estimated_distance_km").HasColumnType("decimal(10,2)");
        builder.Property(t => t.EstimatedDurationHours).HasColumnName("estimated_duration_hours").HasColumnType("decimal(5,2)");
        builder.Property(t => t.ActualStartTime).HasColumnName("actual_start_time");
        builder.Property(t => t.ActualEndTime).HasColumnName("actual_end_time");
        builder.Property(t => t.ActualDistanceKm).HasColumnName("actual_distance_km").HasColumnType("decimal(10,2)");
        builder.Property(t => t.CurrentStatus).HasColumnName("current_status").HasMaxLength(30).HasDefaultValue("created");
        builder.Property(t => t.CurrentLatitude).HasColumnName("current_latitude").HasColumnType("decimal(10,8)");
        builder.Property(t => t.CurrentLongitude).HasColumnName("current_longitude").HasColumnType("decimal(11,8)");
        builder.Property(t => t.LastLocationUpdateAt).HasColumnName("last_location_update_at");
        builder.Property(t => t.DeliveredAt).HasColumnName("delivered_at");
        builder.Property(t => t.DeliveredToName).HasColumnName("delivered_to_name").HasMaxLength(255);
        builder.Property(t => t.DeliveredToPhone).HasColumnName("delivered_to_phone").HasMaxLength(20);
        builder.Property(t => t.ProofOfDeliveryUrl).HasColumnName("proof_of_delivery_url");
        builder.Property(t => t.DeliveryNotes).HasColumnName("delivery_notes");
        builder.Property(t => t.SenderRating).HasColumnName("sender_rating");
        builder.Property(t => t.SenderFeedback).HasColumnName("sender_feedback");
        builder.Property(t => t.ReceiverRating).HasColumnName("receiver_rating");
        builder.Property(t => t.ReceiverFeedback).HasColumnName("receiver_feedback");
        builder.Property(t => t.DriverPaymentAmount).HasColumnName("driver_payment_amount").HasColumnType("decimal(10,2)");
        builder.Property(t => t.DriverPaymentStatus).HasColumnName("driver_payment_status").HasMaxLength(20).HasDefaultValue("pending");
        builder.Property(t => t.DriverPaidAt).HasColumnName("driver_paid_at");
        builder.Property(t => t.HasIssues).HasColumnName("has_issues").HasDefaultValue(false);
        builder.Property(t => t.IssueDescription).HasColumnName("issue_description");
        builder.Property(t => t.DelayReason).HasColumnName("delay_reason");
        builder.Property(t => t.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        builder.Property(t => t.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        builder.Property(t => t.CompletedAt).HasColumnName("completed_at");

        builder.HasOne(t => t.Shipment)
               .WithMany()
               .HasForeignKey(t => t.ShipmentId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(t => t.TripNumber).IsUnique();
        builder.HasIndex(t => t.ShipmentId);
        builder.HasIndex(t => t.DriverId);
        builder.HasIndex(t => t.CurrentStatus);
        builder.HasIndex(t => t.AssignedUnionId);
    }
}