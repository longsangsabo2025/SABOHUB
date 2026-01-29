"""
Add missing assigned_to_name column to tasks table - Simple version
"""
import psycopg2

print("🔧 Connecting to database...")

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)

cur = conn.cursor()

print("📋 Checking current tasks table schema...")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'tasks' 
    ORDER BY ordinal_position
""")

columns = cur.fetchall()
print("\nCurrent columns:")
for col in columns:
    print(f"  - {col[0]}: {col[1]}")

# Check if assigned_to_name exists
has_assigned_to_name = any(col[0] == 'assigned_to_name' for col in columns)

if has_assigned_to_name:
    print("\n✅ Column 'assigned_to_name' already exists!")
else:
    print("\n⚠️ Column 'assigned_to_name' is missing. Adding now...")
    
    try:
        # Add column
        cur.execute("""
            ALTER TABLE tasks 
            ADD COLUMN assigned_to_name TEXT;
        """)
        
        print("✅ Column added!")
        
        # Add index
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
            ON tasks(assigned_to_name);
        """)
        
        print("✅ Index created!")
        
        # Add comment
        cur.execute("""
            COMMENT ON COLUMN tasks.assigned_to_name 
            IS 'Cached name of the assigned user for display purposes';
        """)
        
        print("✅ Comment added!")
        
        conn.commit()
        
        print("\n🎉 Successfully added assigned_to_name column!")
        
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
        
    except Exception as e:
        print(f"❌ Error: {e}")
        conn.rollback()

cur.close()
conn.close()

print("\n✅ Done!")
