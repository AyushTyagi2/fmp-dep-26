public class CreateQueueEventRequest
{
    public Guid? ZoneId { get; set; }

    public int DurationHours { get; set; }

    public int WindowSeconds { get; set; } = 120;
}