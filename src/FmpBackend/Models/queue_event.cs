public class QueueEvent
{
    public Guid Id { get; set; }

    public Guid? ZoneId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public int WindowSeconds { get; set; } = 120;

    public string Status { get; set; } = "scheduled";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}