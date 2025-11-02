-- Rename tables from stores/users to companies/profiles terminology
-- This migration standardizes the naming convention to use "companies" instead of "stores"

BEGIN;

-- Rename the stores table to companies
ALTER TABLE stores RENAME TO companies;

-- Rename the users table to profiles (if it hasn't been renamed already)
-- ALTER TABLE users RENAME TO profiles;

-- Update any indexes that reference the old table names
-- DROP INDEX IF EXISTS idx_stores_name;
-- CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(name);

-- Update any RLS policies that reference old table names
-- This is a template - adjust based on your actual policies

-- Drop old policies on stores table (now companies)
DROP POLICY IF EXISTS "stores_select_policy" ON companies;
DROP POLICY IF EXISTS "stores_insert_policy" ON companies;
DROP POLICY IF EXISTS "stores_update_policy" ON companies;
DROP POLICY IF EXISTS "stores_delete_policy" ON companies;

-- Create new policies on companies table
CREATE POLICY "companies_select_policy" 
ON companies FOR SELECT 
USING (true); -- Adjust based on your security requirements

CREATE POLICY "companies_insert_policy" 
ON companies FOR INSERT 
WITH CHECK (true); -- Adjust based on your security requirements

CREATE POLICY "companies_update_policy" 
ON companies FOR UPDATE 
USING (true); -- Adjust based on your security requirements

CREATE POLICY "companies_delete_policy" 
ON companies FOR DELETE 
USING (true); -- Adjust based on your security requirements

-- Update any views that reference the old table names
-- DROP VIEW IF EXISTS stores_view;
-- CREATE VIEW companies_view AS SELECT * FROM companies;

-- Update any functions that reference old table names
-- This would need to be done case by case based on your actual functions

COMMIT;

-- Verification queries
SELECT 'companies' as table_name, count(*) as record_count FROM companies;