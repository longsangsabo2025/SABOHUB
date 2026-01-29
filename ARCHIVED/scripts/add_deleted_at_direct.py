"""
Direct SQL execution to add deleted_at column to users table
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Parse connection string
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("🔧 Connecting to database...")

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    
    print("✅ Connected successfully!")
    
    # Add deleted_at column
    print("\n🔧 Adding deleted_at column to users table...")
    cursor.execute("""
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;
    """)
    
    conn.commit()
    print("✅ Column added successfully!")
    
    # Verify
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'deleted_at';
    """)
    
    result = cursor.fetchone()
    if result:
        print(f"✅ Verified: deleted_at column exists ({result[1]})")
    else:
        print("❌ Verification failed: Column not found")
    
    cursor.close()
    conn.close()
    
    print("\n✅ Migration complete!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
