# Improvements — Enhancements to What's Already Built

This document covers improvements to things that are already working — making them more robust, efficient, or production-ready. For bugs and broken things, see `flaws.md`.

---

## Backend Improvements

---

### 1. Replace Polling with WebSockets or SSE for the Queue

**Current:** Both the driver queue screen and union queue screen poll the server every 5 seconds. With 100 concurrent drivers, that's 1,200 DB queries per minute just to check for new shipments — most of which return the same unchanged list.

**Improvement:** Use SignalR (built into ASP.NET Core) to push updates to clients in real-time.

```csharp
// Hub
public class ShipmentQueueHub : Hub
{
    public async Task JoinQueueRoom(string zoneId)
        => await Groups.AddToGroupAsync(Context.ConnectionId, $"zone-{zoneId}");
}

// When a shipment is enqueued, broadcast to all connected drivers
await _hubContext.Clients.Group("zone-all").SendAsync("NewShipmentAvailable", shipmentDto);
```

Flutter connects once and receives push events. The 5-second timer is eliminated. Latency drops from up to 5 seconds to near-instant.

---

### 2. Auto-Expire `offered` Queue Items

**Current:** The `ShipmentQueue` model has `OfferExpiresAt` and an `"offered"` status, but these are never used. The `offered` concept (driver offered a shipment but hasn't accepted yet) exists in the data model but is ignored.

**Improvement:** Implement the offer flow and a background expiry worker:

```csharp
// Background service that runs every 30 seconds
public class QueueExpiryWorker : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await _db.ShipmentQueues
                .Where(q => q.Status == "offered" && q.OfferExpiresAt < DateTime.UtcNow)
                .ExecuteUpdateAsync(x => x
                    .SetProperty(q => q.Status, "waiting")
                    .SetProperty(q => q.CurrentDriverId, (Guid?)null)
                    .SetProperty(q => q.OfferExpiresAt, (DateTime?)null));

            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }
}
```

This makes the queue self-healing — a shipment that was offered to a driver who went offline reverts to available automatically.

---

### 3. Paginated Response Should Include `totalItems` Not Just `totalPages`

**Current:** `PagedResult<T>` returns `Total`, `Page`, `PageSize`, and items. The frontend calculates `totalPages = (total + pageSize - 1) / pageSize`.

**Improvement:** Add `TotalPages` as a computed property directly in the DTO so clients don't need to compute it. Also add `HasNext` and `HasPrevious` boolean flags — simpler for the Flutter pagination widget.

```csharp
public class PagedResult<T>
{
    public List<T> Items     { get; set; } = new();
    public int     Total     { get; set; }
    public int     Page      { get; set; }
    public int     PageSize  { get; set; }
    public int     TotalPages => (int)Math.Ceiling((double)Total / PageSize);
    public bool    HasNext    => Page < TotalPages;
    public bool    HasPrevious => Page > 1;
}
```

---

### 4. Add a `GET /api/queue-events/active` Endpoint

**Current:** There is only `POST /api/queue-events` to create an event. There is no way for a driver to query their current window, see when their slot opens, or know if a QueueEvent is active.

**Improvement:** Add a read endpoint so the mobile app can show a countdown to the driver:

```
GET /api/queue-events/active?driverId={id}
→ {
    eventId, status, startTime, endTime, windowSeconds,
    mySlot: { position, claimWindowStart, claimWindowEnd, hasClaimed }
  }
```

This allows the Flutter app to show "Your window opens in 4 minutes 30 seconds" with a live countdown timer.

---

### 5. Add Zone-Based Queue Filtering

**Current:** `ShipmentQueue` has a `ZoneId` field, but `GetWaitingAsync()` returns all waiting items with no zone filter. A driver in Mumbai sees shipments from Delhi.

**Improvement:** Accept an optional `zoneId` query parameter on `GET /api/shipment-queue`:

```csharp
public async Task<(List<ShipmentQueue>, int)> GetWaitingAsync(int page, int pageSize, Guid? zoneId)
{
    var q = WithIncludes().Where(x => x.Status == "waiting");
    if (zoneId.HasValue)
        q = q.Where(x => x.ZoneId == zoneId || x.ZoneId == null);
    // ...
}
```

When a driver logs in, their zone is passed along and they only see local shipments.

---

### 6. Structured Error Responses and Global Exception Handling

**Current:** Unhandled exceptions return ASP.NET's default HTML error pages or raw exception messages. There's no consistent error shape across the API.

**Improvement:** Add a global exception handler middleware:

```csharp
app.UseExceptionHandler(err => err.Run(async ctx =>
{
    ctx.Response.ContentType = "application/json";
    var feature = ctx.Features.Get<IExceptionHandlerFeature>();
    var ex = feature?.Error;

    ctx.Response.StatusCode = ex switch
    {
        KeyNotFoundException => 404,
        UnauthorizedAccessException => 403,
        InvalidOperationException => 409,
        _ => 500
    };

    await ctx.Response.WriteAsJsonAsync(new
    {
        error = ex?.Message,
        code  = ctx.Response.StatusCode
    });
}));
```

This makes the Flutter app's error handling predictable — always a JSON object with `error` and `code`.

---

### 7. Replace Raw SQL in Repository with EF Core Equivalent

**Current:**

```csharp
await _db.ShipmentQueues
    .FromSqlRaw("SELECT * FROM shipment_queue WHERE id={0} AND status='waiting' FOR UPDATE SKIP LOCKED", id)
    .FirstOrDefaultAsync();
```

The `FOR UPDATE SKIP LOCKED` is correct and necessary for race-condition safety. However, raw SQL bypasses EF Core's change tracking fully and is harder to maintain.

**Improvement:** Keep the raw SQL but encapsulate it properly and add a comment explaining why it's raw. Alternatively, EF Core 7+ supports `ExecuteUpdate` / pessimistic locking hints via Npgsql-specific APIs — worth evaluating. At minimum, add an integration test that verifies concurrent accepts are handled correctly.

---

### 8. Add Database Migrations via EF Core

**Current:** The database schema is managed via hand-written SQL files (`trips.sql`, etc.). The EF Core model configurations exist but there are no `dotnet ef migrations` used. Schema and code can drift out of sync.

**Improvement:** Generate an initial migration from the existing EF model:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

Going forward, all schema changes should be done through migrations so the model and DB are always in sync. The existing SQL files can be kept as reference.

---

## Flutter App Improvements

---

### 9. Persist Session State Across App Restarts

**Current:** `AppSession` stores phone and driverId as in-memory static variables. They are lost every time the app is killed.

**Improvement:** Use `flutter_secure_storage` to persist the session token:

```dart
// On login success:
await _storage.write(key: 'driver_id', value: driverId);
await _storage.write(key: 'phone', value: phone);

// On app startup in main.dart:
final driverId = await _storage.read(key: 'driver_id');
if (driverId != null) {
  AppSession.driverId = driverId;
  // navigate directly to dashboard, skip login
}
```

---

### 10. Add Countdown Timer to Driver Queue Screen

**Current:** The driver queue screen shows a list of shipments with a 5-second auto-refresh. There is no indication of the driver's QueueEvent window.

**Improvement:** When a QueueEvent is active:
1. Fetch the driver's `DriverQueueEntry` on screen load.
2. If the window hasn't started yet, show a countdown: "Your window opens in 3:45" and grey out the accept button.
3. When the window opens, animate in access and allow accepting.
4. Use `Timer.periodic(Duration(seconds: 1), ...)` to update the countdown every second.

---

### 11. Optimistic UI on Accept

**Current:** When a driver taps "Accept Shipment", there's a loading spinner while the API call completes. If it succeeds, the navigation happens. The UX feels slow.

**Improvement:** Immediately disable the button and show a success state optimistically, then confirm from the API response. If the API returns a conflict, revert and show the "Already Taken" dialog. This makes the UX feel instant.

---

### 12. Centralize API Base URL Configuration

**Current:** The base URL in `ApiClient` is likely hardcoded to a local IP or development URL. Switching between dev/staging/prod requires editing source code.

**Improvement:** Use Flutter's `--dart-define` flags or a `config.dart` file with environment-specific values:

```dart
// config.dart
class Config {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );
}
```

Run with: `flutter run --dart-define=API_BASE_URL=https://api.fmp.app`

---

### 13. Add Loading Skeleton Screens

**Current:** Queue screens show a `CircularProgressIndicator` centered on the screen while loading. This causes a "flash of empty content" on every navigation.

**Improvement:** Replace with shimmer skeleton cards that match the shape of `ShipmentCard`. Libraries like `shimmer` on pub.dev make this trivial. The screen feels responsive from the first frame.

---

## Database Improvements

---

### 14. Add Index on `shipment_queue(status)`

**Current:** The `shipment_queue` table has no explicit index on `status`. Every poll of `GET /api/shipment-queue` runs `WHERE status = 'waiting'` — a full table scan as the queue grows.

**Improvement:**

```sql
CREATE INDEX idx_shipment_queue_status ON shipment_queue(status) WHERE status = 'waiting';
```

A partial index only on `'waiting'` rows is extremely efficient since accepted/expired rows are excluded.

---

### 15. Add `updated_at` to `shipment_queue`

**Current:** `shipment_queue` has `created_at` but no `updated_at`. Once a row's status changes to `"accepted"`, there's no timestamp for when that happened.

**Improvement:**

```sql
ALTER TABLE shipment_queue ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

Apply the existing `update_updated_at_column()` trigger to this table. This enables auditing of queue state changes.

---

### 16. Add `driver_queue_entries` Index for Fast Lookup

**Current:** Looking up a driver's queue entry (needed when enforcing claim windows) requires scanning all entries for the active event.

**Improvement:**

```sql
CREATE INDEX idx_driver_queue_entries_event_driver
    ON driver_queue_entries(queue_event_id, driver_id);
```

This makes the window validation query in `AcceptAsync` a single-row index lookup instead of a scan.