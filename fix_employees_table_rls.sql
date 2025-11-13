-- Fix RLS policies for employees table to allow CEO access

-- Drop existing policies if any
DROP POLICY IF EXISTS "ceo_select_employees" ON public.employees;

-- Create policy for CEO to SELECT employees
CREATE POLICY "ceo_select_employees"
  ON public.employees
  FOR SELECT
  USING (
    -- Allow if user is CEO of the company
    EXISTS (
      SELECT 1 FROM public.companies
      WHERE companies.id = employees.company_id
      AND companies.created_by = auth.uid()
    )
    OR
    -- Allow service role (for Supabase operations)
    auth.jwt() ->> 'role' = 'service_role'
  );

-- Verify RLS is enabled
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Test query (run this to verify)
-- SELECT * FROM public.employees WHERE company_id = 'feef10d3-899d-4554-8107-b2256918213a';
