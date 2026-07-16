-- =====================================================================
-- Kosovo National Football Team — Supabase Database Schema
-- Run this in the Supabase SQL Editor (PostgreSQL 15)
-- =====================================================================

-- 1. CONTACT MESSAGES — stores form submissions from contact.html
-- =====================================================================
CREATE TABLE IF NOT EXISTS contact_messages (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT        NOT NULL,
  email       TEXT        NOT NULL,
  subject     TEXT        NOT NULL,
  message     TEXT        NOT NULL,
  is_read     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookups by email & date
CREATE INDEX IF NOT EXISTS idx_contact_email
  ON contact_messages (email);

CREATE INDEX IF NOT EXISTS idx_contact_created
  ON contact_messages (created_at DESC);

-- Enable Row Level Security
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (public contact form)
CREATE POLICY "anon_can_insert_contact"
  ON contact_messages
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Only authenticated users can read (admin dashboard)
CREATE POLICY "auth_can_read_contact"
  ON contact_messages
  FOR SELECT
  TO authenticated
  USING (true);

-- Only authenticated users can update (mark as read)
CREATE POLICY "auth_can_update_contact"
  ON contact_messages
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================================

-- 2. PLAYERS — squad roster
-- =====================================================================
CREATE TABLE IF NOT EXISTS players (
  id            BIGSERIAL PRIMARY KEY,
  first_name    TEXT        NOT NULL,
  last_name     TEXT        NOT NULL,
  squad_number  INTEGER,
  position      TEXT        NOT NULL,   -- Goalkeeper, Defender, Midfielder, Forward
  club          TEXT,
  club_country  TEXT,
  caps          INTEGER     DEFAULT 0,
  goals         INTEGER     DEFAULT 0,
  is_captain    BOOLEAN     DEFAULT FALSE,
  is_active     BOOLEAN     DEFAULT TRUE,
  image_url     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE players ENABLE ROW LEVEL SECURITY;

-- Anyone can read
CREATE POLICY "public_read_players"
  ON players
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only authenticated can manage
CREATE POLICY "auth_insert_players"
  ON players
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "auth_update_players"
  ON players
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "auth_delete_players"
  ON players
  FOR DELETE
  TO authenticated
  USING (true);

-- =====================================================================

-- 3. FIXTURES — matches (upcoming & past)
-- =====================================================================
CREATE TABLE IF NOT EXISTS fixtures (
  id              BIGSERIAL PRIMARY KEY,
  match_date      DATE        NOT NULL,
  home_team       TEXT        NOT NULL,
  away_team       TEXT        NOT NULL,
  home_score      INTEGER,                -- NULL = not yet played
  away_score      INTEGER,                -- NULL = not yet played
  competition     TEXT        NOT NULL,    -- e.g. 'WC Qualifier', 'Nations League'
  venue           TEXT,
  status          TEXT        NOT NULL DEFAULT 'upcoming',  -- 'upcoming' | 'played'
  is_home_game    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE fixtures ENABLE ROW LEVEL SECURITY;

-- Anyone can read
CREATE POLICY "public_read_fixtures"
  ON fixtures
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only authenticated can manage
CREATE POLICY "auth_insert_fixtures"
  ON fixtures
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "auth_update_fixtures"
  ON fixtures
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "auth_delete_fixtures"
  ON fixtures
  FOR DELETE
  TO authenticated
  USING (true);

-- =====================================================================

-- 4. NEWS — articles / blog posts
-- =====================================================================
CREATE TABLE IF NOT EXISTS news (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT        NOT NULL,
  slug        TEXT        NOT NULL UNIQUE,
  excerpt     TEXT,
  content     TEXT,
  category    TEXT,                     -- e.g. 'Squad', 'Match Report', 'Stadium'
  image_url   TEXT,
  is_published BOOLEAN    NOT NULL DEFAULT FALSE,
  published_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE news ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_published_news"
  ON news
  FOR SELECT
  TO anon, authenticated
  USING (is_published = true);

CREATE POLICY "auth_read_all_news"
  ON news
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "auth_manage_news"
  ON news
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================================

-- 5. SUBSCRIBERS — newsletter / fan emails
-- =====================================================================
CREATE TABLE IF NOT EXISTS subscribers (
  id          BIGSERIAL PRIMARY KEY,
  email       TEXT        NOT NULL UNIQUE,
  name        TEXT,
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ
);

ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_can_subscribe"
  ON subscribers
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "auth_manage_subscribers"
  ON subscribers
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================================
-- SEED DATA — initial players (insert a few to get started)
-- =====================================================================

INSERT INTO players (first_name, last_name, squad_number, position, club, club_country, caps, goals, is_captain)
VALUES
  ('Arijanet',  'Muric',      1,  'Goalkeeper', 'Ipswich Town',      'England',     42, 0,  false),
  ('Visar',     'Bekaj',      12, 'Goalkeeper', 'Hatayspor',          'Turkey',        8, 0,  false),
  ('Ilir',      'Avdyli',     16, 'Goalkeeper', 'FC Prishtina',       'Kosovo',        2, 0,  false),
  ('Amir',      'Rrahmani',   4,  'Defender',   'Napoli',             'Italy',        62, 7,  true),
  ('Fidan',     'Aliti',      3,  'Defender',   'Alanyaspor',         'Turkey',       56, 1,  false),
  ('Mërgim',    'Vojvoda',    15, 'Defender',   'Torino',             'Italy',        60, 2,  false),
  ('Florent',   'Hadërgjonaj',2,  'Defender',   'Alanyaspor',         'Turkey',       34, 1,  false),
  ('Lumbardh',  'Dellova',    5,  'Defender',   'CSKA Sofia',         'Bulgaria',      8, 0,  false),
  ('Leart',     'Paqarada',   13, 'Defender',   'FC Köln',            'Germany',      32, 2,  false),
  ('Florent',   'Muslija',    8,  'Midfielder', 'SC Freiburg',        'Germany',      28, 2,  false),
  ('Valon',     'Berisha',    14, 'Midfielder', 'LASK',               'Austria',      44, 4,  false),
  ('Edon',      'Zhegrova',   10, 'Midfielder', 'Lille',              'France',       40, 5,  false),
  ('Milot',     'Rashica',    7,  'Midfielder', 'Beşiktaş',           'Turkey',       58, 12, false),
  ('Bernard',   'Berisha',    19, 'Midfielder', 'Akhmat Grozny',      'Russia',       26, 1,  false),
  ('Blendi',    'Idrizi',     6,  'Midfielder', 'Schalke 04',         'Germany',       8, 0,  false),
  ('Lindon',    'Emërllahu',  21, 'Midfielder', 'FC Ballkani',        'Kosovo',        5, 0,  false),
  ('Vedat',     'Muriqi',     9,  'Forward',    'Mallorca',           'Spain',        56, 28, false),
  ('Albion',    'Rrahmani',   11, 'Forward',    'Sparta Prague',      'Czechia',      10, 2,  false),
  ('Ermal',     'Krasniqi',   17, 'Forward',    'Sparta Prague',      'Czechia',       8, 1,  false),
  ('Elbasan',   'Rashani',    20, 'Forward',    'Clermont',           'France',       28, 4,  false);
