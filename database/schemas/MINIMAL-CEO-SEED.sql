-- ============================================================================
-- 🌱 MINIMAL SEED DATA FOR CEO TESTING
-- ============================================================================
-- Test data để verify CEO features work
-- 1 CEO user + 2 companies + 3 branches + sample revenue + activities
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE CEO USER (Link with Supabase Auth)
-- ============================================================================

-- ⚠️ IMPORTANT: Replace <CEO_AUTH_UUID> với UUID thực từ Supabase Auth
-- Bạn cần login qua app rồi lấy UUID từ auth.users table

-- Tạm thời dùng placeholder UUID (sau này replace)
INSERT INTO public.users (id, email, phone, full_name, role, company_id, branch_id, is_active)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'ceo@sabohub.com', '0901234567', 'Nguyễn Văn CEO', 'CEO', NULL, NULL, true)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role;

-- ============================================================================
-- STEP 2: CREATE 2 COMPANIES
-- ============================================================================

INSERT INTO public.companies (id, name, business_type, address, phone, email, tax_code, is_active)
VALUES 
  (
    '10000000-0000-0000-0000-000000000001',
    'Nhà hàng Sabo HCM',
    'restaurant',
    '123 Nguyễn Huệ, Quận 1, TP.HCM',
    '0281234567',
    'sabohcm@example.com',
    '0123456789',
    true
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Cafe Sabo Hà Nội',
    'cafe',
    '456 Hoàn Kiếm, Hà Nội',
    '0241234567',
    'sabohn@example.com',
    '9876543210',
    true
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  business_type = EXCLUDED.business_type,
  address = EXCLUDED.address;

-- ============================================================================
-- STEP 3: CREATE 3 BRANCHES (2 cho HCM, 1 cho HN)
-- ============================================================================

INSERT INTO public.branches (id, company_id, name, code, address, phone, is_active)
VALUES 
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Chi nhánh Quận 1',
    'HCM-Q1',
    '123 Nguyễn Huệ, Quận 1, TP.HCM',
    '0281234567',
    true
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'Chi nhánh Quận 3',
    'HCM-Q3',
    '789 Võ Văn Tần, Quận 3, TP.HCM',
    '0281234568',
    true
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    'Chi nhánh Hoàn Kiếm',
    'HN-HK',
    '456 Hoàn Kiếm, Hà Nội',
    '0241234567',
    true
  )
ON CONFLICT (company_id, code) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address;

-- ============================================================================
-- STEP 4: CREATE SAMPLE MANAGERS & STAFF
-- ============================================================================

INSERT INTO public.users (id, email, phone, full_name, role, company_id, branch_id, is_active)
VALUES 
  -- Branch Manager cho HCM-Q1
  (
    '00000000-0000-0000-0000-000000000002',
    'manager.q1@sabohub.com',
    '0902345678',
    'Trần Thị Manager Q1',
    'BRANCH_MANAGER',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    true
  ),
  -- Branch Manager cho HCM-Q3
  (
    '00000000-0000-0000-0000-000000000003',
    'manager.q3@sabohub.com',
    '0903456789',
    'Lê Văn Manager Q3',
    'BRANCH_MANAGER',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    true
  ),
  -- Branch Manager cho HN-HK
  (
    '00000000-0000-0000-0000-000000000004',
    'manager.hk@sabohub.com',
    '0904567890',
    'Phạm Thị Manager HK',
    'BRANCH_MANAGER',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000003',
    true
  ),
  -- Staff cho HCM-Q1
  (
    '00000000-0000-0000-0000-000000000005',
    'staff1.q1@sabohub.com',
    '0905678901',
    'Nguyễn Văn Staff 1',
    'STAFF',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    true
  )
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name;

-- Update branch managers
UPDATE public.branches SET manager_id = '00000000-0000-0000-0000-000000000002' WHERE id = '20000000-0000-0000-0000-000000000001';
UPDATE public.branches SET manager_id = '00000000-0000-0000-0000-000000000003' WHERE id = '20000000-0000-0000-0000-000000000002';
UPDATE public.branches SET manager_id = '00000000-0000-0000-0000-000000000004' WHERE id = '20000000-0000-0000-0000-000000000003';

-- ============================================================================
-- STEP 5: CREATE DAILY REVENUE DATA (Last 30 days)
-- ============================================================================

-- Generate revenue for last 30 days for HCM-Q1
INSERT INTO public.daily_revenue (company_id, branch_id, date, total_revenue, total_orders, total_customers)
SELECT 
  '10000000-0000-0000-0000-000000000001'::UUID,
  '20000000-0000-0000-0000-000000000001'::UUID,
  CURRENT_DATE - (interval '1 day' * generate_series),
  (RANDOM() * 10000000 + 5000000)::DECIMAL(15,2), -- 5M-15M VNĐ/day
  (RANDOM() * 50 + 20)::INTEGER, -- 20-70 orders/day
  (RANDOM() * 60 + 30)::INTEGER  -- 30-90 customers/day
FROM generate_series(0, 29) AS generate_series
ON CONFLICT (company_id, branch_id, date) DO NOTHING;

-- Generate revenue for HCM-Q3
INSERT INTO public.daily_revenue (company_id, branch_id, date, total_revenue, total_orders, total_customers)
SELECT 
  '10000000-0000-0000-0000-000000000001'::UUID,
  '20000000-0000-0000-0000-000000000002'::UUID,
  CURRENT_DATE - (interval '1 day' * generate_series),
  (RANDOM() * 8000000 + 4000000)::DECIMAL(15,2),
  (RANDOM() * 40 + 15)::INTEGER,
  (RANDOM() * 50 + 20)::INTEGER
FROM generate_series(0, 29) AS generate_series
ON CONFLICT (company_id, branch_id, date) DO NOTHING;

-- Generate revenue for HN-HK
INSERT INTO public.daily_revenue (company_id, branch_id, date, total_revenue, total_orders, total_customers)
SELECT 
  '10000000-0000-0000-0000-000000000002'::UUID,
  '20000000-0000-0000-0000-000000000003'::UUID,
  CURRENT_DATE - (interval '1 day' * generate_series),
  (RANDOM() * 6000000 + 3000000)::DECIMAL(15,2),
  (RANDOM() * 30 + 10)::INTEGER,
  (RANDOM() * 40 + 15)::INTEGER
FROM generate_series(0, 29) AS generate_series
ON CONFLICT (company_id, branch_id, date) DO NOTHING;

-- ============================================================================
-- STEP 6: CREATE ACTIVITY LOGS (Recent activities cho Dashboard)
-- ============================================================================

INSERT INTO public.activity_logs (company_id, branch_id, user_id, action, entity_type, entity_id, description)
VALUES 
  (
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'created',
    'task',
    gen_random_uuid(),
    'Tạo nhiệm vụ: Kiểm tra kho nguyên liệu'
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003',
    'updated',
    'order',
    gen_random_uuid(),
    'Cập nhật đơn hàng #1234: Hoàn thành'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000004',
    'completed',
    'shift',
    gen_random_uuid(),
    'Kết thúc ca làm việc sáng'
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000005',
    'created',
    'user',
    '00000000-0000-0000-0000-000000000005',
    'Thêm nhân viên mới: Nguyễn Văn Staff 1'
  ),
  (
    NULL, -- Company-level activity
    NULL,
    '00000000-0000-0000-0000-000000000001',
    'created',
    'company',
    '10000000-0000-0000-0000-000000000002',
    'Tạo công ty mới: Cafe Sabo Hà Nội'
  );

-- ============================================================================
-- STEP 7: CREATE REVENUE SUMMARY (Pre-aggregated cho Analytics)
-- ============================================================================

-- Weekly summary cho HCM company
INSERT INTO public.revenue_summary (
  company_id, 
  branch_id, 
  period_type, 
  period_start, 
  period_end,
  total_revenue,
  total_orders,
  total_customers,
  avg_order_value,
  growth_percentage
)
VALUES 
  (
    '10000000-0000-0000-0000-000000000001',
    NULL, -- Company-wide
    'week',
    CURRENT_DATE - interval '7 days',
    CURRENT_DATE,
    150000000, -- 150M VNĐ
    500,
    600,
    300000, -- 300k/order
    12.5
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    NULL,
    'week',
    CURRENT_DATE - interval '7 days',
    CURRENT_DATE,
    80000000, -- 80M VNĐ
    250,
    300,
    320000,
    8.3
  );

-- Monthly summary
INSERT INTO public.revenue_summary (
  company_id, 
  branch_id, 
  period_type, 
  period_start, 
  period_end,
  total_revenue,
  total_orders,
  total_customers,
  avg_order_value,
  growth_percentage
)
VALUES 
  (
    '10000000-0000-0000-0000-000000000001',
    NULL,
    'month',
    DATE_TRUNC('month', CURRENT_DATE),
    CURRENT_DATE,
    600000000, -- 600M VNĐ
    2000,
    2400,
    300000,
    15.2
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    NULL,
    'month',
    DATE_TRUNC('month', CURRENT_DATE),
    CURRENT_DATE,
    320000000, -- 320M VNĐ
    1000,
    1200,
    320000,
    10.5
  );

-- ============================================================================
-- 🎯 SUMMARY
-- ============================================================================
--
-- Users created: 5
-- - 1 CEO (full access)
-- - 3 Branch Managers (HCM-Q1, HCM-Q3, HN-HK)
-- - 1 Staff (HCM-Q1)
--
-- Companies created: 2
-- - Nhà hàng Sabo HCM (restaurant)
-- - Cafe Sabo Hà Nội (cafe)
--
-- Branches created: 3
-- - HCM-Q1, HCM-Q3 (Sabo HCM)
-- - HN-HK (Sabo Hà Nội)
--
-- Daily revenue: 90 records (30 days × 3 branches)
-- Activity logs: 5 recent activities
-- Revenue summaries: 4 (weekly + monthly for 2 companies)
--
-- ✅ CEO Dashboard will show:
-- - Total revenue: ~920M VNĐ (last month)
-- - Companies: 2
-- - Employees: 5
-- - Branches: 3
-- - Recent activities: 5
--
-- ✅ CEO Companies page will show:
-- - 2 companies with stats
-- - CRUD operations ready
--
-- ✅ CEO Analytics will show:
-- - Week/Month summaries
-- - Growth percentages
-- - Company comparisons
--
-- ⚠️ NEXT STEPS:
-- 1. Run migration: node migrate-new-database.js
-- 2. Enable Auth Hook in Dashboard
-- 3. Create real CEO user via Supabase Auth
-- 4. Update user ID in this seed file
-- 5. Re-run seed data
-- 6. Test login and verify JWT has custom claims
--
-- ============================================================================
