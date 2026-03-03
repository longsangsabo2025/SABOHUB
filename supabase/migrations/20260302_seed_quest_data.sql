-- ============================================================
-- SABOHUB RPG — Seed Data: Act I Quests + Achievements
-- Migration: 20260302 (seed)
-- ============================================================

-- ============================================================
-- ACT I — "Khởi Nghiệp" (The Foundation)
-- ============================================================

INSERT INTO quest_definitions (code, name, description, quest_type, act, category, conditions, xp_reward, reputation_reward, badge_reward, sort_order) VALUES

-- Quest 1.1: Khai Sinh
('act1_khai_sinh', 'Khai Sinh', 'Tạo company và điền đầy đủ thông tin công ty',
 'main', 1, 'operate',
 '{"type": "exists", "table": "companies", "filter": {"name": "not_null", "address": "not_null"}}',
 50, 10, 'Founder', 1),

-- Quest 1.2: Xây Doanh Trại
('act1_xay_doanh_trai', 'Xây Doanh Trại', 'Tạo chi nhánh đầu tiên cho công ty',
 'main', 1, 'operate',
 '{"type": "count", "table": "branches", "operator": ">=", "value": 1}',
 50, 10, NULL, 2),

-- Quest 1.3: Chiêu Mộ Chiến Binh
('act1_chieu_mo', 'Chiêu Mộ Chiến Binh', 'Mời 3 nhân viên đầu tiên vào hệ thống',
 'main', 1, 'operate',
 '{"type": "count", "table": "employees", "filter": {"is_active": true}, "operator": ">=", "value": 3}',
 100, 15, 'Recruiter', 3),

-- Quest 1.4: Phân Binh Bố Trận
('act1_phan_binh', 'Phân Binh Bố Trận', 'Tạo phòng ban và phân công role cho nhân viên',
 'main', 1, 'operate',
 '{"type": "count", "table": "employees", "filter": {"department": "not_null", "role": "not_null"}, "operator": ">=", "value": 3}',
 100, 15, NULL, 4),

-- Quest 1.5: Ngày Đầu Tiên
('act1_ngay_dau', 'Ngày Đầu Tiên', 'Tất cả nhân viên check-in thành công trong 1 ngày',
 'main', 1, 'operate',
 '{"type": "attendance_full_day", "description": "100% attendance for 1 day"}',
 150, 20, NULL, 5),

-- Quest 1.6: Mệnh Lệnh Đầu Tiên
('act1_menh_lenh', 'Mệnh Lệnh Đầu Tiên', 'Tạo và giao 5 task cho nhân viên',
 'main', 1, 'operate',
 '{"type": "count", "table": "tasks", "filter": {"status": "assigned"}, "operator": ">=", "value": 5}',
 100, 15, 'Commander', 6);

-- Set prerequisites (each quest requires the previous one)
UPDATE quest_definitions SET prerequisites = '{}' WHERE code = 'act1_khai_sinh';
UPDATE quest_definitions SET prerequisites = '{act1_khai_sinh}' WHERE code = 'act1_xay_doanh_trai';
UPDATE quest_definitions SET prerequisites = '{act1_xay_doanh_trai}' WHERE code = 'act1_chieu_mo';
UPDATE quest_definitions SET prerequisites = '{act1_chieu_mo}' WHERE code = 'act1_phan_binh';
UPDATE quest_definitions SET prerequisites = '{act1_phan_binh}' WHERE code = 'act1_ngay_dau';
UPDATE quest_definitions SET prerequisites = '{act1_ngay_dau}' WHERE code = 'act1_menh_lenh';

-- Boss Challenge Act I
INSERT INTO quest_definitions (code, name, description, quest_type, act, category, conditions, xp_reward, reputation_reward, title_reward, sort_order) VALUES
('act1_boss', 'Tuần Lễ Hoàn Hảo',
 '7 ngày liên tiếp: 100% attendance + 100% task completion',
 'boss', 1, 'operate',
 '{"type": "streak", "days": 7, "conditions": [{"type": "attendance_full_day"}, {"type": "tasks_all_completed"}]}',
 500, 50, 'Người Khai Sáng', 7);

UPDATE quest_definitions SET prerequisites = '{act1_menh_lenh}' WHERE code = 'act1_boss';

-- ============================================================
-- ACT II — "Vận Hành" Distribution Path (sample)
-- ============================================================

INSERT INTO quest_definitions (code, name, description, quest_type, act, business_type, category, conditions, xp_reward, reputation_reward, sort_order, prerequisites) VALUES

('act2d_kho_bau', 'Kho Báu Đầu Tiên', 'Tạo warehouse và nhập 20 sản phẩm',
 'main', 2, 'distribution', 'operate',
 '{"type": "compound", "all": [{"type": "count", "table": "warehouses", "operator": ">=", "value": 1}, {"type": "count", "table": "products", "operator": ">=", "value": 20}]}',
 150, 20, 10, '{act1_boss}'),

('act2d_khach_vang', 'Khách Hàng Vàng', 'Thêm 10 khách hàng đầu tiên vào hệ thống',
 'main', 2, 'distribution', 'sell',
 '{"type": "count", "table": "customers", "operator": ">=", "value": 10}',
 150, 20, 11, '{act2d_kho_bau}'),

('act2d_don_hang', 'Đơn Hàng Xử Nữ', 'Tạo và hoàn thành đơn hàng đầu tiên',
 'main', 2, 'distribution', 'sell',
 '{"type": "count", "table": "sales_orders", "filter": {"status": "completed"}, "operator": ">=", "value": 1}',
 200, 25, 12, '{act2d_khach_vang}'),

('act2d_tua_lua', 'Con Đường Tơ Lụa', 'Setup delivery route và hoàn thành 5 đơn giao hàng',
 'main', 2, 'distribution', 'operate',
 '{"type": "count", "table": "deliveries", "filter": {"status": "completed"}, "operator": ">=", "value": 5}',
 250, 30, 13, '{act2d_don_hang}'),

('act2d_can_bang', 'Cân Bằng Nguyên Tố', 'Tồn kho khớp 100% sau kiểm kê',
 'main', 2, 'distribution', 'operate',
 '{"type": "inventory_check", "accuracy": 100}',
 300, 35, 14, '{act2d_tua_lua}');

-- ============================================================
-- ACT II — "Vận Hành" Entertainment Path (sample)
-- ============================================================

INSERT INTO quest_definitions (code, name, description, quest_type, act, business_type, category, conditions, xp_reward, reputation_reward, sort_order, prerequisites) VALUES

('act2e_bay_binh', 'Bày Binh Bố Trận', 'Setup 5+ bàn/phòng trong hệ thống',
 'main', 2, 'entertainment', 'operate',
 '{"type": "count", "table": "tables", "operator": ">=", "value": 5}',
 150, 20, 20, '{act1_boss}'),

('act2e_khai_truong', 'Khai Trương', '10 session check-in/check-out hoàn chỉnh',
 'main', 2, 'entertainment', 'sell',
 '{"type": "count", "table": "table_sessions", "filter": {"status": "completed"}, "operator": ">=", "value": 10}',
 200, 25, 21, '{act2e_bay_binh}'),

('act2e_dau_bep', 'Đầu Bếp Tài Ba', 'Tạo menu 15+ món',
 'main', 2, 'entertainment', 'operate',
 '{"type": "count", "table": "menu_items", "operator": ">=", "value": 15}',
 150, 20, 22, '{act2e_khai_truong}');

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================

INSERT INTO achievements (code, name, description, icon, rarity, category, condition_type, condition_value, is_secret, sort_order) VALUES

-- Common
('founder', 'Người Sáng Lập', 'Tạo công ty đầu tiên', 'rocket', 'common', 'general',
 'quest_complete', '{"quest_code": "act1_khai_sinh"}', false, 1),

('recruiter', 'Nhà Tuyển Dụng', 'Mời 3 nhân viên đầu tiên', 'star', 'common', 'operate',
 'quest_complete', '{"quest_code": "act1_chieu_mo"}', false, 2),

('commander', 'Chỉ Huy', 'Tạo và giao 5 task đầu tiên', 'sword', 'common', 'operate',
 'quest_complete', '{"quest_code": "act1_menh_lenh"}', false, 3),

-- Rare
('speed_demon', 'Speed Demon', 'Hoàn thành đơn hàng trong dưới 2 giờ', 'bolt', 'rare', 'sell',
 'order_speed', '{"max_hours": 2}', false, 10),

('week_warrior', 'Chiến Binh Tuần', '7 ngày daily combo liên tiếp', 'shield', 'rare', 'general',
 'streak', '{"days": 7, "type": "daily_combo"}', false, 11),

-- Epic
('no_sleep', 'Không Ngủ', 'Login lúc 5AM-6AM, 7 ngày liên tiếp', 'moon', 'epic', 'general',
 'early_login_streak', '{"start_hour": 5, "end_hour": 6, "days": 7}', false, 20),

('zero_defect', 'Zero Defect', '0 complaint từ khách hàng trong 30 ngày', 'target', 'epic', 'sell',
 'zero_complaints', '{"days": 30}', false, 21),

('multi_type', 'Đa Nhân Cách', 'Vận hành 3+ business types khác nhau', 'diamond', 'epic', 'general',
 'business_types', '{"min_types": 3}', false, 22),

-- Legendary
('iron_will', 'Sắt Đá', '30 ngày daily combo liên tiếp', 'fire', 'legendary', 'general',
 'streak', '{"days": 30, "type": "daily_combo"}', false, 30),

('revenue_king', 'Vua Doanh Thu', 'Doanh thu tháng top 1 trên leaderboard', 'crown', 'legendary', 'sell',
 'leaderboard_rank', '{"rank": 1, "type": "monthly_revenue"}', false, 31),

-- Mythic
('iron_man', 'Người Sắt', '365 ngày không miss daily login', 'trophy', 'mythic', 'general',
 'streak', '{"days": 365, "type": "daily_login"}', false, 40),

-- Secret
('night_owl', 'Cú Đêm', 'Tạo đơn hàng lúc 2AM-4AM', 'ghost', 'rare', 'secret',
 'action_time', '{"start_hour": 2, "end_hour": 4, "action": "create_order"}', true, 50),

('superman', 'Siêu Nhân', 'Approve 50 tasks trong 1 ngày', 'bolt', 'epic', 'secret',
 'daily_action_count', '{"action": "approve_task", "count": 50}', true, 51),

('phoenix', 'Phượng Hoàng', 'Lỗ 2 tháng liên tiếp rồi lãi tháng thứ 3', 'phoenix', 'legendary', 'secret',
 'financial_recovery', '{"loss_months": 2, "profit_month": 1}', true, 52);
