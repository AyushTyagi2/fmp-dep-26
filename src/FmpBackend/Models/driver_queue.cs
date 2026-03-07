public class DriverQueueEntry
{
    public Guid Id { get; set; }

    public Guid QueueEventId { get; set; }

    public Guid DriverId { get; set; }

    public int Position { get; set; }

    public DateTime ClaimWindowStart { get; set; }

    public DateTime ClaimWindowEnd { get; set; }

    public bool HasClaimed { get; set; } = false;
}