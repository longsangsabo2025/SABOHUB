#!/usr/bin/env python3
"""
Create RPC function to insert task - bypass PostgREST schema cache
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🔧 Creating RPC function: create_task_bypass...")

cur.execute("""
CREATE OR REPLACE FUNCTION create_task_bypass(
    p_branch_id UUID,
    p_company_id UUID,
    p_title TEXT,
    p_description TEXT,
    p_category TEXT,
    p_priority TEXT,
    p_status TEXT,
    p_recurrence TEXT,
    p_assigned_to UUID,
    p_assigned_to_name TEXT,
    p_assigned_to_role TEXT,
    p_due_date TIMESTAMPTZ,
    p_created_by UUID,
    p_created_by_name TEXT,
    p_notes TEXT
) RETURNS JSON AS $$
DECLARE
    v_task_id UUID;
    v_result JSON;
BEGIN
    INSERT INTO tasks (
        branch_id, company_id, title, description,
        category, priority, status, recurrence,
        assigned_to, assigned_to_name, assigned_to_role,
        due_date, created_by, created_by_name, notes, progress
    ) VALUES (
        p_branch_id, p_company_id, p_title, p_description,
        p_category, p_priority, p_status, p_recurrence,
        p_assigned_to, p_assigned_to_name, p_assigned_to_role,
        p_due_date, p_created_by, p_created_by_name, p_notes, 0
    ) RETURNING id INTO v_task_id;
    
    -- Fetch the created task
    SELECT row_to_json(t.*) INTO v_result
    FROM tasks t
    WHERE t.id = v_task_id;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")

print("✅ Created RPC function: create_task_bypass")

# Grant execute permission
cur.execute("GRANT EXECUTE ON FUNCTION create_task_bypass TO anon, authenticated;")
print("✅ Granted permissions to anon and authenticated roles")

cur.close()
conn.close()

print("\n🎯 Now Flutter app can use .rpc('create_task_bypass') to bypass schema cache!")
