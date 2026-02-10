CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic Profile
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    
    -- Authentication
    password_hash VARCHAR(255),
    auth_provider VARCHAR(50), -- 'local', 'google', 'phone_otp'
    auth_provider_id VARCHAR(255),
    
    -- Status & Verification
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, active, suspended, inactive
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    kyc_status VARCHAR(20) DEFAULT 'not_started', -- not_started, pending, verified, rejected
    kyc_verified_at TIMESTAMP,
    kyc_verified_by UUID REFERENCES users(id),
    
    -- Profile
    profile_image_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(20),
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'India',
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    deleted_at TIMESTAMP, -- Soft delete
    
    -- Sync & Offline Support
    synced_at TIMESTAMP,
    version INTEGER DEFAULT 1, -- Optimistic locking for offline sync
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'active', 'suspended', 'inactive')),
    CONSTRAINT valid_kyc_status CHECK (kyc_status IN ('not_started', 'pending', 'verified', 'rejected'))
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
