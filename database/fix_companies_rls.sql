-- Enable RLS on companies table
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Policy: CEO can do everything with all companies
CREATE POLICY "ceo_all_companies"
ON companies
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'ceo'
  )
);

-- Policy: Manager can view companies they belong to
CREATE POLICY "manager_view_companies"
ON companies
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'manager'
    AND users.company_id = companies.id
  )
);

-- Policy: Employee can view their company
CREATE POLICY "employee_view_company"
ON companies
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'employee'
    AND users.company_id = companies.id
  )
);
