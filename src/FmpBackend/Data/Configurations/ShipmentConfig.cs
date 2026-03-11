using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class ShipmentConfiguration : IEntityTypeConfiguration<Shipment>
{
    public void Configure(EntityTypeBuilder<Shipment> entity)
    {
        entity.ToTable("shipments");

        entity.HasKey(e => e.Id);

        entity.Property(e => e.Id).HasColumnName("id");
        entity.Property(e => e.ShipmentNumber).HasColumnName("shipment_number").HasMaxLength(50).IsRequired();
        entity.HasIndex(e => e.ShipmentNumber).IsUnique();
        entity.Property(e => e.SenderOrganizationId).HasColumnName("sender_organization_id");
        entity.Property(e => e.ReceiverOrganizationId).HasColumnName("receiver_organization_id");
        entity.Property(e => e.CreatedByUserId).HasColumnName("created_by_user_id");
        entity.Property(e => e.PickupAddressId).HasColumnName("pickup_address_id");
        entity.Property(e => e.DropAddressId).HasColumnName("drop_address_id");
        entity.Property(e => e.CargoType).HasColumnName("cargo_type").HasMaxLength(100);
        entity.Property(e => e.CargoDescription).HasColumnName("cargo_description");
        entity.Property(e => e.CargoWeightKg).HasColumnName("cargo_weight_kg").HasPrecision(10, 2);
        entity.Property(e => e.CargoVolumeCubicMeters).HasColumnName("cargo_volume_cubic_meters").HasPrecision(10, 2);
        entity.Property(e => e.PackageCount).HasColumnName("package_count");
        entity.Property(e => e.RequiresRefrigeration).HasColumnName("requires_refrigeration");
        entity.Property(e => e.RequiresInsurance).HasColumnName("requires_insurance");
        entity.Property(e => e.SpecialHandlingInstructions).HasColumnName("special_handling_instructions");
        entity.Property(e => e.PreferredPickupDate).HasColumnName("preferred_pickup_date");
        entity.Property(e => e.PreferredDeliveryDate).HasColumnName("preferred_delivery_date");
        entity.Property(e => e.IsUrgent).HasColumnName("is_urgent");
        entity.Property(e => e.AgreedPrice).HasColumnName("agreed_price").HasPrecision(10, 2);
        entity.Property(e => e.Currency).HasColumnName("currency").HasMaxLength(3);
        entity.Property(e => e.PricePerUnit).HasColumnName("price_per_unit");
        entity.Property(e => e.LoadingCharges).HasColumnName("loading_charges").HasPrecision(10, 2);
        entity.Property(e => e.UnloadingCharges).HasColumnName("unloading_charges").HasPrecision(10, 2);
        entity.Property(e => e.OtherCharges).HasColumnName("other_charges").HasPrecision(10, 2);
        entity.Property(e => e.TotalEstimatedPrice).HasColumnName("total_estimated_price").HasPrecision(10, 2);
        entity.Property(e => e.Status).HasColumnName("status").HasMaxLength(30);
        entity.Property(e => e.CreatedAt).HasColumnName("created_at");
        entity.Property(e => e.ApprovedAt).HasColumnName("approved_at");
        entity.Property(e => e.RejectionReason).HasColumnName("rejection_reason");
        entity.Property(e => e.UpdatedAt).HasColumnName("updated_at");
        // ✅ Navigation — lets ShipmentQueueService resolve city names
        entity.HasOne(e => e.PickupAddress)
              .WithMany()
              .HasForeignKey(e => e.PickupAddressId)
              .HasConstraintName("fk_shipment_pickup_address")
              .OnDelete(DeleteBehavior.Restrict);

        entity.HasOne(e => e.DropAddress)
              .WithMany()
              .HasForeignKey(e => e.DropAddressId)
              .HasConstraintName("fk_shipment_drop_address")
              .OnDelete(DeleteBehavior.Restrict);
    }
}