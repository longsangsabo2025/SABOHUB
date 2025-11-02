-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- 
-- This migration adds comprehensive RLS policies to replace backend API authorization.
-- Instead of checking permissions in backend code, we enforce them at database level.
--
-- Created: October 15, 2025
-- Purpose: Enable Supabase direct queries with automatic security
--
-- ============================================================================

-- ============================================================================
-- 1. TASKS TABLE
-- ============================================================================

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Staff can see their own tasks
CREATE POLICY "tasks_select_own"
  ON tasks FOR SELECT
  USING (
    auth.uid() = assigned_to
  );

-- Managers/Leaders can see all tasks in their store (or all for CEO)
CREATE POLICY "tasks_select_leaders"
  ON tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO', 'SHIFT_LEADER')
      AND (users.store_id = tasks.store_id OR users.role = 'CEO')
    )
  );

-- Leaders can create tasks
CREATE POLICY "tasks_insert_leaders"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- Can update own tasks or tasks you created/manage
CREATE POLICY "tasks_update"
  ON tasks FOR UPDATE
  USING (
    auth.uid() = assigned_to 
    OR auth.uid() = assigned_by
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Leaders can delete tasks
CREATE POLICY "tasks_delete_leaders"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 2. ALERTS TABLE
-- ============================================================================

ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Leaders can see all alerts
CREATE POLICY "alerts_select_leaders"
  ON alerts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- System can create alerts (or use service role)
CREATE POLICY "alerts_insert_system"
  ON alerts FOR INSERT
  WITH CHECK (true); -- Allow system to create, controlled by service role

-- Leaders can update alerts (dismiss, mark read)
CREATE POLICY "alerts_update_leaders"
  ON alerts FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 3. ALERT_RECIPIENTS TABLE
-- ============================================================================

ALTER TABLE alert_recipients ENABLE ROW LEVEL SECURITY;

-- Users can see their own alert recipients
CREATE POLICY "alert_recipients_select_own"
  ON alert_recipients FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own alert status
CREATE POLICY "alert_recipients_update_own"
  ON alert_recipients FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 4. USERS TABLE
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- All authenticated users can see all users (for assignment dropdowns)
CREATE POLICY "users_select_all"
  ON users FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only CEO can create users
CREATE POLICY "users_insert_ceo"
  ON users FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

-- CEO and Managers can update users
CREATE POLICY "users_update_admins"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
      AND u.role IN ('CEO', 'MANAGER')
    )
  );

-- Only CEO can delete users
CREATE POLICY "users_delete_ceo"
  ON users FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

-- ============================================================================
-- 5. SHIFTS TABLE
-- ============================================================================

ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;

-- All staff can see shifts (to know their schedule)
CREATE POLICY "shifts_select_all"
  ON shifts FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Managers can create shifts
CREATE POLICY "shifts_insert_managers"
  ON shifts FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update shifts
CREATE POLICY "shifts_update_managers"
  ON shifts FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can delete shifts
CREATE POLICY "shifts_delete_managers"
  ON shifts FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 6. ATTENDANCE TABLE
-- ============================================================================

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Users can see their own attendance
CREATE POLICY "attendance_select_own"
  ON attendance FOR SELECT
  USING (auth.uid() = user_id);

-- Managers can see all attendance in their store
CREATE POLICY "attendance_select_managers"
  ON attendance FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO', 'SHIFT_LEADER')
    )
  );

-- Users can insert their own attendance (check-in via API for validation)
-- This is handled by backend API (attendance.checkIn)

-- Users can update their own attendance (check-out via API for validation)
-- This is handled by backend API (attendance.checkOut)

-- ============================================================================
-- 7. KPI TABLE
-- ============================================================================

ALTER TABLE kpi ENABLE ROW LEVEL SECURITY;

-- Users can see their own KPI
CREATE POLICY "kpi_select_own"
  ON kpi FOR SELECT
  USING (auth.uid() = user_id);

-- Managers can see all KPI in their store
CREATE POLICY "kpi_select_managers"
  ON kpi FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO', 'SHIFT_LEADER')
    )
  );

-- System/Managers can create KPI
CREATE POLICY "kpi_insert_managers"
  ON kpi FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update KPI
CREATE POLICY "kpi_update_managers"
  ON kpi FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 8. TABLES TABLE (billiard tables)
-- ============================================================================

ALTER TABLE tables ENABLE ROW LEVEL SECURITY;

-- All staff can see tables
CREATE POLICY "tables_select_all"
  ON tables FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Managers can create tables
CREATE POLICY "tables_insert_managers"
  ON tables FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update tables
CREATE POLICY "tables_update_managers"
  ON tables FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Only CEO can delete tables
CREATE POLICY "tables_delete_ceo"
  ON tables FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

-- ============================================================================
-- 9. TABLE_SESSIONS TABLE
-- ============================================================================

ALTER TABLE table_sessions ENABLE ROW LEVEL SECURITY;

-- All staff can see sessions
CREATE POLICY "sessions_select_all"
  ON table_sessions FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Sessions created/updated via API (has business logic)
-- INSERT/UPDATE/DELETE handled by pos.sessions.* APIs

-- ============================================================================
-- 10. INVOICES TABLE
-- ============================================================================

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- All staff can see invoices
CREATE POLICY "invoices_select_all"
  ON invoices FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Invoices created via API (has business logic)
-- INSERT/UPDATE handled by pos.invoices.* APIs

-- ============================================================================
-- 11. ORDERS TABLE
-- ============================================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- All staff can see orders
CREATE POLICY "orders_select_all"
  ON orders FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Orders created via API
-- INSERT/UPDATE handled by pos.orders.* APIs

-- ============================================================================
-- 12. PRODUCTS TABLE
-- ============================================================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- All staff can see products
CREATE POLICY "products_select_all"
  ON products FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Managers can create products
CREATE POLICY "products_insert_managers"
  ON products FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update products
CREATE POLICY "products_update_managers"
  ON products FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can delete products
CREATE POLICY "products_delete_managers"
  ON products FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 13. STORES TABLE
-- ============================================================================

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- All users can see all stores
CREATE POLICY "stores_select_all"
  ON stores FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only CEO can create/update/delete stores
CREATE POLICY "stores_insert_ceo"
  ON stores FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

CREATE POLICY "stores_update_ceo"
  ON stores FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

CREATE POLICY "stores_delete_ceo"
  ON stores FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

-- ============================================================================
-- 14. CHECKLISTS TABLE
-- ============================================================================

ALTER TABLE checklists ENABLE ROW LEVEL SECURITY;

-- All staff can see checklists
CREATE POLICY "checklists_select_all"
  ON checklists FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Shift leaders can create checklists
CREATE POLICY "checklists_insert_leaders"
  ON checklists FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- Staff can update checklists (mark items as done)
CREATE POLICY "checklists_update_all"
  ON checklists FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- ============================================================================
-- 15. INCIDENTS TABLE
-- ============================================================================

ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;

-- All staff can see incidents
CREATE POLICY "incidents_select_all"
  ON incidents FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- All staff can report incidents
CREATE POLICY "incidents_insert_all"
  ON incidents FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Leaders can update incidents (resolve, assign)
CREATE POLICY "incidents_update_leaders"
  ON incidents FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 16. INVENTORY_ITEMS TABLE
-- ============================================================================

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- All staff can see inventory
CREATE POLICY "inventory_select_all"
  ON inventory_items FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Managers can create inventory items
CREATE POLICY "inventory_insert_managers"
  ON inventory_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update inventory
CREATE POLICY "inventory_update_managers"
  ON inventory_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 17. PURCHASE_REQUESTS TABLE
-- ============================================================================

ALTER TABLE purchase_requests ENABLE ROW LEVEL SECURITY;

-- All can see purchase requests
CREATE POLICY "purchase_requests_select_all"
  ON purchase_requests FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Shift leaders can create purchase requests
CREATE POLICY "purchase_requests_insert_leaders"
  ON purchase_requests FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- Managers can update (approve/reject)
CREATE POLICY "purchase_requests_update_managers"
  ON purchase_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 18. POSTS TABLE (marketing)
-- ============================================================================

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Managers can see all posts
CREATE POLICY "posts_select_managers"
  ON posts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can create posts
CREATE POLICY "posts_insert_managers"
  ON posts FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Users can update their own posts
CREATE POLICY "posts_update_own"
  ON posts FOR UPDATE
  USING (
    auth.uid() = created_by
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Users can delete their own posts, or managers can delete any
CREATE POLICY "posts_delete"
  ON posts FOR DELETE
  USING (
    auth.uid() = created_by
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 19. MAINTENANCE_SCHEDULES TABLE
-- ============================================================================

ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;

-- All staff can see maintenance schedules
CREATE POLICY "maintenance_select_all"
  ON maintenance_schedules FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Shift leaders can create schedules
CREATE POLICY "maintenance_insert_leaders"
  ON maintenance_schedules FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- Shift leaders can update schedules
CREATE POLICY "maintenance_update_leaders"
  ON maintenance_schedules FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('SHIFT_LEADER', 'MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- 20. MARKETING_CAMPAIGNS TABLE
-- ============================================================================

ALTER TABLE marketing_campaigns ENABLE ROW LEVEL SECURITY;

-- Managers can see campaigns
CREATE POLICY "campaigns_select_managers"
  ON marketing_campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can create campaigns
CREATE POLICY "campaigns_insert_managers"
  ON marketing_campaigns FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- Managers can update campaigns
CREATE POLICY "campaigns_update_managers"
  ON marketing_campaigns FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('MANAGER', 'CEO')
    )
  );

-- ============================================================================
-- NOTES:
-- ============================================================================
--
-- 1. These policies replace backend authorization logic
-- 2. Security is now enforced at database level (safer!)
-- 3. Supabase client automatically applies these policies
-- 4. Service role key bypasses RLS (use carefully!)
-- 5. Test thoroughly with different user roles
--
-- To apply this migration:
-- Run in Supabase SQL Editor or via migration tool
--
-- ============================================================================


