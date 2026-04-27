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

-- 3. Allow user_id to be NULL — driver-submitted alerts won't have one.
--    The CHECK below requires at least one source (driver or passenger).
ALTER TABLE emergency_alerts
  ALTER COLUMN user_id DROP NOT NULL;

DO $$ BEGIN
  ALTER TABLE emergency_alerts
    ADD CONSTRAINT emergency_alerts_source_check
    CHECK (user_id IS NOT NULL OR driver_id IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 4. Add 'accident' to the emergency_type_enum so the driver app's
--    "Accident" alert type can be saved.
ALTER TYPE emergency_type_enum ADD VALUE IF NOT EXISTS 'accident';
