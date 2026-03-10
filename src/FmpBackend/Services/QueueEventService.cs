using FmpBackend.Repositories;
using System.Text.RegularExpressions;
using FmpBackend.Models;
using FmpBackend.Dtos;
namespace FmpBackend.Services;

public class QueueEventService
{
    private readonly QueueEventRepository _queueEventRepo;
    private readonly DriverEligibleRepository _driverRepo;
    private readonly DriverQueueRepository _driverQueueRepo;

    public QueueEventService(
        QueueEventRepository queueEventRepo,
        DriverEligibleRepository driverRepo,
        DriverQueueRepository driverQueueRepo)
    {
        _queueEventRepo = queueEventRepo;
        _driverRepo = driverRepo;
        _driverQueueRepo = driverQueueRepo;
    }

public async Task<QueueEvent> CreateQueueEventAsync(CreateQueueEventRequest request)
{
    var existing = await _queueEventRepo.GetActiveEventAsync();

    if (existing != null)
        throw new Exception("A queue event is already active.");

    var startTime = DateTime.UtcNow;
    var endTime = startTime.AddHours(request.DurationHours);

    var queueEvent = new QueueEvent
    {
        Id = Guid.NewGuid(),
        ZoneId = request.ZoneId,
        StartTime = startTime,
        EndTime = endTime,
        WindowSeconds = request.WindowSeconds,
        Status = "live"
    };

    await _queueEventRepo.CreateAsync(queueEvent);

    await GenerateDriverQueue(queueEvent);

    return queueEvent;
}

    private async Task GenerateDriverQueue(QueueEvent queueEvent)
    {
        var drivers = await _driverRepo.GetEligibleDriversAsync();

        var entries = new List<DriverQueueEntry>();

        int position = 1;

        foreach (var driver in drivers)
        {
            var windowStart = queueEvent.StartTime
                .AddSeconds((position - 1) * queueEvent.WindowSeconds);

            var windowEnd = windowStart
                .AddSeconds(queueEvent.WindowSeconds);

            entries.Add(new DriverQueueEntry
            {
                Id = Guid.NewGuid(),
                QueueEventId = queueEvent.Id,
                DriverId = driver.Id,
                Position = position,
                ClaimWindowStart = windowStart,
                ClaimWindowEnd = windowEnd
            });

            position++;
        }

        await _driverQueueRepo.AddEntriesAsync(entries);
    }
}