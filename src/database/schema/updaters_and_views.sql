
-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at column
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_%I_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
        ', t, t);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sequential numbers (shipments, trips, tickets)
CREATE OR REPLACE FUNCTION generate_sequential_number(prefix TEXT, table_name TEXT, column_name TEXT)
RETURNS TEXT AS $$
DECLARE
    next_num INTEGER;
    year_part TEXT;
BEGIN
    year_part := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    EXECUTE format('
        SELECT COALESCE(MAX(CAST(SUBSTRING(%I FROM ''[0-9]+$'') AS INTEGER)), 0) + 1
        FROM %I
        WHERE %I LIKE %L
    ', column_name, table_name, column_name, prefix || '-' || year_part || '-%')
    INTO next_num;
    
    RETURN prefix || '-' || year_part || '-' || LPAD(next_num::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Active trips with full details
CREATE VIEW active_trips_view AS
SELECT 
    t.id,
    t.trip_number,
    t.current_status,
    s.shipment_number,
    d.license_number AS driver_license,
    u.full_name AS driver_name,
    u.phone AS driver_phone,
    v.registration_number AS vehicle_number,
    fo.business_name AS fleet_owner_name,
    t.current_latitude,
    t.current_longitude,
    t.last_location_update_at,
    t.planned_start_time,
    t.planned_end_time,
    t.actual_start_time
FROM trips t
JOIN shipments s ON t.shipment_id = s.id
JOIN drivers d ON t.driver_id = d.id
JOIN users u ON d.user_id = u.id
JOIN vehicles v ON t.vehicle_id = v.id
JOIN fleet_owners fo ON t.assigned_fleet_owner_id = fo.id
WHERE t.current_status NOT IN ('completed', 'cancelled');

-- Driver performance summary
CREATE VIEW driver_performance_view AS
SELECT 
    d.id AS driver_id,
    u.full_name AS driver_name,
    d.license_number,
    d.average_rating,
    d.total_trips_completed,
    d.total_distance_km,
    COUNT(t.id) AS active_trips,
    d.availability_status,
    d.status
FROM drivers d
JOIN users u ON d.user_id = u.id
LEFT JOIN trips t ON d.id = t.driver_id AND t.current_status IN ('assigned', 'started', 'in_transit')
GROUP BY d.id, u.full_name, d.license_number, d.average_rating, d.total_trips_completed, d.total_distance_km, d.availability_status, d.status;

-- Vehicle utilization
CREATE VIEW vehicle_utilization_view AS
SELECT 
    v.id AS vehicle_id,
    v.registration_number,
    v.vehicle_type,
    v.capacity_tons,
    v.status,
    v.availability_status,
    COUNT(t.id) FILTER (WHERE t.current_status NOT IN ('completed', 'cancelled')) AS active_trips,
    COUNT(t.id) FILTER (WHERE t.current_status = 'completed') AS completed_trips,
    SUM(t.actual_distance_km) AS total_km_run,
    v.last_service_date,
    v.next_service_due_date
FROM vehicles v
LEFT JOIN trips t ON v.id = t.vehicle_id
GROUP BY v.id;

-- ============================================================================
-- SAMPLE DATA INSERTION FUNCTIONS
-- ============================================================================

-- Function to create admin user
CREATE OR REPLACE FUNCTION create_admin_user(
    p_name TEXT,
    p_email TEXT,
    p_phone TEXT,
    p_password TEXT
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_admin_role_id UUID;
BEGIN
    -- Create user
    INSERT INTO users (full_name, email, phone, password_hash, status, email_verified, phone_verified, kyc_status)
    VALUES (p_name, p_email, p_phone, p_password, 'active', TRUE, TRUE, 'verified')
    RETURNING id INTO v_user_id;
    
    -- Get admin role
    SELECT id INTO v_admin_role_id FROM roles WHERE name = 'SUPER_ADMIN';
    
    -- Assign role
    INSERT INTO user_roles (user_id, role_id, is_active)
    VALUES (v_user_id, v_admin_role_id, TRUE);
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE & MAINTENANCE
-- ============================================================================

-- Partitioning strategy for high-volume tables (future optimization)
-- Consider partitioning: trip_locations, trip_status_events, activity_logs by date

-- Materialized views for analytics (refresh periodically)
CREATE MATERIALIZED VIEW trip_analytics_daily AS
SELECT 
    DATE(t.actual_start_time) AS trip_date,
    COUNT(*) AS total_trips,
    COUNT(*) FILTER (WHERE t.current_status = 'completed') AS completed_trips,
    COUNT(*) FILTER (WHERE t.current_status = 'cancelled') AS cancelled_trips,
    AVG(t.actual_distance_km) AS avg_distance_km,
    SUM(t.actual_distance_km) AS total_distance_km,
    AVG(EXTRACT(EPOCH FROM (t.actual_end_time - t.actual_start_time))/3600) AS avg_duration_hours
FROM trips t
WHERE t.actual_start_time IS NOT NULL
GROUP BY DATE(t.actual_start_time);

CREATE UNIQUE INDEX idx_trip_analytics_daily_date ON trip_analytics_daily(trip_date);

-- Archive old data (recommended after 2-3 years)
-- Create archive tables and migration scripts for: activity_logs, trip_locations, notifications

COMMENT ON DATABASE fmp IS 'Production database for Fleet Management Platform';