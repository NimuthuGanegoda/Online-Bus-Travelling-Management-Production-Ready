-- ============================================================
--  BusGo Admin Seed Data
--  Run AFTER admin_schema.sql
--
--  Default admin login:
--    Email    : admin@busgo.lk
--    Password : Admin@2026
--  (bcrypt hash of 'Admin@2026', rounds=12)
-- ============================================================

-- ── Admins ───────────────────────────────────────────────────
INSERT INTO admins (id, full_name, email, phone, password_hash, role, status)
VALUES
  (
    'a0000000-0000-0000-0000-000000000001',
    'Admin Master',
    'admin@busgo.lk',
    '+94770000001',
    '$2b$12$LQv3c1yqBWVHxkd0LQ1Src.4kBnRUdGGmCl5Z6GjvH0yW6YqBJpJy',
    'super_admin',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'Kasun Rajapaksha',
    'kasun@busgo.lk',
    '+94710000002',
    '$2b$12$LQv3c1yqBWVHxkd0LQ1Src.4kBnRUdGGmCl5Z6GjvH0yW6YqBJpJy',
    'admin',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    'Dilani Wickramasinghe',
    'dilani@busgo.lk',
    '+94760000003',
    '$2b$12$LQv3c1yqBWVHxkd0LQ1Src.4kBnRUdGGmCl5Z6GjvH0yW6YqBJpJy',
    'moderator',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000004',
    'Pradeep Gunasekara',
    'pradeep@busgo.lk',
    '+94750000004',
    '$2b$12$LQv3c1yqBWVHxkd0LQ1Src.4kBnRUdGGmCl5Z6GjvH0yW6YqBJpJy',
    'admin',
    'inactive'
  )
ON CONFLICT (email) DO NOTHING;

-- ── Drivers ──────────────────────────────────────────────────
-- Get route IDs from bus_routes to link drivers
-- Route 138: Nugegoda–Colombo, Route 163: Rajagiriya–Maharagama, Route 171: Kaduwela–Pettah

INSERT INTO drivers (id, driver_code, full_name, email, phone, rating, status, pending_review)
VALUES
  (
    'd0000000-0000-0000-0000-000000000001',
    'DRV-001',
    'Kamal Perera',
    'kamal@busgo.lk',
    '+94771234567',
    8.4,
    'active',
    FALSE
  ),
  (
    'd0000000-0000-0000-0000-000000000002',
    'DRV-002',
    'Saman Dias',
    'saman@busgo.lk',
    '+94719876543',
    7.9,
    'active',
    FALSE
  ),
  (
    'd0000000-0000-0000-0000-000000000003',
    'DRV-003',
    'Nimal Silva',
    'nimal@busgo.lk',
    '+94765551234',
    9.1,
    'inactive',
    FALSE
  ),
  (
    'd0000000-0000-0000-0000-000000000004',
    'DRV-004',
    'Ruwan Fernando',
    'ruwan@busgo.lk',
    '+94703219876',
    0.0,
    'pending',
    TRUE
  ),
  (
    'd0000000-0000-0000-0000-000000000005',
    'DRV-005',
    'Amara Wijesinghe',
    'amara@busgo.lk',
    '+94754447890',
    8.8,
    'active',
    FALSE
  )
ON CONFLICT (email) DO NOTHING;

-- Link drivers to routes (using the route_number to look up id)
UPDATE drivers SET route_id = (SELECT id FROM bus_routes WHERE route_number = '138' LIMIT 1)
  WHERE driver_code = 'DRV-001';
UPDATE drivers SET route_id = (SELECT id FROM bus_routes WHERE route_number = '163' LIMIT 1)
  WHERE driver_code = 'DRV-002';
UPDATE drivers SET route_id = (SELECT id FROM bus_routes WHERE route_number = '171' LIMIT 1)
  WHERE driver_code = 'DRV-003';
-- DRV-004 is pending — no route assigned
UPDATE drivers SET route_id = (SELECT id FROM bus_routes WHERE route_number = '138' LIMIT 1)
  WHERE driver_code = 'DRV-005';

-- ── Update buses with registration + driver_id ───────────────
-- Update existing seed buses with registration plates and driver links
UPDATE buses SET
  registration = 'WP-CAR-1234',
  driver_id    = (SELECT id FROM drivers WHERE driver_code = 'DRV-001')
WHERE bus_number = 'BUS-138-A';

UPDATE buses SET
  registration = 'WP-BA-5678',
  driver_id    = (SELECT id FROM drivers WHERE driver_code = 'DRV-002')
WHERE bus_number = 'BUS-163-A';

-- ── Admin Notifications (seed — sent to super_admin) ────────
INSERT INTO admin_notifications (admin_id, type, title, message, is_read)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'emergency', 'Medical Emergency',
   'Medical emergency reported on Bus #138-A near Nugegoda', FALSE),
  ('a0000000-0000-0000-0000-000000000001', 'emergency', 'Road Accident',
   'Accident reported at Kaduwela Junction', FALSE),
  ('a0000000-0000-0000-0000-000000000001', 'driver', 'New Driver Application',
   'Ruwan Fernando submitted a new driver application', FALSE),
  ('a0000000-0000-0000-0000-000000000001', 'system', 'System Ready',
   'BusGo AXIS admin panel is fully operational', TRUE),
  ('a0000000-0000-0000-0000-000000000001', 'passenger', 'Passenger Report',
   'Passenger flagged for policy violation', TRUE)
ON CONFLICT DO NOTHING;

-- ── Audit log — initial admin login ─────────────────────────
INSERT INTO admin_audit_logs
  (admin_id, admin_email, action, entity, entity_id, details, ip_address)
VALUES
  (
    'a0000000-0000-0000-0000-000000000001',
    'admin@busgo.lk',
    'LOGIN',
    'AdminSession',
    'a0000000-0000-0000-0000-000000000001',
    'Initial seed login entry',
    '127.0.0.1'
  );
