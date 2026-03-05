CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) NOT NULL UNIQUE, -- Human-readable ID: SHP-2024-001234
    
    -- Parties
    sender_organization_id UUID NOT NULL REFERENCES organizations(id),
    receiver_organization_id UUID NOT NULL REFERENCES organizations(id),
    created_by_user_id UUID NOT NULL REFERENCES users(id),
    
    -- Locations
    pickup_address_id UUID NOT NULL REFERENCES addresses(id),
    drop_address_id UUID NOT NULL REFERENCES addresses(id),
    
    -- Cargo Details
    cargo_type VARCHAR(100) NOT NULL, -- general, perishable, hazardous, fragile
    cargo_description TEXT NOT NULL,
    cargo_weight_kg DECIMAL(10,2) NOT NULL,
    cargo_volume_cubic_meters DECIMAL(10,2),
    package_count INTEGER,
    
    -- Special Requirements
    requires_refrigeration BOOLEAN DEFAULT FALSE,
    requires_insurance BOOLEAN DEFAULT FALSE,
    special_handling_instructions TEXT,
    
    -- Scheduling
    preferred_pickup_date DATE,
    preferred_delivery_date DATE,
    is_urgent BOOLEAN DEFAULT FALSE,
    
    -- Pricing Agreement (NOT payment)
    agreed_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'INR',
    price_per_unit VARCHAR(20), -- per_ton, per_km, fixed
    
    -- Additional Charges
    loading_charges DECIMAL(10,2) DEFAULT 0.00,
    unloading_charges DECIMAL(10,2) DEFAULT 0.00,
    other_charges DECIMAL(10,2) DEFAULT 0.00,
    total_estimated_price DECIMAL(10,2),
    
    -- Documents
    invoice_number VARCHAR(100),
    invoice_value DECIMAL(12,2),
    eway_bill_number VARCHAR(50),
    
    -- Status
    status VARCHAR(30) DEFAULT 'draft', -- draft, pending_approval, approved, assigned, in_transit, delivered, cancelled
    
    -- Approval Workflow
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Cancellation
    cancelled_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_shipment_status CHECK (status IN ('draft', 'pending_approval', 'approved', 'assigned', 'in_transit', 'delivered', 'cancelled', 'rejected'))
);

CREATE INDEX idx_shipments_number ON shipments(shipment_number);
CREATE INDEX idx_shipments_sender ON shipments(sender_organization_id);
CREATE INDEX idx_shipments_receiver ON shipments(receiver_organization_id);
CREATE INDEX idx_shipments_status ON shipments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_shipments_dates ON shipments(preferred_pickup_date, preferred_delivery_date);
CREATE INDEX idx_shipments_created_by ON shipments(created_by_user_id);

-- ============================================================================
-- 7. TRIPS (OPERATIONAL CORE)
-- ============================================================================
CREATE TABLE shipment_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    shipment_id UUID NOT NULL REFERENCES shipments(id),

    zone_id UUID,
    required_vehicle_type VARCHAR(50),

    status VARCHAR(30) DEFAULT 'waiting',
    -- waiting, offered, accepted, expired

    current_driver_id UUID,
    offer_expires_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_number VARCHAR(50) NOT NULL UNIQUE, -- Human-readable ID: TRP-2024-001234
    
    -- Shipment Reference
    shipment_id UUID NOT NULL REFERENCES shipments(id),
    
    -- Assignments
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    assigned_union_id UUID REFERENCES unions(id), -- Optional
    assigned_fleet_owner_id UUID NOT NULL REFERENCES fleet_owners(id),
    
    -- Assignment Details
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Planned Schedule
    planned_start_time TIMESTAMP,
    planned_end_time TIMESTAMP,
    estimated_distance_km DECIMAL(10,2),
    estimated_duration_hours DECIMAL(5,2),
    
    -- Actual Execution
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    actual_distance_km DECIMAL(10,2),
    
    -- Current Status (denormalized for quick access)
    current_status VARCHAR(30) DEFAULT 'created', -- created, assigned, started, reached_pickup, loaded, in_transit, reached_drop, unloaded, delivered, completed, cancelled
    
    -- Current Location (denormalized for quick access)
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    last_location_update_at TIMESTAMP,
    
    -- Delivery Confirmation
    delivered_at TIMESTAMP,
    delivered_to_name VARCHAR(255),
    delivered_to_phone VARCHAR(20),
    proof_of_delivery_url TEXT,
    delivery_notes TEXT,
    
    -- Rating & Feedback
    sender_rating INTEGER, -- 1-5
    sender_feedback TEXT,
    receiver_rating INTEGER, -- 1-5
    receiver_feedback TEXT,
    
    -- Financials (trip-specific)
    driver_payment_amount DECIMAL(10,2),
    driver_payment_status VARCHAR(20) DEFAULT 'pending', -- pending, paid, disputed
    driver_paid_at TIMESTAMP,
    
    -- Issues & Delays
    has_issues BOOLEAN DEFAULT FALSE,
    issue_description TEXT,
    delay_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    CONSTRAINT valid_trip_status CHECK (current_status IN ('created', 'assigned', 'started', 'reached_pickup', 'loaded', 'in_transit', 'reached_drop', 'unloaded', 'delivered', 'completed', 'cancelled')),
    CONSTRAINT valid_driver_payment_status CHECK (driver_payment_status IN ('pending', 'paid', 'disputed'))
);

CREATE INDEX idx_trips_number ON trips(trip_number);
CREATE INDEX idx_trips_shipment ON trips(shipment_id);
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(current_status);
CREATE INDEX idx_trips_union ON trips(assigned_union_id) WHERE assigned_union_id IS NOT NULL;
CREATE INDEX idx_trips_fleet_owner ON trips(assigned_fleet_owner_id);
CREATE INDEX idx_trips_dates ON trips(planned_start_time, planned_end_time);

-- Event-sourced trip lifecycle (IMMUTABLE AUDIT TRAIL)
CREATE TABLE trip_status_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    
    -- Event Details
    status VARCHAR(30) NOT NULL,
    previous_status VARCHAR(30),
    
    -- Context
    triggered_by_user_id UUID REFERENCES users(id),
    triggered_by_system BOOLEAN DEFAULT FALSE,
    
    -- Location (snapshot at event time)
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Additional Data (flexible JSON for event-specific details)
    event_data JSONB, -- {delay_reason: "traffic", estimated_delay_minutes: 30}
    
    -- Metadata
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Sync Support
    device_id VARCHAR(100), -- For offline-first: which device created this event
    synced_at TIMESTAMP,
    
    CONSTRAINT valid_trip_event_status CHECK (status IN ('created', 'assigned', 'started', 'reached_pickup', 'loaded', 'in_transit', 'reached_drop', 'unloaded', 'delivered', 'completed', 'cancelled'))
);

CREATE INDEX idx_trip_events_trip ON trip_status_events(trip_id, occurred_at DESC);
CREATE INDEX idx_trip_events_status ON trip_status_events(status, occurred_at DESC);
CREATE INDEX idx_trip_events_user ON trip_status_events(triggered_by_user_id) WHERE triggered_by_user_id IS NOT NULL;

-- Trip location tracking (GPS breadcrumbs)
CREATE TABLE trip_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    
    -- Location
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy_meters DECIMAL(6,2),
    altitude_meters DECIMAL(7,2),
    
    -- Source
    source VARCHAR(20) NOT NULL, -- driver_app, gps_device, manual
    device_id VARCHAR(100),
    
    -- Speed & Direction
    speed_kmph DECIMAL(5,2),
    bearing_degrees DECIMAL(5,2),
    
    -- Timestamp
    recorded_at TIMESTAMP NOT NULL,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP,
    
    CONSTRAINT valid_location_source CHECK (source IN ('driver_app', 'gps_device', 'manual'))
);

-- Partition by trip_id for better performance on large datasets
CREATE INDEX idx_trip_locations_trip_time ON trip_locations(trip_id, recorded_at DESC);
CREATE INDEX idx_trip_locations_geo ON trip_locations(latitude, longitude);

-- Trip documents (e-way bill, POD, invoices, etc.)
CREATE TABLE trip_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    
    -- Document Info
    document_type VARCHAR(50) NOT NULL, -- eway_bill, pod, invoice, weighbridge_slip, lr_copy
    document_url TEXT NOT NULL,
    document_number VARCHAR(100),
    
    -- File Details
    file_name VARCHAR(255),
    file_size_bytes INTEGER,
    mime_type VARCHAR(100),
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    
    -- Metadata
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Sync
    synced_at TIMESTAMP
);

CREATE INDEX idx_trip_documents_trip ON trip_documents(trip_id);
CREATE INDEX idx_trip_documents_type ON trip_documents(document_type);

