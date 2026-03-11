# FMP — Fleet Management Platform

## What Is This?

FMP is a logistics and fleet management platform built for the Indian market. It connects **Senders** (organizations that need cargo shipped) with **Drivers** (who physically move cargo) via **Fleet Owners** (who own vehicles and manage drivers). A **Union** role acts as a middle layer that reviews and approves shipments before they become available to drivers. A **SysAdmin** manages the overall platform.

The system is made up of three parts:
- **FmpBackend** — ASP.NET Core 8 REST API backed by PostgreSQL
- **lib** — Flutter mobile application (single codebase, multiple role-based UIs)
- **database** — Raw PostgreSQL schema SQL files

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | ASP.NET Core 8, C# |
| ORM | Entity Framework Core (EF Core) with Npgsql |
| Database | PostgreSQL |
| Mobile App | Flutter (Dart) |
| Auth | Phone OTP (hardcoded `123456` currently) |
| DI | ASP.NET built-in `IServiceCollection` |

---

## Project Structure

### Backend (`FmpBackend/`)

```
FmpBackend/
├── Controllers/         HTTP endpoints, thin — just call services
│   ├── authcontroller.cs
│   ├── DriverController.cs
│   ├── ShipmentController.cs
│   ├── ShipmentQueueController.cs
│   ├── QueueEventController.cs
│   ├── SenderController.cs
│   ├── SysAdminController.cs
│   └── TripsController.cs
│
├── Services/            Business logic layer
│   ├── OtpService.cs
│   ├── RoleService.cs
│   ├── DriverService.cs
│   ├── SenderService.cs
│   ├── ShipmentService.cs
│   ├── ShipmentQueueService.cs
│   ├── QueueEventService.cs
│   ├── TripService.cs
│   └── SysAdminService.cs
│
├── Repositories/        Database access layer
│   ├── UserRepository.cs
│   ├── DriverRepository.cs / DriverEligibleRepository.cs
│   ├── DriverQueue.cs
│   ├── VehicleRepository.cs
│   ├── FleetOwnerRepository.cs
│   ├── OrganizationRepository.cs
│   ├── AddressRepository.cs
│   ├── ShipmentRepository.cs
│   ├── ShipmentQueueRepository.cs
│   ├── QueueEventRepo.cs
│   ├── TripRepository.cs / TripCrudRepository.cs
│   └── ...
│
├── Models/              EF Core entity classes (map to DB tables)
├── Dtos/                Request/response data shapes
├── Data/
│   ├── AppDbContext.cs  EF Core DbContext
│   └── Configurations/  Fluent API table configs
└── Program.cs           DI registration, middleware setup
```

### Flutter App (`lib/`)

```
lib/
├── core/
│   ├── models/          Dart model classes (Shipment, QueueEntry, etc.)
│   └── network/         API client wrappers
│
├── app_session.dart     Global session state (phone, driverId in memory)
│
└── presentation/
    ├── auth/            Welcome → Phone Input → OTP Verify
    ├── role_router/     AccountResolverScreen — routes after login
    ├── onboarding/      Role selection, driver/sender/fleet onboarding flows
    ├── driver/          Driver dashboard, queue screen, trips screen, profile
    ├── sender/          Sender dashboard, create shipment, shipment list
    ├── union/           Union dashboard, shipment request review, queue view
    ├── fleetmgr/        Fleet owner dashboard
    └── sys_admin_dashboard/ System admin panel
```

### Database (`database/`)

```
database/
├── schema/
│   ├── trips.sql            shipments, shipment_queue, trips, trip_status_events,
│   │                        trip_locations, trip_documents
│   ├── support.sql          seed data (addresses, org IDs)
│   └── updaters_and_views.sql  triggers, views, materialized views, helper functions
```

---

## Domain Model & Roles

### Entities

| Entity | Description |
|---|---|
| `User` | Anyone with a phone number. Base identity. |
| `Driver` | A user who drives. Belongs to a `FleetOwner`. Has license, availability status, rating. |
| `Vehicle` | Owned by a `FleetOwner`, assigned to a `Driver`. |
| `FleetOwner` | Business entity owning vehicles and managing drivers. |
| `Organization` | Sender or receiver business. Has a primary contact phone and default address. |
| `Shipment` | A cargo movement request from one org to another. Goes through an approval workflow. |
| `Trip` | Operational execution of a shipment. Assigned to a driver + vehicle. |
| `ShipmentQueue` | An approved shipment waiting for a driver to claim it. |
| `QueueEvent` | A scheduled window during which drivers get time-slotted access to claim shipments. |
| `DriverQueueEntry` | A driver's assigned time slot within a `QueueEvent`. |

---

## End-to-End Flow

### 1. User Registration & Login
1. User enters phone number → OTP is "sent" (hardcoded as `123456` right now).
2. OTP verified → user record created in `users` table if new.
3. User selects a role (Driver / Organization / Fleet Owner).
4. `RoleService.Resolve()` checks if profile exists → routes to onboarding or dashboard.

### 2. Sender Creates a Shipment
1. Sender fills the create-shipment form in app.
2. `POST /api/shipments` → `ShipmentService.CreateShipmentAsync()`.
3. Sender and receiver orgs are looked up by phone. Default addresses are resolved.
4. Shipment is created with `status = "pending_approval"`.

### 3. Union Reviews and Approves
1. Union opens the "Shipment Requests" tab — calls `GET /api/shipments/pending`.
2. Union taps Approve → `POST /api/shipments/{id}/approve`.
3. `ShipmentService.ApproveShipmentAsync()` sets `status = "approved"` and immediately calls `ShipmentQueueService.EnqueueAsync()`.
4. Shipment appears in `shipment_queue` with `status = "waiting"`.

### 4. Driver Sees and Claims Shipment
1. Driver opens the queue screen — polls `GET /api/shipment-queue` every 5 seconds.
2. Driver taps a shipment → sees details (pickup, drop, price, urgency).
3. Driver taps "Accept Shipment" → `POST /api/shipment-queue/{id}/accept`.
4. Backend uses `SELECT ... FOR UPDATE SKIP LOCKED` to prevent race conditions.
5. On success: queue item status → `"accepted"`, a `Trip` record is created automatically, shipment status → `"assigned"`.
6. The `tripId` is returned to the app, which navigates directly to the Active Trip screen.

### 5. Trip Execution
1. Driver updates trip status via `PATCH /api/trips/{id}/status`.
2. Statuses: `assigned → in_transit → delivered`.
3. Each update syncs parent shipment status via `ShipmentService.SyncStatusFromTripAsync()`.
4. GPS coordinates can be included in status updates.

### 6. QueueEvent System (Time-Slotted Access)
1. Admin creates a `QueueEvent` via `POST /api/queue-events`.
2. All eligible drivers (active, available, verified) are fetched and sorted by `TotalTripsCompleted`.
3. Each driver gets a `DriverQueueEntry` with sequential `ClaimWindowStart` and `ClaimWindowEnd` times.
4. Drivers receive fair, prioritized access based on experience.

---

## API Endpoints (Current)

| Method | Route | Description |
|---|---|---|
| POST | `/api/auth/request-otp` | Send OTP to phone |
| POST | `/api/auth/verify-otp` | Verify OTP, create user if new |
| POST | `/api/auth/resolve-role` | Route user to correct screen |
| POST | `/drivers/driver-details` | Driver onboarding |
| GET  | `/drivers/{id}` | Get driver details |
| GET  | `/drivers/fleetowners/{id}/drivers` | All drivers for a fleet owner |
| GET  | `/drivers/fleetowners/phone/{phone}/drivers` | Same, by phone |
| GET  | `/drivers/fleetowners/phone/{phone}/dashboard` | Fleet dashboard metrics |
| POST | `/api/shipments` | Create shipment |
| GET  | `/api/shipments/by-phone/{phone}` | Sent/received shipments for org |
| GET  | `/api/shipments/pending` | List pending approval shipments |
| POST | `/api/shipments/{id}/approve` | Approve shipment (auto-enqueues) |
| POST | `/api/shipments/{id}/reject` | Reject shipment |
| GET  | `/api/shipment-queue` | List waiting queue items (paginated) |
| GET  | `/api/shipment-queue/{id}` | Get single queue item |
| POST | `/api/shipment-queue/enqueue` | Manually enqueue a shipment |
| POST | `/api/shipment-queue/{id}/accept` | Driver accepts a shipment |
| GET  | `/api/trips` | List trips (paginated, filterable) |
| GET  | `/api/trips/{id}` | Get trip by ID |
| POST | `/api/trips` | Create trip manually |
| PATCH | `/api/trips/{id}/status` | Update trip status + GPS |
| GET  | `/api/trips/driver/{driverId}` | Get trips for a driver |
| POST | `/api/queue-events` | Create a timed queue event |
| GET  | `/api/sysadmin/metrics` | System metrics (mocked) |
| GET  | `/api/sysadmin/logs` | Recent logs (mocked) |
| GET  | `/api/sysadmin/users` | Active users (mocked) |

---

## Database Schema Highlights

The PostgreSQL schema includes:
- UUID primary keys everywhere
- `CHECK` constraints on all status columns
- Indexes on all foreign keys and common filter columns
- `updated_at` auto-update triggers on all relevant tables
- Event-sourced `trip_status_events` table for a full, immutable audit trail
- `trip_locations` table for GPS breadcrumb tracking (with `device_id` for offline sync)
- `trip_documents` table for e-way bills, POD, invoices
- Materialized view `trip_analytics_daily` for reporting
- Views: `active_trips_view`, `driver_performance_view`, `vehicle_utilization_view`

---

## Known Dev Shortcuts (Not Production-Ready)

- OTP is hardcoded as `"123456"` — no SMS integration yet.
- `AcceptAsync()` creates trips with hardcoded placeholder `VehicleId` and `FleetOwnerId`.
- `SysAdminService` returns fully mocked metrics and logs.
- `AppSession` in Flutter stores state in memory only — lost on app restart.
- No JWT authentication is enforced — auth middleware is commented out in controllers.
- Driver availability is not automatically set to "unavailable" after accepting a shipment.
- `QueueEvent` claim window enforcement is not connected to the accept endpoint.
- `AddDbContext` is registered twice in `Program.cs`.