-- Hajj & Umrah Guide SaaS - Database Schema
-- Supabase Migration Script

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS FOR TIER AND STATUS
-- ============================================
CREATE TYPE subscription_tier AS ENUM ('free', 'lite', 'pro');
CREATE TYPE pilgrimage_status AS ENUM ('planning', 'in_progress', 'completed');
CREATE TYPE ritual_category AS ENUM ('tawaf', 'sai', 'arafat', 'muzdalifah', 'mina', 'jamarat', 'general');

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  full_name TEXT,
  subscription_tier subscription_tier DEFAULT 'free' NOT NULL,
  pilgrimage_status pilgrimage_status DEFAULT 'planning' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for faster lookups
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_tier ON profiles(subscription_tier);

-- ============================================
-- RITUALS TABLE (Location-based guidance data)
-- ============================================
CREATE TABLE rituals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  category ritual_category NOT NULL,
  step_order INTEGER NOT NULL,
  description TEXT,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  radius_meters INTEGER DEFAULT 50 NOT NULL,
  duas_json JSONB DEFAULT '[]'::jsonb,
  tier_required subscription_tier DEFAULT 'free' NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for geospatial queries (basic, consider PostGIS for production)
CREATE INDEX idx_rituals_location ON rituals(latitude, longitude);
CREATE INDEX idx_rituals_category ON rituals(category);
CREATE INDEX idx_rituals_tier ON rituals(tier_required);

-- ============================================
-- USER PROGRESS TABLE (Track ritual completion)
-- ============================================
CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ritual_id UUID REFERENCES rituals(id) ON DELETE CASCADE NOT NULL,
  current_circuit INTEGER DEFAULT 0 NOT NULL,
  completed BOOLEAN DEFAULT FALSE NOT NULL,
  last_latitude DECIMAL(10, 8),
  last_longitude DECIMAL(11, 8),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, ritual_id)
);

-- Index for user progress lookups
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_ritual_id ON user_progress(ritual_id);

-- ============================================
-- GROUP MEMBERS TABLE (For Pro tier family tracking)
-- ============================================
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_code TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')) NOT NULL,
  last_known_latitude DECIMAL(10, 8),
  last_known_longitude DECIMAL(11, 8),
  last_updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, group_code)
);

-- Index for group lookups
CREATE INDEX idx_group_members_code ON group_members(group_code);
CREATE INDEX idx_group_members_user ON group_members(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rituals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can only view/update their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage profiles"
  ON profiles FOR ALL
  TO service_role
  USING (true);

-- Rituals: Everyone can read, only admins/service can write
CREATE POLICY "Everyone can read rituals"
  ON rituals FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Service role can manage rituals"
  ON rituals FOR ALL
  TO service_role
  USING (true);

-- User Progress: Users can only manage their own progress
CREATE POLICY "Users can view own progress"
  ON user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
  ON user_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON user_progress FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage user progress"
  ON user_progress FOR ALL
  TO service_role
  USING (true);

-- Group Members: Users can manage their own group memberships
CREATE POLICY "Users can view own group memberships"
  ON group_members FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM group_members gm2 
    WHERE gm2.group_code = group_members.group_code 
    AND gm2.user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own group membership"
  ON group_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own group membership"
  ON group_members FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage group members"
  ON group_members FOR ALL
  TO service_role
  USING (true);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rituals_updated_at
  BEFORE UPDATE ON rituals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_members_updated_at
  BEFORE UPDATE ON group_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get user's subscription tier
CREATE OR REPLACE FUNCTION get_user_tier()
RETURNS subscription_tier AS $$
DECLARE
  user_tier subscription_tier;
BEGIN
  SELECT subscription_tier INTO user_tier
  FROM profiles
  WHERE user_id = auth.uid();
  
  RETURN COALESCE(user_tier, 'free');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has access to a tier-restricted feature
CREATE OR REPLACE FUNCTION has_tier_access(required_tier subscription_tier)
RETURNS BOOLEAN AS $$
DECLARE
  user_tier subscription_tier;
BEGIN
  SELECT subscription_tier INTO user_tier
  FROM profiles
  WHERE user_id = auth.uid();
  
  -- Tier hierarchy: pro > lite > free
  IF user_tier = 'pro' THEN
    RETURN true;
  ELSIF user_tier = 'lite' AND required_tier != 'pro' THEN
    RETURN true;
  ELSIF user_tier = required_tier THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SEED DATA - KEY HOLY SITES
-- ============================================

-- Masjid al-Haram (Kaaba) - Tawaf starting point
INSERT INTO rituals (title, category, step_order, description, latitude, longitude, radius_meters, tier_required, duas_json) VALUES
('Tawaf - Start at Black Stone', 'tawaf', 1, 'Begin your Tawaf at the Black Stone (Hajar al-Aswad). Face the Kaaba and make intention.', 21.422487, 39.826206, 30, 'free', '[{"arabic": "بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ", "transliteration": "Bismillahi Allahu Akbar", "translation": "In the name of Allah, Allah is Greatest"}]'),
('Tawaf - Circuit Complete', 'tawaf', 2, 'Complete one full circuit around the Kaaba. Repeat 7 times total.', 21.422487, 39.826206, 50, 'free', '[]'),
('Sa''i - Start at Safa', 'sai', 1, 'Begin Sa''i at Mount Safa. Climb the hill and face the Kaaba.', 21.421847, 39.827366, 40, 'free', '[{"arabic": "إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ", "transliteration": "Inna as-Safa wal-Marwata min sha''a''iri Allah", "translation": "Indeed, as-Safa and al-Marwah are among the symbols of Allah"}]'),
('Sa''i - At Marwah', 'sai', 2, 'Reach Mount Marwah. This completes one round of Sa''i. Repeat 7 times total.', 21.423056, 39.828889, 40, 'free', '[]'),
('Arafat - Stand in Prayer', 'arafat', 1, 'Stand in worship at the Plain of Arafat. This is the pinnacle of Hajj.', 21.366667, 39.983333, 500, 'free', '[{"arabic": "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ", "transliteration": "Labbayk Allahumma Labbayk", "translation": "Here I am, O Allah, here I am"}]'),
('Muzdalifah - Collect Pebbles', 'muzdalifah', 1, 'Collect pebbles for stoning Jamarat. Minimum 49 pebbles recommended.', 21.383333, 39.950000, 300, 'free', '[]'),
('Mina - Jamarat al-Ula', 'jamarat', 1, 'Stone the first pillar (Jamarat al-Ula) with 7 pebbles.', 21.368889, 39.965556, 50, 'free', '[{"arabic": "اللَّهُ أَكْبَرُ", "transliteration": "Allahu Akbar", "translation": "Allah is Greatest"}]'),
('Mina - Jamarat al-Wusta', 'jamarat', 2, 'Stone the middle pillar (Jamarat al-Wusta) with 7 pebbles.', 21.370278, 39.967222, 50, 'free', '[]'),
('Mina - Jamarat al-Aqaba', 'jamarat', 3, 'Stone the largest pillar (Jamarat al-Aqaba) with 7 pebbles.', 21.371667, 39.969444, 50, 'free', '[]');

-- ============================================
-- MOCK SUBSCRIPTION WEBHOOK ENDPOINT STUB
-- ============================================
-- Note: In production, this would be a Supabase Edge Function or external webhook
-- This table stores pending subscription changes from payment providers

CREATE TABLE subscription_webhooks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE POLICY "Service role can manage webhooks"
  ON subscription_webhooks FOR ALL
  TO service_role
  USING (true);

-- Function to process subscription webhook (stub)
CREATE OR REPLACE FUNCTION process_subscription_webhook()
RETURNS TRIGGER AS $$
BEGIN
  -- TODO: Implement actual payment provider logic here
  -- This is a stub that will be replaced with Stripe/PayPal webhook handling
  
  -- Example: Extract user_id and new_tier from payload
  -- UPDATE profiles SET subscription_tier = NEW.payload->>'tier' WHERE user_id = NEW.payload->>'user_id';
  
  NEW.processed = true;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER process_webhook_trigger
  AFTER INSERT ON subscription_webhooks
  FOR EACH ROW
  WHEN (NOT NEW.processed)
  EXECUTE FUNCTION process_subscription_webhook();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE profiles IS 'User profiles with subscription tier and pilgrimage status';
COMMENT ON TABLE rituals IS 'Location-based ritual guidance data with geofencing coordinates';
COMMENT ON TABLE user_progress IS 'Tracks individual user progress through rituals';
COMMENT ON TABLE group_members IS 'Pro tier feature: Track family members in groups during pilgrimage';
COMMENT ON COLUMN rituals.tier_required IS 'Minimum subscription tier needed to access this ritual content';
COMMENT ON COLUMN group_members.last_known_latitude IS 'Last known GPS location of group member (Pro feature)';
