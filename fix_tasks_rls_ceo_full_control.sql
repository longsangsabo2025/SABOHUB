-- FIX RLS POLICIES FOR TASKS - CEO FULL CONTROL
-- CEO phải có quyền tuyệt đối: SELECT, INSERT, UPDATE, DELETE tất cả tasks của công ty

-- 1. DROP các policies cũ có vấn đề
DROP POLICY IF EXISTS "ceo_tasks_select" ON tasks;
DROP POLICY IF EXISTS "ceo_tasks_update" ON tasks;
DROP POLICY IF EXISTS "CEO can update tasks" ON tasks;
DROP POLICY IF EXISTS "Users can view company tasks" ON tasks;

-- 2. CREATE lại policies ĐƠN GIẢN cho CEO
-- CEO SELECT: Xem TẤT CẢ tasks (kể cả đã xóa) của công ty mình
CREATE POLICY "ceo_tasks_select" ON tasks
FOR SELECT
USING (
  company_id IN (
    SELECT id FROM companies WHERE created_by = auth.uid()
  )
);

-- CEO UPDATE: Sửa TẤT CẢ tasks (kể cả đã xóa) của công ty mình
CREATE POLICY "ceo_tasks_update" ON tasks
FOR UPDATE
USING (
  company_id IN (
    SELECT id FROM companies WHERE created_by = auth.uid()
  )
)
WITH CHECK (
  company_id IN (
    SELECT id FROM companies WHERE created_by = auth.uid()
  )
);

-- CEO DELETE: Xóa vĩnh viễn tasks (nếu cần)
CREATE POLICY "ceo_tasks_delete" ON tasks
FOR DELETE
USING (
  company_id IN (
    SELECT id FROM companies WHERE created_by = auth.uid()
  )
);

-- 3. Employees xem tasks được assign cho mình (chỉ tasks ACTIVE)
CREATE POLICY "employees_view_assigned_tasks" ON tasks
FOR SELECT
USING (
  deleted_at IS NULL
  AND assigned_to IN (
    SELECT id FROM employees 
    WHERE company_id IN (
      SELECT id FROM companies WHERE created_by = auth.uid()
    )
  )
);

-- 4. Verify policies
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'tasks'
ORDER BY policyname;
