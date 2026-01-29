"""
Check role constraint in users table
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("🔍 Checking role constraint in users table...")
    print("="*80)
    
    # Get check constraints on users table
    cur.execute("""
        SELECT 
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS constraint_definition
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'users'
        AND nsp.nspname = 'public'
        AND con.contype = 'c'
        ORDER BY con.conname;
    """)
    
    constraints = cur.fetchall()
    
    if constraints:
        print("Check constraints found:")
        for name, definition in constraints:
            print(f"\n  {name}:")
            print(f"    {definition}")
    else:
        print("No check constraints found")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
