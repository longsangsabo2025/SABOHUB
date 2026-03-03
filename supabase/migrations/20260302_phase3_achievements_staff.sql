-- ============================================================
-- SABOHUB RPG — Phase 3: Achievements Auto-Eval + Staff Gamification
-- ============================================================

-- ============================================================
-- 1. ACHIEVEMENT AUTO-EVALUATION ENGINE
-- ============================================================

CREATE OR REPLACE FUNCTION evaluate_achievements(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(achievement_code TEXT, achievement_name TEXT, rarity TEXT, newly_unlocked BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE
  r RECORD;
  v_met BOOLEAN;
  v_already_has BOOLEAN;
BEGIN
  FOR r IN
    SELECT a.id, a.code, a.name, a.rarity, a.condition_type, a.condition_value
    FROM achievements a
    WHERE NOT EXISTS (
      SELECT 1 FROM user_achievements ua
      WHERE ua.user_id = p_user_id
        AND ua.company_id = p_company_id
        AND ua.achievement_id = a.id
    )
  LOOP
    v_met := false;

    CASE r.condition_type

      WHEN 'quest_complete' THEN
        v_met := _ach_quest_complete(p_user_id, p_company_id, r.condition_value);

      WHEN 'streak' THEN
        v_met := _ach_streak(p_user_id, p_company_id, r.condition_value);

      WHEN 'order_speed' THEN
        v_met := _ach_order_speed(p_company_id, r.condition_value);

      WHEN 'early_login_streak' THEN
        v_met := _ach_early_login(p_user_id, p_company_id, r.condition_value);

      WHEN 'zero_complaints' THEN
        v_met := _ach_zero_complaints(p_company_id, r.condition_value);

      WHEN 'business_types' THEN
        v_met := _ach_business_types(p_user_id, r.condition_value);

      WHEN 'leaderboard_rank' THEN
        v_met := _ach_leaderboard_rank(p_user_id, p_company_id, r.condition_value);

      WHEN 'action_time' THEN
        v_met := _ach_action_time(p_company_id, r.condition_value);

      WHEN 'daily_action_count' THEN
        v_met := _ach_daily_action_count(p_company_id, r.condition_value);

      WHEN 'financial_recovery' THEN
        v_met := _ach_financial_recovery(p_company_id, r.condition_value);

      WHEN 'staff_level' THEN
        v_met := _ach_staff_level(p_company_id, r.condition_value);

      WHEN 'employee_count' THEN
        v_met := _ach_employee_count(p_company_id, r.condition_value);

      ELSE
        v_met := false;
    END CASE;

    IF v_met THEN
      INSERT INTO user_achievements (user_id, company_id, achievement_id)
      VALUES (p_user_id, p_company_id, r.id)
      ON CONFLICT (user_id, company_id, achievement_id) DO NOTHING;

      PERFORM add_xp(
        p_user_id, p_company_id,
        CASE r.rarity
          WHEN 'common' THEN 50
          WHEN 'rare' THEN 100
          WHEN 'epic' THEN 200
          WHEN 'legendary' THEN 500
          WHEN 'mythic' THEN 1000
          ELSE 50
        END,
        1.0, 'achievement', r.id::TEXT, 'Thành tựu: ' || r.name
      );

      RETURN QUERY SELECT r.code, r.name, r.rarity, true;
    END IF;
  END LOOP;
END;
$$;

-- Achievement condition helpers

CREATE OR REPLACE FUNCTION _ach_quest_complete(p_uid UUID, p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM quest_progress qp
    JOIN quest_definitions qd ON qp.quest_id = qd.id
    WHERE qp.user_id = p_uid AND qp.company_id = p_cid
      AND qp.status = 'completed'
      AND qd.code = p_cond->>'quest_code'
  );
END;
$$;

CREATE OR REPLACE FUNCTION _ach_streak(p_uid UUID, p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_days INT;
  v_type TEXT;
  v_profile ceo_profiles%ROWTYPE;
  v_combo_streak INT;
BEGIN
  v_days := (p_cond->>'days')::INT;
  v_type := p_cond->>'type';

  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_uid AND company_id = p_cid;

  IF v_type = 'daily_login' THEN
    RETURN COALESCE(v_profile.streak_days, 0) >= v_days
        OR COALESCE(v_profile.longest_streak, 0) >= v_days;
  ELSIF v_type = 'daily_combo' THEN
    SELECT count(*) INTO v_combo_streak
    FROM daily_quest_log
    WHERE user_id = p_uid AND company_id = p_cid
      AND combo_completed = true
      AND log_date >= CURRENT_DATE - v_days;
    RETURN v_combo_streak >= v_days;
  END IF;

  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_order_speed(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_max_hours INT;
BEGIN
  v_max_hours := (p_cond->>'max_hours')::INT;

  RETURN EXISTS (
    SELECT 1 FROM sales_orders
    WHERE company_id = p_cid
      AND status = 'completed'
      AND EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600 < v_max_hours
  );
EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_early_login(p_uid UUID, p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_start INT;
  v_end INT;
  v_days INT;
  v_count INT;
BEGIN
  v_start := (p_cond->>'start_hour')::INT;
  v_end := (p_cond->>'end_hour')::INT;
  v_days := (p_cond->>'days')::INT;

  SELECT count(*) INTO v_count
  FROM daily_quest_log
  WHERE user_id = p_uid AND company_id = p_cid
    AND logged_in = true
    AND log_date >= CURRENT_DATE - v_days;

  RETURN v_count >= v_days;
EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_zero_complaints(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_days INT;
  v_count INT;
BEGIN
  v_days := (p_cond->>'days')::INT;

  BEGIN
    SELECT count(*) INTO v_count
    FROM customer_complaints
    WHERE company_id = p_cid
      AND created_at >= CURRENT_DATE - v_days;
  EXCEPTION WHEN OTHERS THEN
    v_count := 0;
  END;

  RETURN v_count = 0;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_business_types(p_uid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_min INT;
  v_count INT;
BEGIN
  v_min := (p_cond->>'min_types')::INT;

  SELECT count(DISTINCT c.business_type) INTO v_count
  FROM companies c
  JOIN ceo_profiles cp ON cp.company_id = c.id
  WHERE cp.user_id = p_uid;

  RETURN v_count >= v_min;
EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_leaderboard_rank(p_uid UUID, p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_rank INT;
  v_target_rank INT;
BEGIN
  v_target_rank := (p_cond->>'rank')::INT;

  SELECT rank INTO v_rank FROM (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY total_xp DESC) as rank
    FROM ceo_profiles WHERE company_id = p_cid
  ) sub WHERE user_id = p_uid;

  RETURN COALESCE(v_rank, 999) <= v_target_rank;
EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_action_time(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_start INT;
  v_end INT;
BEGIN
  v_start := (p_cond->>'start_hour')::INT;
  v_end := (p_cond->>'end_hour')::INT;

  BEGIN
    RETURN EXISTS (
      SELECT 1 FROM sales_orders
      WHERE company_id = p_cid
        AND EXTRACT(HOUR FROM created_at) >= v_start
        AND EXTRACT(HOUR FROM created_at) < v_end
    );
  EXCEPTION WHEN OTHERS THEN
    RETURN false;
  END;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_daily_action_count(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_count_target INT;
  v_actual INT;
BEGIN
  v_count_target := (p_cond->>'count')::INT;

  BEGIN
    SELECT count(*) INTO v_actual
    FROM tasks
    WHERE company_id = p_cid
      AND status = 'completed'
      AND updated_at::DATE = CURRENT_DATE;
  EXCEPTION WHEN OTHERS THEN
    v_actual := 0;
  END;

  RETURN v_actual >= v_count_target;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_financial_recovery(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_staff_level(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_min_level INT;
  v_count_target INT;
  v_actual INT;
BEGIN
  v_min_level := COALESCE((p_cond->>'min_level')::INT, 5);
  v_count_target := COALESCE((p_cond->>'min_staff')::INT, 1);

  SELECT count(*) INTO v_actual
  FROM employee_game_profiles
  WHERE company_id = p_cid AND level >= v_min_level;

  RETURN v_actual >= v_count_target;
EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION _ach_employee_count(p_cid UUID, p_cond JSONB)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_min INT;
  v_actual INT;
BEGIN
  v_min := COALESCE((p_cond->>'min_count')::INT, 1);

  SELECT count(*) INTO v_actual
  FROM employees WHERE company_id = p_cid AND is_active = true;

  RETURN v_actual >= v_min;
END;
$$;

-- ============================================================
-- 2. STAFF GAMIFICATION: Employee Game Profiles
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_game_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  level INT NOT NULL DEFAULT 1,
  total_xp BIGINT NOT NULL DEFAULT 0,
  current_title TEXT NOT NULL DEFAULT 'Tân Binh',

  attendance_score NUMERIC(5,2) NOT NULL DEFAULT 0,
  task_score NUMERIC(5,2) NOT NULL DEFAULT 0,
  punctuality_score NUMERIC(5,2) NOT NULL DEFAULT 0,
  overall_rating NUMERIC(5,2) NOT NULL DEFAULT 0,

  streak_days INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_checkin_date DATE,

  badges TEXT[] DEFAULT '{}',
  monthly_xp INT NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, company_id)
);

CREATE INDEX IF NOT EXISTS idx_egp_company ON employee_game_profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_egp_level ON employee_game_profiles(company_id, level DESC);

ALTER TABLE employee_game_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "egp_read" ON employee_game_profiles FOR SELECT USING (true);
CREATE POLICY "egp_insert" ON employee_game_profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "egp_update" ON employee_game_profiles FOR UPDATE USING (true);

CREATE TRIGGER update_egp_updated_at
  BEFORE UPDATE ON employee_game_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Staff level titles
CREATE OR REPLACE FUNCTION staff_title_for_level(p_level INT)
RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  IF p_level >= 50 THEN RETURN 'Huyền Thoại';
  ELSIF p_level >= 40 THEN RETURN 'Kim Cương';
  ELSIF p_level >= 30 THEN RETURN 'Bạch Kim';
  ELSIF p_level >= 20 THEN RETURN 'Vàng';
  ELSIF p_level >= 15 THEN RETURN 'Bạc';
  ELSIF p_level >= 10 THEN RETURN 'Đồng';
  ELSIF p_level >= 5 THEN RETURN 'Sắt';
  ELSE RETURN 'Tân Binh';
  END IF;
END;
$$;

-- Staff XP formula (simpler than CEO)
CREATE OR REPLACE FUNCTION staff_xp_for_level(p_level INT)
RETURNS INT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  RETURN (50 * p_level * p_level);
END;
$$;

-- ============================================================
-- 3. STAFF PERFORMANCE AUTO-SCORING
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_employee_scores(
  p_company_id UUID,
  p_period_start DATE DEFAULT NULL,
  p_period_end DATE DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_start DATE;
  v_end DATE;
  r RECORD;
  v_total_workdays INT;
  v_attended INT;
  v_on_time INT;
  v_tasks_assigned INT;
  v_tasks_completed INT;
  v_att_score NUMERIC;
  v_task_score NUMERIC;
  v_punct_score NUMERIC;
  v_overall NUMERIC;
  v_xp_earned INT;
  v_new_total_xp BIGINT;
  v_new_level INT;
BEGIN
  v_start := COALESCE(p_period_start, date_trunc('month', CURRENT_DATE)::DATE);
  v_end := COALESCE(p_period_end, CURRENT_DATE);
  v_total_workdays := GREATEST(1, v_end - v_start);

  FOR r IN
    SELECT id FROM employees
    WHERE company_id = p_company_id AND is_active = true AND role != 'ceo'
  LOOP
    -- Attendance score (0-100)
    SELECT count(*) INTO v_attended
    FROM attendance
    WHERE employee_id = r.id AND company_id = p_company_id
      AND date BETWEEN v_start AND v_end
      AND check_in IS NOT NULL;

    v_att_score := LEAST(100.0, (v_attended::NUMERIC / v_total_workdays) * 100);

    -- Punctuality score (0-100): arrived on time
    SELECT count(*) INTO v_on_time
    FROM attendance
    WHERE employee_id = r.id AND company_id = p_company_id
      AND date BETWEEN v_start AND v_end
      AND check_in IS NOT NULL
      AND is_late = false;

    v_punct_score := CASE WHEN v_attended > 0
      THEN LEAST(100.0, (v_on_time::NUMERIC / v_attended) * 100)
      ELSE 0 END;

    -- Task score (0-100)
    SELECT count(*) INTO v_tasks_assigned
    FROM tasks
    WHERE assigned_to = r.id AND company_id = p_company_id
      AND created_at::DATE BETWEEN v_start AND v_end;

    SELECT count(*) INTO v_tasks_completed
    FROM tasks
    WHERE assigned_to = r.id AND company_id = p_company_id
      AND created_at::DATE BETWEEN v_start AND v_end
      AND status = 'completed';

    v_task_score := CASE WHEN v_tasks_assigned > 0
      THEN LEAST(100.0, (v_tasks_completed::NUMERIC / v_tasks_assigned) * 100)
      ELSE 50 END;

    -- Overall: weighted average
    v_overall := (v_att_score * 0.35) + (v_task_score * 0.35) + (v_punct_score * 0.30);

    -- Calculate XP from performance
    v_xp_earned := (v_overall * 0.5)::INT + (v_tasks_completed * 5);

    -- Upsert employee game profile
    INSERT INTO employee_game_profiles (employee_id, company_id)
    VALUES (r.id, p_company_id)
    ON CONFLICT (employee_id, company_id) DO NOTHING;

    -- Update scores and XP
    UPDATE employee_game_profiles SET
      attendance_score = v_att_score,
      task_score = v_task_score,
      punctuality_score = v_punct_score,
      overall_rating = v_overall,
      monthly_xp = v_xp_earned,
      total_xp = total_xp + v_xp_earned
    WHERE employee_id = r.id AND company_id = p_company_id;

    -- Recalculate level
    SELECT total_xp INTO v_new_total_xp
    FROM employee_game_profiles
    WHERE employee_id = r.id AND company_id = p_company_id;

    v_new_level := 1;
    WHILE staff_xp_for_level(v_new_level + 1) <= v_new_total_xp LOOP
      v_new_level := v_new_level + 1;
    END LOOP;

    UPDATE employee_game_profiles SET
      level = v_new_level,
      current_title = staff_title_for_level(v_new_level)
    WHERE employee_id = r.id AND company_id = p_company_id;
  END LOOP;
END;
$$;

-- Track employee attendance streaks
CREATE OR REPLACE FUNCTION update_employee_streak()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_last DATE;
  v_streak INT;
  v_longest INT;
BEGIN
  IF NEW.check_in IS NULL THEN RETURN NEW; END IF;

  SELECT last_checkin_date, streak_days, longest_streak
  INTO v_last, v_streak, v_longest
  FROM employee_game_profiles
  WHERE employee_id = NEW.employee_id AND company_id = NEW.company_id;

  IF NOT FOUND THEN
    INSERT INTO employee_game_profiles (employee_id, company_id, streak_days, longest_streak, last_checkin_date)
    VALUES (NEW.employee_id, NEW.company_id, 1, 1, NEW.date);
    RETURN NEW;
  END IF;

  IF v_last IS NULL OR NEW.date > v_last THEN
    IF v_last = NEW.date - 1 THEN
      v_streak := v_streak + 1;
    ELSIF v_last < NEW.date - 1 THEN
      v_streak := 1;
    END IF;

    v_longest := GREATEST(v_longest, v_streak);

    UPDATE employee_game_profiles SET
      streak_days = v_streak,
      longest_streak = v_longest,
      last_checkin_date = NEW.date
    WHERE employee_id = NEW.employee_id AND company_id = NEW.company_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_employee_attendance_streak
  AFTER INSERT OR UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION update_employee_streak();

-- ============================================================
-- 4. BUSINESS HEALTH SCORE — Real calculation
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_business_health(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
  v_att_pct NUMERIC := 0;
  v_task_pct NUMERIC := 0;
  v_revenue_trend NUMERIC := 0;
  v_overdue_pct NUMERIC := 0;
  v_total_emp INT;
  v_checked_today INT;
  v_total_tasks INT;
  v_completed_tasks INT;
  v_overdue_tasks INT;
  v_health NUMERIC;
BEGIN
  -- 1. Attendance rate (today) — 30% weight
  SELECT count(*) INTO v_total_emp
  FROM employees WHERE company_id = p_company_id AND is_active = true AND role != 'ceo';

  IF v_total_emp > 0 THEN
    SELECT count(DISTINCT employee_id) INTO v_checked_today
    FROM attendance
    WHERE company_id = p_company_id AND date = CURRENT_DATE AND check_in IS NOT NULL;

    v_att_pct := LEAST(100, (v_checked_today::NUMERIC / v_total_emp) * 100);
  ELSE
    v_att_pct := 50;
  END IF;

  -- 2. Task completion rate (last 30 days) — 30% weight
  SELECT count(*) INTO v_total_tasks
  FROM tasks
  WHERE company_id = p_company_id
    AND created_at >= CURRENT_DATE - 30;

  IF v_total_tasks > 0 THEN
    SELECT count(*) INTO v_completed_tasks
    FROM tasks
    WHERE company_id = p_company_id
      AND created_at >= CURRENT_DATE - 30
      AND status = 'completed';

    v_task_pct := LEAST(100, (v_completed_tasks::NUMERIC / v_total_tasks) * 100);
  ELSE
    v_task_pct := 50;
  END IF;

  -- 3. Overdue penalty — 20% weight (inverse: fewer overdue = higher score)
  SELECT count(*) INTO v_overdue_tasks
  FROM tasks
  WHERE company_id = p_company_id
    AND status NOT IN ('completed', 'cancelled')
    AND due_date < CURRENT_DATE;

  v_overdue_pct := CASE WHEN v_total_tasks > 0
    THEN GREATEST(0, 100 - (v_overdue_tasks::NUMERIC / GREATEST(1, v_total_tasks) * 200))
    ELSE 70 END;

  -- 4. Activity level (orders/sessions in last 7 days) — 20% weight
  BEGIN
    DECLARE v_activity INT;
    BEGIN
      SELECT count(*) INTO v_activity FROM sales_orders
      WHERE company_id = p_company_id AND created_at >= CURRENT_DATE - 7;
      v_revenue_trend := LEAST(100, v_activity * 10);
    EXCEPTION WHEN OTHERS THEN
      BEGIN
        SELECT count(*) INTO v_activity FROM table_sessions
        WHERE company_id = p_company_id AND created_at >= CURRENT_DATE - 7;
        v_revenue_trend := LEAST(100, v_activity * 5);
      EXCEPTION WHEN OTHERS THEN
        v_revenue_trend := 50;
      END;
    END;
  END;

  -- Weighted health score
  v_health := (v_att_pct * 0.30) + (v_task_pct * 0.30) + (v_overdue_pct * 0.20) + (v_revenue_trend * 0.20);
  v_health := LEAST(100, GREATEST(0, v_health));

  -- Update CEO profile
  UPDATE ceo_profiles SET business_health_score = v_health
  WHERE user_id = p_user_id AND company_id = p_company_id;

  RETURN v_health;
END;
$$;

-- ============================================================
-- 5. ADDITIONAL ACHIEVEMENTS for Staff + Health
-- ============================================================

INSERT INTO achievements (code, name, description, icon, rarity, category, condition_type, condition_value, is_secret, sort_order)
VALUES
('team_builder', 'Xây Dựng Đội', '5+ nhân viên active', 'star', 'common', 'operate',
 'employee_count', '{"min_count": 5}', false, 4),

('army', 'Đạo Quân', '20+ nhân viên active', 'shield', 'rare', 'operate',
 'employee_count', '{"min_count": 20}', false, 12),

('elite_team', 'Đội Tinh Nhuệ', '3+ nhân viên đạt level 10', 'diamond', 'epic', 'operate',
 'staff_level', '{"min_level": 10, "min_staff": 3}', false, 23),

('legend_squad', 'Biệt Đội Huyền Thoại', '1 nhân viên đạt level 30+', 'crown', 'legendary', 'operate',
 'staff_level', '{"min_level": 30, "min_staff": 1}', false, 32),

('perfectionist', 'Người Hoàn Hảo', 'Business Health Score 95+ liên tục 7 ngày', 'target', 'epic', 'general',
 'health_streak', '{"min_score": 95, "days": 7}', true, 53),

('comeback', 'Trở Lại Ngoạn Mục', 'Health Score từ <30 lên >80 trong 14 ngày', 'phoenix', 'legendary', 'general',
 'health_recovery', '{"from_max": 30, "to_min": 80, "days": 14}', true, 54)

ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 6. STAFF LEADERBOARD VIEW
-- ============================================================

CREATE OR REPLACE FUNCTION get_staff_leaderboard(
  p_company_id UUID,
  p_limit INT DEFAULT 20
)
RETURNS TABLE(
  rank BIGINT,
  employee_id UUID,
  full_name TEXT,
  level INT,
  total_xp BIGINT,
  current_title TEXT,
  attendance_score NUMERIC,
  task_score NUMERIC,
  overall_rating NUMERIC,
  streak_days INT
) LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY egp.total_xp DESC) as rank,
    egp.employee_id,
    e.full_name,
    egp.level,
    egp.total_xp,
    egp.current_title,
    egp.attendance_score,
    egp.task_score,
    egp.overall_rating,
    egp.streak_days
  FROM employee_game_profiles egp
  JOIN employees e ON egp.employee_id = e.id
  WHERE egp.company_id = p_company_id
  ORDER BY egp.total_xp DESC
  LIMIT p_limit;
END;
$$;
