CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE, -- Cannot be deleted if true
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT role_name_format CHECK (name ~ '^[A-Z_]+$') -- Enforce UPPER_SNAKE_CASE
);

-- Insert default system roles
INSERT INTO roles (name, display_name, is_system_role) VALUES
('SUPER_ADMIN', 'Super Administrator', TRUE),
('ADMIN', 'Administrator', TRUE),
('UNION_MANAGER', 'Union Manager', TRUE),
('FLEET_OWNER', 'Fleet Owner', TRUE),
('DRIVER', 'Driver', TRUE),
('SENDER', 'Sender', TRUE),
('RECEIVER', 'Receiver', TRUE),
('SUPPORT_AGENT', 'Support Agent', TRUE);

-- User-Role mapping (many-to-many)
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    
    -- Scoping (optional context)
    organization_id UUID, -- Reference to organizations table (created later)
    union_id UUID, -- Reference to unions table (created later)
    fleet_owner_id UUID, -- Reference to fleet_owners table (created later)
    
    -- Temporal validity
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, role_id, organization_id, union_id, fleet_owner_id)
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_user_roles_role ON user_roles(role_id) WHERE is_active = TRUE;
CREATE INDEX idx_user_roles_active ON user_roles(user_id, role_id) WHERE is_active = TRUE;
-- Fine-grained permissions
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    resource VARCHAR(50) NOT NULL, -- e.g., 'trips', 'shipments', 'users'
    action VARCHAR(50) NOT NULL, -- e.g., 'create', 'read', 'update', 'delete'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT permission_name_format CHECK (name ~ '^[a-z_]+\.[a-z_]+$') -- e.g., 'trips.create'
);

-- Role-Permission mapping
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);

