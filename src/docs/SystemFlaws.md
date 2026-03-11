# Flaws — Structural, Architectural, and Security Issues

This document covers real problems in the current codebase that will cause pain as the system grows or goes to production. They are grouped by severity.

---

## 🔴 Critical (Will break in production or is a security hole)

---

### 1. No Authentication on Any Endpoint

**Location:** All controllers, `Program.cs`

**What's happening:** There is no JWT middleware configured and `[Authorize]` attributes are commented out everywhere. Any person who knows the API URL can call any endpoint without logging in — approve shipments, accept jobs, read all data.

```csharp
// ShipmentController.cs
[HttpPost("{id}/approve")]
// [Authorize(Roles = "Union")]  ← commented out
public async Task<IActionResult> ApproveShipment(Guid id)
```

**Fix:** Add JWT bearer authentication in `Program.cs`. Issue tokens on successful OTP verification. Add `[Authorize]` with appropriate role claims to every controller. At minimum, protect `/approve`, `/reject`, and `/accept` endpoints immediately.

---

### 2. OTP is Always `123456`

**Location:** `OtpService.cs`

**What's happening:**

```csharp
public void GenerateOtp(string phone)
{
    var otp = "123456"; // later random + SMS
    Console.WriteLine($"OTP for {phone}: {otp}");
}
```

Anyone who knows this can log in as any user just by knowing their phone number. There is no actual SMS delivery, no expiry, and no attempt tracking.

**Fix:** Integrate an SMS provider (e.g., Twilio, MSG91, Fast2SMS for India). Generate a random 6-digit OTP, store it with a 10-minute TTL in Redis or a DB table, validate on verify, and delete after use. Add a rate limit (e.g., 3 attempts per 10 minutes per phone).

---

### 3. Hardcoded GUIDs in Business Logic

**Location:** `ShipmentQueueService.AcceptAsync()`

**What's happening:**

```csharp
var trip = await _tripService.Value.CreateAsync(new CreateTripRequest(
    ShipmentId: item.ShipmentId,
    VehicleId: Guid.Parse("14037f26-fa8b-422d-b1a5-80bbf9eb3201"),  // ← hardcoded
    DriverId: driverId,
    AssignedFleetOwnerId: Guid.Parse("538c0094-5e5c-4429-9f38-63d9ff9acbb9"),  // ← hardcoded
    ...
));
```

Every trip created through the queue will be assigned to the same vehicle and fleet owner regardless of who the driver is or what vehicle they drive. The trips table will have wrong data.

**Fix:** When a driver accepts a shipment, look up `Driver.CurrentFleetOwnerId` and the vehicle currently assigned to that driver (`Vehicle` where `CurrentDriverId = driverId`). Pass those real IDs into `CreateTripRequest`. If the driver has no assigned vehicle, return a meaningful error rather than silently creating a corrupt record.

---

### 4. `AddDbContext` Registered Twice

**Location:** `Program.cs`

**What's happening:**

```csharp
builder.Services.AddDbContext<AppDbContext>(options =>    // ← first registration
    options.UseNpgsql(...));

Console.WriteLine("We're in the ASP.NET API!!");
builder.Services.AddControllers()...;

AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);  // ← this is inside AddControllers chain but not

builder.Services.AddDbContext<AppDbContext>(options =>    // ← second registration
    options.UseNpgsql(...)
);
```

The second `AddDbContext` call overrides the first. More importantly, `AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true)` is placed after `AddControllers()` which can cause timestamp handling issues depending on execution order.

**Fix:** Remove the duplicate. Move `AppContext.SetSwitch` to the very top of `Program.cs` before any service registration, since it must be set before Npgsql initializes.

---

### 5. Driver Availability Not Updated After Accepting a Shipment

**Location:** `ShipmentQueueService.AcceptAsync()`

**What's happening:** When a driver accepts a shipment, their `Driver.AvailabilityStatus` is never changed from `"available"` to `"unavailable"` (or `"on_trip"`). This means:

- The same driver can appear in the eligible driver list for a new `QueueEvent` immediately after accepting a job.
- The `GetEligibleDriversAsync()` query will keep returning them as available.
- A driver could theoretically accept multiple shipments simultaneously.

**Fix:** After successfully creating a trip in `AcceptAsync()`, update the driver's `AvailabilityStatus = "on_trip"` (or `"unavailable"`). When the trip reaches `"delivered"`, set it back to `"available"`. This transition should happen inside a transaction with the trip creation.

---

## 🟠 Significant (Will cause bugs or scaling pain)

---

### 6. Circular Dependency Patched with `Lazy<T>` / `IServiceProvider`

**Location:** `ShipmentQueueService.cs`

**What's happening:** Three services form a cycle:
`ShipmentService → ShipmentQueueService → TripService → ShipmentService`

This is patched by injecting `IServiceProvider` and using `Lazy<TripService>`, which resolves the service from the container at runtime instead of injection time.

```csharp
private readonly Lazy<TripService> _tripService;
public ShipmentQueueService(..., IServiceProvider sp)
{
    _tripService = new Lazy<TripService>(() => sp.GetRequiredService<TripService>());
}
```

This is a code smell — it bypasses constructor injection, hides dependencies, and makes the code harder to test and reason about.

**Root cause:** `ShipmentQueueService` is doing too much. It owns both "managing the queue" AND "creating a trip when accepted" in one place.

**Fix:** Extract trip creation out of `ShipmentQueueService`. Either have the controller call both services in sequence after a successful accept, or introduce a dedicated `AcceptShipmentUseCase` / orchestration service that depends on both, breaking the cycle cleanly.

---

### 7. `QueueEvent` Claim Windows Are Never Enforced

**Location:** `ShipmentQueueService.AcceptAsync()`, `QueueEventService`

**What's happening:** The entire `QueueEvent` / `DriverQueueEntry` system is set up — drivers are slotted, windows are generated — but the `AcceptAsync` method never checks whether the accepting driver is within their assigned window. Any driver can accept at any time, making the QueueEvent system functionally inert.

**Fix:** In `AcceptAsync(queueItemId, driverId)`, before the lock:
1. Query `DriverQueueEntries` for the active `QueueEvent`.
2. Find this driver's entry.
3. Check `DateTime.UtcNow >= entry.ClaimWindowStart && DateTime.UtcNow <= entry.ClaimWindowEnd`.
4. If outside the window, return an appropriate error (e.g., `"Your window opens at {time}"`).
5. On successful claim, set `entry.HasClaimed = true`.

---

### 8. `QueueEvent` Never Closes Automatically

**Location:** `QueueEventRepository`, `QueueEventService`

**What's happening:** `QueueEvent.Status` is set to `"live"` on creation and the `GetActiveEventAsync()` check relies on this status. But nothing ever transitions it to `"closed"` when `EndTime` passes. The one-active-event guard will permanently block new events once an event is created (until someone manually updates the DB row).

**Fix:** Either add a background `IHostedService` (e.g., a `QueueEventExpiryWorker`) that runs every minute and closes expired events, or check `EndTime < DateTime.UtcNow` in `GetActiveEventAsync()` and treat expired events as closed on read.

---

### 9. `DriverService` Mixes Sync and Async

**Location:** `DriverService.cs`

**What's happening:** `DriverService` uses synchronous repository calls (`GetById`, `GetByFleetOwnerId`, etc.) while the rest of the codebase is async. Inside `GetDriversForFleetOwner`, it calls sync DB operations in a loop — one DB round trip per driver to fetch user and vehicle data.

```csharp
foreach (var d in drivers)
{
    var user = _users.GetById(d.UserId);      // ← sync DB call
    var vehicle = _vehicles.GetByCurrentDriverId(d.Id);  // ← another sync DB call
}
```

For a fleet with 50 drivers, this is 101 sequential DB queries.

**Fix:** Convert `DriverRepository`, `UserRepository`, and `VehicleRepository` to async. Fetch all users and vehicles in bulk before the loop with `WHERE id IN (...)` queries. Or use EF Core navigation properties and `.Include()` to load everything in one query.

---

### 10. `AppSession` in Flutter Is In-Memory Only

**Location:** `lib/app_session.dart`

**What's happening:** Session data (phone number, driver ID) is stored as static variables in `AppSession`. When the app is backgrounded and killed by the OS (which Android and iOS do regularly), all session data is lost. The user has to log in again from scratch every time the app restarts.

**Fix:** Persist session data using `flutter_secure_storage` or `shared_preferences`. On app startup, check for an existing session token and restore it. Combine with proper JWT tokens so the backend can validate the session.

---

### 11. Reject Shipment Reason Is Hardcoded

**Location:** `ShipmentController.cs`

**What's happening:**

```csharp
[HttpPost("{id}/reject")]
public async Task<IActionResult> RejectShipment(Guid id)
{
    var result = await _service.RejectShipmentAsync(id, "bad bad");  // ← hardcoded
```

The rejection reason is always `"bad bad"` — it's never passed from the client.

**Fix:** Accept a `RejectShipmentRequest` body with a `reason` field. Pass it through to `RejectShipmentAsync`.

---

## 🟡 Structural / Design Issues

---

### 12. Two Separate `TripRepository` and `TripCrudRepository`

**Location:** `Repositories/TripRepository.cs`, `Repositories/TripCrudRepository.cs`

**What's happening:** Trip database access is split across two repositories with no clear separation of concerns. `TripService` uses `TripCrudRepository` while `DriverService` uses `TripRepository`. Both are registered in DI separately.

**Fix:** Merge them into a single `TripRepository`. Use method naming to distinguish simple reads from complex queries.

---

### 13. `SysAdminService` Returns Entirely Mocked Data

**Location:** `SysAdminService.cs`

**What's happening:** All three methods return hardcoded lists and fake GUIDs. The metrics dashboard shows `activeDrivers = 42` regardless of what's actually in the database.

**Fix:** Query the real data. Active drivers: `COUNT(*) FROM drivers WHERE status = 'active'`. Pending shipments: `COUNT(*) FROM shipments WHERE status = 'pending_approval'`. Active trips: `COUNT(*) FROM trips WHERE current_status NOT IN ('completed', 'cancelled')`.

---

### 14. No Input Validation on Any Endpoint

**Location:** All controllers and DTOs

**What's happening:** There are no `[Required]`, `[Range]`, `[MaxLength]` attributes on any DTO, and no `FluentValidation` or similar library is configured. Invalid or missing data will either throw unhandled exceptions or silently create bad records.

**Fix:** Add data annotations or FluentValidation to all request DTOs. Add a global exception handler middleware that catches unhandled exceptions and returns structured error responses instead of stack traces.

---

### 15. Status Values Are Magic Strings Everywhere

**Location:** Throughout services, repositories, and models

**What's happening:** Shipment statuses (`"pending_approval"`, `"approved"`, `"rejected"`, etc.), trip statuses, and queue statuses are raw strings scattered across the codebase. A typo in any one place silently breaks the logic.

```csharp
shipment.Status = "pending_approval";  // in ShipmentService
x.Status == "waiting"                  // in ShipmentQueueRepository
d.Status == "active"                   // in DriverEligibleRepository
```

**Fix:** Replace with `static class` constants or `enum`s:

```csharp
public static class ShipmentStatus
{
    public const string PendingApproval = "pending_approval";
    public const string Approved        = "approved";
    public const string Rejected        = "rejected";
    // ...
}
```

---

### 16. `DriverController` Route Is Inconsistent with the Rest

**Location:** `DriverController.cs`

**What's happening:** All other controllers use `api/[controller]` or explicit `api/...` routes. `DriverController` uses just `drivers` without the `api/` prefix. This is inconsistent and will cause confusion when building client code.

```csharp
[Route("drivers")]        // ← no "api/" prefix
public class DriverController : ControllerBase
```

**Fix:** Change to `[Route("api/drivers")]` and update the Flutter API client accordingly.