CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User reference (driver must be a registered user)
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    
    -- License Info
    license_number VARCHAR(50) NOT NULL UNIQUE,
    license_type VARCHAR(20) NOT NULL, -- LMV, HMV, etc.
    license_issue_date DATE,
    license_expiry_date DATE NOT NULL,
    license_issuing_authority VARCHAR(255),
    
    -- Experience
    years_of_experience INTEGER,
    previous_employers TEXT,
    
    -- Current Assignment
    current_fleet_owner_id UUID REFERENCES fleet_owners(id),
    employment_start_date DATE,
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'available', -- available, on_trip, on_leave, inactive
    preferred_routes JSONB, -- [{from: "Delhi", to: "Mumbai"}]
    
    -- Emergency Contact
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    
    -- Health & Safety
    medical_fitness_valid_until DATE,
    last_safety_training_date DATE,
    
    -- Rating & Performance
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_trips_completed INTEGER DEFAULT 0,
    total_distance_km DECIMAL(10,2) DEFAULT 0.00,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_driver_status CHECK (status IN ('active', 'suspended', 'inactive')),
    CONSTRAINT valid_availability CHECK (availability_status IN ('available', 'on_trip', 'on_leave', 'inactive'))
);

CREATE INDEX idx_drivers_user ON drivers(user_id);
CREATE INDEX idx_drivers_fleet_owner ON drivers(current_fleet_owner_id);
CREATE INDEX idx_drivers_availability ON drivers(availability_status) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_drivers_license_expiry ON drivers(license_expiry_date) WHERE status = 'active';

-- Driver documents (compliance & verification)
CREATE TABLE driver_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    
    -- Document Info
    document_type VARCHAR(50) NOT NULL, -- license, aadhaar, pan, medical_certificate, police_verification
    document_number VARCHAR(100),
    document_url TEXT NOT NULL, -- S3/cloud storage URL
    
    -- Validity
    issue_date DATE,
    expiry_date DATE,
    
    -- Verification
    verification_status VARCHAR(20) DEFAULT 'pending', -- pending, verified, rejected
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    
    -- Metadata
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_doc_verification_status CHECK (verification_status IN ('pending', 'verified', 'rejected'))
);

CREATE INDEX idx_driver_documents_driver ON driver_documents(driver_id);
CREATE INDEX idx_driver_documents_type ON driver_documents(driver_id, document_type);
CREATE INDEX idx_driver_documents_expiry ON driver_documents(expiry_date) WHERE verification_status = 'verified';

-- Driver employment history (track switches between fleet owners)
CREATE TABLE driver_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    fleet_owner_id UUID NOT NULL REFERENCES fleet_owners(id) ON DELETE CASCADE,
    
    -- Assignment Period
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Terms
    salary_type VARCHAR(20), -- fixed, per_trip, per_km
    salary_amount DECIMAL(10,2),
    payment_frequency VARCHAR(20), -- daily, weekly, monthly
    
    -- Exit Info
    termination_reason TEXT,
    terminated_by UUID REFERENCES users(id),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_driver_assignments_driver ON driver_assignments(driver_id);
CREATE INDEX idx_driver_assignments_current ON driver_assignments(driver_id) WHERE is_current = TRUE;
CREATE INDEX idx_driver_assignments_fleet ON driver_assignments(fleet_owner_id);

-- ============================================================================
-- 4. VEHICLE MANAGEMENT
-- ============================================================================

CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Ownership
    fleet_owner_id UUID NOT NULL REFERENCES fleet_owners(id),
    
    -- Vehicle Identity
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    chassis_number VARCHAR(50) UNIQUE,
    engine_number VARCHAR(50),
    
    -- Vehicle Details
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    manufacture_year INTEGER,
    vehicle_type VARCHAR(50) NOT NULL, -- truck, trailer, tanker, etc.
    
    -- Capacity
    capacity_tons DECIMAL(10,2) NOT NULL,
    capacity_cubic_meters DECIMAL(10,2),
    max_load_weight_kg DECIMAL(10,2),
    
    -- Dimensions
    length_meters DECIMAL(5,2),
    width_meters DECIMAL(5,2),
    height_meters DECIMAL(5,2),
    
    -- Fuel
    fuel_type VARCHAR(20), -- diesel, petrol, cng, electric
    average_mileage_kmpl DECIMAL(5,2),
    
    -- Current Status
    status VARCHAR(20) DEFAULT 'active', -- active, maintenance, inactive, sold
    availability_status VARCHAR(20) DEFAULT 'available', -- available, on_trip, maintenance
    current_driver_id UUID REFERENCES drivers(id),
    
    -- Location (last known)
    last_known_latitude DECIMAL(10,8),
    last_known_longitude DECIMAL(11,8),
    last_location_update_at TIMESTAMP,
    
    -- Maintenance
    last_service_date DATE,
    next_service_due_date DATE,
    total_km_run DECIMAL(10,2) DEFAULT 0.00,
    
    -- GPS Device
    gps_device_id VARCHAR(100),
    gps_device_active BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_vehicle_status CHECK (status IN ('active', 'maintenance', 'inactive', 'sold')),
    CONSTRAINT valid_vehicle_availability CHECK (availability_status IN ('available', 'on_trip', 'maintenance'))
);

CREATE INDEX idx_vehicles_fleet_owner ON vehicles(fleet_owner_id);
CREATE INDEX idx_vehicles_registration ON vehicles(registration_number);
CREATE INDEX idx_vehicles_status ON vehicles(status, availability_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_vehicles_driver ON vehicles(current_driver_id) WHERE current_driver_id IS NOT NULL;

-- Vehicle documents (compliance)
CREATE TABLE vehicle_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    
    -- Document Info
    document_type VARCHAR(50) NOT NULL, -- rc, insurance, pollution, permit, fitness
    document_number VARCHAR(100),
    document_url TEXT NOT NULL,
    
    -- Validity
    issue_date DATE,
    expiry_date DATE,
    
    -- Verification
    verification_status VARCHAR(20) DEFAULT 'pending',
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    
    -- Metadata
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_vehicle_doc_status CHECK (verification_status IN ('pending', 'verified', 'rejected'))
);

CREATE INDEX idx_vehicle_documents_vehicle ON vehicle_documents(vehicle_id);
CREATE INDEX idx_vehicle_documents_type ON vehicle_documents(vehicle_id, document_type);
CREATE INDEX idx_vehicle_documents_expiry ON vehicle_documents(expiry_date) WHERE verification_status = 'verified';

-- Vehicle-Driver assignments (temporal tracking)
CREATE TABLE vehicle_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    
    -- Assignment Period
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unassigned_at TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Assignment Context
    assigned_by UUID REFERENCES users(id),
    assignment_type VARCHAR(20), -- permanent, temporary, trip_based
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vehicle_assignments_vehicle ON vehicle_assignments(vehicle_id);
CREATE INDEX idx_vehicle_assignments_driver ON vehicle_assignments(driver_id);
CREATE INDEX idx_vehicle_assignments_current ON vehicle_assignments(vehicle_id) WHERE is_current = TRUE;