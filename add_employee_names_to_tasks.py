"""
Migration: Add employee names to tasks table
- Adds assigned_to_name, assigned_by_name, assigned_to_role columns
- Updates existing records with employee names
- Improves performance (no need to JOIN users table every time)
"""

import os
from supabase import create_client, Client

# Initialize Supabase client with hardcoded credentials (for now)
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.3vwY0FyHMqkGHG7mXIjrS57o86LwGLYptC2k4cvnTIQ"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def add_employee_columns_to_tasks():
    """Add employee name columns to tasks table"""
    print("\n📋 === ADDING EMPLOYEE NAMES TO TASKS TABLE ===\n")
    
    try:
        # Step 1: Add columns
        print("1️⃣ Adding columns to tasks table...")
        
        columns_sql = """
        -- Add employee name columns
        ALTER TABLE tasks 
        ADD COLUMN IF NOT EXISTS assigned_to_name TEXT,
        ADD COLUMN IF NOT EXISTS assigned_by_name TEXT,
        ADD COLUMN IF NOT EXISTS assigned_to_role TEXT;
        """
        
        result = supabase.rpc('exec_sql', {'sql': columns_sql}).execute()
        print("   ✅ Columns added: assigned_to_name, assigned_by_name, assigned_to_role")
        
        # Step 2: Update existing records
        print("\n2️⃣ Updating existing tasks with employee names...")
        
        update_sql = """
        -- Update assigned_to info
        UPDATE tasks t
        SET 
          assigned_to_name = u.name,
          assigned_to_role = u.role
        FROM users u
        WHERE t.assigned_to = u.id AND t.assigned_to_name IS NULL;
        
        -- Update assigned_by info  
        UPDATE tasks t
        SET assigned_by_name = u.name
        FROM users u
        WHERE t.assigned_by = u.id AND t.assigned_by_name IS NULL;
        """
        
        supabase.rpc('exec_sql', {'sql': update_sql}).execute()
        
        # Check how many records were updated
        tasks_result = supabase.table('tasks').select('id', count='exact').execute()
        total_tasks = tasks_result.count
        
        updated_result = supabase.table('tasks').select('id', count='exact').not_.is_('assigned_to_name', 'null').execute()
        updated_tasks = updated_result.count
        
        print(f"   ✅ Updated {updated_tasks}/{total_tasks} tasks with employee names")
        
        # Step 3: Create index for performance
        print("\n3️⃣ Creating performance indexes...")
        
        index_sql = """
        CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
        ON tasks(assigned_to_name) 
        WHERE assigned_to_name IS NOT NULL;
        
        CREATE INDEX IF NOT EXISTS idx_tasks_company_assignee 
        ON tasks(company_id, assigned_to);
        """
        
        supabase.rpc('exec_sql', {'sql': index_sql}).execute()
        print("   ✅ Indexes created for better query performance")
        
        # Step 4: Verify schema
        print("\n4️⃣ Verifying tasks table schema...")
        
        # Get sample task with new columns
        sample = supabase.table('tasks').select('id, title, assigned_to_name, assigned_by_name, assigned_to_role').limit(1).execute()
        
        if sample.data:
            task = sample.data[0]
            print(f"   ✅ Sample task:")
            print(f"      - Title: {task.get('title', 'N/A')}")
            print(f"      - Assigned to: {task.get('assigned_to_name', 'NULL')}")
            print(f"      - Assigned by: {task.get('assigned_by_name', 'NULL')}")
            print(f"      - Role: {task.get('assigned_to_role', 'NULL')}")
        
        print("\n✅ === MIGRATION COMPLETED SUCCESSFULLY ===\n")
        
        # Summary
        print("📊 SUMMARY:")
        print(f"   • Total tasks: {total_tasks}")
        print(f"   • Tasks with names: {updated_tasks}")
        print(f"   • New columns: 3 (assigned_to_name, assigned_by_name, assigned_to_role)")
        print(f"   • New indexes: 2")
        print("\n💡 NEXT STEPS:")
        print("   1. Update TaskService.createTask() to populate these fields")
        print("   2. Update TaskService.updateTask() to maintain name consistency")
        print("   3. Update UI to display names instead of UUIDs")
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        print("\nTrying alternative approach without RPC...")
        
        # Alternative: Direct SQL execution
        try:
            print("\n🔄 Using PostgreSQL direct execution...")
            
            # Note: This requires the exec_sql RPC function to be created
            # If it doesn't exist, we'll use Supabase REST API directly
            
            print("⚠️ Cannot proceed without exec_sql RPC function.")
            print("\nPlease run this SQL manually in Supabase SQL Editor:")
            print("\n" + "="*60)
            print("""
-- Add columns
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to_name TEXT,
ADD COLUMN IF NOT EXISTS assigned_by_name TEXT,
ADD COLUMN IF NOT EXISTS assigned_to_role TEXT;

-- Update existing records
UPDATE tasks t
SET 
  assigned_to_name = u.name,
  assigned_to_role = u.role
FROM users u
WHERE t.assigned_to = u.id AND t.assigned_to_name IS NULL;

UPDATE tasks t
SET assigned_by_name = u.name
FROM users u
WHERE t.assigned_by = u.id AND t.assigned_by_name IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
ON tasks(assigned_to_name) 
WHERE assigned_to_name IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_company_assignee 
ON tasks(company_id, assigned_to);
            """)
            print("="*60)
            
        except Exception as e2:
            print(f"❌ Alternative approach also failed: {str(e2)}")

if __name__ == "__main__":
    add_employee_columns_to_tasks()
