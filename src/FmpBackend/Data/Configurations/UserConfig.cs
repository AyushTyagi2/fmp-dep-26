using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using FmpBackend.Models;

namespace FmpBackend.Data.Configurations;

public class UserConfig : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> entity)
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
    }
}