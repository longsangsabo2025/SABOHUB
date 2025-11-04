
        CREATE OR REPLACE FUNCTION test_simple()
        RETURNS text
        LANGUAGE sql
        AS $$
            SELECT 'Function creation test successful' as result;
        $$;
        