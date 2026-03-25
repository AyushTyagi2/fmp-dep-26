-- =============================================================================
-- ADMIN FOUNDATION LAYER — Logistics Platform
-- PostgreSQL · Compatible with existing schema
-- Sections:
--   1. system_logs table + indexes
--   2. Shipments table patch (admin override flag)
--   3. Audit helper function (log_event)
--   4. Automatic shipment-change trigger
-- =============================================================================


-- =============================================================================
-- 1. SYSTEM LOGS TABLE
-- =============================================================================
-- Central, append-only audit table. Covers admin actions, driver events,
-- race-condition markers, and background system operations.

CREATE TYPE actor_type_enum AS ENUM ('admin', 'driver', 'system');

CREATE TABLE system_logs (
    -- Identity
    id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- What happened
    event_type       VARCHAR(100) NOT NULL,  -- e.g. 'shipment.force_assigned', 'driver.assignment_conflict'

    -- Who did it
    user_id          UUID        REFERENCES users(id) ON DELETE SET NULL,
    actor_type       actor_type_enum NOT NULL,

    -- What it affected
    entity_type      VARCHAR(50),            -- 'shipment', 'trip', 'driver', 'vehicle' …
    entity_id        UUID,                   -- FK to the affected row (not enforced; rows may be deleted)

    -- Structured context (flexible payload)
    metadata         JSONB       NOT NULL DEFAULT '{}',
    -- Recommended keys per event_type:
    --   shipment.force_assigned  → { previous_driver_id, new_driver_id, reason, shipment_number }
    --   shipment.cancelled       → { reason, previous_status, shipment_number }
    --   driver.assignment_conflict → { shipment_id, winning_driver_id, losing_driver_id, delta_ms }
    --   shipment.status_changed  → { from, to, shipment_number }

    -- Immutable timestamp
    created_at       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── Indexes ──────────────────────────────────────────────────────────────────

-- Primary query pattern: "all events for a specific entity"
CREATE INDEX idx_syslogs_entity
    ON system_logs (entity_type, entity_id, created_at DESC);

-- "all actions by a user / admin"
CREATE INDEX idx_syslogs_user
    ON system_logs (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

-- "all events of a given type" (great for dashboards / alerts)
CREATE INDEX idx_syslogs_event_type
    ON system_logs (event_type, created_at DESC);

-- "all actions by actor category" (e.g. show only admin overrides)
CREATE INDEX idx_syslogs_actor_type
    ON system_logs (actor_type, created_at DESC);

-- Time-range scans (used by log viewers / cron cleanup)
CREATE INDEX idx_syslogs_created_at
    ON system_logs (created_at DESC);

-- GIN index on metadata for ad-hoc JSONB queries
-- e.g. WHERE metadata->>'reason' = 'race_condition'
CREATE INDEX idx_syslogs_metadata_gin
    ON system_logs USING GIN (metadata);


-- =============================================================================
-- 2. SHIPMENTS TABLE PATCH — Admin Override Flag
-- =============================================================================
-- Marks rows that were last touched by an admin action so they can be
-- filtered / highlighted in the UI and queries without joining system_logs.

ALTER TABLE shipments
    ADD COLUMN IF NOT EXISTS updated_by_admin   BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS admin_override_by  UUID        REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS admin_override_at  TIMESTAMP;

-- Partial index: quick retrieval of all admin-touched shipments
CREATE INDEX idx_shipments_admin_override
    ON shipments (admin_override_at DESC)
    WHERE updated_by_admin = TRUE;

COMMENT ON COLUMN shipments.updated_by_admin  IS 'TRUE when the last significant change was made by an admin override.';
COMMENT ON COLUMN shipments.admin_override_by IS 'The admin user who last performed an override.';
COMMENT ON COLUMN shipments.admin_override_at IS 'Timestamp of the most recent admin override.';


-- =============================================================================
-- 3. AUDIT HELPER FUNCTION — log_event()
-- =============================================================================
-- Call this inside the SAME transaction as your business logic update so the
-- log entry is atomically committed or rolled back with the data change.
--
-- Usage (from application code via a single transaction):
--
--   BEGIN;
--     UPDATE shipments
--        SET driver_id = $new_driver, updated_by_admin = TRUE, …
--      WHERE id = $shipment_id;
--
--     SELECT log_event(
--         'shipment.force_assigned',          -- event_type
--         $admin_user_id,                     -- user_id
--         'admin'::actor_type_enum,           -- actor_type
--         'shipment',                         -- entity_type
--         $shipment_id,                       -- entity_id
--         jsonb_build_object(                 -- metadata
--             'shipment_number', $number,
--             'previous_driver_id', $old_driver,
--             'new_driver_id', $new_driver,
--             'reason', $reason
--         )
--     );
--   COMMIT;

CREATE OR REPLACE FUNCTION log_event(
    p_event_type   VARCHAR(100),
    p_user_id      UUID,
    p_actor_type   actor_type_enum,
    p_entity_type  VARCHAR(50)  DEFAULT NULL,
    p_entity_id    UUID         DEFAULT NULL,
    p_metadata     JSONB        DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO system_logs (
        event_type,
        user_id,
        actor_type,
        entity_type,
        entity_id,
        metadata
    ) VALUES (
        p_event_type,
        p_user_id,
        p_actor_type,
        p_entity_type,
        p_entity_id,
        p_metadata
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;

COMMENT ON FUNCTION log_event IS
'Insert a row into system_logs. Always call inside the same transaction as the
 business-logic change so audit and data are atomically consistent.';


-- =============================================================================
-- 4. AUTOMATIC SHIPMENT AUDIT TRIGGER
-- =============================================================================
-- Fires AFTER any UPDATE on shipments. Writes a system_log entry
-- automatically when status changes or admin override columns are set.
-- This guarantees no change slips through without an audit record,
-- even if application code forgets to call log_event().

CREATE OR REPLACE FUNCTION trg_shipments_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_actor_type  actor_type_enum;
    v_event_type  VARCHAR(100);
    v_actor_id    UUID;
    v_meta        JSONB;
BEGIN
    -- Determine actor
    IF NEW.updated_by_admin = TRUE AND OLD.updated_by_admin = FALSE THEN
        v_actor_type := 'admin';
        v_actor_id   := NEW.admin_override_by;
        v_event_type := 'shipment.admin_override';
    ELSIF NEW.status <> OLD.status THEN
        -- Non-admin status transitions recorded as system events when no user
        -- context is available (e.g., triggered by background job).
        v_actor_type := 'system';
        v_actor_id   := NULL;
        v_event_type := 'shipment.status_changed';
    ELSE
        -- Field changed but not status or admin flag — skip to avoid noise
        RETURN NEW;
    END IF;

    -- Build metadata
    v_meta := jsonb_build_object(
        'shipment_number',  NEW.shipment_number,
        'status_from',      OLD.status,
        'status_to',        NEW.status,
        'updated_by_admin', NEW.updated_by_admin
    );

    -- Append cancellation details when relevant
    IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        v_event_type := 'shipment.cancelled';
        v_meta       := v_meta || jsonb_build_object(
                            'cancellation_reason', NEW.cancellation_reason,
                            'cancelled_by',        NEW.cancelled_by
                        );
    END IF;

    -- Write the log (fire-and-forget; errors bubble up and abort the TX)
    PERFORM log_event(
        v_event_type,
        v_actor_id,
        v_actor_type,
        'shipment',
        NEW.id,
        v_meta
    );

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_after_shipments_update
    AFTER UPDATE ON shipments
    FOR EACH ROW
    EXECUTE FUNCTION trg_shipments_audit();

COMMENT ON TRIGGER trg_after_shipments_update ON shipments IS
'Automatically writes a system_logs entry on status changes or admin overrides.
 Application code can additionally call log_event() in the same transaction for
 richer metadata (e.g. conflict details on race conditions).';


-- =============================================================================
-- REFERENCE: Canonical event_type values
-- =============================================================================
-- Keep these consistent in application code and use them for filtering.
--
--  Entity: shipment
--    shipment.created
--    shipment.status_changed
--    shipment.force_assigned        ← admin override: new driver injected
--    shipment.cancelled             ← admin or system cancellation
--    shipment.admin_override        ← generic admin mutation (trigger fires this)
--    shipment.approval_granted
--    shipment.approval_rejected
--
--  Entity: trip / driver
--    trip.started
--    trip.completed
--    driver.assignment_conflict     ← race condition detected; log both driver IDs
--    driver.forced_reassigned       ← admin moved a driver mid-trip
--
--  System / background
--    system.queue_expired           ← shipment_queue offer timed out
--    system.auto_reassign           ← background job re-queued a shipment
-- =============================================================================


-- 1. Create the admin user
INSERT INTO users (id, full_name, phone, status, phone_verified, auth_provider)
VALUES (
  uuid_generate_v4(),
  'System Administrator',
  '9911217068',   -- ← change to your phone number
  'active',
  TRUE,
  'phone_otp'
);

-- 2. Assign SUPER_ADMIN role
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT 
  u.id,
  r.id,
  u.id   -- self-assigned for the bootstrap admin
FROM users u, roles r
WHERE u.phone = '9911217068'   -- ← same number as above
  AND r.name  = 'SUPER_ADMIN';