namespace FmpBackend.Models;

public class UserRole
{
    public Guid      Id             { get; set; }
    public Guid      UserId         { get; set; }
    public Guid      RoleId         { get; set; }
    public bool      IsActive       { get; set; } = true;

    // Temporal validity — matches valid_from / valid_until columns in DB
    public DateTime  ValidFrom      { get; set; } = DateTime.UtcNow;
    public DateTime? ValidUntil     { get; set; }   // null = never expires

    // Navigation
    public Role?     Role           { get; set; }
}