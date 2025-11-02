-- ========================================
-- SABOHUB - PERFORMANCE INDEXES MIGRATION
-- ========================================
-- Created: 2025-10-15
-- Purpose: Add critical indexes for production performance
-- Estimated Impact: 10-100x faster queries on large datasets
-- ========================================

-- Enable pg_stat_statements for query monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ========================================
-- USERS & AUTHENTICATION INDEXES
-- ========================================

-- Index for filtering users by store (most common query)
CREATE INDEX IF NOT EXISTS idx_users_store_id 
ON public.users(store_id) 
WHERE store_id IS NOT NULL;

-- Index for role-based queries and authorization checks
CREATE INDEX IF NOT EXISTS idx_users_role 
ON public.users(role);

-- Index for login lookup (email is unique but index helps)
CREATE INDEX IF NOT EXISTS idx_users_email 
ON public.users(email);

-- Composite index for store + role queries (CEO/Manager dashboards)
CREATE INDEX IF NOT EXISTS idx_users_store_role 
ON public.users(store_id, role) 
WHERE store_id IS NOT NULL;

-- ========================================
-- TABLES & SESSIONS INDEXES
-- ========================================

-- Most critical: Filter tables by store and status
CREATE INDEX IF NOT EXISTS idx_tables_store_status 
ON public.tables(store_id, status);

-- For quick lookup of active session
CREATE INDEX IF NOT EXISTS idx_tables_current_session 
ON public.tables(current_session_id) 
WHERE current_session_id IS NOT NULL;

-- For table availability queries
CREATE INDEX IF NOT EXISTS idx_tables_store_type_status 
ON public.tables(store_id, table_type, status);

-- Session queries by table and status (most common)
CREATE INDEX IF NOT EXISTS idx_sessions_table_status 
ON public.table_sessions(table_id, status);

-- For revenue calculations and reports (ORDER BY created_at DESC)
CREATE INDEX IF NOT EXISTS idx_sessions_created_at_desc 
ON public.table_sessions(created_at DESC);

-- For calculating today's revenue
CREATE INDEX IF NOT EXISTS idx_sessions_store_date_status 
ON public.table_sessions(
  ((created_at AT TIME ZONE 'UTC')::date), 
  status
) WHERE status = 'COMPLETED';

-- For finding active sessions
CREATE INDEX IF NOT EXISTS idx_sessions_status_start_time 
ON public.table_sessions(status, start_time) 
WHERE status IN ('ACTIVE', 'PAUSED');

-- ========================================
-- ORDERS & PRODUCTS INDEXES
-- ========================================

-- Orders by session (for invoice generation)
CREATE INDEX IF NOT EXISTS idx_orders_session_id 
ON public.orders(session_id);

-- Orders by product (for inventory deduction)
CREATE INDEX IF NOT EXISTS idx_orders_product_id 
ON public.orders(product_id) 
WHERE product_id IS NOT NULL;

-- Orders by date for reports
CREATE INDEX IF NOT EXISTS idx_orders_created_at_desc 
ON public.orders(created_at DESC);

-- Products by store and category (menu display)
CREATE INDEX IF NOT EXISTS idx_products_store_category 
ON public.products(store_id, category) 
WHERE is_active = true;

-- Active products only
CREATE INDEX IF NOT EXISTS idx_products_active 
ON public.products(store_id, is_active);

-- ========================================
-- INVENTORY INDEXES
-- ========================================

-- Inventory by store and category (most common filter)
CREATE INDEX IF NOT EXISTS idx_inventory_store_category 
ON public.inventory(store_id, category);

-- Low stock alerts (critical for operations)
CREATE INDEX IF NOT EXISTS idx_inventory_low_stock 
ON public.inventory(store_id, quantity, min_threshold) 
WHERE quantity <= min_threshold;

-- All inventory items that need restocking
CREATE INDEX IF NOT EXISTS idx_inventory_needs_restock 
ON public.inventory(store_id) 
WHERE quantity < min_threshold;

-- Inventory transactions by item
CREATE INDEX IF NOT EXISTS idx_inventory_transactions_item 
ON public.inventory_transactions(inventory_id, created_at DESC);

-- ========================================
-- TASKS & ALERTS INDEXES
-- ========================================

-- Tasks by store, status, and assignee (most common dashboard query)
CREATE INDEX IF NOT EXISTS idx_tasks_store_status_assigned 
ON public.tasks(store_id, status, assigned_to);

-- Tasks by assignee and status (staff task list)
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status 
ON public.tasks(assigned_to, status) 
WHERE assigned_to IS NOT NULL;

-- Overdue tasks (for reminders)
CREATE INDEX IF NOT EXISTS idx_tasks_overdue 
ON public.tasks(deadline, status) 
WHERE deadline < NOW() AND status NOT IN ('COMPLETED', 'CANCELLED');

-- Tasks by priority for sorting
CREATE INDEX IF NOT EXISTS idx_tasks_priority_deadline 
ON public.tasks(priority, deadline);

-- Alerts by store, severity, and read status (critical for dashboard)
CREATE INDEX IF NOT EXISTS idx_alerts_store_severity_read 
ON public.alerts(store_id, severity, is_read);

-- Unread alerts only
CREATE INDEX IF NOT EXISTS idx_alerts_unread 
ON public.alerts(store_id, created_at DESC) 
WHERE is_read = false;

-- Alerts by type and severity
CREATE INDEX IF NOT EXISTS idx_alerts_type_severity 
ON public.alerts(type, severity, created_at DESC);

-- ========================================
-- KPI & PERFORMANCE INDEXES
-- ========================================

-- KPI evaluations by user and period (monthly reports)
CREATE INDEX IF NOT EXISTS idx_kpi_user_period 
ON public.kpi_evaluations(user_id, year, month);

-- KPI leaderboard queries
CREATE INDEX IF NOT EXISTS idx_kpi_store_period_score 
ON public.kpi_evaluations(store_id, year, month, total_score DESC);

-- Current month KPI
CREATE INDEX IF NOT EXISTS idx_kpi_current_month 
ON public.kpi_evaluations(
  store_id, 
  year, 
  month
) WHERE year = EXTRACT(YEAR FROM CURRENT_DATE) 
  AND month = EXTRACT(MONTH FROM CURRENT_DATE);

-- ========================================
-- ATTENDANCE & SHIFTS INDEXES
-- ========================================

-- Attendance by user and shift
CREATE INDEX IF NOT EXISTS idx_attendance_user_shift 
ON public.attendance(user_id, shift_id);

-- Attendance by user and date (for reports)
CREATE INDEX IF NOT EXISTS idx_attendance_user_checkin 
ON public.attendance(user_id, check_in DESC);

-- Today's attendance
CREATE INDEX IF NOT EXISTS idx_attendance_today 
ON public.attendance(store_id, check_in) 
WHERE (check_in AT TIME ZONE 'UTC')::date = CURRENT_DATE;

-- Late check-ins
CREATE INDEX IF NOT EXISTS idx_attendance_late 
ON public.attendance(store_id, is_late) 
WHERE is_late = true;

-- Shifts by store and date
CREATE INDEX IF NOT EXISTS idx_shifts_store_date 
ON public.shifts(store_id, shift_date);

-- Shift assignments by user
CREATE INDEX IF NOT EXISTS idx_shift_assignments_user 
ON public.shift_assignments(user_id, shift_id);

-- ========================================
-- SHIFT REPORTS INDEXES
-- ========================================

-- Shift reports by shift (unique constraint already exists)
CREATE INDEX IF NOT EXISTS idx_shift_reports_shift_id 
ON public.shift_reports(shift_id);

-- Reports by store and date
CREATE INDEX IF NOT EXISTS idx_shift_reports_store_created 
ON public.shift_reports(store_id, created_at DESC);

-- ========================================
-- PURCHASE REQUESTS INDEXES
-- ========================================

-- Purchase requests by store and status
CREATE INDEX IF NOT EXISTS idx_purchase_requests_store_status 
ON public.purchase_requests(store_id, status);

-- Pending requests (for approval workflow)
CREATE INDEX IF NOT EXISTS idx_purchase_requests_pending 
ON public.purchase_requests(store_id, created_at DESC) 
WHERE status = 'PENDING';

-- Requests by requester
CREATE INDEX IF NOT EXISTS idx_purchase_requests_requester 
ON public.purchase_requests(requested_by, status);

-- ========================================
-- INVOICES & PAYMENTS INDEXES
-- ========================================

-- Invoices by store and status
CREATE INDEX IF NOT EXISTS idx_invoices_store_status 
ON public.invoices(store_id, status);

-- Invoices by date for reports
CREATE INDEX IF NOT EXISTS idx_invoices_created_at_desc 
ON public.invoices(created_at DESC);

-- Unpaid invoices
CREATE INDEX IF NOT EXISTS idx_invoices_unpaid 
ON public.invoices(store_id, created_at DESC) 
WHERE status = 'PENDING';

-- Payments by invoice
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id 
ON public.payments(invoice_id);

-- Payments by method and status (for analytics)
CREATE INDEX IF NOT EXISTS idx_payments_method_status 
ON public.payments(payment_method, status, created_at DESC);

-- Failed payments
CREATE INDEX IF NOT EXISTS idx_payments_failed 
ON public.payments(created_at DESC) 
WHERE status = 'FAILED';

-- ========================================
-- ACTIVITY LOGS INDEXES
-- ========================================

-- Activity logs by user
CREATE INDEX IF NOT EXISTS idx_activity_logs_user 
ON public.activity_logs(user_id, created_at DESC);

-- Activity logs by store
CREATE INDEX IF NOT EXISTS idx_activity_logs_store 
ON public.activity_logs(store_id, created_at DESC) 
WHERE store_id IS NOT NULL;

-- Activity logs by action type
CREATE INDEX IF NOT EXISTS idx_activity_logs_action 
ON public.activity_logs(action, created_at DESC);

-- Recent activity (last 30 days)
CREATE INDEX IF NOT EXISTS idx_activity_logs_recent 
ON public.activity_logs(created_at DESC) 
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- ========================================
-- MAINTENANCE & INCIDENTS INDEXES
-- ========================================

-- Maintenance logs by store and status
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_store_status 
ON public.maintenance_logs(store_id, status);

-- Pending maintenance
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_pending 
ON public.maintenance_logs(store_id, created_at DESC) 
WHERE status IN ('PENDING', 'IN_PROGRESS');

-- Maintenance by table
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_table 
ON public.maintenance_logs(table_id, created_at DESC) 
WHERE table_id IS NOT NULL;

-- ========================================
-- NOTIFICATIONS INDEXES
-- ========================================

-- Notifications by recipient and read status
CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
ON public.notifications(user_id, is_read, created_at DESC) 
WHERE user_id IS NOT NULL;

-- Unread notifications count
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON public.notifications(user_id) 
WHERE is_read = false AND user_id IS NOT NULL;

-- ========================================
-- PARTIAL INDEXES FOR COMMON QUERIES
-- ========================================

-- Active tables only (most queries filter by status)
CREATE INDEX IF NOT EXISTS idx_tables_active 
ON public.tables(store_id, table_number) 
WHERE status != 'MAINTENANCE';

-- Completed sessions for revenue calculations
CREATE INDEX IF NOT EXISTS idx_sessions_completed 
ON public.table_sessions(created_at DESC, total_amount) 
WHERE status = 'COMPLETED';

-- Active sessions for real-time display
CREATE INDEX IF NOT EXISTS idx_sessions_active 
ON public.table_sessions(table_id, start_time) 
WHERE status IN ('ACTIVE', 'PAUSED');

-- ========================================
-- COVERING INDEXES (Include commonly selected columns)
-- ========================================

-- Tables with session info (avoids table lookup)
CREATE INDEX IF NOT EXISTS idx_tables_status_covering 
ON public.tables(store_id, status) 
INCLUDE (table_number, table_type, hourly_rate);

-- Sessions with amount info
CREATE INDEX IF NOT EXISTS idx_sessions_completed_covering 
ON public.table_sessions(created_at DESC) 
INCLUDE (total_amount, table_amount, orders_amount) 
WHERE status = 'COMPLETED';

-- ========================================
-- ANALYZE TABLES (Update statistics)
-- ========================================

ANALYZE public.users;
ANALYZE public.stores;
ANALYZE public.tables;
ANALYZE public.table_sessions;
ANALYZE public.orders;
ANALYZE public.products;
ANALYZE public.inventory;
ANALYZE public.tasks;
ANALYZE public.alerts;
ANALYZE public.kpi_evaluations;
ANALYZE public.attendance;
ANALYZE public.shifts;
ANALYZE public.shift_reports;
ANALYZE public.purchase_requests;
ANALYZE public.invoices;
ANALYZE public.payments;
ANALYZE public.activity_logs;
ANALYZE public.maintenance_logs;
ANALYZE public.notifications;

-- ========================================
-- VERIFY INDEXES
-- ========================================

-- Query to verify all indexes were created
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- ========================================
-- PERFORMANCE MONITORING QUERIES
-- ========================================

-- After running this migration, use these queries to monitor:

-- 1. Check index usage
-- SELECT 
--   schemaname,
--   tablename,
--   indexname,
--   idx_scan as index_scans,
--   idx_tup_read as tuples_read,
--   idx_tup_fetch as tuples_fetched
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY idx_scan DESC;

-- 2. Check slow queries
-- SELECT 
--   query,
--   calls,
--   total_time,
--   mean_time,
--   max_time
-- FROM pg_stat_statements
-- WHERE query NOT LIKE '%pg_stat%'
-- ORDER BY mean_time DESC
-- LIMIT 20;

-- 3. Check table sizes
-- SELECT 
--   schemaname,
--   tablename,
--   pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ========================================
-- MIGRATION COMPLETE
-- ========================================
-- Total indexes created: 60+
-- Estimated performance improvement: 10-100x on large datasets
-- Next: Monitor query performance and adjust as needed
-- ========================================

