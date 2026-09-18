-- Hajj/Umrah Group Tracking Platform - SaaS Subscription Schema
-- This migration creates the core tables, RLS policies, and tier enforcement triggers.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE
-- Links to auth.users and stores subscription tier information
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  subscription_tier TEXT NOT NULL DEFAULT 'FREE' CHECK (subscription_tier IN ('FREE', 'LITE', 'PRO')),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster tier lookups
CREATE INDEX IF NOT EXISTS idx_profiles_subscription_tier ON profiles(subscription_tier);

-- 2. GROUP_PROFILES TABLE
-- Tracks Hajj/Umrah groups associated with each user
CREATE TABLE IF NOT EXISTS group_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for user's groups lookup
CREATE INDEX IF NOT EXISTS idx_group_profiles_user_id ON group_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_group_profiles_is_active ON group_profiles(is_active);

-- 3. RITUAL_LOGS TABLE
-- Logs ritual milestones/updates for each group
CREATE TABLE IF NOT EXISTS ritual_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_profile_id UUID NOT NULL REFERENCES group_profiles(id) ON DELETE CASCADE,
  ritual_type TEXT NOT NULL,
  notes TEXT,
  location_lat DECIMAL(9,6),
  location_lng DECIMAL(9,6),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for group's ritual logs and monthly queries
CREATE INDEX IF NOT EXISTS idx_ritual_logs_group_profile_id ON ritual_logs(group_profile_id);
CREATE INDEX IF NOT EXISTS idx_ritual_logs_created_at ON ritual_logs(created_at);

-- 4. ROW-LEVEL SECURITY (RLS) POLICIES
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ritual_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can only read/write their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Group Profiles: Users can only manage their own groups
CREATE POLICY "Users can view own groups" ON group_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own groups" ON group_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own groups" ON group_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own groups" ON group_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- Ritual Logs: Users can only manage logs for their own groups
CREATE POLICY "Users can view own ritual logs" ON ritual_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM group_profiles gp
      JOIN profiles p ON gp.user_id = p.id
      WHERE gp.id = ritual_logs.group_profile_id AND p.id = auth.uid()
    )
  );

CREATE POLICY "Users can create ritual logs" ON ritual_logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_profiles gp
      JOIN profiles p ON gp.user_id = p.id
      WHERE gp.id = ritual_logs.group_profile_id AND p.id = auth.uid()
    )
  );

CREATE POLICY "Users can update own ritual logs" ON ritual_logs
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM group_profiles gp
      JOIN profiles p ON gp.user_id = p.id
      WHERE gp.id = ritual_logs.group_profile_id AND p.id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own ritual logs" ON ritual_logs
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM group_profiles gp
      JOIN profiles p ON gp.user_id = p.id
      WHERE gp.id = ritual_logs.group_profile_id AND p.id = auth.uid()
    )
  );

-- 5. TIER LIMIT ENFORCEMENT TRIGGER FUNCTION
-- This function intercepts INSERT operations and enforces tier-based limits
CREATE OR REPLACE FUNCTION check_tier_limits_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_subscription_tier TEXT;
  v_group_count INTEGER;
  v_ritual_count_month INTEGER;
  v_limit_groups INTEGER;
  v_limit_rituals INTEGER;
BEGIN
  -- Determine which table is being inserted into and get the user_id
  IF TG_TABLE_NAME = 'group_profiles' THEN
    v_user_id := NEW.user_id;
  ELSIF TG_TABLE_NAME = 'ritual_logs' THEN
    -- Get user_id from the associated group_profile
    SELECT gp.user_id INTO v_user_id
    FROM group_profiles gp
    WHERE gp.id = NEW.group_profile_id;
  END IF;

  -- Get user's subscription tier
  SELECT subscription_tier INTO v_subscription_tier
  FROM profiles
  WHERE id = v_user_id;

  -- Set limits based on tier
  IF v_subscription_tier = 'FREE' THEN
    v_limit_groups := 3;
    v_limit_rituals := 100; -- Total lifetime limit for FREE
  ELSIF v_subscription_tier = 'LITE' THEN
    v_limit_groups := 15;
    v_limit_rituals := 2000; -- Monthly limit for LITE
  ELSIF v_subscription_tier = 'PRO' THEN
    v_limit_groups := 999999; -- Effectively unlimited
    v_limit_rituals := 999999; -- Effectively unlimited
  ELSE
    -- Default to FREE limits if tier is unknown
    v_limit_groups := 3;
    v_limit_rituals := 100;
  END IF;

  -- Enforce group_profiles limits
  IF TG_TABLE_NAME = 'group_profiles' THEN
    SELECT COUNT(*) INTO v_group_count
    FROM group_profiles
    WHERE user_id = v_user_id AND is_active = TRUE;

    IF v_group_count >= v_limit_groups THEN
      RAISE EXCEPTION 'Subscription tier % limit exceeded: maximum % active groups allowed (current: %)',
        v_subscription_tier, v_limit_groups, v_group_count;
    END IF;
  END IF;

  -- Enforce ritual_logs limits
  IF TG_TABLE_NAME = 'ritual_logs' THEN
    -- For FREE tier, count total lifetime logs
    -- For LITE/PRO, count monthly logs
    IF v_subscription_tier = 'FREE' THEN
      SELECT COUNT(*) INTO v_ritual_count_month
      FROM ritual_logs rl
      JOIN group_profiles gp ON rl.group_profile_id = gp.id
      WHERE gp.user_id = v_user_id;
    ELSE
      -- Count logs in current month for LITE/PRO
      SELECT COUNT(*) INTO v_ritual_count_month
      FROM ritual_logs rl
      JOIN group_profiles gp ON rl.group_profile_id = gp.id
      WHERE gp.user_id = v_user_id
        AND rl.created_at >= DATE_TRUNC('month', NOW());
    END IF;

    IF v_ritual_count_month >= v_limit_rituals THEN
      IF v_subscription_tier = 'FREE' THEN
        RAISE EXCEPTION 'Subscription tier % limit exceeded: maximum % total ritual logs allowed (current: %)',
          v_subscription_tier, v_limit_rituals, v_ritual_count_month;
      ELSE
        RAISE EXCEPTION 'Subscription tier % limit exceeded: maximum % ritual logs per month allowed (current: %)',
          v_subscription_tier, v_limit_rituals, v_ritual_count_month;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CREATE TRIGGERS
-- Attach the trigger to group_profiles INSERT operations
CREATE TRIGGER trg_check_group_profiles_tier_limits
  BEFORE INSERT ON group_profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_tier_limits_trigger();

-- Attach the trigger to ritual_logs INSERT operations
CREATE TRIGGER trg_check_ritual_logs_tier_limits
  BEFORE INSERT ON ritual_logs
  FOR EACH ROW
  EXECUTE FUNCTION check_tier_limits_trigger();

-- 7. HELPER FUNCTION: Get current usage for a user
-- Useful for displaying usage stats in the UI
CREATE OR REPLACE FUNCTION get_user_usage_stats(p_user_id UUID)
RETURNS TABLE (
  subscription_tier TEXT,
  active_groups_count INTEGER,
  total_ritual_logs INTEGER,
  monthly_ritual_logs INTEGER,
  max_groups_allowed INTEGER,
  max_ritual_logs_allowed INTEGER
) AS $$
DECLARE
  v_tier TEXT;
  v_max_groups INTEGER;
  v_max_rituals INTEGER;
BEGIN
  -- Get user's tier
  SELECT subscription_tier INTO v_tier FROM profiles WHERE id = p_user_id;

  -- Set limits based on tier
  IF v_tier = 'FREE' THEN
    v_max_groups := 3;
    v_max_rituals := 100;
  ELSIF v_tier = 'LITE' THEN
    v_max_groups := 15;
    v_max_rituals := 2000;
  ELSIF v_tier = 'PRO' THEN
    v_max_groups := 999999;
    v_max_rituals := 999999;
  ELSE
    v_max_groups := 3;
    v_max_rituals := 100;
  END IF;

  RETURN QUERY
  SELECT
    v_tier AS subscription_tier,
    (SELECT COUNT(*) FROM group_profiles gp WHERE gp.user_id = p_user_id AND gp.is_active = TRUE) AS active_groups_count,
    (SELECT COUNT(*) FROM ritual_logs rl JOIN group_profiles gp ON rl.group_profile_id = gp.id WHERE gp.user_id = p_user_id) AS total_ritual_logs,
    (SELECT COUNT(*) FROM ritual_logs rl JOIN group_profiles gp ON rl.group_profile_id = gp.id WHERE gp.user_id = p_user_id AND rl.created_at >= DATE_TRUNC('month', NOW())) AS monthly_ritual_logs,
    v_max_groups AS max_groups_allowed,
    v_max_rituals AS max_ritual_logs_allowed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
