"""
Add missing assigned_to_name column to tasks table
"""
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase_url = os.getenv('SUPABASE_URL')
supabase_service_role_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase = create_client(supabase_url, supabase_service_role_key)

# SQL to add the missing column
sql = """
-- Add assigned_to_name column if not exists
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to_name TEXT;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
ON tasks(assigned_to_name);

-- Add comment
COMMENT ON COLUMN tasks.assigned_to_name IS 'Cached name of the assigned user for display purposes';
"""

print("🔧 Adding assigned_to_name column to tasks table...")
print(f"SQL:\n{sql}\n")

try:
    result = supabase.rpc('exec_sql', {'query': sql}).execute()
    print("✅ Column added successfully!")
    print(f"Result: {result}")
except Exception as e:
    print(f"❌ Error: {e}")
    print("\nTrying alternative method...")
    
    # Try using postgrest directly
    try:
        import psycopg2
        
        conn = psycopg2.connect(
            host='aws-1-ap-southeast-2.pooler.supabase.com',
            port=6543,
            database='postgres',
            user='postgres.dqddxowyikefqcdiioyh',
            password='Acookingoil123'
        )
        
        cur = conn.cursor()
        
        # Add column
        cur.execute("""
            ALTER TABLE tasks 
            ADD COLUMN IF NOT EXISTS assigned_to_name TEXT;
        """)
        
        # Add index
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
            ON tasks(assigned_to_name);
        """)
        
        # Add comment
        cur.execute("""
            COMMENT ON COLUMN tasks.assigned_to_name 
            IS 'Cached name of the assigned user for display purposes';
        """)
        
        conn.commit()
        
        print("✅ Column added successfully using direct connection!")
        
        # Verify
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'assigned_to_name'
        """)
        
        result = cur.fetchone()
        if result:
            print(f"✅ Verified: {result[0]} ({result[1]})")
        else:
            print("⚠️ Column not found after creation")
        
        cur.close()
        conn.close()
        
    except Exception as e2:
        print(f"❌ Alternative method also failed: {e2}")
