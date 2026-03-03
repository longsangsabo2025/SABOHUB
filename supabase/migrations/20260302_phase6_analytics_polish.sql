-- ============================================================
-- SABOHUB RPG — Phase 6: Analytics, Premium Pass, Notifications
-- ============================================================

-- ============================================================
-- 1. GAMIFICATION ANALYTICS
-- ============================================================

-- Quest completion rates by type
CREATE OR REPLACE FUNCTION get_quest_analytics(p_company_id UUID DEFAULT NULL)
RETURNS TABLE(
  quest_type TEXT,
  total_quests BIGINT,
  completed_quests BIGINT,
  completion_rate NUMERIC,
  avg_completion_days NUMERIC,
  active_users BIGINT
) LANGUAGE sql STABLE AS $$
  SELECT
    qd.quest_type AS quest_type,
    COUNT(DISTINCT qd.id) AS total_quests,
    COUNT(DISTINCT qp.id) FILTER (WHERE qp.status = 'completed') AS completed_quests,
    CASE
      WHEN COUNT(DISTINCT qp.id) = 0 THEN 0
      ELSE ROUND(
        COUNT(DISTINCT qp.id) FILTER (WHERE qp.status = 'completed')::NUMERIC /
        NULLIF(COUNT(DISTINCT qp.id), 0) * 100, 1
      )
    END AS completion_rate,
    ROUND(AVG(
      CASE WHEN qp.status = 'completed' AND qp.completed_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (qp.completed_at - qp.started_at)) / 86400
        ELSE NULL
      END
    )::NUMERIC, 1) AS avg_completion_days,
    COUNT(DISTINCT qp.user_id) FILTER (WHERE qp.status = 'in_progress') AS active_users
  FROM quest_definitions qd
  LEFT JOIN quest_progress qp ON qp.quest_id = qd.id
    AND (p_company_id IS NULL OR qp.company_id = p_company_id)
  GROUP BY qd.quest_type
  ORDER BY qd.quest_type;
$$;

-- XP distribution breakdown
CREATE OR REPLACE FUNCTION get_xp_analytics(
  p_company_id UUID DEFAULT NULL,
  p_days INT DEFAULT 30
)
RETURNS TABLE(
  source_type TEXT,
  total_xp BIGINT,
  transaction_count BIGINT,
  avg_xp_per_tx NUMERIC,
  unique_users BIGINT,
  percentage NUMERIC
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_grand_total BIGINT;
BEGIN
  SELECT COALESCE(SUM(final_amount), 0) INTO v_grand_total
  FROM xp_transactions
  WHERE created_at >= CURRENT_DATE - p_days
    AND (p_company_id IS NULL OR company_id = p_company_id);

  RETURN QUERY
  SELECT
    xt.source_type,
    COALESCE(SUM(xt.final_amount), 0) AS total_xp,
    COUNT(*) AS transaction_count,
    ROUND(AVG(xt.final_amount)::NUMERIC, 1) AS avg_xp_per_tx,
    COUNT(DISTINCT xt.user_id) AS unique_users,
    CASE WHEN v_grand_total = 0 THEN 0
      ELSE ROUND(SUM(xt.final_amount)::NUMERIC / v_grand_total * 100, 1)
    END AS percentage
  FROM xp_transactions xt
  WHERE xt.created_at >= CURRENT_DATE - p_days
    AND (p_company_id IS NULL OR xt.company_id = p_company_id)
  GROUP BY xt.source_type
  ORDER BY total_xp DESC;
END;
$$;

-- Engagement metrics (daily active, streaks, retention)
CREATE OR REPLACE FUNCTION get_engagement_metrics(p_company_id UUID DEFAULT NULL)
RETURNS TABLE(
  metric_name TEXT,
  metric_value NUMERIC,
  metric_detail TEXT
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_total_ceos BIGINT;
  v_active_today BIGINT;
  v_active_week BIGINT;
  v_active_month BIGINT;
  v_avg_streak NUMERIC;
  v_max_streak INT;
  v_avg_level NUMERIC;
  v_total_xp_today BIGINT;
  v_total_quests_completed BIGINT;
  v_avg_health NUMERIC;
  v_prestige_count BIGINT;
  v_season_participants BIGINT;
BEGIN
  -- Total CEOs
  SELECT COUNT(*) INTO v_total_ceos FROM ceo_profiles
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  -- Active today (logged in)
  SELECT COUNT(*) INTO v_active_today FROM ceo_profiles
  WHERE last_login_date = CURRENT_DATE
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Active this week
  SELECT COUNT(*) INTO v_active_week FROM ceo_profiles
  WHERE last_login_date >= CURRENT_DATE - 7
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Active this month
  SELECT COUNT(*) INTO v_active_month FROM ceo_profiles
  WHERE last_login_date >= CURRENT_DATE - 30
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Streak stats
  SELECT COALESCE(AVG(streak_days), 0), COALESCE(MAX(longest_streak), 0)
  INTO v_avg_streak, v_max_streak
  FROM ceo_profiles
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  -- Level stats
  SELECT COALESCE(AVG(level), 0) INTO v_avg_level FROM ceo_profiles
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  -- Today's XP
  SELECT COALESCE(SUM(final_amount), 0) INTO v_total_xp_today FROM xp_transactions
  WHERE created_at::DATE = CURRENT_DATE
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Total quests completed
  SELECT COUNT(*) INTO v_total_quests_completed FROM quest_progress
  WHERE status = 'completed'
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Avg health
  SELECT COALESCE(AVG(business_health_score), 0) INTO v_avg_health FROM ceo_profiles
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  -- Prestige count
  SELECT COUNT(*) INTO v_prestige_count FROM prestige_history
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  -- Season participants
  SELECT COUNT(DISTINCT user_id) INTO v_season_participants FROM season_progress sp
  JOIN seasons s ON s.id = sp.season_id AND s.is_active = true
  WHERE p_company_id IS NULL OR sp.company_id = p_company_id;

  RETURN QUERY VALUES
    ('total_ceos'::TEXT,        v_total_ceos::NUMERIC,          'Tổng CEO đang chơi'::TEXT),
    ('active_today',            v_active_today::NUMERIC,        'Hoạt động hôm nay'),
    ('active_week',             v_active_week::NUMERIC,         'Hoạt động tuần này'),
    ('active_month',            v_active_month::NUMERIC,        'Hoạt động tháng này'),
    ('dau_rate',                CASE WHEN v_total_ceos = 0 THEN 0 ELSE ROUND(v_active_today::NUMERIC / v_total_ceos * 100, 1) END, 'DAU %'),
    ('wau_rate',                CASE WHEN v_total_ceos = 0 THEN 0 ELSE ROUND(v_active_week::NUMERIC / v_total_ceos * 100, 1) END,  'WAU %'),
    ('mau_rate',                CASE WHEN v_total_ceos = 0 THEN 0 ELSE ROUND(v_active_month::NUMERIC / v_total_ceos * 100, 1) END, 'MAU %'),
    ('avg_streak',              ROUND(v_avg_streak, 1),         'Streak trung bình'),
    ('max_streak',              v_max_streak::NUMERIC,          'Streak kỷ lục'),
    ('avg_level',               ROUND(v_avg_level, 1),          'Level trung bình'),
    ('xp_today',                v_total_xp_today::NUMERIC,      'XP kiếm hôm nay'),
    ('quests_completed',        v_total_quests_completed::NUMERIC, 'Quest hoàn thành'),
    ('avg_health',              ROUND(v_avg_health, 1),         'Health trung bình'),
    ('prestige_count',          v_prestige_count::NUMERIC,      'Lần Prestige'),
    ('season_participants',     v_season_participants::NUMERIC,  'Người chơi Season');
END;
$$;

-- Drop-off analysis: quests started but abandoned
CREATE OR REPLACE FUNCTION get_quest_dropoff(p_company_id UUID DEFAULT NULL, p_limit INT DEFAULT 20)
RETURNS TABLE(
  quest_code TEXT,
  quest_name TEXT,
  quest_type TEXT,
  started_count BIGINT,
  completed_count BIGINT,
  abandoned_count BIGINT,
  dropoff_rate NUMERIC
) LANGUAGE sql STABLE AS $$
  SELECT
    qd.code AS quest_code,
    qd.name AS quest_name,
    qd.quest_type AS quest_type,
    COUNT(*) AS started_count,
    COUNT(*) FILTER (WHERE qp.status = 'completed') AS completed_count,
    COUNT(*) FILTER (WHERE qp.status = 'in_progress' AND qp.updated_at < CURRENT_DATE - 14) AS abandoned_count,
    CASE WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(
        COUNT(*) FILTER (WHERE qp.status = 'in_progress' AND qp.updated_at < CURRENT_DATE - 14)::NUMERIC
        / COUNT(*) * 100, 1
      )
    END AS dropoff_rate
  FROM quest_definitions qd
  JOIN quest_progress qp ON qp.quest_id = qd.id
    AND (p_company_id IS NULL OR qp.company_id = p_company_id)
  GROUP BY qd.code, qd.name, qd.quest_type
  HAVING COUNT(*) > 0
  ORDER BY dropoff_rate DESC
  LIMIT p_limit;
$$;

-- Level distribution
CREATE OR REPLACE FUNCTION get_level_distribution(p_company_id UUID DEFAULT NULL)
RETURNS TABLE(
  level_range TEXT,
  player_count BIGINT,
  percentage NUMERIC
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_total BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total FROM ceo_profiles
  WHERE p_company_id IS NULL OR company_id = p_company_id;

  RETURN QUERY
  SELECT
    CASE
      WHEN cp.level BETWEEN 1 AND 5 THEN '1-5 Tân Binh'
      WHEN cp.level BETWEEN 6 AND 15 THEN '6-15 Học Việc'
      WHEN cp.level BETWEEN 16 AND 30 THEN '16-30 Chủ Tiệm'
      WHEN cp.level BETWEEN 31 AND 50 THEN '31-50 Thương Gia'
      WHEN cp.level BETWEEN 51 AND 75 THEN '51-75 Đại Gia'
      ELSE '76+ Huyền Thoại'
    END AS level_range,
    COUNT(*) AS player_count,
    CASE WHEN v_total = 0 THEN 0
      ELSE ROUND(COUNT(*)::NUMERIC / v_total * 100, 1)
    END AS percentage
  FROM ceo_profiles cp
  WHERE p_company_id IS NULL OR cp.company_id = p_company_id
  GROUP BY
    CASE
      WHEN cp.level BETWEEN 1 AND 5 THEN '1-5 Tân Binh'
      WHEN cp.level BETWEEN 6 AND 15 THEN '6-15 Học Việc'
      WHEN cp.level BETWEEN 16 AND 30 THEN '16-30 Chủ Tiệm'
      WHEN cp.level BETWEEN 31 AND 50 THEN '31-50 Thương Gia'
      WHEN cp.level BETWEEN 51 AND 75 THEN '51-75 Đại Gia'
      ELSE '76+ Huyền Thoại'
    END
  ORDER BY MIN(cp.level);
END;
$$;

-- XP trend (daily XP for last N days)
CREATE OR REPLACE FUNCTION get_xp_trend(
  p_company_id UUID DEFAULT NULL,
  p_days INT DEFAULT 14
)
RETURNS TABLE(
  day DATE,
  total_xp BIGINT,
  transaction_count BIGINT,
  unique_users BIGINT
) LANGUAGE sql STABLE AS $$
  SELECT
    d.day::DATE,
    COALESCE(SUM(xt.final_amount), 0) AS total_xp,
    COUNT(xt.id) AS transaction_count,
    COUNT(DISTINCT xt.user_id) AS unique_users
  FROM generate_series(CURRENT_DATE - p_days, CURRENT_DATE, '1 day'::INTERVAL) AS d(day)
  LEFT JOIN xp_transactions xt
    ON xt.created_at::DATE = d.day::DATE
    AND (p_company_id IS NULL OR xt.company_id = p_company_id)
  GROUP BY d.day
  ORDER BY d.day;
$$;

-- ============================================================
-- 2. PREMIUM SEASON PASS
-- ============================================================

-- Add premium tiers for Season 1
WITH s1 AS (SELECT id FROM seasons WHERE season_number = 1)
INSERT INTO season_pass_tiers (season_id, tier, xp_required, reward_type, reward_value, reward_name, reward_icon, is_premium)
SELECT s1.id, tier, xp_req, rtype, rval::JSONB, rname, ricon, true
FROM s1, (VALUES
  (1,  100,  'badge',    '{"code": "premium_s1_vip"}',     'VIP Badge S1',            'diamond'),
  (2,  300,  'title',    '{"title": "VIP Pioneer"}',       'Title: VIP Pioneer',      'crown'),
  (3,  600,  'xp',       '{"amount": 200}',                '200 XP Premium',          'fire'),
  (4,  1000, 'badge',    '{"code": "premium_s1_gold"}',    'Golden Frame S1',         'star'),
  (5,  1500, 'reputation', '{"amount": 50}',               '50 Uy Tín Premium',       'diamond'),
  (6,  2000, 'skill_point', '{"amount": 2}',               '2 Skill Points',          'bolt'),
  (7,  2800, 'badge',    '{"code": "premium_s1_elite"}',   'Elite Badge S1',          'sword'),
  (8,  3500, 'xp',       '{"amount": 500}',                '500 XP Mega',             'fire'),
  (9,  4500, 'badge',    '{"code": "premium_s1_legend"}',  'Legendary Frame S1',      'crown'),
  (10, 5000, 'title',    '{"title": "Đại Gia S1"}',       'Title: Đại Gia S1',       'crown')
) AS t(tier, xp_req, rtype, rval, rname, ricon)
ON CONFLICT (season_id, tier) WHERE is_premium = true DO NOTHING;

-- Premium pass purchases table
CREATE TABLE IF NOT EXISTS premium_pass_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  season_id UUID NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  cost_reputation INT NOT NULL DEFAULT 200,
  UNIQUE(user_id, company_id, season_id)
);

ALTER TABLE premium_pass_purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ppp_read" ON premium_pass_purchases FOR SELECT USING (true);
CREATE POLICY "ppp_insert" ON premium_pass_purchases FOR INSERT WITH CHECK (true);

-- Buy premium pass with Uy Tín
CREATE OR REPLACE FUNCTION buy_premium_pass(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE
  v_season seasons%ROWTYPE;
  v_profile ceo_profiles%ROWTYPE;
  v_cost INT := 200;
BEGIN
  SELECT * INTO v_season FROM seasons WHERE is_active = true LIMIT 1;
  IF v_season IS NULL THEN
    RETURN QUERY SELECT false, 'Không có season nào đang hoạt động'::TEXT;
    RETURN;
  END IF;

  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN
    RETURN QUERY SELECT false, 'Profile không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_profile.reputation_points < v_cost THEN
    RETURN QUERY SELECT false, ('Cần ' || v_cost || ' Uy Tín (hiện có ' || v_profile.reputation_points || ')')::TEXT;
    RETURN;
  END IF;

  -- Check already purchased
  IF EXISTS (
    SELECT 1 FROM premium_pass_purchases
    WHERE user_id = p_user_id AND company_id = p_company_id AND season_id = v_season.id
  ) THEN
    RETURN QUERY SELECT false, 'Đã mua Premium Pass mùa này'::TEXT;
    RETURN;
  END IF;

  -- Deduct and record
  UPDATE ceo_profiles SET reputation_points = reputation_points - v_cost
  WHERE user_id = p_user_id AND company_id = p_company_id;

  INSERT INTO premium_pass_purchases (user_id, company_id, season_id, cost_reputation)
  VALUES (p_user_id, p_company_id, v_season.id, v_cost);

  RETURN QUERY SELECT true, 'Premium Pass đã được kích hoạt!'::TEXT;
END;
$$;

-- Check if user has premium pass
CREATE OR REPLACE FUNCTION has_premium_pass(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM premium_pass_purchases pp
    JOIN seasons s ON s.id = pp.season_id AND s.is_active = true
    WHERE pp.user_id = p_user_id AND pp.company_id = p_company_id
  );
$$;

-- ============================================================
-- 3. NOTIFICATION / REMINDER SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS game_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'streak_warning', 'quest_reminder', 'achievement_near',
    'level_up', 'season_ending', 'weekly_summary', 'prestige_ready',
    'daily_combo', 'leaderboard_change', 'store_new_item'
  )),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_game_notif_user ON game_notifications(user_id, company_id, is_read);
CREATE INDEX idx_game_notif_created ON game_notifications(created_at DESC);

ALTER TABLE game_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_read" ON game_notifications FOR SELECT USING (true);
CREATE POLICY "notif_insert" ON game_notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "notif_update" ON game_notifications FOR UPDATE USING (true);

-- Generate notifications based on current state
CREATE OR REPLACE FUNCTION generate_game_notifications(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_count INT := 0;
  v_season seasons%ROWTYPE;
  v_today DATE := CURRENT_DATE;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;
  IF v_profile IS NULL THEN RETURN 0; END IF;

  -- Streak warning: if last login was yesterday and streak > 3
  IF v_profile.last_login_date = v_today - 1 AND v_profile.streak_days >= 3 THEN
    IF NOT EXISTS (
      SELECT 1 FROM game_notifications
      WHERE user_id = p_user_id AND company_id = p_company_id
        AND type = 'streak_warning' AND created_at::DATE = v_today
    ) THEN
      INSERT INTO game_notifications (user_id, company_id, type, title, body, data)
      VALUES (p_user_id, p_company_id, 'streak_warning',
        'Streak sắp mất!',
        'Bạn có streak ' || v_profile.streak_days || ' ngày. Đăng nhập hôm nay để giữ streak!',
        jsonb_build_object('streak_days', v_profile.streak_days, 'freeze_remaining', v_profile.streak_freeze_remaining)
      );
      v_count := v_count + 1;
    END IF;
  END IF;

  -- Prestige ready
  IF v_profile.level >= 50 THEN
    IF NOT EXISTS (
      SELECT 1 FROM game_notifications
      WHERE user_id = p_user_id AND company_id = p_company_id
        AND type = 'prestige_ready' AND created_at >= v_today - 7
    ) THEN
      INSERT INTO game_notifications (user_id, company_id, type, title, body)
      VALUES (p_user_id, p_company_id, 'prestige_ready',
        'Sẵn sàng Prestige!',
        'Level ' || v_profile.level || ' — bạn có thể Prestige để nhận bonus vĩnh viễn!'
      );
      v_count := v_count + 1;
    END IF;
  END IF;

  -- Season ending warning (7 days)
  SELECT * INTO v_season FROM seasons WHERE is_active = true LIMIT 1;
  IF v_season IS NOT NULL AND (v_season.end_date - v_today) <= 7 AND (v_season.end_date - v_today) > 0 THEN
    IF NOT EXISTS (
      SELECT 1 FROM game_notifications
      WHERE user_id = p_user_id AND company_id = p_company_id
        AND type = 'season_ending' AND created_at::DATE = v_today
    ) THEN
      INSERT INTO game_notifications (user_id, company_id, type, title, body, data)
      VALUES (p_user_id, p_company_id, 'season_ending',
        'Season sắp kết thúc!',
        v_season.name || ' còn ' || (v_season.end_date - v_today) || ' ngày. Nhận hết rewards!',
        jsonb_build_object('days_remaining', v_season.end_date - v_today)
      );
      v_count := v_count + 1;
    END IF;
  END IF;

  -- Near-achievement notifications (achievements close to unlocking)
  DECLARE
    v_ach RECORD;
  BEGIN
    FOR v_ach IN
      SELECT a.name, a.condition_type, a.condition_value
      FROM achievements a
      LEFT JOIN user_achievements ua ON ua.achievement_id = a.id
        AND ua.user_id = p_user_id AND ua.company_id = p_company_id
      WHERE ua.id IS NULL
        AND a.condition_type = 'streak'
        AND a.condition_value::INT <= v_profile.streak_days + 2
        AND a.condition_value::INT > v_profile.streak_days
      LIMIT 3
    LOOP
      IF NOT EXISTS (
        SELECT 1 FROM game_notifications
        WHERE user_id = p_user_id AND company_id = p_company_id
          AND type = 'achievement_near' AND created_at >= v_today - 3
          AND data->>'achievement_name' = v_ach.name
      ) THEN
        INSERT INTO game_notifications (user_id, company_id, type, title, body, data)
        VALUES (p_user_id, p_company_id, 'achievement_near',
          'Gần đạt thành tựu!',
          v_ach.name || ' — còn ' || (v_ach.condition_value::INT - v_profile.streak_days) || ' ngày nữa!',
          jsonb_build_object('achievement_name', v_ach.name)
        );
        v_count := v_count + 1;
      END IF;
    END LOOP;
  END;

  RETURN v_count;
END;
$$;

-- Get unread notifications
CREATE OR REPLACE FUNCTION get_game_notifications(
  p_user_id UUID,
  p_company_id UUID,
  p_limit INT DEFAULT 20,
  p_unread_only BOOLEAN DEFAULT false
)
RETURNS TABLE(
  id UUID, type TEXT, title TEXT, body TEXT,
  data JSONB, is_read BOOLEAN, created_at TIMESTAMPTZ
) LANGUAGE sql STABLE AS $$
  SELECT gn.id, gn.type, gn.title, gn.body, gn.data, gn.is_read, gn.created_at
  FROM game_notifications gn
  WHERE gn.user_id = p_user_id AND gn.company_id = p_company_id
    AND (NOT p_unread_only OR NOT gn.is_read)
  ORDER BY gn.created_at DESC
  LIMIT p_limit;
$$;

-- Mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(
  p_user_id UUID,
  p_company_id UUID,
  p_notification_ids UUID[] DEFAULT NULL
)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
  v_count INT;
BEGIN
  IF p_notification_ids IS NULL THEN
    UPDATE game_notifications SET is_read = true
    WHERE user_id = p_user_id AND company_id = p_company_id AND NOT is_read;
  ELSE
    UPDATE game_notifications SET is_read = true
    WHERE id = ANY(p_notification_ids)
      AND user_id = p_user_id AND company_id = p_company_id;
  END IF;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Unread count
CREATE OR REPLACE FUNCTION get_unread_notification_count(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS INT LANGUAGE sql STABLE AS $$
  SELECT COUNT(*)::INT FROM game_notifications
  WHERE user_id = p_user_id AND company_id = p_company_id AND NOT is_read;
$$;

-- ============================================================
-- 4. WEEKLY SUMMARY GENERATOR
-- ============================================================

CREATE OR REPLACE FUNCTION generate_weekly_summary(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(
  xp_earned BIGINT,
  quests_completed BIGINT,
  achievements_unlocked BIGINT,
  streak_days INT,
  level_progress TEXT,
  rank_change TEXT,
  top_source TEXT
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_week_start DATE := date_trunc('week', CURRENT_DATE)::DATE;
  v_xp BIGINT;
  v_quests BIGINT;
  v_achievements BIGINT;
  v_top_src TEXT;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;
  IF v_profile IS NULL THEN RETURN; END IF;

  SELECT COALESCE(SUM(final_amount), 0) INTO v_xp FROM xp_transactions
  WHERE user_id = p_user_id AND company_id = p_company_id
    AND created_at >= v_week_start;

  SELECT COUNT(*) INTO v_quests FROM quest_progress
  WHERE user_id = p_user_id AND company_id = p_company_id
    AND status = 'completed' AND completed_at >= v_week_start;

  SELECT COUNT(*) INTO v_achievements FROM user_achievements
  WHERE user_id = p_user_id AND company_id = p_company_id
    AND unlocked_at >= v_week_start;

  SELECT source_type INTO v_top_src FROM xp_transactions
  WHERE user_id = p_user_id AND company_id = p_company_id
    AND created_at >= v_week_start
  GROUP BY source_type
  ORDER BY SUM(final_amount) DESC
  LIMIT 1;

  RETURN QUERY SELECT
    v_xp,
    v_quests,
    v_achievements,
    v_profile.streak_days,
    ('Level ' || v_profile.level || ' (' || v_profile.current_title || ')')::TEXT,
    ''::TEXT,
    COALESCE(v_top_src, 'N/A');
END;
$$;
