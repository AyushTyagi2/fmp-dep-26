DO $$
DECLARE
    -- Role variables
    v_role_fleet_owner_id UUID;
    v_role_driver_id UUID;

    -- Arrays to hold generated UUIDs for relationships
    v_fm_user_ids UUID[] := '{}';
    v_fm_ids UUID[] := '{}';
    v_driver_user_ids UUID[] := '{}';
    v_driver_ids UUID[] := '{}';
    v_vehicle_ids UUID[] := '{}';

    -- Loop & Temp variables
    i INT;
    v_current_fm_id UUID;
    v_temp_uuid UUID; -- Temporary variable to catch RETURNING values

    -- Generic placeholder data arrays for realism
    v_driver_names TEXT[] := ARRAY['Harpreet Singh', 'Gurdeep Singh', 'Ramesh Yadav', 'Abdul Khan', 'Manoj Tiwari', 'Karan Sharma', 'Deepak Verma', 'Sanjay Gupta', 'Rajinder Pal', 'Sunil Kumar'];
    v_vehicle_regs TEXT[] := ARRAY['PB12-AB-1001', 'CH01-CD-2002', 'PB10-EF-3003', 'DL1M-GH-4004', 'HR38-IJ-5005', 'PB12-KL-6006', 'CH01-MN-7007', 'PB10-OP-8008', 'DL1M-QR-9009', 'HR38-ST-0010'];
    v_vehicle_types TEXT[] := ARRAY['truck', 'truck', 'trailer', 'tanker', 'truck', 'trailer', 'truck', 'tanker', 'truck', 'trailer'];

BEGIN
    -- 1. Fetch System Role IDs
    SELECT id INTO v_role_fleet_owner_id FROM roles WHERE name = 'FLEET_OWNER';
    SELECT id INTO v_role_driver_id FROM roles WHERE name = 'DRIVER';

    -- ==========================================
    -- 2. INSERT FLEET MANAGERS
    -- ==========================================
    
    -- FM 1: Nishant 
    INSERT INTO users (full_name, phone, email, status, kyc_status)
    VALUES ('Nishant', '9876826025', 'nishant@ropar-logistics.com', 'active', 'verified') 
    RETURNING id INTO v_temp_uuid;
    v_fm_user_ids[1] := v_temp_uuid;

    -- FM 2
    INSERT INTO users (full_name, phone, email, status, kyc_status)
    VALUES ('Mansi', '9876543202', 'mansi@chandigarh-freight.com', 'active', 'verified') 
    RETURNING id INTO v_temp_uuid;
    v_fm_user_ids[2] := v_temp_uuid;

    -- FM 3
    INSERT INTO users (full_name, phone, email, status, kyc_status)
    VALUES ('Vikram Singh', '9876543203', 'vikram@punjab-transport.com', 'active', 'verified') 
    RETURNING id INTO v_temp_uuid;
    v_fm_user_ids[3] := v_temp_uuid;

    -- FM 4
    INSERT INTO users (full_name, phone, email, status, kyc_status)
    VALUES ('Amit Patel', '9876543204', 'amit@national-carriers.com', 'active', 'verified') 
    RETURNING id INTO v_temp_uuid;
    v_fm_user_ids[4] := v_temp_uuid;

    -- 3. Assign Roles & Create Fleet Owner Records
    FOR i IN 1..4 LOOP
        -- Link user to FLEET_OWNER role
        INSERT INTO user_roles (user_id, role_id) VALUES (v_fm_user_ids[i], v_role_fleet_owner_id);

        -- Create the actual fleet_owners profile
        INSERT INTO fleet_owners (
            user_id, business_name, business_type, city, state, pan_number, status, verified
        ) VALUES (
            v_fm_user_ids[i],
            CASE i
                WHEN 1 THEN 'Nishant Logistics'
                WHEN 2 THEN 'Mansi Freight Carriers'
                WHEN 3 THEN 'Punjab Highway Transport'
                ELSE 'National Cargo Movers'
            END,
            'company',
            CASE i WHEN 1 THEN 'Ropar' WHEN 2 THEN 'Chandigarh' WHEN 3 THEN 'Ludhiana' ELSE 'Delhi' END,
            CASE i WHEN 1 THEN 'Punjab' WHEN 2 THEN 'Chandigarh' WHEN 3 THEN 'Punjab' ELSE 'Delhi' END,
            'ABCDE' || (1000 + i)::TEXT || 'F', 
            'active', TRUE
        ) RETURNING id INTO v_temp_uuid;
        
        v_fm_ids[i] := v_temp_uuid;
    END LOOP;

    -- ==========================================
    -- 4. INSERT DRIVERS, VEHICLES & ASSIGNMENTS
    -- ==========================================
    
    FOR i IN 1..10 LOOP
        -- Distribute resources across the 4 fleet managers
        v_current_fm_id := v_fm_ids[((i - 1) % 4) + 1];

        -- Create User profile for Driver
        INSERT INTO users (full_name, phone, email, status, kyc_status)
        VALUES (
            v_driver_names[i],
            '99000000' || LPAD(i::TEXT, 2, '0'), 
            'driver' || i::TEXT || '@example.com',
            'active', 'verified'
        ) RETURNING id INTO v_temp_uuid;
        
        v_driver_user_ids[i] := v_temp_uuid;

        -- Assign DRIVER role
        INSERT INTO user_roles (user_id, role_id) VALUES (v_driver_user_ids[i], v_role_driver_id);

        -- Create Driver specific record
        INSERT INTO drivers (
            user_id, license_number, license_type, license_expiry_date,
            current_fleet_owner_id, employment_start_date, status
        ) VALUES (
            v_driver_user_ids[i],
            'DL-PB-' || (20240000 + i)::TEXT,
            'HMV',
            CURRENT_DATE + INTERVAL '5 years',
            v_current_fm_id,
            CURRENT_DATE - INTERVAL '1 year',
            'active'
        ) RETURNING id INTO v_temp_uuid;
        
        v_driver_ids[i] := v_temp_uuid;

        -- Create Driver Assignment History
        INSERT INTO driver_assignments (driver_id, fleet_owner_id, start_date, is_current)
        VALUES (v_driver_ids[i], v_current_fm_id, CURRENT_DATE - INTERVAL '1 year', TRUE);

        -- Create Vehicle Record
        INSERT INTO vehicles (
            fleet_owner_id, registration_number, vehicle_type,
            capacity_tons, status, current_driver_id
        ) VALUES (
            v_current_fm_id,
            v_vehicle_regs[i],
            v_vehicle_types[i],
            CASE WHEN v_vehicle_types[i] = 'truck' THEN 10.0 ELSE 25.0 END,
            'active',
            v_driver_ids[i]
        ) RETURNING id INTO v_temp_uuid;
        
        v_vehicle_ids[i] := v_temp_uuid;

        -- Create Vehicle Assignment History
        INSERT INTO vehicle_assignments (vehicle_id, driver_id, is_current)
        VALUES (v_vehicle_ids[i], v_driver_ids[i], TRUE);

    END LOOP;
    // ...existing code...

-- Ensure auth_provider set for fleet managers inserted above
UPDATE users
SET auth_provider = 'local'
WHERE phone IN (
  '9876826025',
  '9876543202',
  '9876543203',
  '9876543204'
) AND auth_provider IS NULL;

-- Ensure auth_provider set for drivers inserted above
UPDATE users
SET auth_provider = 'phone_otp'
WHERE phone IN (
  '9900000001','9900000002','9900000003','9900000004','9900000005',
  '9900000006','9900000007','9900000008','9900000009','9900000010'
) AND auth_provider IS NULL;

UPDATE users
SET password_hash = 'DUMMY_HASH'
WHERE phone IN (
  '9876826025',
  '9876543202',
  '9876543203',
  '9876543204'
) AND password_hash IS NULL;

-- Set password_hash for drivers if NULL
UPDATE users
SET password_hash = 'DUMMY_HASH'
WHERE phone IN (
  '9900000001','9900000002','9900000003','9900000004','9900000005',
  '9900000006','9900000007','9900000008','9900000009','9900000010'
) AND password_hash IS NULL;
END $$;