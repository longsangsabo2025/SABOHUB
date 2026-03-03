-- ============================================================
-- SABOHUB RPG — Phase 5: Social & Seasons
-- Leaderboards, Seasons, Prestige, Guild War
-- ============================================================

-- ============================================================
-- 1. MATERIALIZED VIEW LEADERBOARDS
-- ============================================================

-- Global CEO leaderboard (all-time)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ceo_leaderboard AS
SELECT
  ROW_NUMBER() OVER (ORDER BY cp.total_xp DESC) AS rank,
  cp.user_id,
  cp.company_id,
  e.full_name,
  c.name AS company_name,
  cp.level,
  cp.total_xp,
  cp.current_title,
  cp.streak_days,
  cp.reputation_points,
  cp.business_health_score
FROM ceo_profiles cp
JOIN employees e ON cp.user_id = e.id
JOIN companies c ON cp.company_id = c.id
ORDER BY cp.total_xp DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_ceo_lb_user ON mv_ceo_leaderboard(user_id, company_id);

-- Monthly CEO leaderboard (XP earned this month)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ceo_monthly AS
SELECT
  ROW_NUMBER() OVER (ORDER BY COALESCE(monthly.xp, 0) DESC) AS rank,
  cp.user_id,
  cp.company_id,
  e.full_name,
  c.name AS company_name,
  cp.level,
  cp.current_title,
  COALESCE(monthly.xp, 0) AS monthly_xp,
  COALESCE(monthly.quests, 0) AS monthly_quests
FROM ceo_profiles cp
JOIN employees e ON cp.user_id = e.id
JOIN companies c ON cp.company_id = c.id
LEFT JOIN (
  SELECT user_id, company_id,
    SUM(final_amount)::INT AS xp,
    COUNT(*) FILTER (WHERE source_type = 'quest') AS quests
  FROM xp_transactions
  WHERE created_at >= date_trunc('month', CURRENT_DATE)
  GROUP BY user_id, company_id
) monthly ON monthly.user_id = cp.user_id AND monthly.company_id = cp.company_id
ORDER BY COALESCE(monthly.xp, 0) DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_ceo_monthly_user ON mv_ceo_monthly(user_id, company_id);

-- Company ranking (Guild War)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_company_ranking AS
SELECT
  ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(cp.total_xp), 0) DESC) AS rank,
  c.id AS company_id,
  c.name AS company_name,
  c.business_type,
  COUNT(DISTINCT cp.id) AS ceo_count,
  COALESCE(SUM(cp.total_xp), 0) AS total_xp,
  COALESCE(AVG(cp.level), 0)::INT AS avg_level,
  COALESCE(AVG(cp.business_health_score), 0)::NUMERIC(5,2) AS avg_health,
  COALESCE(SUM(cp.reputation_points), 0) AS total_reputation,
  COUNT(DISTINCT e_active.id) AS total_employees,
  COALESCE(AVG(egp.overall_rating), 0)::NUMERIC(5,2) AS avg_staff_rating
FROM companies c
LEFT JOIN ceo_profiles cp ON cp.company_id = c.id
LEFT JOIN employees e_active ON e_active.company_id = c.id AND e_active.is_active = true
LEFT JOIN employee_game_profiles egp ON egp.company_id = c.id
GROUP BY c.id, c.name, c.business_type
ORDER BY COALESCE(SUM(cp.total_xp), 0) DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_company_rank ON mv_company_ranking(company_id);

-- Refresh functions
CREATE OR REPLACE FUNCTION refresh_leaderboards()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ceo_leaderboard;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ceo_monthly;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_company_ranking;
END;
$$;

-- Expose materialized views via functions (for Supabase RPC)
CREATE OR REPLACE FUNCTION get_global_leaderboard(p_limit INT DEFAULT 50)
RETURNS TABLE(
  rank BIGINT, user_id UUID, company_id UUID, full_name TEXT,
  company_name TEXT, level INT, total_xp BIGINT, current_title TEXT,
  streak_days INT, reputation_points INT, business_health_score NUMERIC
) LANGUAGE sql STABLE AS $$
  SELECT rank, user_id, company_id, full_name, company_name,
         level, total_xp, current_title, streak_days,
         reputation_points, business_health_score
  FROM mv_ceo_leaderboard
  LIMIT p_limit;
$$;

CREATE OR REPLACE FUNCTION get_monthly_leaderboard(p_limit INT DEFAULT 50)
RETURNS TABLE(
  rank BIGINT, user_id UUID, company_id UUID, full_name TEXT,
  company_name TEXT, level INT, current_title TEXT,
  monthly_xp INT, monthly_quests BIGINT
) LANGUAGE sql STABLE AS $$
  SELECT rank, user_id, company_id, full_name, company_name,
         level, current_title, monthly_xp, monthly_quests
  FROM mv_ceo_monthly
  LIMIT p_limit;
$$;

CREATE OR REPLACE FUNCTION get_company_ranking(p_limit INT DEFAULT 50)
RETURNS TABLE(
  rank BIGINT, company_id UUID, company_name TEXT, business_type TEXT,
  ceo_count BIGINT, total_xp NUMERIC, avg_level INT, avg_health NUMERIC,
  total_reputation NUMERIC, total_employees BIGINT, avg_staff_rating NUMERIC
) LANGUAGE sql STABLE AS $$
  SELECT rank, company_id, company_name, business_type,
         ceo_count, total_xp, avg_level, avg_health,
         total_reputation, total_employees, avg_staff_rating
  FROM mv_company_ranking
  LIMIT p_limit;
$$;

-- ============================================================
-- 2. SEASON SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_number INT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  theme TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT false,
  bonus_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS season_pass_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id UUID NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
  tier INT NOT NULL,
  xp_required INT NOT NULL,
  reward_type TEXT NOT NULL CHECK (reward_type IN ('xp', 'reputation', 'badge', 'title', 'store_item', 'skill_point', 'streak_freeze')),
  reward_value JSONB NOT NULL DEFAULT '{}',
  reward_name TEXT NOT NULL,
  reward_icon TEXT NOT NULL DEFAULT 'star',
  is_premium BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(season_id, tier)
);

CREATE TABLE IF NOT EXISTS season_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  season_id UUID NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
  season_xp INT NOT NULL DEFAULT 0,
  current_tier INT NOT NULL DEFAULT 0,
  claimed_tiers INT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, company_id, season_id)
);

ALTER TABLE season_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sp_read" ON season_progress FOR SELECT USING (true);
CREATE POLICY "sp_insert" ON season_progress FOR INSERT WITH CHECK (true);
CREATE POLICY "sp_update" ON season_progress FOR UPDATE USING (true);

-- Seed Season 1
INSERT INTO seasons (season_number, name, theme, start_date, end_date, is_active, bonus_multiplier) VALUES
(1, 'Mùa Khởi Nghiệp', 'Khởi đầu mới', '2026-03-01', '2026-05-31', true, 1.1);

-- Season 1 pass tiers (free track)
WITH s1 AS (SELECT id FROM seasons WHERE season_number = 1)
INSERT INTO season_pass_tiers (season_id, tier, xp_required, reward_type, reward_value, reward_name, reward_icon, is_premium)
SELECT s1.id, tier, xp_req, rtype, rval::JSONB, rname, ricon, false
FROM s1, (VALUES
  (1,  100,  'xp',            '{"amount": 50}',     '50 XP Bonus',          'bolt'),
  (2,  300,  'reputation',    '{"amount": 10}',     '10 Uy Tín',            'star'),
  (3,  600,  'badge',         '{"code": "s1_starter"}', 'Badge: Khởi Nghiệp', 'shield'),
  (4,  1000, 'xp',            '{"amount": 100}',    '100 XP Bonus',         'bolt'),
  (5,  1500, 'streak_freeze', '{"amount": 1}',      '+1 Streak Freeze',     'shield'),
  (6,  2000, 'reputation',    '{"amount": 25}',     '25 Uy Tín',            'star'),
  (7,  2800, 'xp',            '{"amount": 200}',    '200 XP Bonus',         'fire'),
  (8,  3500, 'badge',         '{"code": "s1_veteran"}', 'Badge: Chiến Binh S1', 'sword'),
  (9,  4500, 'reputation',    '{"amount": 50}',     '50 Uy Tín',            'diamond'),
  (10, 5000, 'title',         '{"title": "Tiên Phong"}', 'Title: Tiên Phong', 'crown')
) AS t(tier, xp_req, rtype, rval, rname, ricon);

-- Add season XP when regular XP is earned
CREATE OR REPLACE FUNCTION add_season_xp()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_season seasons%ROWTYPE;
  v_season_mult NUMERIC;
BEGIN
  SELECT * INTO v_season FROM seasons WHERE is_active = true LIMIT 1;
  IF v_season IS NULL THEN RETURN NEW; END IF;

  v_season_mult := v_season.bonus_multiplier;

  INSERT INTO season_progress (user_id, company_id, season_id, season_xp)
  VALUES (NEW.user_id, NEW.company_id, v_season.id, (NEW.final_amount * v_season_mult)::INT)
  ON CONFLICT (user_id, company_id, season_id) DO UPDATE SET
    season_xp = season_progress.season_xp + (NEW.final_amount * v_season_mult)::INT,
    updated_at = now();

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_season_xp
  AFTER INSERT ON xp_transactions
  FOR EACH ROW EXECUTE FUNCTION add_season_xp();

-- Claim season pass tier reward
CREATE OR REPLACE FUNCTION claim_season_tier(
  p_user_id UUID,
  p_company_id UUID,
  p_tier INT
)
RETURNS TABLE(success BOOLEAN, message TEXT, reward_name TEXT)
LANGUAGE plpgsql AS $$
DECLARE
  v_season seasons%ROWTYPE;
  v_progress season_progress%ROWTYPE;
  v_tier_def season_pass_tiers%ROWTYPE;
BEGIN
  SELECT * INTO v_season FROM seasons WHERE is_active = true LIMIT 1;
  IF v_season IS NULL THEN
    RETURN QUERY SELECT false, 'Không có season nào đang hoạt động'::TEXT, ''::TEXT;
    RETURN;
  END IF;

  SELECT * INTO v_progress FROM season_progress
  WHERE user_id = p_user_id AND company_id = p_company_id AND season_id = v_season.id;

  IF v_progress IS NULL THEN
    RETURN QUERY SELECT false, 'Chưa có tiến độ season'::TEXT, ''::TEXT;
    RETURN;
  END IF;

  SELECT * INTO v_tier_def FROM season_pass_tiers
  WHERE season_id = v_season.id AND tier = p_tier;

  IF v_tier_def IS NULL THEN
    RETURN QUERY SELECT false, 'Tier không tồn tại'::TEXT, ''::TEXT;
    RETURN;
  END IF;

  IF v_progress.season_xp < v_tier_def.xp_required THEN
    RETURN QUERY SELECT false, ('Cần ' || v_tier_def.xp_required || ' Season XP')::TEXT, ''::TEXT;
    RETURN;
  END IF;

  IF p_tier = ANY(v_progress.claimed_tiers) THEN
    RETURN QUERY SELECT false, 'Đã nhận phần thưởng này'::TEXT, ''::TEXT;
    RETURN;
  END IF;

  -- Claim reward
  UPDATE season_progress SET
    claimed_tiers = array_append(claimed_tiers, p_tier),
    current_tier = GREATEST(current_tier, p_tier)
  WHERE user_id = p_user_id AND company_id = p_company_id AND season_id = v_season.id;

  -- Apply reward
  CASE v_tier_def.reward_type
    WHEN 'xp' THEN
      PERFORM add_xp(p_user_id, p_company_id,
        (v_tier_def.reward_value->>'amount')::INT, 1.0, 'bonus', 'season_' || p_tier, 'Season reward: ' || v_tier_def.reward_name);
    WHEN 'reputation' THEN
      UPDATE ceo_profiles SET reputation_points = reputation_points + (v_tier_def.reward_value->>'amount')::INT
      WHERE user_id = p_user_id AND company_id = p_company_id;
    WHEN 'streak_freeze' THEN
      UPDATE ceo_profiles SET streak_freeze_remaining = streak_freeze_remaining + (v_tier_def.reward_value->>'amount')::INT
      WHERE user_id = p_user_id AND company_id = p_company_id;
    WHEN 'skill_point' THEN
      UPDATE ceo_profiles SET skill_points = skill_points + COALESCE((v_tier_def.reward_value->>'amount')::INT, 1)
      WHERE user_id = p_user_id AND company_id = p_company_id;
    WHEN 'badge' THEN
      UPDATE ceo_profiles SET active_badges = array_append(active_badges, v_tier_def.reward_value->>'code')
      WHERE user_id = p_user_id AND company_id = p_company_id;
    WHEN 'title' THEN
      UPDATE ceo_profiles SET current_title = v_tier_def.reward_value->>'title'
      WHERE user_id = p_user_id AND company_id = p_company_id;
    ELSE NULL;
  END CASE;

  RETURN QUERY SELECT true, ('Đã nhận: ' || v_tier_def.reward_name)::TEXT, v_tier_def.reward_name;
END;
$$;

-- Get season pass info for a user
CREATE OR REPLACE FUNCTION get_season_pass(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(
  season_name TEXT, season_number INT, season_xp INT, current_tier INT,
  claimed_tiers INT[], start_date DATE, end_date DATE, bonus_multiplier NUMERIC,
  days_remaining INT
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_season seasons%ROWTYPE;
BEGIN
  SELECT * INTO v_season FROM seasons WHERE is_active = true LIMIT 1;
  IF v_season IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    v_season.name,
    v_season.season_number,
    COALESCE(sp.season_xp, 0),
    COALESCE(sp.current_tier, 0),
    COALESCE(sp.claimed_tiers, '{}'),
    v_season.start_date,
    v_season.end_date,
    v_season.bonus_multiplier,
    (v_season.end_date - CURRENT_DATE)::INT
  FROM (SELECT 1) dummy
  LEFT JOIN season_progress sp
    ON sp.user_id = p_user_id AND sp.company_id = p_company_id AND sp.season_id = v_season.id;
END;
$$;

-- ============================================================
-- 3. PRESTIGE / REBIRTH SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS prestige_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  prestige_level INT NOT NULL DEFAULT 1,
  level_before_reset INT NOT NULL,
  xp_before_reset BIGINT NOT NULL,
  permanent_bonus JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE prestige_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prestige_read" ON prestige_history FOR SELECT USING (true);
CREATE POLICY "prestige_insert" ON prestige_history FOR INSERT WITH CHECK (true);

-- Add prestige columns to ceo_profiles
ALTER TABLE ceo_profiles ADD COLUMN IF NOT EXISTS prestige_level INT NOT NULL DEFAULT 0;
ALTER TABLE ceo_profiles ADD COLUMN IF NOT EXISTS prestige_bonuses JSONB NOT NULL DEFAULT '{}';

CREATE OR REPLACE FUNCTION prestige_reset(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(success BOOLEAN, message TEXT, new_prestige_level INT, bonuses JSONB)
LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_new_prestige INT;
  v_bonus JSONB;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN
    RETURN QUERY SELECT false, 'Profile không tồn tại'::TEXT, 0, '{}'::JSONB;
    RETURN;
  END IF;

  IF v_profile.level < 50 THEN
    RETURN QUERY SELECT false, 'Cần Level 50 để Prestige'::TEXT, v_profile.prestige_level, v_profile.prestige_bonuses;
    RETURN;
  END IF;

  v_new_prestige := v_profile.prestige_level + 1;

  -- Calculate permanent bonuses (stacking)
  v_bonus := jsonb_build_object(
    'xp_bonus_percent', LEAST(v_new_prestige * 5, 50),
    'reputation_bonus_percent', LEAST(v_new_prestige * 3, 30),
    'max_streak_freeze', 1 + v_new_prestige,
    'prestige_badge', 'prestige_' || v_new_prestige
  );

  -- Record history
  INSERT INTO prestige_history (user_id, company_id, prestige_level, level_before_reset, xp_before_reset, permanent_bonus)
  VALUES (p_user_id, p_company_id, v_new_prestige, v_profile.level, v_profile.total_xp, v_bonus);

  -- Reset profile but keep prestige bonuses
  UPDATE ceo_profiles SET
    level = 1,
    total_xp = 0,
    current_title = 'Tân Binh ★' || v_new_prestige,
    prestige_level = v_new_prestige,
    prestige_bonuses = v_bonus,
    skill_tree = '{"leader": 0, "merchant": 0, "strategist": 0}'::JSONB,
    skill_points = v_new_prestige,
    streak_freeze_remaining = 1 + v_new_prestige,
    active_badges = array_append(active_badges, 'prestige_' || v_new_prestige)
  WHERE user_id = p_user_id AND company_id = p_company_id;

  -- Grant prestige XP boost to start fresh
  PERFORM add_xp(p_user_id, p_company_id, v_new_prestige * 500, 1.0, 'bonus', 'prestige', 'Prestige ' || v_new_prestige || ' bonus!');

  RETURN QUERY SELECT true, ('Prestige ' || v_new_prestige || '! Bắt đầu lại với sức mạnh mới.')::TEXT, v_new_prestige, v_bonus;
END;
$$;

-- Get prestige info
CREATE OR REPLACE FUNCTION get_prestige_info(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(
  prestige_level INT, prestige_bonuses JSONB, can_prestige BOOLEAN,
  total_prestiges INT, highest_level_ever INT
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_max_level INT;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN RETURN; END IF;

  SELECT COALESCE(MAX(level_before_reset), v_profile.level) INTO v_max_level
  FROM prestige_history
  WHERE user_id = p_user_id AND company_id = p_company_id;

  RETURN QUERY SELECT
    v_profile.prestige_level,
    v_profile.prestige_bonuses,
    v_profile.level >= 50,
    (SELECT count(*)::INT FROM prestige_history WHERE user_id = p_user_id AND company_id = p_company_id),
    GREATEST(v_max_level, v_profile.level);
END;
$$;

-- Do initial refresh
SELECT refresh_leaderboards();
