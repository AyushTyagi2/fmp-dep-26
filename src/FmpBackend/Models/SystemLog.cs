namespace FmpBackend.Models;

public class SystemLog
{
    public Guid    Id          { get; set; } = Guid.NewGuid();
    public string  EventType   { get; set; } = default!;   // e.g. "shipment.approved"
    public Guid?   UserId      { get; set; }                // admin/driver who acted
    public string  ActorType   { get; set; } = default!;   // "admin" | "driver" | "system"
    public string? EntityType  { get; set; }                // "shipment" | "trip" | "driver"
    public Guid?   EntityId    { get; set; }                // ID of the affected row
    public string  Metadata    { get; set; } = "{}";        // JSON string (flexible payload)
    public DateTime CreatedAt  { get; set; } = DateTime.UtcNow;
}