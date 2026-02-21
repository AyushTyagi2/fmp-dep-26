 --50d2194e-a86b-4aba-919a-e01fba1c0c39 | 7351053399
 --b148bc03-fbc8-4127-8de9-e6c2dbcc46f8 | 8191096907

 INSERT INTO addresses (
    owner_type,
    owner_id,
    label,
    contact_person_name,
    contact_phone,
    address_line1,
    address_line2,
    landmark,
    city,
    state,
    postal_code,
    country,
    latitude,
    longitude,
    is_default,
    is_active
)
VALUES
(
    'organization',
    'b148bc03-fbc8-4127-8de9-e6c2dbcc46f8',  -- Org for 8191096907
    'Primary Warehouse',
    'Sender Contact',
    '8191096907',
    'Plot 12, Industrial Area Phase 1',
    NULL,
    'Near Metro Pillar 45',
    'Noida',
    'Uttar Pradesh',
    '201301',
    'India',
    28.5355,
    77.3910,
    TRUE,
    TRUE
),
(
    'organization',
    '50d2194e-a86b-4aba-919a-e01fba1c0c39',  -- Org for 7351053399
    'Delivery Office',
    'Receiver Contact',
    '7351053399',
    'Sector 62, Tower B',
    '5th Floor',
    'Opposite IT Park',
    'Noida',
    'Uttar Pradesh',
    '201309',
    'India',
    28.6139,
    77.2090,
    TRUE,
    TRUE
);