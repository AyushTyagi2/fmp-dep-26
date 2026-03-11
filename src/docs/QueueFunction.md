# Queue System — How It Works

FMP has two distinct but related queue mechanisms. They solve different problems and work independently of each other right now.

---

## The Two Queues at a Glance

| | ShipmentQueue | QueueEvent / DriverQueueEntry |
|---|---|---|
| **What it is** | A list of approved shipments waiting to be claimed | A time-slotted access system controlling *when* each driver can claim |
| **Created by** | Auto-created when a shipment is approved | Manually triggered by an admin |
| **Consumed by** | Any driver hitting the accept endpoint | Meant to gate access per driver (not yet enforced) |
| **DB table** | `shipment_queue` | `queue_events` + `driver_queue_entries` |
| **Status** | Fully working end-to-end | Created correctly, but claim window enforcement not wired up yet |

---

## Part 1: ShipmentQueue — The Live Dispatch Board

This is the core operational queue. Think of it as the "available jobs" board that all drivers see.

### Data Model

```csharp
public class ShipmentQueue
{
    public Guid     Id                  // PK
    public Guid     ShipmentId          // FK → shipments
    public Guid?    ZoneId              // optional geographic zone
    public string?  RequiredVehicleType // e.g. "truck", "mini"
    public string   Status              // waiting | offered | accepted | expired
    public Guid?    CurrentDriverId     // set when a driver accepts
    public DateTime? OfferExpiresAt     // for offer-based flow (unused currently)
    public DateTime  CreatedAt
}
```

### Lifecycle

```
Shipment approved
       │
       ▼
ShipmentQueueService.EnqueueAsync()
       │
       ▼
shipment_queue row inserted  (status = "waiting")
       │
       ▼
Driver polls GET /api/shipment-queue every 5s
       │
       ▼
Driver taps "Accept" → POST /api/shipment-queue/{id}/accept
       │
       ▼
Backend: SELECT ... FOR UPDATE SKIP LOCKED  ← race-condition safe
       │
       ├─ row already taken? → return null → 409 Conflict to app
       │
       └─ row is free?
               │
               ▼
         status → "accepted", CurrentDriverId = driverId
               │
               ▼
         TripService.CreateAsync() called → Trip row inserted
               │
               ▼
         ShipmentService.SyncStatusFromTripAsync() → shipment status → "assigned"
               │
               ▼
         { success: true, tripId: "..." } returned to app
               │
               ▼
         App navigates driver to ActiveTripScreen
```

### Race Condition Handling

The accept flow uses PostgreSQL row-level locking to safely handle multiple drivers accepting the same shipment at the same time:

```csharp
// ShipmentQueueRepository.cs
public async Task<ShipmentQueue?> LockForAcceptAsync(Guid id) =>
    await _db.ShipmentQueues
        .FromSqlRaw("SELECT * FROM shipment_queue WHERE id={0} AND status='waiting' FOR UPDATE SKIP LOCKED", id)
        .FirstOrDefaultAsync();
```

- `FOR UPDATE` acquires an exclusive row lock.
- `SKIP LOCKED` means if another transaction already has this row locked, this query returns nothing immediately instead of waiting. The first driver in wins; everyone else gets a 409.

The service wraps this in a retry loop (up to 3 attempts) to handle `DbUpdateConcurrencyException`:

```csharp
for (int attempt = 0; attempt < 3; attempt++)
{
    await using var tx = await _db.Database.BeginTransactionAsync();
    try
    {
        var item = await _repo.LockForAcceptAsync(queueItemId);
        if (item == null) { await tx.RollbackAsync(); return null; }

        item.Status = "accepted";
        item.CurrentDriverId = driverId;
        await _repo.SaveAsync();
        await tx.CommitAsync();

        var trip = await _tripService.Value.CreateAsync(...);
        return trip.Id;
    }
    catch (DbUpdateConcurrencyException) { await tx.RollbackAsync(); }
    catch { await tx.RollbackAsync(); throw; }
}
```

### Flutter Side (Polling)

Both the Union queue screen (`union_queue/queue.dart`) and the Driver queue screen (`driver/queue/driver_queue_screen.dart`) use identical polling logic:

```dart
static const _refreshIntervalSeconds = 5;

void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) => _silentRefresh(),
    );
}
```

- Initial load shows a full loading spinner.
- Background refreshes are silent — no spinner, just data swap.
- Manual pull-to-refresh is also supported.
- Pagination: 20 items per page, prev/next buttons shown if `totalPages > 1`.

When a driver accepts:
1. `ShipmentApiService.acceptShipment()` calls `POST /api/shipment-queue/{id}/accept`.
2. If `result.success == true` → navigate to `ActiveTripScreen(tripId: result.tripId)`.
3. If `result.success == false` → show "Already Taken" dialog, go back to queue.

---

## Part 2: QueueEvent — Time-Slotted Driver Access

This is a fairness layer on top of the shipment queue. Instead of all drivers competing equally in real-time, a `QueueEvent` gives each driver an exclusive time window to browse and accept shipments.

### Data Models

```csharp
public class QueueEvent
{
    public Guid     Id
    public Guid?    ZoneId
    public DateTime StartTime
    public DateTime EndTime
    public int      WindowSeconds   // how many seconds each driver gets
    public string   Status          // live | closed
}

public class DriverQueueEntry
{
    public Guid     Id
    public Guid     QueueEventId
    public Guid     DriverId
    public int      Position          // 1 = first in line
    public DateTime ClaimWindowStart  // when this driver's window opens
    public DateTime ClaimWindowEnd    // when this driver's window closes
    public bool     HasClaimed        // has this driver accepted a shipment yet
}
```

### How a QueueEvent Is Created

```
POST /api/queue-events
{
  "zoneId": null,
  "durationHours": 2,
  "windowSeconds": 300
}
```

1. `QueueEventService.CreateQueueEventAsync()` checks that no other event is currently `"live"`. If one exists, it throws — one event at a time.
2. A `QueueEvent` row is created with `StartTime = now`, `EndTime = now + durationHours`.
3. `GenerateDriverQueue()` is called:
   - Fetches all eligible drivers: `status = "active"`, `availabilityStatus = "available"`, `verified = true`.
   - Sorts them by `TotalTripsCompleted DESC` (most experienced first).
   - Assigns each driver a sequential slot:
     - Driver at position `N` gets `ClaimWindowStart = eventStart + (N-1) * windowSeconds`.
     - Their window is `windowSeconds` long.
4. All `DriverQueueEntry` rows are bulk-inserted.

### Example: 3 Drivers, 5-Minute Windows

```
QueueEvent: StartTime = 10:00, WindowSeconds = 300

Driver A (position 1, 50 trips):  window 10:00 → 10:05
Driver B (position 2, 30 trips):  window 10:05 → 10:10
Driver C (position 3, 10 trips):  window 10:10 → 10:15
```

Driver A gets first pick because they have the most completed trips.

### Current State vs. Intended Behavior

| Aspect | Current | Intended |
|---|---|---|
| QueueEvent creation | ✅ Works | — |
| Driver slot generation | ✅ Works | — |
| Enforcing claim window on accept | ❌ Not implemented | Accept endpoint should check `DriverQueueEntry.ClaimWindowStart/End` before allowing |
| Closing expired events | ❌ Not implemented | A background job or trigger should set status → `"closed"` when `EndTime` passes |
| `HasClaimed` flag update | ❌ Not implemented | Should be set to `true` when driver successfully accepts a shipment |
| Frontend for QueueEvent | ❌ No UI | Drivers need to see their window time, countdown timer, etc. |

---

## How the Two Queues Interact (Currently)

Right now they are **parallel but disconnected**:

```
ShipmentQueue  ←──── drivers poll this and accept freely (no window check)
QueueEvent     ←──── admin creates this and slot assignments are generated, but not enforced
```

The intended architecture is:

```
ShipmentQueue  ←──── drivers can only accept if DateTime.UtcNow is within their DriverQueueEntry window
QueueEvent     ←──── defines those windows
```

Connecting them requires the `AcceptAsync` method to query `DriverQueueEntry` for the given driver and validate the current time falls within their slot.

---

## Circular Dependency Note

There is a deliberate circular dependency between `ShipmentService` and `ShipmentQueueService`/`TripService`:

```
ShipmentService → ShipmentQueueService (to enqueue on approve)
ShipmentQueueService → TripService (to create trip on accept)
TripService → ShipmentService (to sync status on trip update)
```

This is resolved using `Lazy<TripService>` inside `ShipmentQueueService`:

```csharp
private readonly Lazy<TripService> _tripService;

public ShipmentQueueService(..., IServiceProvider sp)
{
    _tripService = new Lazy<TripService>(() => sp.GetRequiredService<TripService>());
}
```

This breaks the DI cycle by deferring resolution until first use. It works but is a code smell — see `flaws.md` for the architectural recommendation.