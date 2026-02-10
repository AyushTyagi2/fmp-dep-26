CREATE TABLE unions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic Info
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    pan_number VARCHAR(10) UNIQUE,
    gst_number VARCHAR(15) UNIQUE,
    
    -- Contact
    primary_contact_name VARCHAR(255),
    primary_contact_phone VARCHAR(20) NOT NULL,
    primary_contact_email VARCHAR(255),
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'India',
    
    -- Operating Regions (JSONB for flexibility)
    operating_regions JSONB, -- [{state: "Punjab", cities: ["Chandigarh", "Ludhiana"]}]
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- active, suspended, inactive
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    
    -- Metadata
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_union_status CHECK (status IN ('active', 'suspended', 'inactive'))
);

CREATE INDEX idx_unions_status ON unions(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_unions_regions ON unions USING GIN(operating_regions);

-- Fleet owners (individual or company)
CREATE TABLE fleet_owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User reference (owner must be a registered user)
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- Business Info
    business_name VARCHAR(255),
    business_type VARCHAR(50), -- individual, partnership, company
    pan_number VARCHAR(10) UNIQUE,
    gst_number VARCHAR(15),
    
    -- Contact (can differ from user)
    business_contact_phone VARCHAR(20),
    business_contact_email VARCHAR(255),
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'India',
    
    -- Bank Details (for payments)
    bank_account_number VARCHAR(50),
    bank_ifsc_code VARCHAR(11),
    bank_account_holder_name VARCHAR(255),
    bank_name VARCHAR(255),
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_fleet_owner_status CHECK (status IN ('active', 'suspended', 'inactive'))
);

CREATE INDEX idx_fleet_owners_user ON fleet_owners(user_id);
CREATE INDEX idx_fleet_owners_status ON fleet_owners(status) WHERE deleted_at IS NULL;

-- Union-Fleet Owner mapping (many-to-many)
CREATE TABLE union_fleet_owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    union_id UUID NOT NULL REFERENCES unions(id) ON DELETE CASCADE,
    fleet_owner_id UUID NOT NULL REFERENCES fleet_owners(id) ON DELETE CASCADE,
    
    -- Temporal validity
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Terms
    commission_percentage DECIMAL(5,2), -- Union's commission
    payment_terms TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(union_id, fleet_owner_id)
);

CREATE INDEX idx_union_fleet_owners_union ON union_fleet_owners(union_id) WHERE is_active = TRUE;
CREATE INDEX idx_union_fleet_owners_fleet ON union_fleet_owners(fleet_owner_id) WHERE is_active = TRUE;

-- ============================================================================
-- 3. DRIVER MANAGEMENT
-- ============================================================================
