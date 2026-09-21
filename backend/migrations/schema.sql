-- AI Image Understanding App — Postgres schema (Neon)
-- Run once against the Neon database referenced by DATABASE_URL, e.g.:
--   psql "$DATABASE_URL" -f migrations/schema.sql
-- or via `npm run migrate` (backend/src/migrate.js runs this file idempotently).

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid()

-- One row per anonymous device/app-install. Created by POST /api/auth/anonymous.
-- No personal data is collected; this exists purely to scope history per installer.
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per analyzed image. Mirrors the SQLite shape from the spec, adapted to
-- Postgres types (JSONB for structured sub-objects, TIMESTAMPTZ for timestamps).
CREATE TABLE IF NOT EXISTS image_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Small base64 JPEG thumbnail (longest side capped ~256px) so history loads fast
  -- without re-fetching the original image. The original is never stored server-side
  -- once analysis completes (see PRIVACY.md / AI_DOCUMENTATION.md).
  image_thumbnail TEXT,

  description TEXT NOT NULL,
  detected_objects JSONB NOT NULL DEFAULT '[]',   -- [{name, confidence, band}, ...]
  detected_text TEXT,                              -- OCR summary, if any text was found
  user_questions JSONB NOT NULL DEFAULT '[]',       -- [{question, answer, confidence, askedAt}, ...]

  confidence_score REAL,                            -- overall confidence 0..1
  confidence_band TEXT,                             -- 'high' | 'medium' | 'low'
  is_demo_mode BOOLEAN NOT NULL DEFAULT false,       -- true if produced without a live API key

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_image_history_user_created
  ON image_history (user_id, created_at DESC);

-- Keep updated_at current on any row change (e.g. when a question is appended).
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_image_history_updated_at ON image_history;
CREATE TRIGGER trg_image_history_updated_at
  BEFORE UPDATE ON image_history
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
