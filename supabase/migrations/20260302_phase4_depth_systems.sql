-- ============================================================
-- SABOHUB RPG — Phase 4: Depth Systems
-- Skill Tree, XP Multipliers, Uy Tín Store, Act II-IV Quests
-- ============================================================

-- ============================================================
-- 1. CEO SKILL TREE — Allocate points + passive bonuses
-- ============================================================

CREATE TABLE IF NOT EXISTS skill_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch TEXT NOT NULL CHECK (branch IN ('leader', 'merchant', 'strategist')),
  tier INT NOT NULL CHECK (tier BETWEEN 1 AND 5),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  effect_type TEXT NOT NULL,
  effect_value JSONB NOT NULL DEFAULT '{}',
  icon TEXT NOT NULL DEFAULT 'star',
  prerequisite_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO skill_definitions (branch, tier, code, name, description, effect_type, effect_value, icon, prerequisite_code) VALUES
-- Leader Branch (Con Người)
('leader', 1, 'lead_inspire', 'Truyền Cảm Hứng', 'Team XP +10%', 'team_xp_bonus', '{"percent": 10}', 'heart', NULL),
('leader', 2, 'lead_mentor', 'Cố Vấn', 'Staff level-up nhanh hơn 15%', 'staff_xp_bonus', '{"percent": 15}', 'star', 'lead_inspire'),
('leader', 3, 'lead_diplomat', 'Ngoại Giao', 'Uy Tín earned +20%', 'reputation_bonus', '{"percent": 20}', 'shield', 'lead_mentor'),
('leader', 4, 'lead_commander', 'Chỉ Huy', 'Task completion XP +25%', 'task_xp_bonus', '{"percent": 25}', 'sword', 'lead_diplomat'),
('leader', 5, 'lead_emperor', 'Đế Vương', 'ALL XP +10%, Streak Freeze +1', 'global_xp_bonus', '{"percent": 10, "extra_freeze": 1}', 'crown', 'lead_commander'),

-- Merchant Branch (Kinh Doanh)
('merchant', 1, 'merc_haggler', 'Mặc Cả', 'Order-related quest XP +15%', 'order_xp_bonus', '{"percent": 15}', 'bolt', NULL),
('merchant', 2, 'merc_networker', 'Kết Nối', 'Customer quest targets -1', 'quest_target_reduce', '{"amount": 1, "category": "sell"}', 'diamond', 'merc_haggler'),
('merchant', 3, 'merc_analyst', 'Phân Tích', 'Business Health Score +5 baseline', 'health_baseline', '{"amount": 5}', 'target', 'merc_networker'),
('merchant', 4, 'merc_tycoon', 'Trùm Buôn', 'Daily Combo bonus +25 XP', 'combo_bonus', '{"amount": 25}', 'fire', 'merc_analyst'),
('merchant', 5, 'merc_mogul', 'Đại Gia', 'Golden Hour duration +30 min', 'golden_hour_extend', '{"minutes": 30}', 'crown', 'merc_tycoon'),

-- Strategist Branch (Tài Chính)
('strategist', 1, 'strat_planner', 'Hoạch Định', 'Weekly quest XP +15%', 'weekly_xp_bonus', '{"percent": 15}', 'target', NULL),
('strategist', 2, 'strat_optimizer', 'Tối Ưu', 'Early completion bonus +10%', 'early_bonus_extra', '{"percent": 10}', 'bolt', 'strat_planner'),
('strategist', 3, 'strat_calculator', 'Tính Toán', 'Overdue penalty reduced 50%', 'overdue_penalty_reduce', '{"percent": 50}', 'shield', 'strat_optimizer'),
('strategist', 4, 'strat_visionary', 'Viễn Kiến', 'Achievement scan auto-runs daily', 'auto_achievement_scan', '{}', 'diamond', 'strat_calculator'),
('strategist', 5, 'strat_mastermind', 'Quân Sư', 'Unlock secret quest hints', 'secret_hints', '{}', 'crown', 'strat_visionary');

-- Allocate skill point
CREATE OR REPLACE FUNCTION allocate_skill_point(
  p_user_id UUID,
  p_company_id UUID,
  p_skill_code TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT, new_skill_tree JSONB, remaining_points INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_profile ceo_profiles%ROWTYPE;
  v_skill skill_definitions%ROWTYPE;
  v_current_branch_level INT;
  v_prereq_met BOOLEAN;
BEGIN
  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN
    RETURN QUERY SELECT false, 'Profile not found'::TEXT, '{}'::JSONB, 0;
    RETURN;
  END IF;

  IF v_profile.level < 20 THEN
    RETURN QUERY SELECT false, 'Cần Level 20 để mở khóa Skill Tree'::TEXT, v_profile.skill_tree, v_profile.skill_points;
    RETURN;
  END IF;

  IF v_profile.skill_points <= 0 THEN
    RETURN QUERY SELECT false, 'Không đủ Skill Points'::TEXT, v_profile.skill_tree, 0;
    RETURN;
  END IF;

  SELECT * INTO v_skill FROM skill_definitions WHERE code = p_skill_code;
  IF v_skill IS NULL THEN
    RETURN QUERY SELECT false, 'Skill không tồn tại'::TEXT, v_profile.skill_tree, v_profile.skill_points;
    RETURN;
  END IF;

  v_current_branch_level := COALESCE((v_profile.skill_tree->>v_skill.branch)::INT, 0);

  IF v_current_branch_level >= v_skill.tier THEN
    RETURN QUERY SELECT false, 'Skill đã được mở khóa'::TEXT, v_profile.skill_tree, v_profile.skill_points;
    RETURN;
  END IF;

  IF v_skill.tier > v_current_branch_level + 1 THEN
    RETURN QUERY SELECT false, 'Cần mở khóa skill trước đó'::TEXT, v_profile.skill_tree, v_profile.skill_points;
    RETURN;
  END IF;

  -- Check prerequisite
  IF v_skill.prerequisite_code IS NOT NULL THEN
    v_prereq_met := v_current_branch_level >= v_skill.tier - 1;
    IF NOT v_prereq_met THEN
      RETURN QUERY SELECT false, 'Chưa đạt prerequisite'::TEXT, v_profile.skill_tree, v_profile.skill_points;
      RETURN;
    END IF;
  END IF;

  -- Allocate
  UPDATE ceo_profiles SET
    skill_tree = jsonb_set(skill_tree, ARRAY[v_skill.branch], to_jsonb(v_current_branch_level + 1)),
    skill_points = skill_points - 1
  WHERE user_id = p_user_id AND company_id = p_company_id;

  SELECT skill_tree, skill_points INTO v_profile.skill_tree, v_profile.skill_points
  FROM ceo_profiles WHERE user_id = p_user_id AND company_id = p_company_id;

  RETURN QUERY SELECT true, ('Đã mở khóa: ' || v_skill.name)::TEXT, v_profile.skill_tree, v_profile.skill_points;
END;
$$;

-- Get active skill effects for a CEO
CREATE OR REPLACE FUNCTION get_skill_effects(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS TABLE(effect_type TEXT, effect_value JSONB, skill_name TEXT)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_tree JSONB;
  v_leader INT;
  v_merchant INT;
  v_strategist INT;
BEGIN
  SELECT skill_tree INTO v_tree FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_tree IS NULL THEN RETURN; END IF;

  v_leader := COALESCE((v_tree->>'leader')::INT, 0);
  v_merchant := COALESCE((v_tree->>'merchant')::INT, 0);
  v_strategist := COALESCE((v_tree->>'strategist')::INT, 0);

  RETURN QUERY
  SELECT sd.effect_type, sd.effect_value, sd.name
  FROM skill_definitions sd
  WHERE (sd.branch = 'leader' AND sd.tier <= v_leader)
     OR (sd.branch = 'merchant' AND sd.tier <= v_merchant)
     OR (sd.branch = 'strategist' AND sd.tier <= v_strategist);
END;
$$;

-- ============================================================
-- 2. XP MULTIPLIER SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS xp_multiplier_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.5,
  start_hour INT,
  end_hour INT,
  day_of_week INT[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO xp_multiplier_events (code, name, description, multiplier, start_hour, end_hour, day_of_week) VALUES
('golden_morning', 'Giờ Vàng Sáng', 'XP x1.5 từ 7AM-9AM', 1.5, 7, 9, NULL),
('golden_evening', 'Giờ Vàng Tối', 'XP x1.5 từ 8PM-10PM', 1.5, 20, 22, NULL),
('weekend_warrior', 'Chiến Binh Cuối Tuần', 'XP x1.3 thứ 7 & CN', 1.3, NULL, NULL, '{6,0}'),
('first_blood', 'First Blood', 'Login đầu tiên trong ngày XP x2', 2.0, NULL, NULL, NULL);

-- Get current active multiplier for a user
CREATE OR REPLACE FUNCTION get_current_multiplier(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS NUMERIC LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_mult NUMERIC := 1.0;
  v_hour INT;
  v_dow INT;
  v_streak INT;
  r RECORD;
  v_has_skill_extend BOOLEAN := false;
  v_extend_mins INT := 0;
BEGIN
  v_hour := EXTRACT(HOUR FROM now() AT TIME ZONE 'Asia/Ho_Chi_Minh');
  v_dow := EXTRACT(DOW FROM now() AT TIME ZONE 'Asia/Ho_Chi_Minh');

  -- Check skill extension for golden hour
  SELECT EXISTS (
    SELECT 1 FROM get_skill_effects(p_user_id, p_company_id)
    WHERE effect_type = 'golden_hour_extend'
  ) INTO v_has_skill_extend;

  IF v_has_skill_extend THEN v_extend_mins := 30; END IF;

  -- Check time-based multipliers
  FOR r IN
    SELECT * FROM xp_multiplier_events WHERE is_active = true
    AND (valid_from IS NULL OR valid_from <= now())
    AND (valid_until IS NULL OR valid_until >= now())
  LOOP
    IF r.start_hour IS NOT NULL AND r.end_hour IS NOT NULL THEN
      -- Time-window events (extend if skill)
      IF v_hour >= r.start_hour AND v_hour < (r.end_hour + CASE WHEN v_extend_mins > 0 THEN 1 ELSE 0 END) THEN
        v_mult := GREATEST(v_mult, r.multiplier);
      END IF;
    ELSIF r.day_of_week IS NOT NULL THEN
      IF v_dow = ANY(r.day_of_week) THEN
        v_mult := GREATEST(v_mult, r.multiplier);
      END IF;
    END IF;
  END LOOP;

  -- Streak bonus: every 7 days adds 0.05x (max 0.5)
  SELECT streak_days INTO v_streak FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  v_mult := v_mult + LEAST(0.5, COALESCE(v_streak, 0) / 7 * 0.05);

  -- Global XP bonus from skill tree
  BEGIN
    DECLARE v_global_pct NUMERIC := 0;
    BEGIN
      SELECT COALESCE((effect_value->>'percent')::NUMERIC, 0) INTO v_global_pct
      FROM get_skill_effects(p_user_id, p_company_id)
      WHERE effect_type = 'global_xp_bonus'
      LIMIT 1;

      IF v_global_pct > 0 THEN
        v_mult := v_mult + (v_global_pct / 100);
      END IF;
    END;
  END;

  RETURN ROUND(v_mult, 2);
END;
$$;

-- Enhanced add_xp that applies multipliers
CREATE OR REPLACE FUNCTION add_xp_with_multiplier(
  p_user_id UUID,
  p_company_id UUID,
  p_amount INT,
  p_source_type TEXT DEFAULT 'bonus',
  p_source_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE(new_level INT, new_total_xp BIGINT, leveled_up BOOLEAN, new_title TEXT, applied_multiplier NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
  v_mult NUMERIC;
BEGIN
  v_mult := get_current_multiplier(p_user_id, p_company_id);

  RETURN QUERY
  SELECT r.new_level, r.new_total_xp, r.leveled_up, r.new_title, v_mult
  FROM add_xp(p_user_id, p_company_id, p_amount, v_mult, p_source_type, p_source_id, p_description) r;
END;
$$;

-- ============================================================
-- 3. UY TÍN STORE — Feature unlock system
-- ============================================================

CREATE TABLE IF NOT EXISTS uytin_store_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('perk', 'cosmetic', 'boost', 'unlock')),
  cost INT NOT NULL,
  icon TEXT NOT NULL DEFAULT 'star',
  is_one_time BOOLEAN NOT NULL DEFAULT true,
  duration_hours INT,
  min_level INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS uytin_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES uytin_store_items(id),
  cost INT NOT NULL,
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(user_id, company_id, item_id)
);

ALTER TABLE uytin_purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "uytin_read" ON uytin_purchases FOR SELECT USING (true);
CREATE POLICY "uytin_insert" ON uytin_purchases FOR INSERT WITH CHECK (true);

-- Seed store items
INSERT INTO uytin_store_items (code, name, description, category, cost, icon, is_one_time, duration_hours, min_level, sort_order) VALUES

-- Perks
('extra_freeze', 'Thêm Streak Freeze', '+1 Streak Freeze (vĩnh viễn)', 'perk', 50, 'shield', true, NULL, 1, 10),
('double_daily', 'Double Daily', 'XP daily quests x2 trong 24h', 'boost', 30, 'bolt', false, 24, 5, 11),
('vip_badge', 'VIP Badge', 'Badge VIP hiển thị trên profile', 'cosmetic', 100, 'crown', true, NULL, 10, 20),

-- Boosts
('xp_boost_1h', 'XP Boost 1h', 'XP x2 trong 1 giờ', 'boost', 20, 'fire', false, 1, 3, 30),
('xp_boost_24h', 'XP Boost 24h', 'XP x1.5 trong 24 giờ', 'boost', 80, 'fire', false, 24, 10, 31),
('health_boost', 'Health Boost', 'Business Health +10 trong 24h', 'boost', 25, 'heart', false, 24, 5, 32),

-- Unlocks
('unlock_dark_theme', 'Dark Theme', 'Mở khóa giao diện tối', 'unlock', 150, 'moon', true, NULL, 15, 40),
('unlock_custom_title', 'Custom Title', 'Tự đặt title hiển thị', 'unlock', 200, 'diamond', true, NULL, 20, 41),
('unlock_analytics', 'Analytics Pro', 'Mở khóa báo cáo nâng cao', 'unlock', 300, 'target', true, NULL, 25, 42),
('unlock_ai_assistant', 'AI Trợ Lý', 'Mở khóa AI gợi ý kinh doanh', 'unlock', 500, 'rocket', true, NULL, 30, 43);

-- Purchase from store
CREATE OR REPLACE FUNCTION purchase_store_item(
  p_user_id UUID,
  p_company_id UUID,
  p_item_code TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT, remaining_reputation INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_item uytin_store_items%ROWTYPE;
  v_profile ceo_profiles%ROWTYPE;
  v_already_purchased BOOLEAN;
BEGIN
  SELECT * INTO v_item FROM uytin_store_items WHERE code = p_item_code AND is_active = true;
  IF v_item IS NULL THEN
    RETURN QUERY SELECT false, 'Vật phẩm không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  SELECT * INTO v_profile FROM ceo_profiles
  WHERE user_id = p_user_id AND company_id = p_company_id;

  IF v_profile IS NULL THEN
    RETURN QUERY SELECT false, 'Profile không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  IF v_profile.level < v_item.min_level THEN
    RETURN QUERY SELECT false, ('Cần Level ' || v_item.min_level)::TEXT, v_profile.reputation_points;
    RETURN;
  END IF;

  IF v_profile.reputation_points < v_item.cost THEN
    RETURN QUERY SELECT false, 'Không đủ Uy Tín'::TEXT, v_profile.reputation_points;
    RETURN;
  END IF;

  -- Check one-time purchase
  IF v_item.is_one_time THEN
    SELECT EXISTS (
      SELECT 1 FROM uytin_purchases
      WHERE user_id = p_user_id AND company_id = p_company_id AND item_id = v_item.id
    ) INTO v_already_purchased;

    IF v_already_purchased THEN
      RETURN QUERY SELECT false, 'Đã mua rồi'::TEXT, v_profile.reputation_points;
      RETURN;
    END IF;
  END IF;

  -- Deduct Uy Tín
  UPDATE ceo_profiles SET
    reputation_points = reputation_points - v_item.cost
  WHERE user_id = p_user_id AND company_id = p_company_id;

  -- Record purchase
  INSERT INTO uytin_purchases (user_id, company_id, item_id, cost, expires_at, is_active)
  VALUES (
    p_user_id, p_company_id, v_item.id, v_item.cost,
    CASE WHEN v_item.duration_hours IS NOT NULL
      THEN now() + (v_item.duration_hours || ' hours')::INTERVAL
      ELSE NULL
    END,
    true
  )
  ON CONFLICT (user_id, company_id, item_id) DO UPDATE SET
    purchased_at = now(),
    expires_at = CASE WHEN v_item.duration_hours IS NOT NULL
      THEN now() + (v_item.duration_hours || ' hours')::INTERVAL
      ELSE NULL
    END,
    is_active = true,
    cost = v_item.cost;

  -- Apply effects
  IF v_item.code = 'extra_freeze' THEN
    UPDATE ceo_profiles SET streak_freeze_remaining = streak_freeze_remaining + 1
    WHERE user_id = p_user_id AND company_id = p_company_id;
  END IF;

  RETURN QUERY
  SELECT true, ('Đã mua: ' || v_item.name)::TEXT,
    (v_profile.reputation_points - v_item.cost);
END;
$$;

-- ============================================================
-- 4. ACT II-IV QUEST LINES
-- ============================================================

-- ACT III — "Mở Rộng" (Expansion) — Universal
INSERT INTO quest_definitions (code, name, description, quest_type, act, business_type, category, conditions, xp_reward, reputation_reward, sort_order, prerequisites) VALUES

('act3_chi_nhanh', 'Mở Chi Nhánh', 'Tạo chi nhánh thứ 2',
 'main', 3, NULL, 'operate',
 '{"type": "count", "table": "branches", "operator": ">=", "value": 2}',
 500, 50, 30, '{act1_boss}'),

('act3_doi_quan', 'Đạo Quân', '20+ nhân viên active',
 'main', 3, NULL, 'operate',
 '{"type": "count", "table": "employees", "filter": {"is_active": true}, "operator": ">=", "value": 20}',
 400, 40, 31, '{act3_chi_nhanh}'),

('act3_tai_chinh', 'Bậc Thầy Tài Chính', 'Business Health Score ≥ 80',
 'main', 3, NULL, 'finance',
 '{"type": "health_score", "operator": ">=", "value": 80}',
 500, 50, 32, '{act3_doi_quan}'),

('act3_da_nang', 'Đa Năng', 'Hoàn thành 50 quests tổng cộng',
 'main', 3, NULL, 'operate',
 '{"type": "total_quests_completed", "operator": ">=", "value": 50}',
 600, 60, 33, '{act3_tai_chinh}'),

('act3_boss', '⚔️ BOSS: Đại Ca', 'Level 30 + 100 Uy Tín + Health ≥ 70',
 'main', 3, NULL, 'operate',
 '{"type": "compound", "all": [{"type": "level", "operator": ">=", "value": 30}, {"type": "reputation", "operator": ">=", "value": 100}, {"type": "health_score", "operator": ">=", "value": 70}]}',
 1000, 100, 34, '{act3_da_nang}'),

-- ACT IV — "Huyền Thoại" (Legend) — Universal
('act4_de_che', 'Đế Chế', '3+ chi nhánh active',
 'main', 4, NULL, 'operate',
 '{"type": "count", "table": "branches", "filter": {"is_active": true}, "operator": ">=", "value": 3}',
 800, 80, 40, '{act3_boss}'),

('act4_skill_master', 'Tông Sư', 'Max 1 nhánh skill tree (5/5)',
 'main', 4, NULL, 'operate',
 '{"type": "skill_branch_max", "value": 5}',
 600, 60, 41, '{act4_de_che}'),

('act4_nha_dau_tu', 'Nhà Đầu Tư', 'Chi 500+ Uy Tín trong store',
 'main', 4, NULL, 'finance',
 '{"type": "total_uytin_spent", "operator": ">=", "value": 500}',
 500, 50, 42, '{act4_skill_master}'),

('act4_huyen_thoai', 'Huyền Thoại', '365 ngày streak + Level 50',
 'main', 4, NULL, 'operate',
 '{"type": "compound", "all": [{"type": "streak", "operator": ">=", "value": 365}, {"type": "level", "operator": ">=", "value": 50}]}',
 2000, 200, 43, '{act4_nha_dau_tu}'),

('act4_boss_final', '⚔️ FINAL BOSS: Huyền Thoại CEO', 'Level 50 + 500 Uy Tín + Health ≥ 90 + All skills 3+',
 'main', 4, NULL, 'operate',
 '{"type": "compound", "all": [{"type": "level", "operator": ">=", "value": 50}, {"type": "reputation", "operator": ">=", "value": 500}, {"type": "health_score", "operator": ">=", "value": 90}]}',
 5000, 500, 44, '{act4_huyen_thoai}')

ON CONFLICT (code) DO NOTHING;

-- ACT II distribution additional quests
INSERT INTO quest_definitions (code, name, description, quest_type, act, business_type, category, conditions, xp_reward, reputation_reward, sort_order, prerequisites) VALUES

('act2d_giao_hang_50', 'Vận Chuyển 50', 'Hoàn thành 50 delivery',
 'main', 2, 'distribution', 'sell',
 '{"type": "count", "table": "deliveries", "filter": {"status": "delivered"}, "operator": ">=", "value": 50}',
 350, 30, 15, '{act2d_tua_lua}'),

('act2d_khach_vip', 'Khách VIP', '10 khách hàng có 5+ đơn hàng',
 'main', 2, 'distribution', 'sell',
 '{"type": "repeat_customers", "min_orders": 5, "min_customers": 10}',
 400, 40, 16, '{act2d_giao_hang_50}'),

('act2d_boss', '⚔️ BOSS: Ông Chủ Phân Phối', 'Level 20 + 50 Uy Tín + 100 đơn hàng',
 'main', 2, 'distribution', 'sell',
 '{"type": "compound", "all": [{"type": "level", "operator": ">=", "value": 20}, {"type": "reputation", "operator": ">=", "value": 50}, {"type": "count", "table": "sales_orders", "operator": ">=", "value": 100}]}',
 800, 80, 17, '{act2d_khach_vip}'),

-- ACT II entertainment additional quests
('act2e_phuc_vu', 'Phục Vụ Hoàn Hảo', '50 session completed',
 'main', 2, 'entertainment', 'sell',
 '{"type": "count", "table": "table_sessions", "filter": {"status": "completed"}, "operator": ">=", "value": 50}',
 350, 30, 23, '{act2e_dau_bep}'),

('act2e_boss', '⚔️ BOSS: Ông Chủ Giải Trí', 'Level 20 + 10 bàn + 100 sessions',
 'main', 2, 'entertainment', 'sell',
 '{"type": "compound", "all": [{"type": "level", "operator": ">=", "value": 20}, {"type": "count", "table": "tables", "operator": ">=", "value": 10}, {"type": "count", "table": "table_sessions", "filter": {"status": "completed"}, "operator": ">=", "value": 100}]}',
 800, 80, 24, '{act2e_phuc_vu}')

ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 5. GRANT SKILL POINTS on level up (modify add_xp trigger)
-- ============================================================

CREATE OR REPLACE FUNCTION grant_skill_point_on_level()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Grant 1 skill point every 5 levels starting from level 20
  IF NEW.level >= 20 AND NEW.level > OLD.level THEN
    IF NEW.level % 5 = 0 THEN
      NEW.skill_points := NEW.skill_points + 1;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_skill_point_on_level ON ceo_profiles;
CREATE TRIGGER trg_skill_point_on_level
  BEFORE UPDATE OF level ON ceo_profiles
  FOR EACH ROW EXECUTE FUNCTION grant_skill_point_on_level();
