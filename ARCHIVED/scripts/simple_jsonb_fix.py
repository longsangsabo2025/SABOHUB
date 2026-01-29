#!/usr/bin/env python3
"""
SIMPLE & EFFECTIVE: Use JSONB parameter to bypass all schema lookups
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

print("🎯 Creating JSONB-based insert function (bypasses ALL schema cache)...\n")

cur.execute("""
CREATE OR REPLACE FUNCTION create_task(task_data JSONB)
RETURNS JSONB AS $$
DECLARE
    new_id UUID;
    result JSONB;
BEGIN
    INSERT INTO tasks (
        branch_id, company_id, title, description,
        category, priority, status, recurrence,
        assigned_to, assigned_to_name, assigned_to_role,
        due_date, created_by, created_by_name, notes, progress
    ) VALUES (
        (task_data->>'branch_id')::UUID,
        (task_data->>'company_id')::UUID,
        task_data->>'title',
        task_data->>'description',
        task_data->>'category',
        task_data->>'priority',
        task_data->>'status',
        task_data->>'recurrence',
        (task_data->>'assigned_to')::UUID,
        task_data->>'assigned_to_name',
        task_data->>'assigned_to_role',
        (task_data->>'due_date')::TIMESTAMPTZ,
        (task_data->>'created_by')::UUID,
        task_data->>'created_by_name',
        task_data->>'notes',
        COALESCE((task_data->>'progress')::INTEGER, 0)
    ) RETURNING id INTO new_id;
    
    SELECT jsonb_build_object(
        'id', id::TEXT,
        'branch_id', branch_id::TEXT,
        'company_id', company_id::TEXT,
        'title', title,
        'description', description,
        'category', category,
        'priority', priority,
        'status', status,
        'recurrence', recurrence,
        'assigned_to', assigned_to::TEXT,
        'assigned_to_name', assigned_to_name,
        'assigned_to_role', assigned_to_role,
        'due_date', due_date::TEXT,
        'created_by', created_by::TEXT,
        'created_by_name', created_by_name,
        'created_at', created_at::TEXT,
        'updated_at', updated_at::TEXT,
        'notes', notes,
        'progress', progress,
        'deleted_at', deleted_at::TEXT
    ) INTO result
    FROM tasks
    WHERE id = new_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")
print("✅ Created create_task(task_data JSONB)")

cur.execute("GRANT EXECUTE ON FUNCTION create_task TO anon, authenticated;")
print("✅ Granted permissions")

# Send reload
for _ in range(5):
    cur.execute("NOTIFY pgrst, 'reload schema';")
print("✅ Sent reload signals")

print("\n" + "="*60)
print("📱 Flutter Usage:")
print("="*60)
print("""
final response = await supabase.rpc('create_task', params: {
  'task_data': {
    'branch_id': task.branchId,
    'company_id': task.companyId,
    'title': task.title,
    // ... other fields
  }
});
""")

cur.close()
conn.close()
