-- ===================================
-- SEED DATA FOR MANAGEMENT PAGES
-- Sample data for Operations, Staff, Tasks, Notifications
-- ===================================

-- ===================================
-- SAMPLE TASKS
-- ===================================
INSERT INTO public.tasks (
  title,
  description,
  priority,
  status,
  category,
  assigned_to,
  due_date,
  store_id,
  created_by
) VALUES
-- High Priority Tasks
('Kiểm tra bàn 5', 'Kiểm tra và sửa chữa đèn LED bàn 5', 'HIGH', 'TODO', 'MAINTENANCE', 
  (SELECT id FROM public.users WHERE role = 'TECHNICAL' LIMIT 1),
  NOW() + INTERVAL '2 hours',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1)
),
('Đặt hàng bia mới', 'Kho bia sắp hết, cần đặt hàng thêm 10 thùng', 'HIGH', 'IN_PROGRESS', 'INVENTORY',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  NOW() + INTERVAL '1 day',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1)
),
-- Medium Priority Tasks
('Vệ sinh khu vực VIP', 'Vệ sinh toàn bộ khu VIP trước 18h', 'MEDIUM', 'TODO', 'OPERATIONS',
  (SELECT id FROM public.users WHERE role = 'STAFF' OFFSET 1 LIMIT 1),
  NOW() + INTERVAL '6 hours',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'SHIFT_LEADER' LIMIT 1)
),
('Kiểm kê tồn kho', 'Kiểm kê tồn kho cuối tháng', 'MEDIUM', 'TODO', 'INVENTORY',
  (SELECT id FROM public.users WHERE role = 'STAFF' OFFSET 2 LIMIT 1),
  NOW() + INTERVAL '3 days',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1)
),
-- Low Priority Tasks  
('Cập nhật menu đồ uống', 'Thiết kế menu mới cho mùa hè', 'LOW', 'TODO', 'CUSTOMER_SERVICE',
  (SELECT id FROM public.users WHERE role = 'STAFF' OFFSET 3 LIMIT 1),
  NOW() + INTERVAL '1 week',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1)
),
-- Completed Tasks
('Sửa bàn 3', 'Đã thay nỉ mới cho bàn 3', 'HIGH', 'COMPLETED', 'MAINTENANCE',
  (SELECT id FROM public.users WHERE role = 'TECHNICAL' LIMIT 1),
  NOW() - INTERVAL '1 day',
  (SELECT id FROM public.stores LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1)
);

-- Update completed_at for completed task
UPDATE public.tasks 
SET completed_at = NOW() - INTERVAL '2 hours'
WHERE status = 'COMPLETED';

-- ===================================
-- SAMPLE NOTIFICATIONS
-- ===================================
INSERT INTO public.notifications (
  recipient_id,
  sender_id,
  title,
  message,
  type,
  priority,
  is_read
) VALUES
-- System Notifications
((SELECT id FROM public.users WHERE role = 'CEO' LIMIT 1),
  NULL,
  'Hệ thống cập nhật',
  'Hệ thống đã được cập nhật lên phiên bản 1.0.0',
  'SYSTEM',
  'MEDIUM',
  FALSE
),
-- Revenue Notifications
((SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1),
  NULL,
  'Doanh thu vượt mục tiêu',
  'Doanh thu hôm nay đã vượt 15 triệu đồng!',
  'REVENUE',
  'HIGH',
  FALSE
),
-- Staff Notifications
((SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1),
  NULL,
  'Nhân viên mới check-in',
  'Nguyễn Văn A đã check-in lúc 08:00',
  'STAFF',
  'LOW',
  TRUE
),
-- Table Notifications
((SELECT id FROM public.users WHERE role = 'SHIFT_LEADER' LIMIT 1),
  NULL,
  'Bàn 5 cần bảo trì',
  'Bàn 5 đã được sử dụng hơn 100 giờ, cần kiểm tra',
  'TABLES',
  'HIGH',
  FALSE
),
-- Alert Notifications
((SELECT id FROM public.users WHERE role = 'CEO' LIMIT 1),
  NULL,
  'Cảnh báo: Kho hàng sắp hết',
  'Còn 5 chai bia, cần đặt hàng ngay',
  'ALERT',
  'HIGH',
  FALSE
),
-- Info Notifications
((SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.users WHERE role = 'MANAGER' LIMIT 1),
  'Lịch làm việc tuần sau',
  'Lịch làm việc tuần sau đã được cập nhật, vui lòng kiểm tra',
  'INFO',
  'MEDIUM',
  FALSE
);

-- Update read_at for read notifications
UPDATE public.notifications 
SET read_at = NOW() - INTERVAL '1 hour'
WHERE is_read = TRUE;

-- ===================================
-- SAMPLE ACTIVITIES
-- ===================================
INSERT INTO public.activities (
  type,
  timestamp,
  details,
  staff_id,
  staff_name,
  shift_id,
  table_id,
  store_id
) VALUES
-- Today's activities
('CHECK_IN', NOW() - INTERVAL '4 hours', 
  '{"early": false}',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  NULL,
  (SELECT id FROM public.stores LIMIT 1)
),
('TABLE_START', NOW() - INTERVAL '3 hours',
  '{"table_number": 1, "customer_name": "Nguyễn Văn A"}',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  (SELECT id FROM public.tables LIMIT 1),
  (SELECT id FROM public.stores LIMIT 1)
),
('ORDER', NOW() - INTERVAL '2 hours',
  '{"items": ["Bia Heineken", "Nước suối"], "total": 50000}',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  (SELECT id FROM public.tables LIMIT 1),
  (SELECT id FROM public.stores LIMIT 1)
),
('PAYMENT', NOW() - INTERVAL '1 hour',
  '{"amount": 350000, "method": "CASH"}',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  (SELECT id FROM public.tables LIMIT 1),
  (SELECT id FROM public.stores LIMIT 1)
),
('TABLE_END', NOW() - INTERVAL '30 minutes',
  '{"table_number": 1, "duration_minutes": 150, "total_amount": 350000}',
  (SELECT id FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'STAFF' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  (SELECT id FROM public.tables LIMIT 1),
  (SELECT id FROM public.stores LIMIT 1)
),
('MAINTENANCE', NOW() - INTERVAL '5 hours',
  '{"table_number": 3, "issue": "Thay nỉ mới", "technician": "Nguyễn Văn B"}',
  (SELECT id FROM public.users WHERE role = 'TECHNICAL' LIMIT 1),
  (SELECT name FROM public.users WHERE role = 'TECHNICAL' LIMIT 1),
  (SELECT id FROM public.shifts WHERE shift_date = CURRENT_DATE LIMIT 1),
  (SELECT id FROM public.tables OFFSET 2 LIMIT 1),
  (SELECT id FROM public.stores LIMIT 1)
);

-- ===================================
-- UPDATE SHIFT METRICS
-- ===================================
-- Update shift revenue based on activities
UPDATE public.shifts s
SET 
  revenue = COALESCE((
    SELECT SUM((details->>'total_amount')::DECIMAL)
    FROM public.activities
    WHERE shift_id = s.id AND type = 'PAYMENT'
  ), 0),
  activities_count = (
    SELECT COUNT(*)
    FROM public.activities
    WHERE shift_id = s.id
  ),
  updated_at = NOW()
WHERE shift_date = CURRENT_DATE;

-- ===================================
-- UPDATE USER METRICS
-- ===================================
-- Update user completed tasks count
UPDATE public.users u
SET 
  completed_tasks = (
    SELECT COUNT(*)
    FROM public.tasks
    WHERE assigned_to = u.id AND status = 'COMPLETED'
  ),
  total_shifts = (
    SELECT COUNT(DISTINCT shift_id)
    FROM public.shift_assignments
    WHERE user_id = u.id
  ),
  updated_at = NOW();

-- ===================================
-- VERIFICATION QUERIES
-- ===================================
-- Check tasks count
DO $$
DECLARE
  task_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO task_count FROM public.tasks;
  RAISE NOTICE 'Created % tasks', task_count;
END $$;

-- Check notifications count
DO $$
DECLARE
  notif_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO notif_count FROM public.notifications;
  RAISE NOTICE 'Created % notifications', notif_count;
END $$;

-- Check activities count
DO $$
DECLARE
  activity_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO activity_count FROM public.activities;
  RAISE NOTICE 'Created % activities', activity_count;
END $$;

