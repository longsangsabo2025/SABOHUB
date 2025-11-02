
CREATE OR REPLACE FUNCTION exec_sql(sql_string text)
RETURNS text AS $$
DECLARE
  result text;
BEGIN
  EXECUTE sql_string;
  result := 'SQL executed successfully';
  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
