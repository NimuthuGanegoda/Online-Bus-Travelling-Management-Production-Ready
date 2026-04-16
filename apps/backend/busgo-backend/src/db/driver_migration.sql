-- ═══════════════════════════════════════════════════════════════
--  Driver app migration — run once in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. Add password_hash column to drivers table
--    (drivers registered via the app will have a hashed password;
--     admin-created drivers use their driver_code as default password)
ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 2. Add driver_id to emergency_alerts so driver-submitted alerts
--    can be linked back to the driver (not just the bus)
ALTER TABLE emergency_alerts
  ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL;
