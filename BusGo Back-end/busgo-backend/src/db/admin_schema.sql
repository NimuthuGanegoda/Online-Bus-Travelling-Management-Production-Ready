-- ============================================================
--  BusGo Admin Schema Extensions
--  Run AFTER schema.sql in the Supabase SQL Editor
-- ============================================================

-- ── Utility function (idempotent — also defined in schema.sql) ───────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

-- ── Extend existing enums ────────────────────────────────────
-- Adds new bus status values whether or not schema.sql was run first.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bus_status_enum') THEN
    -- Type already exists (schema.sql was run) — just add missing values
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum
      WHERE enumtypid = 'bus_status_enum'::regtype AND enumlabel = 'standby'
    ) THEN ALTER TYPE bus_status_enum ADD VALUE 'standby'; END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_enum
      WHERE enumtypid = 'bus_status_enum'::regtype AND enumlabel = 'in_repair'
    ) THEN ALTER TYPE bus_status_enum ADD VALUE 'in_repair'; END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_enum
      WHERE enumtypid = 'bus_status_enum'::regtype AND enumlabel = 'recalled'
    ) THEN ALTER TYPE bus_status_enum ADD VALUE 'recalled'; END IF;
  ELSE
    -- schema.sql not run yet — create the full type now
    CREATE TYPE bus_status_enum AS ENUM (
      'active', 'inactive', 'breakdown', 'standby', 'in_repair', 'recalled'
    );
  END IF;
END $$;

-- ── Extend existing tables (only if schema.sql tables exist) ─
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'buses') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'buses' AND column_name = 'registration') THEN
      ALTER TABLE buses ADD COLUMN registration VARCHAR(20);
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emergency_alerts') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'emergency_alerts' AND column_name = 'priority') THEN
      ALTER TABLE emergency_alerts ADD COLUMN priority VARCHAR(2) DEFAULT 'P3' CHECK (priority IN ('P1','P2','P3'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'emergency_alerts' AND column_name = 'police_notified') THEN
      ALTER TABLE emergency_alerts ADD COLUMN police_notified BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'nic') THEN
      ALTER TABLE users ADD COLUMN nic VARCHAR(12);
    END IF;
  END IF;
END $$;

-- ── New enums ────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE driver_status AS ENUM ('active', 'inactive', 'pending');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE admin_role AS ENUM ('super_admin', 'admin', 'moderator');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE admin_status AS ENUM ('active', 'inactive');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE audit_action AS ENUM (
    'LOGIN', 'LOGOUT', 'CREATE', 'UPDATE', 'DELETE',
    'RESOLVE', 'DEPLOY', 'APPROVE', 'REJECT', 'SUSPEND'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE admin_notif_type AS ENUM ('emergency', 'system', 'driver', 'passenger');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── drivers ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drivers (
  id             UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_code    VARCHAR(20)   UNIQUE,
  full_name      VARCHAR(100)  NOT NULL,
  email          VARCHAR(255)  UNIQUE NOT NULL,
  phone          VARCHAR(20),
  rating         DECIMAL(3,1)  DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 10),
  route_id       UUID,         -- FK to bus_routes added below if that table exists
  status         driver_status NOT NULL DEFAULT 'pending',
  pending_review BOOLEAN       DEFAULT TRUE,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Add FK to bus_routes only if that table already exists (schema.sql was run first)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bus_routes')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'drivers' AND constraint_name = 'drivers_route_id_fkey'
  ) THEN
    ALTER TABLE drivers
      ADD CONSTRAINT drivers_route_id_fkey
      FOREIGN KEY (route_id) REFERENCES bus_routes(id) ON DELETE SET NULL;
  END IF;
END $$;

-- buses: add FK to drivers (nullable — some buses may not have a registered driver)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'buses')
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'buses' AND column_name = 'driver_id'
  ) THEN
    ALTER TABLE buses ADD COLUMN driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ── admins ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admins (
  id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  phone         VARCHAR(20),
  password_hash VARCHAR(255) NOT NULL,
  role          admin_role   NOT NULL DEFAULT 'admin',
  status        admin_status NOT NULL DEFAULT 'active',
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── admin_refresh_tokens ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_refresh_tokens (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id   UUID        NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── admin_audit_logs ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id    UUID         REFERENCES admins(id) ON DELETE SET NULL,
  admin_email VARCHAR(255),
  action      audit_action NOT NULL,
  entity      VARCHAR(50)  NOT NULL,
  entity_id   VARCHAR(100),
  details     TEXT,
  ip_address  VARCHAR(45),
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── admin_notifications ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_notifications (
  id         UUID             PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id   UUID             REFERENCES admins(id) ON DELETE CASCADE,
  type       admin_notif_type NOT NULL DEFAULT 'system',
  title      VARCHAR(255)     NOT NULL,
  message    TEXT,
  is_read    BOOLEAN          NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

-- ── Triggers ─────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER set_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE TRIGGER set_admins_updated_at
  BEFORE UPDATE ON admins
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_drivers_status     ON drivers (status);
CREATE INDEX IF NOT EXISTS idx_drivers_route_id   ON drivers (route_id);
CREATE INDEX IF NOT EXISTS idx_drivers_email      ON drivers (email);

CREATE INDEX IF NOT EXISTS idx_admins_email       ON admins (email);
CREATE INDEX IF NOT EXISTS idx_admins_status      ON admins (status);

CREATE INDEX IF NOT EXISTS idx_admin_rt_admin_id  ON admin_refresh_tokens (admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_rt_hash      ON admin_refresh_tokens (token_hash);

CREATE INDEX IF NOT EXISTS idx_audit_admin_id     ON admin_audit_logs (admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_action       ON admin_audit_logs (action);
CREATE INDEX IF NOT EXISTS idx_audit_entity       ON admin_audit_logs (entity);
CREATE INDEX IF NOT EXISTS idx_audit_created_at   ON admin_audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_notif_admin_id ON admin_notifications (admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_notif_read    ON admin_notifications (is_read);
CREATE INDEX IF NOT EXISTS idx_admin_notif_type    ON admin_notifications (type);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'emergency_alerts')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'emergency_alerts' AND column_name = 'priority') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_emergency_priority') THEN
      CREATE INDEX idx_emergency_priority ON emergency_alerts (priority);
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'buses') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_buses_driver_id') THEN
      CREATE INDEX idx_buses_driver_id ON buses (driver_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_buses_registration') THEN
      CREATE INDEX idx_buses_registration ON buses (registration);
    END IF;
  END IF;
END $$;

-- ── RLS ──────────────────────────────────────────────────────
ALTER TABLE drivers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins               ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications  ENABLE ROW LEVEL SECURITY;

-- Service-role key bypasses RLS on all tables.
-- Client-side anon key is never used for admin operations.
