-- ============================================================
-- SABOHUB RPG — Phase 7: Adaptive Business Type Config
-- Config-driven quest system that scales to ANY business type
-- ============================================================

-- ============================================================
-- 1. BUSINESS TYPE CONFIG (abstract concept → concrete mapping)
-- ============================================================

CREATE TABLE IF NOT EXISTS business_type_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_type TEXT NOT NULL,
  concept TEXT NOT NULL,
  table_name TEXT,
  filter JSONB DEFAULT '{}',
  display_name TEXT NOT NULL,
  display_name_plural TEXT,
  icon TEXT DEFAULT 'star',
  metadata JSONB DEFAULT '{}',
  UNIQUE(business_type, concept)
);

CREATE INDEX idx_btc_type ON business_type_config(business_type);

-- ============================================================
-- 2. QUEST TEMPLATES (abstract patterns, business-agnostic)
-- ============================================================

CREATE TABLE IF NOT EXISTS quest_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name_pattern TEXT NOT NULL,
  description_pattern TEXT NOT NULL,
  quest_type TEXT NOT NULL CHECK (quest_type IN ('main', 'daily', 'weekly', 'boss')),
  category TEXT CHECK (category IN ('operate', 'sell', 'finance')),
  concept TEXT NOT NULL,
  condition_pattern JSONB NOT NULL,
  xp_reward INT NOT NULL DEFAULT 20,
  reputation_reward INT NOT NULL DEFAULT 0,
  threshold_curve JSONB DEFAULT '{"beginner": 1, "intermediate": 3, "advanced": 5}',
  act INT,
  sort_order INT NOT NULL DEFAULT 0,
  is_universal BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- ============================================================
-- 3. SEED BUSINESS TYPE CONFIGS
-- ============================================================

-- ---- DISTRIBUTION ----
INSERT INTO business_type_config (business_type, concept, table_name, filter, display_name, display_name_plural, icon, metadata) VALUES
('distribution', 'primary_transaction', 'sales_orders', '{"status": "completed"}', 'đơn hàng', 'đơn hàng', 'package', '{}'),
('distribution', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('distribution', 'inventory_object', 'products', '{}', 'sản phẩm', 'sản phẩm', 'inventory', '{}'),
('distribution', 'customer_object', 'customers', '{}', 'khách hàng', 'khách hàng', 'people', '{}'),
('distribution', 'delivery_object', 'deliveries', '{"status": "completed"}', 'đơn giao', 'đơn giao', 'truck', '{}'),
('distribution', 'workspace_object', 'warehouses', '{}', 'kho', 'kho', 'warehouse', '{}'),
('distribution', 'peak_hours', NULL, '{}', 'giờ làm việc', NULL, 'clock', '{"start": 8, "end": 17}'),
('distribution', 'daily_transaction_target', NULL, '{}', '3', NULL, 'target', '{"threshold": 3}'),

-- ---- BILLIARDS ----
('billiards', 'primary_transaction', 'table_sessions', '{"status": "completed"}', 'session', 'sessions', 'sports_bar', '{}'),
('billiards', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('billiards', 'inventory_object', 'menu_items', '{}', 'món/dịch vụ', 'món/dịch vụ', 'menu_book', '{}'),
('billiards', 'customer_object', 'customers', '{}', 'khách', 'khách', 'people', '{}'),
('billiards', 'workspace_object', 'tables', '{}', 'bàn', 'bàn', 'table_bar', '{}'),
('billiards', 'peak_hours', NULL, '{}', 'giờ cao điểm', NULL, 'clock', '{"start": 18, "end": 23}'),
('billiards', 'daily_transaction_target', NULL, '{}', '5', NULL, 'target', '{"threshold": 5}'),

-- ---- RESTAURANT ----
('restaurant', 'primary_transaction', 'table_sessions', '{"status": "completed"}', 'lượt khách', 'lượt khách', 'restaurant', '{}'),
('restaurant', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('restaurant', 'inventory_object', 'menu_items', '{}', 'món ăn', 'món ăn', 'menu_book', '{}'),
('restaurant', 'customer_object', 'customers', '{}', 'khách', 'khách', 'people', '{}'),
('restaurant', 'workspace_object', 'tables', '{}', 'bàn', 'bàn', 'table_restaurant', '{}'),
('restaurant', 'peak_hours', NULL, '{}', 'giờ cao điểm', NULL, 'clock', '{"start": 11, "end": 13}'),
('restaurant', 'daily_transaction_target', NULL, '{}', '10', NULL, 'target', '{"threshold": 10}'),

-- ---- CAFE ----
('cafe', 'primary_transaction', 'table_sessions', '{"status": "completed"}', 'đơn', 'đơn', 'coffee', '{}'),
('cafe', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('cafe', 'inventory_object', 'menu_items', '{}', 'đồ uống', 'đồ uống', 'local_cafe', '{}'),
('cafe', 'customer_object', 'customers', '{}', 'khách', 'khách', 'people', '{}'),
('cafe', 'workspace_object', 'tables', '{}', 'bàn', 'bàn', 'table_bar', '{}'),
('cafe', 'peak_hours', NULL, '{}', 'giờ cao điểm', NULL, 'clock', '{"start": 7, "end": 10}'),
('cafe', 'daily_transaction_target', NULL, '{}', '15', NULL, 'target', '{"threshold": 15}'),

-- ---- HOTEL ----
('hotel', 'primary_transaction', 'table_sessions', '{"status": "completed"}', 'lượt check-in', 'lượt check-in', 'hotel', '{}'),
('hotel', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('hotel', 'inventory_object', 'menu_items', '{}', 'dịch vụ', 'dịch vụ', 'room_service', '{}'),
('hotel', 'customer_object', 'customers', '{}', 'khách', 'khách', 'people', '{}'),
('hotel', 'workspace_object', 'tables', '{}', 'phòng', 'phòng', 'meeting_room', '{}'),
('hotel', 'peak_hours', NULL, '{}', 'giờ cao điểm', NULL, 'clock', '{"start": 14, "end": 18}'),
('hotel', 'daily_transaction_target', NULL, '{}', '5', NULL, 'target', '{"threshold": 5}'),

-- ---- RETAIL ----
('retail', 'primary_transaction', 'sales_orders', '{"status": "completed"}', 'đơn bán', 'đơn bán', 'store', '{}'),
('retail', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('retail', 'inventory_object', 'products', '{}', 'sản phẩm', 'sản phẩm', 'inventory_2', '{}'),
('retail', 'customer_object', 'customers', '{}', 'khách hàng', 'khách hàng', 'people', '{}'),
('retail', 'workspace_object', 'warehouses', '{}', 'cửa hàng', 'cửa hàng', 'storefront', '{}'),
('retail', 'peak_hours', NULL, '{}', 'giờ cao điểm', NULL, 'clock', '{"start": 17, "end": 21}'),
('retail', 'daily_transaction_target', NULL, '{}', '10', NULL, 'target', '{"threshold": 10}'),

-- ---- MANUFACTURING ----
('manufacturing', 'primary_transaction', 'production_orders', '{"status": "completed"}', 'đơn sản xuất', 'đơn sản xuất', 'factory', '{}'),
('manufacturing', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('manufacturing', 'inventory_object', 'materials', '{}', 'nguyên liệu', 'nguyên liệu', 'category', '{}'),
('manufacturing', 'customer_object', 'customers', '{}', 'khách hàng', 'khách hàng', 'people', '{}'),
('manufacturing', 'workspace_object', 'warehouses', '{}', 'xưởng', 'xưởng', 'warehouse', '{}'),
('manufacturing', 'peak_hours', NULL, '{}', 'giờ sản xuất', NULL, 'clock', '{"start": 7, "end": 17}'),
('manufacturing', 'daily_transaction_target', NULL, '{}', '2', NULL, 'target', '{"threshold": 2}'),

-- ---- CORPORATION ----
('corporation', 'primary_transaction', 'tasks', '{"status": "completed"}', 'task', 'tasks', 'domain', '{}'),
('corporation', 'revenue_event', 'payments', '{}', 'thanh toán', 'thanh toán', 'payments', '{}'),
('corporation', 'inventory_object', 'products', '{}', 'sản phẩm', 'sản phẩm', 'inventory', '{}'),
('corporation', 'customer_object', 'customers', '{}', 'khách hàng', 'khách hàng', 'people', '{}'),
('corporation', 'workspace_object', 'branches', '{}', 'chi nhánh', 'chi nhánh', 'business', '{}'),
('corporation', 'peak_hours', NULL, '{}', 'giờ làm việc', NULL, 'clock', '{"start": 8, "end": 17}'),
('corporation', 'daily_transaction_target', NULL, '{}', '5', NULL, 'target', '{"threshold": 5}')

ON CONFLICT (business_type, concept) DO NOTHING;

-- ============================================================
-- 4. SEED QUEST TEMPLATES
-- ============================================================

INSERT INTO quest_templates (code, name_pattern, description_pattern, quest_type, category, concept, condition_pattern, xp_reward, reputation_reward, threshold_curve, sort_order, is_universal) VALUES

-- Daily templates (universal)
('daily_attendance', 'Điểm Danh Hoàn Hảo', '100% nhân viên điểm danh', 'daily', 'operate', 'attendance', '{"type": "attendance_full"}', 20, 2, '{}', 1, true),
('daily_tasks', 'Không Ai Bỏ Lại', '0 task quá hạn trong ngày', 'daily', 'operate', 'tasks_no_overdue', '{"type": "zero_overdue"}', 20, 2, '{}', 2, true),
('daily_transactions', 'Kinh Doanh Xuất Sắc', '{threshold}+ {display_name} trong ngày', 'daily', 'sell', 'primary_transaction', '{"type": "count", "concept": "primary_transaction", "operator": ">="}', 25, 3, '{"beginner": 1, "intermediate": 3, "advanced": 5}', 3, false),
('daily_revenue', 'Thu Tiền Đúng Hạn', '1+ {display_name} trong ngày', 'daily', 'finance', 'revenue_event', '{"type": "count", "concept": "revenue_event", "operator": ">=", "value": 1}', 15, 2, '{}', 4, false),
('daily_login', 'CEO Có Tâm', 'Đăng nhập hôm nay', 'daily', 'operate', 'login', '{"type": "login"}', 10, 1, '{}', 5, true),

-- Weekly templates
('weekly_unbeaten', 'Tuần Lễ Bất Bại', '0 {display_name} bị cancel trong tuần', 'weekly', 'sell', 'primary_transaction', '{"type": "zero_cancelled", "concept": "primary_transaction", "period": "week"}', 100, 10, '{}', 1, false),
('weekly_marathon', 'Marathon', '7/7 daily combo', 'weekly', 'operate', 'daily_combo', '{"type": "streak", "target": 7}', 200, 20, '{}', 2, true),
('weekly_mentor', 'Mentor', 'Approve 10+ tasks trong tuần', 'weekly', 'operate', 'tasks_approved', '{"type": "count", "table": "tasks", "filter": {"status": "completed"}, "operator": ">=", "value": 10, "period": "week"}', 80, 8, '{}', 3, true),

-- Main quest templates (Act II onboarding per business type)
('main_setup_workspace', 'Xây Doanh Trại', 'Setup {threshold}+ {display_name}', 'main', 'operate', 'workspace_object', '{"type": "count", "concept": "workspace_object", "operator": ">="}', 150, 20, '{"beginner": 1, "intermediate": 3, "advanced": 5}', 10, false),
('main_stock_inventory', 'Nhập Kho', 'Thêm {threshold}+ {display_name} vào hệ thống', 'main', 'operate', 'inventory_object', '{"type": "count", "concept": "inventory_object", "operator": ">="}', 150, 20, '{"beginner": 5, "intermediate": 15, "advanced": 30}', 11, false),
('main_first_customers', 'Khách Hàng Đầu Tiên', 'Thêm {threshold}+ {display_name}', 'main', 'sell', 'customer_object', '{"type": "count", "concept": "customer_object", "operator": ">="}', 150, 20, '{"beginner": 3, "intermediate": 10, "advanced": 30}', 12, false),
('main_first_transaction', 'Giao Dịch Đầu Tiên', 'Hoàn thành {display_name} đầu tiên', 'main', 'sell', 'primary_transaction', '{"type": "count", "concept": "primary_transaction", "operator": ">=", "value": 1}', 200, 25, '{}', 13, false),
('main_transaction_milestone', 'Nhà Kinh Doanh', 'Hoàn thành {threshold}+ {display_name}', 'main', 'sell', 'primary_transaction', '{"type": "count", "concept": "primary_transaction", "operator": ">="}', 300, 35, '{"beginner": 10, "intermediate": 50, "advanced": 100}', 14, false)

ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 5. CONFIG-AWARE DAILY QUEST EVALUATOR (replaces hardcoded)
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
  v_btype TEXT;
  v_completed TEXT[];
  v_xp INT := 0;
  v_combo BOOLEAN;
  v_count INT;
  v_cfg RECORD;
  v_threshold INT;
  v_total_employees INT;
  v_checked_in INT;
  v_overdue_tasks INT;
BEGIN
  -- Get company business type
  SELECT c.business_type INTO v_btype
  FROM companies c WHERE c.id = p_company_id;

  -- Ensure daily log exists
  INSERT INTO daily_quest_log (user_id, company_id, log_date)
  VALUES (p_user_id, p_company_id, v_today)
  ON CONFLICT (user_id, company_id, log_date) DO NOTHING;

  SELECT * INTO v_log FROM daily_quest_log
  WHERE user_id = p_user_id AND company_id = p_company_id AND log_date = v_today;

  v_completed := COALESCE(v_log.quests_completed, '{}');

  -- ═══════════════════════════════════════════════
  -- 1. Điểm Danh Hoàn Hảo (universal — attendance)
  -- ═══════════════════════════════════════════════
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

  -- ═══════════════════════════════════════════════
  -- 2. Không Ai Bỏ Lại (universal — 0 overdue tasks)
  -- ═══════════════════════════════════════════════
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

  -- ═══════════════════════════════════════════════
  -- 3. Kinh Doanh Xuất Sắc (config-driven — primary_transaction)
  -- ═══════════════════════════════════════════════
  SELECT * INTO v_cfg FROM business_type_config
  WHERE business_type = v_btype AND concept = 'primary_transaction';

  SELECT (metadata->>'threshold')::INT INTO v_threshold FROM business_type_config
  WHERE business_type = v_btype AND concept = 'daily_transaction_target';
  v_threshold := COALESCE(v_threshold, 3);

  IF v_cfg.table_name IS NOT NULL THEN
    BEGIN
      EXECUTE format(
        'SELECT count(*) FROM %I WHERE company_id = $1 AND created_at::DATE = $2',
        v_cfg.table_name
      ) INTO v_count USING p_company_id, v_today;
    EXCEPTION WHEN OTHERS THEN
      v_count := 0;
    END;
  ELSE
    v_count := 0;
  END IF;

  IF v_count >= v_threshold AND NOT ('orders' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'orders');
    v_xp := v_xp + 25;
    RETURN QUERY SELECT 'orders'::TEXT, true, 25;
  ELSE
    RETURN QUERY SELECT 'orders'::TEXT, ('orders' = ANY(v_completed)), 0;
  END IF;

  -- ═══════════════════════════════════════════════
  -- 4. Thu Tiền Đúng Hạn (config-driven — revenue_event)
  -- ═══════════════════════════════════════════════
  SELECT * INTO v_cfg FROM business_type_config
  WHERE business_type = v_btype AND concept = 'revenue_event';

  IF v_cfg.table_name IS NOT NULL THEN
    BEGIN
      EXECUTE format(
        'SELECT count(*) FROM %I WHERE created_at::DATE = $1',
        v_cfg.table_name
      ) INTO v_count USING v_today;
    EXCEPTION WHEN OTHERS THEN
      v_count := 0;
    END;
  ELSE
    v_count := 0;
  END IF;

  IF v_count >= 1 AND NOT ('payment' = ANY(v_completed)) THEN
    v_completed := array_append(v_completed, 'payment');
    v_xp := v_xp + 15;
    RETURN QUERY SELECT 'payment'::TEXT, true, 15;
  ELSE
    RETURN QUERY SELECT 'payment'::TEXT, ('payment' = ANY(v_completed)), 0;
  END IF;

  -- ═══════════════════════════════════════════════
  -- 5. CEO Có Tâm (universal — login)
  -- ═══════════════════════════════════════════════
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

  IF v_xp > 0 THEN
    PERFORM add_xp(p_user_id, p_company_id, v_xp, 1.0, 'daily', NULL, 'Daily quests');
  END IF;

  IF v_combo AND NOT v_log.combo_completed THEN
    PERFORM add_xp(p_user_id, p_company_id, 50, 1.0, 'daily', 'combo', 'Daily Combo bonus!');
  END IF;
END;
$$;

-- ============================================================
-- 6. CONFIG-AWARE QUEST RESOLVER
-- Resolves a template into concrete quest for a business type
-- ============================================================

CREATE OR REPLACE FUNCTION resolve_quest_template(
  p_template_code TEXT,
  p_business_type TEXT,
  p_difficulty TEXT DEFAULT 'intermediate'
)
RETURNS TABLE(
  quest_name TEXT,
  quest_description TEXT,
  resolved_condition JSONB,
  xp_reward INT,
  reputation_reward INT
) LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_tpl quest_templates%ROWTYPE;
  v_cfg business_type_config%ROWTYPE;
  v_threshold INT;
  v_name TEXT;
  v_desc TEXT;
  v_cond JSONB;
BEGIN
  SELECT * INTO v_tpl FROM quest_templates WHERE code = p_template_code AND is_active = true;
  IF v_tpl IS NULL THEN RETURN; END IF;

  -- Get config for the concept
  SELECT * INTO v_cfg FROM business_type_config
  WHERE business_type = p_business_type AND concept = v_tpl.concept;

  -- Get threshold from curve
  v_threshold := COALESCE(
    (v_tpl.threshold_curve->>p_difficulty)::INT,
    (v_tpl.threshold_curve->>'intermediate')::INT,
    1
  );

  -- Resolve name pattern
  v_name := REPLACE(v_tpl.name_pattern, '{display_name}', COALESCE(v_cfg.display_name, v_tpl.concept));
  v_name := REPLACE(v_name, '{threshold}', v_threshold::TEXT);

  -- Resolve description pattern
  v_desc := REPLACE(v_tpl.description_pattern, '{display_name}', COALESCE(v_cfg.display_name, v_tpl.concept));
  v_desc := REPLACE(v_desc, '{threshold}', v_threshold::TEXT);

  -- Resolve condition
  v_cond := v_tpl.condition_pattern;
  IF v_cfg.table_name IS NOT NULL THEN
    v_cond := v_cond || jsonb_build_object('table', v_cfg.table_name);
  END IF;
  IF v_cfg.filter != '{}' THEN
    v_cond := v_cond || jsonb_build_object('filter', v_cfg.filter);
  END IF;
  v_cond := v_cond || jsonb_build_object('value', v_threshold);

  RETURN QUERY SELECT v_name, v_desc, v_cond, v_tpl.xp_reward, v_tpl.reputation_reward;
END;
$$;

-- ============================================================
-- 7. GET CONFIG FOR BUSINESS TYPE (used by Flutter app)
-- ============================================================

CREATE OR REPLACE FUNCTION get_business_config(p_business_type TEXT)
RETURNS TABLE(
  concept TEXT, table_name TEXT, filter JSONB,
  display_name TEXT, display_name_plural TEXT,
  icon TEXT, metadata JSONB
) LANGUAGE sql STABLE AS $$
  SELECT concept, table_name, filter, display_name, display_name_plural, icon, metadata
  FROM business_type_config
  WHERE business_type = p_business_type
  ORDER BY concept;
$$;

-- ============================================================
-- 8. AI QUEST GENERATOR SUPPORT
-- Store AI-generated configs pending CEO approval
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_generated_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  business_type TEXT NOT NULL,
  generated_config JSONB NOT NULL,
  generated_quests JSONB DEFAULT '[]',
  ai_model TEXT NOT NULL DEFAULT 'gemini-2.0-flash',
  prompt_used TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'applied')),
  reviewed_by UUID REFERENCES employees(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  applied_at TIMESTAMPTZ
);

ALTER TABLE ai_generated_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_cfg_read" ON ai_generated_configs FOR SELECT USING (true);
CREATE POLICY "ai_cfg_insert" ON ai_generated_configs FOR INSERT WITH CHECK (true);
CREATE POLICY "ai_cfg_update" ON ai_generated_configs FOR UPDATE USING (true);

-- Apply an AI-generated config after CEO approval
CREATE OR REPLACE FUNCTION apply_ai_config(
  p_config_id UUID,
  p_user_id UUID
)
RETURNS TABLE(success BOOLEAN, message TEXT, configs_applied INT, quests_created INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_gen ai_generated_configs%ROWTYPE;
  v_cfg JSONB;
  v_quest JSONB;
  v_cfg_count INT := 0;
  v_quest_count INT := 0;
BEGIN
  SELECT * INTO v_gen FROM ai_generated_configs WHERE id = p_config_id;
  IF v_gen IS NULL THEN
    RETURN QUERY SELECT false, 'Config không tồn tại'::TEXT, 0, 0;
    RETURN;
  END IF;
  IF v_gen.status = 'applied' THEN
    RETURN QUERY SELECT false, 'Config đã được áp dụng'::TEXT, 0, 0;
    RETURN;
  END IF;

  -- Apply business type configs
  FOR v_cfg IN SELECT * FROM jsonb_array_elements(v_gen.generated_config)
  LOOP
    INSERT INTO business_type_config (business_type, concept, table_name, filter, display_name, display_name_plural, icon, metadata)
    VALUES (
      v_gen.business_type,
      v_cfg->>'concept',
      v_cfg->>'table_name',
      COALESCE(v_cfg->'filter', '{}'),
      v_cfg->>'display_name',
      v_cfg->>'display_name_plural',
      COALESCE(v_cfg->>'icon', 'star'),
      COALESCE(v_cfg->'metadata', '{}')
    ) ON CONFLICT (business_type, concept) DO UPDATE SET
      table_name = EXCLUDED.table_name,
      filter = EXCLUDED.filter,
      display_name = EXCLUDED.display_name,
      display_name_plural = EXCLUDED.display_name_plural,
      icon = EXCLUDED.icon,
      metadata = EXCLUDED.metadata;
    v_cfg_count := v_cfg_count + 1;
  END LOOP;

  -- Apply custom quests
  FOR v_quest IN SELECT * FROM jsonb_array_elements(v_gen.generated_quests)
  LOOP
    INSERT INTO quest_definitions (
      code, name, description, quest_type, act, business_type, category,
      conditions, xp_reward, reputation_reward, sort_order
    ) VALUES (
      v_quest->>'code',
      v_quest->>'name',
      v_quest->>'description',
      COALESCE(v_quest->>'quest_type', 'main'),
      COALESCE((v_quest->>'act')::INT, 2),
      v_gen.business_type,
      v_quest->>'category',
      COALESCE(v_quest->'conditions', '{}'),
      COALESCE((v_quest->>'xp_reward')::INT, 100),
      COALESCE((v_quest->>'reputation_reward')::INT, 10),
      COALESCE((v_quest->>'sort_order')::INT, 50)
    ) ON CONFLICT (code) DO NOTHING;
    v_quest_count := v_quest_count + 1;
  END LOOP;

  -- Mark as applied
  UPDATE ai_generated_configs SET
    status = 'applied',
    reviewed_by = p_user_id,
    applied_at = now()
  WHERE id = p_config_id;

  RETURN QUERY SELECT true, ('Đã áp dụng ' || v_cfg_count || ' configs, ' || v_quest_count || ' quests')::TEXT, v_cfg_count, v_quest_count;
END;
$$;

-- ============================================================
-- 9. INITIALIZE QUESTS WITH BUSINESS TYPE AWARENESS
-- ============================================================

CREATE OR REPLACE FUNCTION initialize_quests_for_company(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
  v_btype TEXT;
  v_quest RECORD;
  v_count INT := 0;
  v_first BOOLEAN := true;
BEGIN
  SELECT business_type INTO v_btype FROM companies WHERE id = p_company_id;

  -- Act I quests (universal)
  FOR v_quest IN
    SELECT id, sort_order FROM quest_definitions
    WHERE is_active = true AND quest_type = 'main' AND act = 1
      AND (business_type IS NULL OR business_type = v_btype)
    ORDER BY sort_order
  LOOP
    INSERT INTO quest_progress (user_id, company_id, quest_id, status, progress_current, progress_target)
    VALUES (p_user_id, p_company_id, v_quest.id,
      CASE WHEN v_first THEN 'available' ELSE 'locked' END, 0, 1)
    ON CONFLICT (user_id, company_id, quest_id) DO NOTHING;
    v_first := false;
    v_count := v_count + 1;
  END LOOP;

  -- Act II quests (filtered by business type)
  v_first := true;
  FOR v_quest IN
    SELECT id, sort_order FROM quest_definitions
    WHERE is_active = true AND quest_type = 'main' AND act = 2
      AND (business_type IS NULL OR business_type = v_btype)
    ORDER BY sort_order
  LOOP
    INSERT INTO quest_progress (user_id, company_id, quest_id, status, progress_current, progress_target)
    VALUES (p_user_id, p_company_id, v_quest.id, 'locked', 0, 1)
    ON CONFLICT (user_id, company_id, quest_id) DO NOTHING;
    v_count := v_count + 1;
  END LOOP;

  -- Act III + IV quests (universal)
  FOR v_quest IN
    SELECT id FROM quest_definitions
    WHERE is_active = true AND quest_type = 'main' AND act IN (3, 4)
      AND (business_type IS NULL OR business_type = v_btype)
    ORDER BY sort_order
  LOOP
    INSERT INTO quest_progress (user_id, company_id, quest_id, status, progress_current, progress_target)
    VALUES (p_user_id, p_company_id, v_quest.id, 'locked', 0, 1)
    ON CONFLICT (user_id, company_id, quest_id) DO NOTHING;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;
