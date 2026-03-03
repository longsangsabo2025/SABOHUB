-- ============================================================
-- SABOHUB RPG — Quest & Gamification System
-- Migration: 20260302
-- ============================================================

-- 1. CEO Game Profiles
CREATE TABLE IF NOT EXISTS ceo_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  level INT NOT NULL DEFAULT 1,
  total_xp BIGINT NOT NULL DEFAULT 0,
  current_title TEXT NOT NULL DEFAULT 'Tân Binh',
  active_badges TEXT[] DEFAULT '{}',
  streak_days INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_login_date DATE,
  streak_freeze_remaining INT NOT NULL DEFAULT 1,
  reputation_points INT NOT NULL DEFAULT 0,
  skill_points INT NOT NULL DEFAULT 0,
  skill_tree JSONB NOT NULL DEFAULT '{"leader": 0, "merchant": 0, "strategist": 0}',
  business_health_score NUMERIC(5,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, company_id)
);

CREATE INDEX idx_ceo_profiles_user ON ceo_profiles(user_id);
CREATE INDEX idx_ceo_profiles_company ON ceo_profiles(company_id);
CREATE INDEX idx_ceo_profiles_level ON ceo_profiles(level DESC);

-- 2. Quest Definitions (admin-managed, seed data)
CREATE TABLE IF NOT EXISTS quest_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  quest_type TEXT NOT NULL CHECK (quest_type IN ('main', 'daily', 'weekly', 'boss', 'achievement')),
  act INT,
  business_type TEXT,
  category TEXT CHECK (category IN ('operate', 'sell', 'finance')),
  prerequisites TEXT[] DEFAULT '{}',
  conditions JSONB NOT NULL DEFAULT '{}',
  xp_reward INT NOT NULL DEFAULT 0,
  reputation_reward INT NOT NULL DEFAULT 0,
  badge_reward TEXT,
  title_reward TEXT,
  unlock_feature TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_secret BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_quest_definitions_type ON quest_definitions(quest_type);
CREATE INDEX idx_quest_definitions_act ON quest_definitions(act);
CREATE INDEX idx_quest_definitions_active ON quest_definitions(is_active) WHERE is_active = true;

-- 3. Quest Progress (per user)
CREATE TABLE IF NOT EXISTS quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES quest_definitions(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'locked' CHECK (status IN ('locked', 'available', 'in_progress', 'completed', 'failed')),
  progress_current INT NOT NULL DEFAULT 0,
  progress_target INT NOT NULL DEFAULT 1,
  progress_data JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, company_id, quest_id)
);

CREATE INDEX idx_quest_progress_user ON quest_progress(user_id, company_id);
CREATE INDEX idx_quest_progress_status ON quest_progress(status) WHERE status IN ('available', 'in_progress');

-- 4. Daily Quest Log
CREATE TABLE IF NOT EXISTS daily_quest_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  quests_completed TEXT[] DEFAULT '{}',
  combo_completed BOOLEAN NOT NULL DEFAULT false,
  xp_earned INT NOT NULL DEFAULT 0,
  streak_count INT NOT NULL DEFAULT 0,
  logged_in BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, company_id, log_date)
);

CREATE INDEX idx_daily_quest_log_date ON daily_quest_log(user_id, log_date DESC);

-- 5. Achievements / Badges
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT NOT NULL DEFAULT 'star',
  rarity TEXT NOT NULL DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
  category TEXT CHECK (category IN ('operate', 'sell', 'finance', 'general', 'secret')),
  condition_type TEXT NOT NULL,
  condition_value JSONB NOT NULL DEFAULT '{}',
  is_secret BOOLEAN NOT NULL DEFAULT false,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. User Achievements
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(user_id, company_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id, company_id);

-- 7. XP Transaction Log (audit trail)
CREATE TABLE IF NOT EXISTS xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  amount INT NOT NULL,
  multiplier NUMERIC(3,1) NOT NULL DEFAULT 1.0,
  final_amount INT NOT NULL,
  source_type TEXT NOT NULL CHECK (source_type IN ('quest', 'daily', 'weekly', 'boss', 'achievement', 'login', 'bonus', 'multiplier')),
  source_id TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_xp_transactions_user ON xp_transactions(user_id, company_id);
CREATE INDEX idx_xp_transactions_date ON xp_transactions(created_at DESC);

-- 8. Branch Star Ratings
CREATE TABLE IF NOT EXISTS branch_star_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  star_rating INT NOT NULL DEFAULT 0 CHECK (star_rating BETWEEN 0 AND 3),
  criteria_scores JSONB NOT NULL DEFAULT '{}',
  evaluated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(branch_id)
);

CREATE INDEX idx_branch_stars_company ON branch_star_ratings(company_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Calculate XP needed for a given level: floor(100 * n^1.5)
CREATE OR REPLACE FUNCTION xp_for_level(n INT)
RETURNS BIGINT LANGUAGE sql IMMUTABLE AS $$
  SELECT floor(100 * power(n, 1.5))::BIGINT;
$$;

-- Calculate level from total XP
CREATE OR REPLACE FUNCTION level_from_xp(total BIGINT)
RETURNS INT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  lvl INT := 1;
BEGIN
  WHILE xp_for_level(lvl + 1) <= total LOOP
    lvl := lvl + 1;
    IF lvl >= 100 THEN EXIT; END IF;
  END LOOP;
  RETURN lvl;
END;
$$;

-- Title for a given level
CREATE OR REPLACE FUNCTION title_for_level(lvl INT)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN lvl BETWEEN 1  AND 5  THEN 'Tân Binh'
    WHEN lvl BETWEEN 6  AND 15 THEN 'Chủ Tiệm'
    WHEN lvl BETWEEN 16 AND 30 THEN 'Ông Chủ'
    WHEN lvl BETWEEN 31 AND 50 THEN 'Doanh Nhân'
    WHEN lvl BETWEEN 51 AND 75 THEN 'Tướng Quân'
    WHEN lvl BETWEEN 76 AND 99 THEN 'Đế Vương'
    WHEN lvl >= 100 THEN 'Huyền Thoại'
    ELSE 'Tân Binh'
  END;
$$;

-- Add XP to a CEO profile (with multiplier support)
CREATE OR REPLACE FUNCTION add_xp(
  p_user_id UUID,
  p_company_id UUID,
  p_amount INT,
  p_multiplier NUMERIC DEFAULT 1.0,
  p_source_type TEXT DEFAULT 'bonus',
  p_source_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE(new_level INT, new_total_xp BIGINT, leveled_up BOOLEAN, new_title TEXT)
LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_final_amount INT;
  v_old_level INT;
  v_new_level INT;
  v_new_xp BIGINT;
BEGIN
  v_final_amount := floor(p_amount * p_multiplier)::INT;

  -- Upsert CEO profile
  INSERT INTO ceo_profiles (user_id, company_id)
  VALUES (p_user_id, p_company_id)
  ON CONFLICT (user_id, company_id) DO NOTHING;

  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  v_old_level := v_profile.level;
  v_new_xp := v_profile.total_xp + v_final_amount;
  v_new_level := level_from_xp(v_new_xp);

  UPDATE ceo_profiles SET
    total_xp = v_new_xp,
    level = v_new_level,
    current_title = title_for_level(v_new_level),
    skill_points = CASE
      WHEN v_new_level / 5 > v_old_level / 5
      THEN skill_points + ((v_new_level / 5) - (v_old_level / 5))
      ELSE skill_points
    END,
    updated_at = now()
  WHERE user_id = p_user_id AND company_id = p_company_id;

  INSERT INTO xp_transactions (user_id, company_id, amount, multiplier, final_amount, source_type, source_id, description)
  VALUES (p_user_id, p_company_id, p_amount, p_multiplier, v_final_amount, p_source_type, p_source_id, p_description);

  RETURN QUERY SELECT
    v_new_level,
    v_new_xp,
    (v_new_level > v_old_level),
    title_for_level(v_new_level);
END;
$$;

-- Record daily login and update streak
CREATE OR REPLACE FUNCTION record_daily_login(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(streak INT, xp_earned INT, is_new_login BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_yesterday DATE := CURRENT_DATE - 1;
  v_streak INT;
  v_xp INT;
  v_already_logged BOOLEAN;
BEGIN
  INSERT INTO ceo_profiles (user_id, company_id)
  VALUES (p_user_id, p_company_id)
  ON CONFLICT (user_id, company_id) DO NOTHING;

  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  -- Check if already logged in today
  SELECT EXISTS(
    SELECT 1 FROM daily_quest_log
    WHERE user_id = p_user_id AND company_id = p_company_id
      AND log_date = v_today AND logged_in = true
  ) INTO v_already_logged;

  IF v_already_logged THEN
    RETURN QUERY SELECT v_profile.streak_days, 0, false;
    RETURN;
  END IF;

  -- Calculate streak
  IF v_profile.last_login_date = v_yesterday THEN
    v_streak := v_profile.streak_days + 1;
  ELSIF v_profile.last_login_date = v_today THEN
    v_streak := v_profile.streak_days;
  ELSE
    -- Streak broken, check freeze
    IF v_profile.streak_freeze_remaining > 0
       AND v_profile.last_login_date >= v_today - 2 THEN
      v_streak := v_profile.streak_days;
      UPDATE ceo_profiles SET streak_freeze_remaining = streak_freeze_remaining - 1
      WHERE user_id = p_user_id AND company_id = p_company_id;
    ELSE
      v_streak := 1;
    END IF;
  END IF;

  -- Calculate login XP (scales with streak, capped at 50)
  v_xp := LEAST(10 + (v_streak * 2), 50);

  -- Update profile
  UPDATE ceo_profiles SET
    streak_days = v_streak,
    longest_streak = GREATEST(longest_streak, v_streak),
    last_login_date = v_today,
    updated_at = now()
  WHERE user_id = p_user_id AND company_id = p_company_id;

  -- Upsert daily log
  INSERT INTO daily_quest_log (user_id, company_id, log_date, logged_in, streak_count)
  VALUES (p_user_id, p_company_id, v_today, true, v_streak)
  ON CONFLICT (user_id, company_id, log_date)
  DO UPDATE SET logged_in = true, streak_count = v_streak;

  -- Grant login XP
  PERFORM add_xp(p_user_id, p_company_id, v_xp, 1.0, 'login', NULL, 'Daily login streak ' || v_streak);

  RETURN QUERY SELECT v_streak, v_xp, true;
END;
$$;

-- Get leaderboard
CREATE OR REPLACE FUNCTION get_ceo_leaderboard(
  p_company_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS TABLE(
  rank BIGINT,
  user_id UUID,
  full_name TEXT,
  company_name TEXT,
  level INT,
  total_xp BIGINT,
  current_title TEXT,
  streak_days INT
)
LANGUAGE sql STABLE AS $$
  SELECT
    ROW_NUMBER() OVER (ORDER BY cp.total_xp DESC) AS rank,
    cp.user_id,
    e.full_name,
    c.name AS company_name,
    cp.level,
    cp.total_xp,
    cp.current_title,
    cp.streak_days
  FROM ceo_profiles cp
  JOIN employees e ON cp.user_id = e.id
  JOIN companies c ON cp.company_id = c.id
  WHERE (p_company_id IS NULL OR cp.company_id = p_company_id)
  ORDER BY cp.total_xp DESC
  LIMIT p_limit;
$$;

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ceo_profiles_updated
  BEFORE UPDATE ON ceo_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_quest_progress_updated
  BEFORE UPDATE ON quest_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- RLS Policies
-- ============================================================
ALTER TABLE ceo_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_quest_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE branch_star_ratings ENABLE ROW LEVEL SECURITY;

-- Quest definitions and achievements are public read
ALTER TABLE quest_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quest_defs_read" ON quest_definitions FOR SELECT USING (true);
CREATE POLICY "achievements_read" ON achievements FOR SELECT USING (true);

CREATE POLICY "ceo_profiles_own" ON ceo_profiles FOR ALL USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);

CREATE POLICY "quest_progress_own" ON quest_progress FOR ALL USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);

CREATE POLICY "daily_log_own" ON daily_quest_log FOR ALL USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);

CREATE POLICY "achievements_own" ON user_achievements FOR ALL USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);

CREATE POLICY "xp_own" ON xp_transactions FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);

CREATE POLICY "branch_stars_read" ON branch_star_ratings FOR SELECT USING (true);
CREATE POLICY "branch_stars_write" ON branch_star_ratings FOR ALL USING (
  EXISTS (SELECT 1 FROM employees WHERE id = auth.uid() AND role IN ('super_admin', 'ceo'))
);
