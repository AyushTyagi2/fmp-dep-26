# Fleet Management Platform - Database Design Documentation

## Table of Contents
1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Architecture Decisions](#architecture-decisions)
4. [Entity Relationship Overview](#entity-relationship-overview)
5. [Core Workflows](#core-workflows)
6. [Security & Access Control](#security--access-control)
7. [Offline Sync Strategy](#offline-sync-strategy)
8. [Scaling Considerations](#scaling-considerations)
9. [API Integration Guidelines](#api-integration-guidelines)
10. [Migration & Deployment](#migration--deployment)

---

## Overview

This database design supports a multi-stakeholder fleet management platform with:
- **Role-based access control** (RBAC) for drivers, fleet owners, unions, senders, receivers, and admins
- **Event-sourced trip lifecycle** for complete auditability
- **Offline-first architecture** with sync capabilities
- **Document management** for compliance (licenses, permits, POD)
- **Real-time location tracking** with GPS breadcrumbs
- **Dispute resolution** with immutable audit trails

**Technology Stack:**
- PostgreSQL 14+ (with UUID and JSONB support)
- Event sourcing for critical state changes
- Normalized schema with strategic denormalization

---

## Design Principles

### 1. **Separation of Concerns**
```
Identity (users) → Roles (drivers, fleet owners) → Business Logic (trips, shipments)
```

**Why?** A single person can:
- Be a driver for one fleet owner
- Own their own truck (fleet owner)
- Send goods occasionally (sender role)

This design allows role flexibility without data duplication.

### 2. **Event Sourcing for State Changes**

**Critical Decision:** The `trips` table has a `current_status` field (denormalized) BUT all status changes are recorded in `trip_status_events` (immutable).

**Benefits:**
- Complete audit trail (who changed what, when, why)
- Replay capability (reconstruct trip history)
- Dispute resolution (prove delivery time)
- Analytics (average time per status)

**Trade-off:** Slight write overhead, massive read/audit benefits.

### 3. **Offline-First Design**

**Features:**
- UUIDs instead of auto-increment IDs (no central ID generator needed)
- `synced_at` timestamps on critical tables
- `version` fields for optimistic locking
- `device_id` to track which device created events

**Flow:**
```
Driver App (Offline) → Creates trip_status_event with local UUID
                     → Stores in local SQLite
                     → When online, syncs to server
                     → Server validates and commits
```

### 4. **Temporal Data Modeling**

Many relationships have time dimensions:
- `driver_assignments` (driver changes employers)
- `vehicle_assignments` (driver switches trucks)
- `user_roles` (user gains/loses roles)

**Pattern:**
```sql
valid_from TIMESTAMP
valid_until TIMESTAMP
is_current BOOLEAN
```

This allows historical queries: "Who was driving this truck on Jan 15, 2024?"

---

## Architecture Decisions

### Why Shipments ≠ Trips?

**Shipment:** Commercial intent (business contract)
- Created by sender
- Defines what, where, when
- Pricing agreement
- Can exist without assignment

**Trip:** Physical execution (operations)
- Requires vehicle + driver assignment
- Tracks real-time status
- Has GPS data
- Proof of delivery

**Why Separate?**
1. Shipment can be created days before trip starts
2. One shipment could theoretically need multiple trips (if cargo doesn't fit)
3. Trip can be reassigned to different driver/vehicle
4. Clear separation of sales vs operations

### Why Event Sourcing for Trips?

**Scenario:** Dispute over delivery time

**Without Events:**
```
trips.delivered_at = "2024-01-15 14:30"
```
Someone updates it to 14:00. No proof of original time.

**With Events:**
```sql
trip_status_events:
id    | trip_id | status    | occurred_at         | triggered_by
------|---------|-----------|---------------------|-------------
uuid1 | trip123 | delivered | 2024-01-15 14:30:00 | driver_id
```
**Immutable.** Any dispute? Check the events table.

### Normalized Addresses

Instead of storing addresses inline in `shipments`:

```sql
shipments.pickup_address_id → addresses.id
shipments.drop_address_id → addresses.id
```

**Benefits:**
- Geocoding once (save API costs)
- Reuse for repeat customers
- Consistent address formatting
- User can save "favorites"

### JSONB for Flexibility

Used sparingly for truly flexible data:
- `unions.operating_regions` - varies by union
- `trip_status_events.event_data` - different events need different metadata
- `system_configs.config_value` - dynamic business rules

**Anti-pattern:** Using JSONB for structured data (use proper columns).

---

## Entity Relationship Overview

### Core Identity Chain
```
users (1) ←→ (N) user_roles (N) ←→ (1) roles
  ↓
drivers / fleet_owners / organization_users
```

### Organizational Hierarchy
```
unions (1) ←→ (N) union_fleet_owners (N) ←→ (1) fleet_owners
                                                    ↓
                                              vehicles (N)
                                                    ↓
                                            vehicle_assignments
                                                    ↓
                                              drivers (N)
```

### Business Flow
```
organizations (sender) → shipments ← organizations (receiver)
                            ↓
                         trips
                            ↓
        ┌──────────────────┼──────────────────┐
        ↓                  ↓                  ↓
trip_status_events  trip_locations  trip_documents
```

### Support & Audit
```
activity_logs (everything) ← all tables
support_tickets → trips/shipments
notifications → users
```

---

## Core Workflows

### 1. User Onboarding

```sql
-- Step 1: Create user
INSERT INTO users (full_name, phone, email, password_hash, status)
VALUES ('John Doe', '+91-9876543210', 'john@example.com', 'hash', 'pending');

-- Step 2: Assign role
INSERT INTO user_roles (user_id, role_id)
SELECT user_id, (SELECT id FROM roles WHERE name = 'DRIVER')
FROM users WHERE phone = '+91-9876543210';

-- Step 3: Create driver profile
INSERT INTO drivers (user_id, license_number, license_type, license_expiry_date)
VALUES (user_id, 'DL1234567890', 'HMV', '2027-12-31');

-- Step 4: Upload documents
INSERT INTO driver_documents (driver_id, document_type, document_url)
VALUES (driver_id, 'license', 's3://bucket/license.pdf');

-- Step 5: Admin verifies
UPDATE users SET kyc_status = 'verified', status = 'active'
WHERE id = user_id;
```

### 2. Shipment Creation → Trip Assignment

```sql
-- Sender creates shipment
INSERT INTO shipments (
    shipment_number,
    sender_organization_id,
    receiver_organization_id,
    pickup_address_id,
    drop_address_id,
    cargo_description,
    cargo_weight_kg,
    status
) VALUES (
    generate_sequential_number('SHP', 'shipments', 'shipment_number'),
    sender_org_id,
    receiver_org_id,
    pickup_addr_id,
    drop_addr_id,
    'Electronics - 100 boxes',
    500.00,
    'approved'
);

-- Fleet manager assigns trip
INSERT INTO trips (
    trip_number,
    shipment_id,
    vehicle_id,
    driver_id,
    assigned_fleet_owner_id,
    assigned_by,
    current_status
) VALUES (
    generate_sequential_number('TRP', 'trips', 'trip_number'),
    shipment_id,
    vehicle_id,
    driver_id,
    fleet_owner_id,
    manager_user_id,
    'assigned'
);

-- Record event
INSERT INTO trip_status_events (trip_id, status, triggered_by_user_id)
VALUES (trip_id, 'assigned', manager_user_id);

-- Notify driver
INSERT INTO notifications (user_id, notification_type, title, message)
VALUES (
    driver_user_id,
    'trip_assigned',
    'New Trip Assigned',
    'You have been assigned trip TRP-2024-001234'
);
```

### 3. Trip Execution (Driver App)

```sql
-- Driver starts trip
UPDATE trips SET 
    current_status = 'started',
    actual_start_time = CURRENT_TIMESTAMP
WHERE id = trip_id;

INSERT INTO trip_status_events (trip_id, status, latitude, longitude)
VALUES (trip_id, 'started', 28.7041, 77.1025); -- Delhi coordinates

-- Driver sends location pings (every 30 seconds)
INSERT INTO trip_locations (trip_id, latitude, longitude, source, recorded_at)
VALUES (trip_id, 28.7041, 77.1025, 'driver_app', CURRENT_TIMESTAMP);

-- Update denormalized location in trips table
UPDATE trips SET
    current_latitude = 28.7041,
    current_longitude = 77.1025,
    last_location_update_at = CURRENT_TIMESTAMP
WHERE id = trip_id;

-- Driver reaches pickup
INSERT INTO trip_status_events (trip_id, status, latitude, longitude)
VALUES (trip_id, 'reached_pickup', 28.7041, 77.1025);

-- Driver uploads e-way bill
INSERT INTO trip_documents (trip_id, document_type, document_url, uploaded_by)
VALUES (trip_id, 'eway_bill', 's3://bucket/eway.pdf', driver_user_id);

-- Mark loaded
INSERT INTO trip_status_events (trip_id, status)
VALUES (trip_id, 'loaded');

-- ... (similar for in_transit, reached_drop, delivered)

-- Mark completed with POD
UPDATE trips SET 
    current_status = 'completed',
    delivered_at = CURRENT_TIMESTAMP,
    proof_of_delivery_url = 's3://bucket/pod.jpg',
    completed_at = CURRENT_TIMESTAMP
WHERE id = trip_id;

INSERT INTO trip_status_events (trip_id, status)
VALUES (trip_id, 'completed');

-- Update driver stats
UPDATE drivers SET
    total_trips_completed = total_trips_completed + 1,
    total_distance_km = total_distance_km + (SELECT actual_distance_km FROM trips WHERE id = trip_id),
    availability_status = 'available'
WHERE id = driver_id;
```

### 4. Dispute Resolution

```sql
-- Create support ticket
INSERT INTO support_tickets (
    ticket_number,
    reported_by_user_id,
    category,
    priority,
    subject,
    description,
    related_trip_id,
    status
) VALUES (
    generate_sequential_number('TKT', 'support_tickets', 'ticket_number'),
    receiver_user_id,
    'trip_dispute',
    'high',
    'Delivery time discrepancy',
    'Package shows delivered at 2 PM but we received at 4 PM',
    trip_id,
    'open'
);

-- Admin investigates - checks event log
SELECT 
    status,
    occurred_at,
    latitude,
    longitude,
    triggered_by_user_id
FROM trip_status_events
WHERE trip_id = trip_id
ORDER BY occurred_at;

-- Response: Event shows delivered at 14:00 (2 PM)
-- Location matches receiver address
-- Triggered by driver's device
-- Case closed with proof
```

---

## Security & Access Control

### Row-Level Security (RLS) Implementation

**PostgreSQL RLS Example:**

```sql
-- Enable RLS on trips table
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Policy: Drivers can only see their own trips
CREATE POLICY driver_trips_policy ON trips
FOR SELECT
TO app_user
USING (
    driver_id IN (
        SELECT id FROM drivers WHERE user_id = current_setting('app.user_id')::UUID
    )
);

-- Policy: Fleet owners see trips for their vehicles
CREATE POLICY fleet_owner_trips_policy ON trips
FOR SELECT
TO app_user
USING (
    assigned_fleet_owner_id IN (
        SELECT id FROM fleet_owners WHERE user_id = current_setting('app.user_id')::UUID
    )
);

-- Policy: Admins see all
CREATE POLICY admin_trips_policy ON trips
FOR ALL
TO app_user
USING (
    EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON ur.role_id = r.id
        WHERE ur.user_id = current_setting('app.user_id')::UUID
        AND r.name IN ('ADMIN', 'SUPER_ADMIN')
        AND ur.is_active = TRUE
    )
);
```

### Permission Check Function

```sql
CREATE OR REPLACE FUNCTION has_permission(
    p_user_id UUID,
    p_permission_name TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = p_user_id
        AND p.name = p_permission_name
        AND ur.is_active = TRUE
        AND (ur.valid_until IS NULL OR ur.valid_until > CURRENT_TIMESTAMP)
    );
END;
$$ LANGUAGE plpgsql;

-- Usage in application
SELECT * FROM trips
WHERE has_permission('user-uuid', 'trips.read');
```

### Sensitive Data Encryption

**Application-level encryption for:**
- Bank account numbers
- Government IDs (Aadhaar, PAN)
- Phone numbers (in some jurisdictions)

**Implementation:**
```python
# Backend (Python/Django example)
from cryptography.fernet import Fernet

class EncryptedField:
    def encrypt(self, value):
        f = Fernet(settings.ENCRYPTION_KEY)
        return f.encrypt(value.encode()).decode()
    
    def decrypt(self, encrypted_value):
        f = Fernet(settings.ENCRYPTION_KEY)
        return f.decrypt(encrypted_value.encode()).decode()
```

---

## Offline Sync Strategy

### Conflict Resolution

**Scenario:** Driver goes offline, marks trip as "delivered". Another admin cancels it online.

**Strategy: Last-Write-Wins with Version Numbers**

```sql
-- Optimistic locking
UPDATE trips
SET 
    current_status = 'delivered',
    version = version + 1
WHERE id = trip_id
AND version = expected_version; -- Fails if version mismatch

-- Check rows affected
IF ROW_COUNT = 0 THEN
    -- Conflict detected
    -- Fetch latest version
    -- Merge or prompt user
END IF;
```

### Sync Queue Design

**Mobile App (SQLite):**
```sql
CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    entity_type TEXT, -- 'trip_status_event', 'trip_location'
    entity_id TEXT,
    operation TEXT, -- 'INSERT', 'UPDATE'
    payload TEXT, -- JSON
    created_at INTEGER,
    synced INTEGER DEFAULT 0
);
```

**Sync Process:**
```python
# Mobile app (pseudo-code)
def sync_to_server():
    pending = db.execute("SELECT * FROM sync_queue WHERE synced = 0 ORDER BY created_at")
    
    for item in pending:
        try:
            response = api.post(f"/sync/{item.entity_type}", json=item.payload)
            if response.success:
                db.execute("UPDATE sync_queue SET synced = 1 WHERE id = ?", item.id)
        except NetworkError:
            break # Retry later

def sync_from_server():
    last_sync = get_last_sync_timestamp()
    updates = api.get(f"/sync/pull?since={last_sync}")
    
    for update in updates:
        # Apply updates to local SQLite
        merge_entity(update)
```

---

## Scaling Considerations

### 1. **Database Partitioning**

**Hot Tables:**
- `trip_locations` (millions of rows per month)
- `trip_status_events` (hundreds of thousands per month)
- `activity_logs` (continuous growth)

**Strategy: Range Partitioning by Date**

```sql
-- Partition trip_locations by month
CREATE TABLE trip_locations_2024_01 PARTITION OF trip_locations
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE trip_locations_2024_02 PARTITION OF trip_locations
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Auto-create monthly partitions via cron job
```

### 2. **Read Replicas**

```
Primary DB (writes) → trip creation, status updates
    ↓ Replication
Replica 1 (reads) → driver app location queries
Replica 2 (reads) → analytics dashboards
Replica 3 (reads) → customer tracking pages
```

### 3. **Caching Strategy**

**Redis Cache:**
- Active trip locations (TTL: 1 minute)
- Driver availability status (TTL: 5 minutes)
- User permissions (TTL: 15 minutes)

```python
# Cache active trip locations
redis.setex(
    f"trip:{trip_id}:location",
    60, # 1 minute
    json.dumps({"lat": 28.7041, "lng": 77.1025})
)
```

### 4. **Archival Strategy**

**After 2 years:**
- Move `trip_locations` to cold storage (S3 + Parquet)
- Move `activity_logs` to data warehouse
- Keep `trips`, `shipments` in primary DB (indexes only)

```sql
-- Archive old locations to S3
COPY (
    SELECT * FROM trip_locations
    WHERE recorded_at < CURRENT_DATE - INTERVAL '2 years'
) TO PROGRAM 'aws s3 cp - s3://archive/trip_locations/2022.csv';

DELETE FROM trip_locations
WHERE recorded_at < CURRENT_DATE - INTERVAL '2 years';
```

---

## API Integration Guidelines

### RESTful Endpoints Design

```
POST   /api/v1/shipments              # Create shipment
GET    /api/v1/shipments/:id          # Get shipment details
PATCH  /api/v1/shipments/:id          # Update shipment

POST   /api/v1/trips                  # Create trip (assign)
GET    /api/v1/trips/:id              # Get trip details
PATCH  /api/v1/trips/:id/status       # Update trip status

POST   /api/v1/trips/:id/locations    # Add GPS location
GET    /api/v1/trips/:id/locations    # Get trip route

POST   /api/v1/trips/:id/documents    # Upload document
GET    /api/v1/trips/:id/documents    # List documents

POST   /api/v1/support/tickets        # Create ticket
GET    /api/v1/support/tickets/:id    # Get ticket
POST   /api/v1/support/tickets/:id/comments # Add comment
```

### GraphQL Schema (Alternative)

```graphql
type Trip {
    id: ID!
    tripNumber: String!
    shipment: Shipment!
    driver: Driver!
    vehicle: Vehicle!
    currentStatus: TripStatus!
    statusHistory: [TripStatusEvent!]!
    locations: [TripLocation!]!
    documents: [TripDocument!]!
    currentLocation: Location
}

type Query {
    trip(id: ID!): Trip
    trips(
        status: TripStatus
        driverId: ID
        fleetOwnerId: ID
        limit: Int
        offset: Int
    ): [Trip!]!
}

type Mutation {
    updateTripStatus(
        tripId: ID!
        status: TripStatus!
        location: LocationInput
    ): Trip!
    
    addTripLocation(
        tripId: ID!
        latitude: Float!
        longitude: Float!
    ): TripLocation!
}

subscription {
    tripLocationUpdated(tripId: ID!): TripLocation!
    tripStatusChanged(tripId: ID!): TripStatusEvent!
}
```

### Webhook Events

```json
// Trip status changed
{
    "event": "trip.status.updated",
    "timestamp": "2024-01-30T10:30:00Z",
    "data": {
        "trip_id": "uuid",
        "trip_number": "TRP-2024-001234",
        "old_status": "in_transit",
        "new_status": "delivered",
        "driver": {
            "id": "uuid",
            "name": "John Doe"
        }
    }
}
```

---

## Migration & Deployment

### Initial Setup

```bash
# 1. Create database
createdb fleet_management

# 2. Run schema
psql -d fleet_management -f fleet_management_schema.sql

# 3. Create admin user
psql -d fleet_management -c "
    SELECT create_admin_user(
        'Admin User',
        'admin@company.com',
        '+91-1234567890',
        'hashed_password'
    );
"

# 4. Insert sample permissions
psql -d fleet_management -f sample_permissions.sql
```

### Migration Script Template

```sql
-- migrations/002_add_vehicle_color.sql
BEGIN;

-- Add new column
ALTER TABLE vehicles ADD COLUMN color VARCHAR(50);

-- Backfill existing data
UPDATE vehicles SET color = 'Unknown' WHERE color IS NULL;

-- Activity log
INSERT INTO activity_logs (
    action,
    entity_type,
    entity_id,
    description
) VALUES (
    'schema_migration',
    'vehicles',
    '00000000-0000-0000-0000-000000000000',
    'Added color column to vehicles table'
);

COMMIT;
```

### Backup Strategy

```bash
# Daily backup
pg_dump fleet_management | gzip > backup_$(date +%Y%m%d).sql.gz

# Point-in-time recovery (WAL archiving)
archive_command = 'cp %p /backup/wal/%f'

# Restore
gunzip < backup_20240130.sql.gz | psql fleet_management
```

---

## Performance Tuning Checklist

- [ ] All foreign keys have indexes
- [ ] Composite indexes for common WHERE clauses
- [ ] EXPLAIN ANALYZE on slow queries
- [ ] Vacuum and analyze regularly
- [ ] Connection pooling (PgBouncer)
- [ ] Materialized views for analytics
- [ ] Partition hot tables
- [ ] Archive old data
- [ ] Monitor slow query log
- [ ] Index on `deleted_at IS NULL` for soft deletes

---

## Monitoring Queries

```sql
-- Active trips count by status
SELECT current_status, COUNT(*)
FROM trips
WHERE current_status NOT IN ('completed', 'cancelled')
GROUP BY current_status;

-- Drivers on trip vs available
SELECT 
    availability_status,
    COUNT(*)
FROM drivers
WHERE status = 'active'
GROUP BY availability_status;

-- Vehicles needing service soon
SELECT 
    registration_number,
    next_service_due_date,
    DATE_PART('day', next_service_due_date - CURRENT_DATE) AS days_until_service
FROM vehicles
WHERE next_service_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
AND status = 'active';

-- Documents expiring in next 30 days
SELECT 
    d.license_number,
    u.full_name,
    dd.document_type,
    dd.expiry_date
FROM driver_documents dd
JOIN drivers d ON dd.driver_id = d.id
JOIN users u ON d.user_id = u.id
WHERE dd.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
AND dd.verification_status = 'verified'
ORDER BY dd.expiry_date;
```

---

## Conclusion

This database design is:
✅ **Scalable**: Handles millions of trips with partitioning
✅ **Auditable**: Complete event history for compliance
✅ **Flexible**: RBAC + JSONB for future requirements
✅ **Offline-ready**: UUIDs + sync queues
✅ **Maintainable**: Clear separation of concerns
✅ **Performant**: Strategic indexes + caching

**Next Steps:**
1. Set up CI/CD for migrations
2. Implement API layer (REST/GraphQL)
3. Add monitoring (Prometheus + Grafana)
4. Load testing (simulate 10K concurrent users)
5. Security audit (penetration testing)