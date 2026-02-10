CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic Info
    name VARCHAR(255) NOT NULL,
    organization_type VARCHAR(50) NOT NULL, -- company, individual, partnership
    
    -- Registration
    registration_number VARCHAR(100) UNIQUE,
    pan_number VARCHAR(10) UNIQUE,
    gst_number VARCHAR(15),
    
    -- Contact
    primary_contact_name VARCHAR(255),
    primary_contact_phone VARCHAR(20) NOT NULL,
    primary_contact_email VARCHAR(255),
    website VARCHAR(255),
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'India',
    
    -- Business Details
    industry VARCHAR(100),
    description TEXT,
    
    -- Billing
    billing_address_same_as_primary BOOLEAN DEFAULT TRUE,
    billing_address_line1 TEXT,
    billing_address_line2 TEXT,
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_postal_code VARCHAR(20),
    
    -- Credit Terms
    credit_limit DECIMAL(12,2),
    credit_days INTEGER,
    payment_terms TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active',
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    
    -- Metadata
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT valid_org_status CHECK (status IN ('active', 'suspended', 'inactive'))
);

CREATE INDEX idx_organizations_status ON organizations(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_gst ON organizations(gst_number) WHERE gst_number IS NOT NULL;

-- Organization-User mapping (many-to-many)
CREATE TABLE organization_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Role within organization
    organization_role VARCHAR(50), -- admin, manager, staff, accountant
    
    -- Permissions within org context
    can_create_shipments BOOLEAN DEFAULT FALSE,
    can_approve_shipments BOOLEAN DEFAULT FALSE,
    can_view_financials BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(organization_id, user_id)
);

CREATE INDEX idx_org_users_org ON organization_users(organization_id) WHERE is_active = TRUE;
CREATE INDEX idx_org_users_user ON organization_users(user_id) WHERE is_active = TRUE;

-- Normalized addresses (reusable for multiple shipments)
CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Owner (can be user or organization)
    owner_type VARCHAR(20) NOT NULL, -- user, organization
    owner_id UUID NOT NULL,
    
    -- Address Details
    label VARCHAR(100), -- "Home", "Office", "Warehouse A"
    contact_person_name VARCHAR(255),
    contact_phone VARCHAR(20),
    
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    landmark TEXT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    
    -- Geocoding
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Operational Details
    access_instructions TEXT,
    operating_hours VARCHAR(255),
    
    -- Status
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_owner_type CHECK (owner_type IN ('user', 'organization'))
);

CREATE INDEX idx_addresses_owner ON addresses(owner_type, owner_id) WHERE is_active = TRUE;
CREATE INDEX idx_addresses_location ON addresses(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
