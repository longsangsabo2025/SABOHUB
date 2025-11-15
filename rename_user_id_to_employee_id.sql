-- Rename user_id to employee_id in daily_work_reports table
-- Since employees are stored in 'employees' table, not 'users' table

-- Step 1: Drop constraints that reference user_id
ALTER TABLE daily_work_reports 
DROP CONSTRAINT IF EXISTS unique_daily_report;

ALTER TABLE daily_work_reports 
DROP CONSTRAINT IF EXISTS daily_work_reports_user_id_fkey;

-- Step 2: Drop index
DROP INDEX IF EXISTS idx_daily_reports_user_id;

-- Step 3: Rename column (PostgreSQL syntax)
ALTER TABLE daily_work_reports 
RENAME COLUMN user_id TO employee_id;

-- Step 4: Re-create foreign key constraint
ALTER TABLE daily_work_reports 
ADD CONSTRAINT daily_work_reports_employee_id_fkey 
FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;

-- Step 5: Re-create unique constraint
ALTER TABLE daily_work_reports 
ADD CONSTRAINT unique_daily_report UNIQUE(employee_id, report_date);

-- Step 6: Re-create index
CREATE INDEX idx_daily_reports_employee_id ON daily_work_reports(employee_id);

-- Step 7: Update RLS policies to use employee_id
DROP POLICY IF EXISTS "CEO can view all reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Manager can view branch reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Staff can view own reports" ON daily_work_reports;
DROP POLICY IF EXISTS "CEO can insert reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Manager can insert reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Staff can insert own reports" ON daily_work_reports;
DROP POLICY IF EXISTS "CEO can update reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Manager can update reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Staff can update own reports" ON daily_work_reports;
DROP POLICY IF EXISTS "CEO can delete reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Manager can delete reports" ON daily_work_reports;
DROP POLICY IF EXISTS "Staff can delete own reports" ON daily_work_reports;

-- Re-create RLS policies with employee_id
-- SELECT Policies
CREATE POLICY "CEO can view all reports" ON daily_work_reports
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        JOIN companies c ON e.company_id = c.id
        WHERE e.id = auth.uid()::uuid
        AND c.owner_id = auth.uid()::uuid
    )
);

CREATE POLICY "Manager can view branch reports" ON daily_work_reports
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = auth.uid()::uuid
        AND e.role = 'MANAGER'
        AND e.branch_id = daily_work_reports.branch_id
    )
);

CREATE POLICY "Staff can view own reports" ON daily_work_reports
FOR SELECT TO authenticated
USING (employee_id = auth.uid()::uuid);

-- INSERT Policies
CREATE POLICY "CEO can insert reports" ON daily_work_reports
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM employees e
        JOIN companies c ON e.company_id = c.id
        WHERE e.id = auth.uid()::uuid
        AND c.owner_id = auth.uid()::uuid
    )
);

CREATE POLICY "Manager can insert reports" ON daily_work_reports
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = auth.uid()::uuid
        AND e.role = 'MANAGER'
        AND e.branch_id = daily_work_reports.branch_id
    )
);

CREATE POLICY "Staff can insert own reports" ON daily_work_reports
FOR INSERT TO authenticated
WITH CHECK (employee_id = auth.uid()::uuid);

-- UPDATE Policies
CREATE POLICY "CEO can update reports" ON daily_work_reports
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        JOIN companies c ON e.company_id = c.id
        WHERE e.id = auth.uid()::uuid
        AND c.owner_id = auth.uid()::uuid
    )
);

CREATE POLICY "Manager can update reports" ON daily_work_reports
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = auth.uid()::uuid
        AND e.role = 'MANAGER'
        AND e.branch_id = daily_work_reports.branch_id
    )
);

CREATE POLICY "Staff can update own reports" ON daily_work_reports
FOR UPDATE TO authenticated
USING (employee_id = auth.uid()::uuid);

-- DELETE Policies
CREATE POLICY "CEO can delete reports" ON daily_work_reports
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        JOIN companies c ON e.company_id = c.id
        WHERE e.id = auth.uid()::uuid
        AND c.owner_id = auth.uid()::uuid
    )
);

CREATE POLICY "Manager can delete reports" ON daily_work_reports
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM employees e
        WHERE e.id = auth.uid()::uuid
        AND e.role = 'MANAGER'
        AND e.branch_id = daily_work_reports.branch_id
    )
);

CREATE POLICY "Staff can delete own reports" ON daily_work_reports
FOR DELETE TO authenticated
USING (employee_id = auth.uid()::uuid);

-- Verify the change
SELECT 'Column renamed successfully!' as message,
       column_name, 
       data_type,
       is_nullable
FROM information_schema.columns
WHERE table_name = 'daily_work_reports'
AND column_name = 'employee_id';

