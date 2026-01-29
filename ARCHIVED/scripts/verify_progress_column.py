"""
Verify progress column was added to tasks table
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Check if progress column exists
    cur.execute("""
        SELECT column_name, data_type, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = 'tasks'
        AND column_name = 'progress';
    """)
    
    result = cur.fetchone()
    
    if result:
        print("✅ Progress column exists in tasks table!")
        print(f"   Column: {result[0]}")
        print(f"   Type: {result[1]}")
        print(f"   Default: {result[2]}")
        print(f"   Nullable: {result[3]}")
    else:
        print("❌ Progress column NOT found in tasks table")
    
    # Also list all columns in tasks table
    print("\n📋 All columns in tasks table:")
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = 'tasks'
        ORDER BY ordinal_position;
    """)
    
    for row in cur.fetchall():
        print(f"   - {row[0]} ({row[1]})")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
