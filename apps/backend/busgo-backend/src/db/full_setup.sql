/*
  BusGo Full Setup SQL
  Generated automatically by combining base schema + admin schema + base seed + admin seed.
  Run this whole file in Supabase SQL Editor.
*/



-- ============================================================
-- BEGIN FILE: schema.sql
-- ============================================================

-- ============================================================
--  BusGo — PostgreSQL Schema (Supabase)
--  Run this in Supabase SQL Editor → New Query
-- ============================================================

-- ── Extensions ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Custom ENUM types ─────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE membership_type_enum  AS ENUM ('standard', 'premium', 'student');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE crowd_level_enum  AS ENUM ('low', 'medium', 'high', 'full');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE bus_status_enum  AS ENUM ('active', 'inactive', 'breakdown');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE trip_status_enum  AS ENUM ('ongoing', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE emergency_type_enum  AS ENUM ('medical', 'criminal', 'breakdown', 'harassment', 'other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE emergency_status_enum  AS ENUM ('pending', 'acknowledged', 'resolved');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE notification_category_enum AS ENUM ('bus_alert', 'trip', 'emergency', 'payment', 'general');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ═══════════════════════════════════════════════════════════════════════════════
--  1. users
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS users (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email                   TEXT UNIQUE NOT NULL,
  password_hash           TEXT NOT NULL,
  full_name               TEXT NOT NULL,
  username                TEXT UNIQUE,
  phone                   TEXT,
  date_of_birth           DATE,
  avatar_url              TEXT,
  membership_type         membership_type_enum NOT NULL DEFAULT 'standard',
  -- QR token
  qr_token                UUID DEFAULT uuid_generate_v4(),
  qr_expires_at           TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 seconds'),
  -- Password reset
  reset_pin               TEXT,                         -- bcrypt hash of PIN
  reset_pin_expires_at    TIMESTAMPTZ,
  -- Misc
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS users_set_updated_at ON users;
CREATE TRIGGER users_set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════════
--  2. notification_preferences
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notification_preferences (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bus_alerts              BOOLEAN NOT NULL DEFAULT TRUE,
  trip_updates            BOOLEAN NOT NULL DEFAULT TRUE,
  emergency_alerts        BOOLEAN NOT NULL DEFAULT TRUE,
  payment_notifications   BOOLEAN NOT NULL DEFAULT TRUE,
  promotions              BOOLEAN NOT NULL DEFAULT FALSE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_notif_prefs_user UNIQUE (user_id)
);

DROP TRIGGER IF EXISTS notif_prefs_set_updated_at ON notification_preferences;
CREATE TRIGGER notif_prefs_set_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════════
--  3. bus_routes
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bus_routes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_number    TEXT NOT NULL UNIQUE,            -- e.g. '138'
  route_name      TEXT NOT NULL,
  origin          TEXT NOT NULL,
  destination     TEXT NOT NULL,
  waypoints       JSONB NOT NULL DEFAULT '[]',     -- [{lat, lng}, ...]
  color           TEXT NOT NULL DEFAULT '#1565C0', -- hex color for map
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  4. bus_stops
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bus_stops (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  stop_name   TEXT NOT NULL,
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  5. bus_stop_routes (junction)
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS bus_stop_routes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  stop_id     UUID NOT NULL REFERENCES bus_stops(id)  ON DELETE CASCADE,
  route_id    UUID NOT NULL REFERENCES bus_routes(id) ON DELETE CASCADE,
  stop_order  INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT uq_stop_route UNIQUE (stop_id, route_id)
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  6. buses
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS buses (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id                UUID NOT NULL REFERENCES bus_routes(id) ON DELETE RESTRICT,
  bus_number              TEXT NOT NULL UNIQUE,
  driver_name             TEXT NOT NULL,
  driver_phone            TEXT,
  current_lat             DOUBLE PRECISION,
  current_lng             DOUBLE PRECISION,
  heading                 DOUBLE PRECISION,        -- degrees 0-360
  speed_kmh               DOUBLE PRECISION DEFAULT 0,
  crowd_level             crowd_level_enum NOT NULL DEFAULT 'low',
  status                  bus_status_enum  NOT NULL DEFAULT 'active',
  last_location_update    TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  7. trips
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS trips (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
  bus_id            UUID NOT NULL REFERENCES buses(id)      ON DELETE RESTRICT,
  route_id          UUID NOT NULL REFERENCES bus_routes(id) ON DELETE RESTRICT,
  boarding_stop_id  UUID REFERENCES bus_stops(id)           ON DELETE SET NULL,
  alighting_stop_id UUID REFERENCES bus_stops(id)           ON DELETE SET NULL,
  boarded_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  alighted_at       TIMESTAMPTZ,
  fare_lkr          NUMERIC(10, 2),
  status            trip_status_enum NOT NULL DEFAULT 'ongoing',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  8. ratings
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS ratings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id     UUID NOT NULL REFERENCES trips(id)  ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  bus_id      UUID NOT NULL REFERENCES buses(id)  ON DELETE CASCADE,
  stars       SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
  tags        TEXT[] NOT NULL DEFAULT '{}',
  comment     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_rating_trip UNIQUE (trip_id)
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  9. emergency_alerts
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  bus_id      UUID         REFERENCES buses(id)    ON DELETE SET NULL,
  trip_id     UUID         REFERENCES trips(id)    ON DELETE SET NULL,
  alert_type  emergency_type_enum   NOT NULL,
  description TEXT,
  latitude    DOUBLE PRECISION,
  longitude   DOUBLE PRECISION,
  status      emergency_status_enum NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS emergency_set_updated_at ON emergency_alerts;
CREATE TRIGGER emergency_set_updated_at
  BEFORE UPDATE ON emergency_alerts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════════
--  10. notifications
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  category    notification_category_enum NOT NULL DEFAULT 'general',
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  meta        JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  11. recent_searches
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS recent_searches (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  query       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: enforce max 5 recent searches per user (delete oldest beyond 5)
CREATE OR REPLACE FUNCTION enforce_max_recent_searches()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM recent_searches
  WHERE id IN (
    SELECT id FROM recent_searches
    WHERE user_id = NEW.user_id
    ORDER BY created_at DESC
    OFFSET 5
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS recent_searches_max_5 ON recent_searches;
CREATE TRIGGER recent_searches_max_5
  AFTER INSERT ON recent_searches
  FOR EACH ROW EXECUTE FUNCTION enforce_max_recent_searches();

-- ═══════════════════════════════════════════════════════════════════════════════
--  12. refresh_tokens
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════════
--  INDEXES
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_users_email               ON users(email);
CREATE INDEX IF NOT EXISTS idx_notif_prefs_user          ON notification_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_buses_route               ON buses(route_id);
CREATE INDEX IF NOT EXISTS idx_buses_status              ON buses(status);
CREATE INDEX IF NOT EXISTS idx_bus_stop_routes_stop      ON bus_stop_routes(stop_id);
CREATE INDEX IF NOT EXISTS idx_bus_stop_routes_route     ON bus_stop_routes(route_id);
CREATE INDEX IF NOT EXISTS idx_trips_user                ON trips(user_id);
CREATE INDEX IF NOT EXISTS idx_trips_status              ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_bus                 ON trips(bus_id);
CREATE INDEX IF NOT EXISTS idx_trips_route               ON trips(route_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user              ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_bus               ON ratings(bus_id);
CREATE INDEX IF NOT EXISTS idx_emergency_user            ON emergency_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_status          ON emergency_alerts(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user        ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read     ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_category    ON notifications(user_id, category);
CREATE INDEX IF NOT EXISTS idx_recent_searches_user      ON recent_searches(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user       ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash       ON refresh_tokens(token_hash);

-- ═══════════════════════════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTE: The backend uses the SERVICE ROLE key which bypasses RLS.
-- These policies protect direct Supabase client access (e.g., anon key).

ALTER TABLE users                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications           ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_searches         ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens          ENABLE ROW LEVEL SECURITY;

-- bus_routes, bus_stops, bus_stop_routes, buses — publicly readable
ALTER TABLE bus_routes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_stops       ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_stop_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses           ENABLE ROW LEVEL SECURITY;

-- Public read policies for bus data
CREATE POLICY "bus_routes_public_read"      ON bus_routes      FOR SELECT USING (true);
CREATE POLICY "bus_stops_public_read"       ON bus_stops       FOR SELECT USING (true);
CREATE POLICY "bus_stop_routes_public_read" ON bus_stop_routes FOR SELECT USING (true);
CREATE POLICY "buses_public_read"           ON buses           FOR SELECT USING (true);

-- Users can only access their own data
CREATE POLICY "users_own_row"        ON users                    FOR ALL USING (auth.uid() = id);
CREATE POLICY "notif_prefs_own_row"  ON notification_preferences FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "trips_own_row"        ON trips                    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "ratings_own_row"      ON ratings                  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "emergency_own_row"    ON emergency_alerts         FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "notifications_own_row" ON notifications           FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "searches_own_row"     ON recent_searches          FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "refresh_tokens_own"   ON refresh_tokens           FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- END FILE: schema.sql
-- ============================================================



-- ============================================================
-- BEGIN FILE: admin_schema.sql
-- ============================================================

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

-- ============================================================
-- END FILE: admin_schema.sql
-- ============================================================



-- ============================================================
-- BEGIN FILE: seed.sql
-- ============================================================

-- ============================================================
--  BusGo — Seed Data
--  Run AFTER schema.sql in Supabase SQL Editor
-- ============================================================

-- ── 1. Demo user (admin@gmail.com / 12345678) ─────────────────────────────────
-- Password hash for "12345678" with bcrypt rounds=12
-- Pre-generated: $2b$12$rOmXqKt3KVdlz1mFH3Ry3OQpYJKVqRhFf8wTrKPKpVH6JlF9QXBJ2
INSERT INTO users (
  id, email, password_hash, full_name, username, phone,
  membership_type, is_active
) VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'admin@gmail.com',
  '$2b$12$rOmXqKt3KVdlz1mFH3Ry3OQpYJKVqRhFf8wTrKPKpVH6JlF9QXBJ2',
  'Admin User',
  'admin',
  '+94771234567',
  'standard',
  TRUE
) ON CONFLICT (email) DO NOTHING;

-- Demo user notification preferences
INSERT INTO notification_preferences (user_id)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890')
ON CONFLICT (user_id) DO NOTHING;

-- ── 2. Bus Routes ─────────────────────────────────────────────────────────────

-- Route 138: Maharagama → Pettah (via Nugegoda, Borella, Maradana)
INSERT INTO bus_routes (id, route_number, route_name, origin, destination, color, waypoints) VALUES (
  '00000138-0000-0000-0000-000000000001',
  '138',
  'Maharagama - Pettah',
  'Maharagama',
  'Pettah',
  '#E53935',
  '[
    {"lat": 6.8447, "lng": 79.9262},
    {"lat": 6.8480, "lng": 79.9220},
    {"lat": 6.8650, "lng": 79.9000},
    {"lat": 6.8790, "lng": 79.8950},
    {"lat": 6.8900, "lng": 79.8900},
    {"lat": 6.9000, "lng": 79.8800},
    {"lat": 6.9100, "lng": 79.8650},
    {"lat": 6.9200, "lng": 79.8520}
  ]'::jsonb
) ON CONFLICT (route_number) DO NOTHING;

-- Route 163: Kottawa → Fort (via Borella, Maradana)
INSERT INTO bus_routes (id, route_number, route_name, origin, destination, color, waypoints) VALUES (
  '00000163-0000-0000-0000-000000000002',
  '163',
  'Kottawa - Fort',
  'Kottawa',
  'Colombo Fort',
  '#1E88E5',
  '[
    {"lat": 6.8370, "lng": 79.9700},
    {"lat": 6.8450, "lng": 79.9600},
    {"lat": 6.8600, "lng": 79.9450},
    {"lat": 6.8750, "lng": 79.9200},
    {"lat": 6.8900, "lng": 79.9000},
    {"lat": 6.9050, "lng": 79.8800},
    {"lat": 6.9200, "lng": 79.8520}
  ]'::jsonb
) ON CONFLICT (route_number) DO NOTHING;

-- Route 171: Nugegoda → Maradana (via Borella)
INSERT INTO bus_routes (id, route_number, route_name, origin, destination, color, waypoints) VALUES (
  '00000171-0000-0000-0000-000000000003',
  '171',
  'Nugegoda - Maradana',
  'Nugegoda',
  'Maradana',
  '#43A047',
  '[
    {"lat": 6.8650, "lng": 79.9000},
    {"lat": 6.8720, "lng": 79.8980},
    {"lat": 6.8800, "lng": 79.8950},
    {"lat": 6.8900, "lng": 79.8900},
    {"lat": 6.9000, "lng": 79.8820},
    {"lat": 6.9070, "lng": 79.8750},
    {"lat": 6.9120, "lng": 79.8700},
    {"lat": 6.9170, "lng": 79.8640}
  ]'::jsonb
) ON CONFLICT (route_number) DO NOTHING;

-- ── 3. Bus Stops ──────────────────────────────────────────────────────────────
INSERT INTO bus_stops (id, stop_name, latitude, longitude) VALUES
  ('00000001-0000-0000-0000-000000000001', 'Maharagama Bus Stand',    6.8447,  79.9262),
  ('00000002-0000-0000-0000-000000000002', 'Nugegoda Junction',        6.8650,  79.9000),
  ('00000003-0000-0000-0000-000000000003', 'Borella',                  6.9000,  79.8800),
  ('00000004-0000-0000-0000-000000000004', 'Maradana',                 6.9170,  79.8640),
  ('00000005-0000-0000-0000-000000000005', 'Pettah / Colombo Fort',   6.9200,  79.8520),
  ('00000006-0000-0000-0000-000000000006', 'Kottawa',                  6.8370,  79.9700),
  ('00000007-0000-0000-0000-000000000007', 'Rajagiriya',               6.9000,  79.9100),
  ('00000008-0000-0000-0000-000000000008', 'Kirulapone',               6.8790,  79.8950)
ON CONFLICT DO NOTHING;

-- ── 4. Bus Stop ↔ Route associations ─────────────────────────────────────────
INSERT INTO bus_stop_routes (stop_id, route_id, stop_order) VALUES
  -- Route 138 stops
  ('00000001-0000-0000-0000-000000000001', '00000138-0000-0000-0000-000000000001', 1),
  ('00000002-0000-0000-0000-000000000002', '00000138-0000-0000-0000-000000000001', 2),
  ('00000003-0000-0000-0000-000000000003', '00000138-0000-0000-0000-000000000001', 3),
  ('00000004-0000-0000-0000-000000000004', '00000138-0000-0000-0000-000000000001', 4),
  ('00000005-0000-0000-0000-000000000005', '00000138-0000-0000-0000-000000000001', 5),
  -- Route 163 stops
  ('00000006-0000-0000-0000-000000000006', '00000163-0000-0000-0000-000000000002', 1),
  ('00000002-0000-0000-0000-000000000002', '00000163-0000-0000-0000-000000000002', 2),
  ('00000003-0000-0000-0000-000000000003', '00000163-0000-0000-0000-000000000002', 3),
  ('00000005-0000-0000-0000-000000000005', '00000163-0000-0000-0000-000000000002', 4),
  -- Route 171 stops
  ('00000002-0000-0000-0000-000000000002', '00000171-0000-0000-0000-000000000003', 1),
  ('00000008-0000-0000-0000-000000000008', '00000171-0000-0000-0000-000000000003', 2),
  ('00000003-0000-0000-0000-000000000003', '00000171-0000-0000-0000-000000000003', 3),
  ('00000004-0000-0000-0000-000000000004', '00000171-0000-0000-0000-000000000003', 4)
ON CONFLICT (stop_id, route_id) DO NOTHING;

-- ── 5. Buses (2 per route = 6 total) ─────────────────────────────────────────
INSERT INTO buses (id, route_id, bus_number, driver_name, driver_phone, current_lat, current_lng, heading, speed_kmh, crowd_level, status) VALUES
  -- Route 138 buses
  ('0000b138-0000-0000-0000-000000000001', '00000138-0000-0000-0000-000000000001',
   'NC-1381', 'Suresh Perera',   '+94771000001', 6.8550, 79.9100, 315.0, 35.0, 'medium', 'active'),
  ('0000b138-0000-0000-0000-000000000002', '00000138-0000-0000-0000-000000000001',
   'NC-1382', 'Chamara Silva',   '+94771000002', 6.8900, 79.8870, 315.0, 42.0, 'low',    'active'),
  -- Route 163 buses
  ('0000b163-0000-0000-0000-000000000001', '00000163-0000-0000-0000-000000000002',
   'NC-1631', 'Ruwan Fernando',  '+94771000003', 6.8500, 79.9530, 315.0, 30.0, 'high',   'active'),
  ('0000b163-0000-0000-0000-000000000002', '00000163-0000-0000-0000-000000000002',
   'NC-1632', 'Pradeep Jayasena','+94771000004', 6.8950, 79.8950, 315.0, 28.0, 'medium', 'active'),
  -- Route 171 buses
  ('0000b171-0000-0000-0000-000000000001', '00000171-0000-0000-0000-000000000003',
   'NC-1711', 'Thilanka Bandara','+94771000005', 6.8700, 79.8970, 315.0, 45.0, 'low',    'active'),
  ('0000b171-0000-0000-0000-000000000002', '00000171-0000-0000-0000-000000000003',
   'NC-1712', 'Nuwan Rathnayake','+94771000006', 6.9050, 79.8790, 315.0, 38.0, 'full',   'active')
ON CONFLICT (bus_number) DO NOTHING;

-- ── 6. Sample notifications for demo user ────────────────────────────────────
INSERT INTO notifications (user_id, category, title, body, meta) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'bus_alert', 'Bus 138 Approaching',
   'Bus 138 (Maharagama - Pettah) is 2 stops away from Nugegoda Junction.',
   '{"route_number": "138", "eta_minutes": 4}'::jsonb),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'trip', 'Trip Completed',
   'Your trip on Route 163 has been completed. Fare: LKR 45.00',
   '{"route_number": "163", "fare_lkr": 45.00}'::jsonb),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'general', 'Welcome to BusGo!',
   'Track buses in real-time across Colombo. Have a safe journey!',
   '{}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================================
-- END FILE: seed.sql
-- ============================================================



-- ============================================================
-- BEGIN FILE: admin_seed.sql
-- ============================================================

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
    '$2a$12$Nb34.Tm0/wQAAsQ8jqZpBunKKNuLiH9e.6W.xdrzEL78l8fuS3nxq',
    'super_admin',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'Kasun Rajapaksha',
    'kasun@busgo.lk',
    '+94710000002',
    '$2a$12$Nb34.Tm0/wQAAsQ8jqZpBunKKNuLiH9e.6W.xdrzEL78l8fuS3nxq',
    'admin',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    'Dilani Wickramasinghe',
    'dilani@busgo.lk',
    '+94760000003',
    '$2a$12$Nb34.Tm0/wQAAsQ8jqZpBunKKNuLiH9e.6W.xdrzEL78l8fuS3nxq',
    'moderator',
    'active'
  ),
  (
    'a0000000-0000-0000-0000-000000000004',
    'Pradeep Gunasekara',
    'pradeep@busgo.lk',
    '+94750000004',
    '$2a$12$Nb34.Tm0/wQAAsQ8jqZpBunKKNuLiH9e.6W.xdrzEL78l8fuS3nxq',
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

-- ============================================================
-- END FILE: admin_seed.sql
-- ============================================================

