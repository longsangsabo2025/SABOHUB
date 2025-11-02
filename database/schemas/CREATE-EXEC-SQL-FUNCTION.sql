-- ============================================================================
-- CREATE EXEC_SQL FUNCTION
-- ============================================================================
-- This function allows executing arbitrary SQL via RPC
-- SECURITY: Only accessible with service_role key
-- ============================================================================

-- Drop existing function if it exists (in case of different signature)
DROP FUNCTION IF EXISTS exec_sql(text);

CREATE OR REPLACE FUNCTION exec_sql(query text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  EXECUTE query;
END;
$$;

-- Grant execute permission to service_role only
REVOKE ALL ON FUNCTION exec_sql(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION exec_sql(text) TO service_role;

-- Add comment
COMMENT ON FUNCTION exec_sql(text) IS 'Execute arbitrary SQL - Only accessible via service_role';
