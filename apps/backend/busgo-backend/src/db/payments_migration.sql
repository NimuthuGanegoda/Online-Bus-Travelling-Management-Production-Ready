-- ═══════════════════════════════════════════════════════════════
--  Payments migration — run once in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS payments (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payment_method   TEXT        NOT NULL CHECK (payment_method IN ('credit_card', 'debit_card')),
  card_holder_name TEXT        NOT NULL,
  masked_card      TEXT        NOT NULL,   -- e.g. ****1234
  amount_lkr       NUMERIC(10,2) NOT NULL DEFAULT 0,
  status           TEXT        NOT NULL CHECK (status IN ('success', 'failed')) DEFAULT 'success',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user-scoped queries
CREATE INDEX IF NOT EXISTS idx_payments_user_id    ON payments (user_id);
-- Index for admin listing by date
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments (created_at DESC);
