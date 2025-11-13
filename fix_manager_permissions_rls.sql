-- Drop existing RLS policies if any
DROP POLICY IF EXISTS "CEO can view all manager permissions in their company" ON manager_permissions;
DROP POLICY IF EXISTS "CEO can insert manager permissions in their company" ON manager_permissions;
DROP POLICY IF EXISTS "CEO can update manager permissions in their company" ON manager_permissions;
DROP POLICY IF EXISTS "CEO can delete manager permissions in their company" ON manager_permissions;
DROP POLICY IF EXISTS "Manager can view their own permissions" ON manager_permissions;

-- Enable RLS on manager_permissions table
ALTER TABLE manager_permissions ENABLE ROW LEVEL SECURITY;

-- Policy 1: CEO can SELECT all manager permissions in their company
CREATE POLICY "CEO can view all manager permissions in their company"
ON manager_permissions
FOR SELECT
USING (
  company_id IN (
    SELECT company_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND role = 'CEO'
  )
);

-- Policy 2: CEO can INSERT manager permissions in their company
CREATE POLICY "CEO can insert manager permissions in their company"
ON manager_permissions
FOR INSERT
WITH CHECK (
  company_id IN (
    SELECT company_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND role = 'CEO'
  )
);

-- Policy 3: CEO can UPDATE manager permissions in their company
CREATE POLICY "CEO can update manager permissions in their company"
ON manager_permissions
FOR UPDATE
USING (
  company_id IN (
    SELECT company_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND role = 'CEO'
  )
)
WITH CHECK (
  company_id IN (
    SELECT company_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND role = 'CEO'
  )
);

-- Policy 4: CEO can DELETE manager permissions in their company
CREATE POLICY "CEO can delete manager permissions in their company"
ON manager_permissions
FOR DELETE
USING (
  company_id IN (
    SELECT company_id 
    FROM employees 
    WHERE id = auth.uid() 
    AND role = 'CEO'
  )
);

-- Policy 5: Manager can view their own permissions (read-only)
CREATE POLICY "Manager can view their own permissions"
ON manager_permissions
FOR SELECT
USING (
  manager_id = auth.uid()
);

-- Verify policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'manager_permissions';
