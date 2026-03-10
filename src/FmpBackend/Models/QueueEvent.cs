namespace FmpBackend.Models;

public class QueueEvent
{
    public Guid     Id            { get; set; }
    public Guid?    ZoneId        { get; set; }
    public DateTime StartTime     { get; set; }
    public DateTime EndTime       { get; set; }
    public int      WindowSeconds { get; set; }
    public string   Status        { get; set; } = "live"; // live, closed
}