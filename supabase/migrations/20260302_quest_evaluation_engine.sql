-- ============================================================
-- SABOHUB RPG — Phase 2: Quest Auto-Evaluation Engine
-- Triggers + Functions that connect gamification to real data
-- ============================================================

-- ============================================================
-- CORE: Evaluate all active quests for a user
-- Called by triggers when business data changes
-- ============================================================

CREATE OR REPLACE FUNCTION evaluate_user_quests(
  p_user_id UUID,
  p_company_id UUID,
  p_event_type TEXT DEFAULT 'generic'
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  r RECORD;
  v_count INT;
  v_met BOOLEAN;
  v_target INT;
BEGIN
  FOR r IN
    SELECT qp.id AS progress_id, qp.quest_id, qp.progress_current, qp.progress_target,
           qd.code, qd.conditions, qd.xp_reward, qd.reputation_reward,
           qd.badge_reward, qd.name AS quest_name
    FROM quest_progress qp
    JOIN quest_definitions qd ON qp.quest_id = qd.id
    WHERE qp.user_id = p_user_id
      AND qp.company_id = p_company_id
      AND qp.status IN ('available', 'in_progress')
  LOOP
    v_met := false;
    v_count := 0;
    v_target := r.progress_target;

    -- Evaluate based on condition type
    CASE (r.conditions->>'type')

      WHEN 'count' THEN
        v_target := COALESCE((r.conditions->>'value')::INT, 1);
        v_count := _eval_count_condition(r.conditions, p_company_id);
        v_met := v_count >= v_target;

      WHEN 'exists' THEN
        v_count := _eval_exists_condition(r.conditions, p_company_id);
        v_target := 1;
        v_met := v_count >= 1;

      WHEN 'compound' THEN
        v_met := _eval_compound_condition(r.conditions, p_company_id);
        IF v_met THEN v_count := 1; v_target := 1; END IF;

      WHEN 'attendance_full_day' THEN
        v_met := _eval_attendance_full_day(p_company_id);
        IF v_met THEN v_count := 1; v_target := 1; END IF;

      ELSE
        CONTINUE;
    END CASE;

    -- Update progress
    IF v_count > r.progress_current OR v_met THEN
      UPDATE quest_progress SET
        progress_current = LEAST(v_count, v_target),
        progress_target = v_target,
        status = CASE WHEN v_met THEN 'completed' ELSE 'in_progress' END,
        started_at = COALESCE(started_at, now()),
        completed_at = CASE WHEN v_met THEN now() ELSE NULL END
      WHERE id = r.progress_id;

      -- If quest just completed, grant rewards
      IF v_met AND r.progress_current < v_target THEN
        PERFORM add_xp(p_user_id, p_company_id, r.xp_reward, 1.0, 'quest', r.quest_id::TEXT, 'Hoàn thành: ' || r.quest_name);

        IF r.reputation_reward > 0 THEN
          UPDATE ceo_profiles SET reputation_points = reputation_points + r.reputation_reward
          WHERE user_id = p_user_id AND company_id = p_company_id;
        END IF;

        -- Record in daily log
        UPDATE daily_quest_log SET
          quests_completed = array_append(quests_completed, r.code),
          xp_earned = xp_earned + r.xp_reward
        WHERE user_id = p_user_id AND company_id = p_company_id AND log_date = CURRENT_DATE;

        -- Unlock next quests
        PERFORM _unlock_next_quests(p_user_id, p_company_id);
      END IF;
    END IF;
  END LOOP;

  -- Check daily combo
  PERFORM _check_daily_combo(p_user_id, p_company_id);
END;
$$;

-- ============================================================
-- HELPER: Count-based condition evaluator
-- ============================================================

CREATE OR REPLACE FUNCTION _eval_count_condition(
  p_conditions JSONB,
  p_company_id UUID
)
RETURNS INT LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_table TEXT;
  v_count INT := 0;
  v_filter JSONB;
  v_sql TEXT;
BEGIN
  v_table := p_conditions->>'table';
  v_filter := p_conditions->'filter';

  IF v_table IS NULL THEN RETURN 0; END IF;

  -- Build dynamic count query with company filter
  v_sql := format('SELECT count(*) FROM %I WHERE company_id = $1', v_table);

  -- Add filters
  IF v_filter IS NOT NULL THEN
    IF v_filter->>'status' IS NOT NULL THEN
      v_sql := v_sql || format(' AND status = %L', v_filter->>'status');
    END IF;
    IF v_filter->>'is_active' IS NOT NULL THEN
      v_sql := v_sql || format(' AND is_active = %L', (v_filter->>'is_active')::BOOLEAN);
    END IF;
    IF (v_filter->>'department') = 'not_null' THEN
      v_sql := v_sql || ' AND department IS NOT NULL';
    END IF;
    IF (v_filter->>'role') = 'not_null' THEN
      v_sql := v_sql || ' AND role IS NOT NULL';
    END IF;
  END IF;

  EXECUTE v_sql INTO v_count USING p_company_id;
  RETURN COALESCE(v_count, 0);

EXCEPTION WHEN OTHERS THEN
  RETURN 0;
END;
$$;

-- ============================================================
-- HELPER: Exists condition evaluator
-- ============================================================

CREATE OR REPLACE FUNCTION _eval_exists_condition(
  p_conditions JSONB,
  p_company_id UUID
)
RETURNS INT LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_table TEXT;
  v_count INT := 0;
BEGIN
  v_table := p_conditions->>'table';
  IF v_table IS NULL THEN RETURN 0; END IF;

  EXECUTE format('SELECT count(*) FROM %I WHERE company_id = $1', v_table)
  INTO v_count USING p_company_id;

  RETURN COALESCE(v_count, 0);

EXCEPTION WHEN OTHERS THEN
  RETURN 0;
END;
$$;

-- ============================================================
-- HELPER: Compound (ALL) condition evaluator
-- ============================================================

CREATE OR REPLACE FUNCTION _eval_compound_condition(
  p_conditions JSONB,
  p_company_id UUID
)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_sub JSONB;
  v_count INT;
  v_target INT;
BEGIN
  IF p_conditions->'all' IS NOT NULL THEN
    FOR v_sub IN SELECT * FROM jsonb_array_elements(p_conditions->'all')
    LOOP
      v_target := COALESCE((v_sub->>'value')::INT, 1);
      v_count := _eval_count_condition(v_sub, p_company_id);
      IF v_count < v_target THEN RETURN false; END IF;
    END LOOP;
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

-- ============================================================
-- HELPER: Full day attendance check
-- ============================================================

CREATE OR REPLACE FUNCTION _eval_attendance_full_day(p_company_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_total_employees INT;
  v_checked_in INT;
BEGIN
  SELECT count(*) INTO v_total_employees
  FROM employees WHERE company_id = p_company_id AND is_active = true;

  IF v_total_employees = 0 THEN RETURN false; END IF;

  SELECT count(DISTINCT employee_id) INTO v_checked_in
  FROM attendance
  WHERE company_id = p_company_id
    AND date = CURRENT_DATE
    AND check_in IS NOT NULL;

  RETURN v_checked_in >= v_total_employees;

EXCEPTION WHEN OTHERS THEN
  RETURN false;
END;
$$;

-- ============================================================
-- HELPER: Unlock next quests after completion
-- ============================================================

CREATE OR REPLACE FUNCTION _unlock_next_quests(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_completed_codes TEXT[];
  r RECORD;
  v_prereqs TEXT[];
  v_all_met BOOLEAN;
BEGIN
  SELECT array_agg(qd.code)
  INTO v_completed_codes
  FROM quest_progress qp
  JOIN quest_definitions qd ON qp.quest_id = qd.id
  WHERE qp.user_id = p_user_id
    AND qp.company_id = p_company_id
    AND qp.status = 'completed';

  IF v_completed_codes IS NULL THEN v_completed_codes := '{}'; END IF;

  FOR r IN
    SELECT qp.id, qd.prerequisites
    FROM quest_progress qp
    JOIN quest_definitions qd ON qp.quest_id = qd.id
    WHERE qp.user_id = p_user_id
      AND qp.company_id = p_company_id
      AND qp.status = 'locked'
      AND qd.prerequisites IS NOT NULL
      AND array_length(qd.prerequisites, 1) > 0
  LOOP
    v_all_met := true;
    FOREACH v_prereqs SLICE 0 IN ARRAY r.prerequisites LOOP
      -- Check each prerequisite code
    END LOOP;

    v_all_met := r.prerequisites <@ v_completed_codes;

    IF v_all_met THEN
      UPDATE quest_progress SET status = 'available' WHERE id = r.id;
    END IF;
  END LOOP;
END;
$$;

-- ============================================================
-- DAILY QUEST EVALUATION
-- Called once per day or on-demand to check daily quests
-- ============================================================

CREATE OR REPLACE FUNCTION evaluate_daily_quests(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(quest_code TEXT, is_completed BOOLEAN, xp_reward INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_log daily_quest_log%ROWTYPE;
  v_total_employees INT;
  v_checked_in INT;
  v_overdue_tasks INT;
  v_orders_today INT;
  v_payments_today INT;
  v_logged_in BOOLEAN;
  v_completed TEXT[];
  v_xp INT := 0;
  v_combo BOOLEAN;
  v_streak INT;
BEGIN
  -- Ensure daily log exists
  INSERT INTO daily_quest_log (user_id, company_id, log_date)
  VALUES (p_user_id, p_company_id, v_today)
  ON CONFLICT (user_id, company_id, log_date) DO NOTHING;

  SELECT * INTO v_log FROM daily_quest_log
  WHERE user_id = p_user_id AND company_id = p_company_id AND log_date = v_today;

  v_completed := COALESCE(v_log.quests_completed, '{}');

  -- 1. Điểm Danh Hoàn Hảo (attendance)
  SELECT count(*) INTO v_total_employees
  FROM employees WHERE company_id = p_company_id AND is_active = true AND role != 'ceo';

  SELECT count(DISTINCT employee_id) INTO v_checked_in
  FROM attendance
  WHERE company_id = p_company_id AND date = v_today AND check_in IS NOT NULL;

  IF v_total_employees > 0 AND v_checked_in >= v_total_employees AND NOT ('attendance' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'attendance');
    v_xp := v_xp + 20;
    RETURN QUERY SELECT 'attendance'::TEXT, true, 20;
  ELSE
    RETURN QUERY SELECT 'attendance'::TEXT, ('attendance' = ANY(v_completed)), 0;
  END IF;

  -- 2. Không Ai Bỏ Lại (0 overdue tasks)
  SELECT count(*) INTO v_overdue_tasks
  FROM tasks
  WHERE company_id = p_company_id
    AND status NOT IN ('completed', 'cancelled')
    AND due_date < v_today;

  IF v_overdue_tasks = 0 AND NOT ('tasks' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'tasks');
    v_xp := v_xp + 20;
    RETURN QUERY SELECT 'tasks'::TEXT, true, 20;
  ELSE
    RETURN QUERY SELECT 'tasks'::TEXT, ('tasks' = ANY(v_completed)), 0;
  END IF;

  -- 3. Nhà Buôn Cần Mẫn (>=3 orders today)
  BEGIN
    SELECT count(*) INTO v_orders_today
    FROM sales_orders
    WHERE company_id = p_company_id AND created_at::DATE = v_today;
  EXCEPTION WHEN OTHERS THEN
    v_orders_today := 0;
  END;

  IF v_orders_today >= 3 AND NOT ('orders' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'orders');
    v_xp := v_xp + 25;
    RETURN QUERY SELECT 'orders'::TEXT, true, 25;
  ELSE
    RETURN QUERY SELECT 'orders'::TEXT, ('orders' = ANY(v_completed)), 0;
  END IF;

  -- 4. Thu Tiền Đúng Hạn (>=1 payment today)
  BEGIN
    SELECT count(*) INTO v_payments_today
    FROM payments
    WHERE created_at::DATE = v_today;
  EXCEPTION WHEN OTHERS THEN
    v_payments_today := 0;
  END;

  IF v_payments_today >= 1 AND NOT ('payment' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'payment');
    v_xp := v_xp + 15;
    RETURN QUERY SELECT 'payment'::TEXT, true, 15;
  ELSE
    RETURN QUERY SELECT 'payment'::TEXT, ('payment' = ANY(v_completed)), 0;
  END IF;

  -- 5. CEO Có Tâm (logged in today) — always true if this function runs
  IF v_log.logged_in AND NOT ('login' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'login');
    v_xp := v_xp + 10;
    RETURN QUERY SELECT 'login'::TEXT, true, 10;
  ELSE
    RETURN QUERY SELECT 'login'::TEXT, ('login' = ANY(v_completed)), 0;
  END IF;

  -- Check combo (all 5 completed)
  v_combo := array_length(v_completed, 1) >= 5;

  -- Update daily log
  UPDATE daily_quest_log SET
    quests_completed = v_completed,
    combo_completed = v_combo,
    xp_earned = v_log.xp_earned + v_xp
  WHERE user_id = p_user_id AND company_id = p_company_id AND log_date = v_today;

  -- Grant XP for newly completed daily quests
  IF v_xp > 0 THEN
    PERFORM add_xp(p_user_id, p_company_id, v_xp, 1.0, 'daily', NULL, 'Daily quests');
  END IF;

  -- Combo bonus
  IF v_combo AND NOT v_log.combo_completed THEN
    PERFORM add_xp(p_user_id, p_company_id, 50, 1.0, 'daily', 'combo', 'Daily Combo bonus!');
  END IF;
END;
$$;

-- ============================================================
-- HELPER: Check daily combo completion
-- ============================================================

CREATE OR REPLACE FUNCTION _check_daily_combo(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_log daily_quest_log%ROWTYPE;
BEGIN
  SELECT * INTO v_log FROM daily_quest_log
  WHERE user_id = p_user_id AND company_id = p_company_id AND log_date = CURRENT_DATE;

  IF v_log IS NULL THEN RETURN; END IF;

  IF array_length(v_log.quests_completed, 1) >= 5 AND NOT v_log.combo_completed THEN
    UPDATE daily_quest_log SET combo_completed = true
    WHERE id = v_log.id;

    PERFORM add_xp(p_user_id, p_company_id, 50, 1.0, 'daily', 'combo', 'Daily Combo bonus!');
  END IF;
END;
$$;

-- ============================================================
-- STREAK FREEZE
-- ============================================================

CREATE OR REPLACE FUNCTION use_streak_freeze(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(success BOOLEAN, remaining INT, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN
    RETURN QUERY SELECT false, 0, 'Profile not found'::TEXT;
    RETURN;
  END IF;

  IF v_profile.streak_freeze_remaining <= 0 THEN
    RETURN QUERY SELECT false, 0, 'Không còn Streak Freeze'::TEXT;
    RETURN;
  END IF;

  UPDATE ceo_profiles SET
    streak_freeze_remaining = streak_freeze_remaining - 1
  WHERE user_id = p_user_id AND company_id = p_company_id;

  RETURN QUERY SELECT true, v_profile.streak_freeze_remaining - 1, 'Streak Freeze đã kích hoạt!'::TEXT;
END;
$$;

-- Refill streak freeze monthly (1 freeze per month)
CREATE OR REPLACE FUNCTION refill_streak_freeze()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE ceo_profiles SET streak_freeze_remaining = 1
  WHERE streak_freeze_remaining < 1;
END;
$$;

-- ============================================================
-- TRIGGERS: Auto-evaluate quests on business events
-- ============================================================

-- Trigger function for generic table changes
CREATE OR REPLACE FUNCTION trg_quest_evaluate()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_company_id UUID;
  v_user RECORD;
BEGIN
  -- Get company_id from the changed row
  v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  IF v_company_id IS NULL THEN RETURN COALESCE(NEW, OLD); END IF;

  -- Evaluate quests for all CEO profiles in this company
  FOR v_user IN
    SELECT user_id FROM ceo_profiles WHERE company_id = v_company_id
  LOOP
    PERFORM evaluate_user_quests(v_user.user_id, v_company_id, TG_TABLE_NAME);
  END LOOP;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger on employees table (for recruiting quests)
CREATE TRIGGER trg_employees_quest_eval
  AFTER INSERT OR UPDATE ON employees
  FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate();

-- Trigger on branches table (for expansion quests)
CREATE TRIGGER trg_branches_quest_eval
  AFTER INSERT ON branches
  FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate();

-- Trigger on tasks table (for task quests)
CREATE TRIGGER trg_tasks_quest_eval
  AFTER INSERT OR UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate();

-- Trigger on attendance table (for attendance quests)
CREATE TRIGGER trg_attendance_quest_eval
  AFTER INSERT OR UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate();

-- Conditional triggers for business-type specific tables
DO $$
BEGIN
  -- Sales orders (distribution)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sales_orders' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_sales_orders_quest_eval AFTER INSERT OR UPDATE ON sales_orders FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Customers (distribution)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_customers_quest_eval AFTER INSERT ON customers FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Deliveries (distribution)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'deliveries' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_deliveries_quest_eval AFTER UPDATE ON deliveries FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Warehouses
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warehouses' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_warehouses_quest_eval AFTER INSERT ON warehouses FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Products
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_products_quest_eval AFTER INSERT ON products FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Tables (entertainment)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tables' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_tables_quest_eval AFTER INSERT ON tables FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Table sessions (entertainment)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'table_sessions' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_sessions_quest_eval AFTER UPDATE ON table_sessions FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;

  -- Payments
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments' AND table_schema = 'public') THEN
    EXECUTE 'CREATE TRIGGER trg_payments_quest_eval AFTER INSERT ON payments FOR EACH ROW EXECUTE FUNCTION trg_quest_evaluate()';
  END IF;
END $$;

-- ============================================================
-- WEEKLY CHALLENGE DEFINITIONS
-- ============================================================

INSERT INTO quest_definitions (code, name, description, quest_type, category, conditions, xp_reward, reputation_reward, sort_order) VALUES

('weekly_bat_bai', 'Tuần Lễ Bất Bại', '0 đơn hàng bị cancel trong tuần',
 'weekly', 'sell',
 '{"type": "weekly_zero", "table": "sales_orders", "filter": {"status": "cancelled"}, "period": "week"}',
 100, 15, 100),

('weekly_marathon', 'Marathon', '7/7 daily combo trong tuần',
 'weekly', 'operate',
 '{"type": "weekly_combo_streak", "days": 7}',
 200, 25, 101),

('weekly_mentor', 'Mentor', 'Approve 10+ tasks trong tuần',
 'weekly', 'operate',
 '{"type": "weekly_count", "table": "task_approvals", "operator": ">=", "value": 10, "period": "week"}',
 80, 10, 102),

('weekly_detective', 'Thám Tử', 'Xem tất cả báo cáo (attendance, finance, sales) trong tuần',
 'weekly', 'finance',
 '{"type": "manual", "description": "View all report types"}',
 60, 10, 103),

('weekly_communicator', 'Giao Tiếp', 'Gửi 5+ thông báo cho team trong tuần',
 'weekly', 'operate',
 '{"type": "weekly_count", "table": "notifications", "filter": {"type": "announcement"}, "operator": ">=", "value": 5, "period": "week"}',
 50, 8, 104);
