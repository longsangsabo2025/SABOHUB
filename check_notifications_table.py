import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

# Check for notification tables
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%notif%'
""")

tables = cur.fetchall()
print(f"📋 Notification tables: {[r[0] for r in tables]}")

# Check if notifications table exists
cur.execute("""
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
    )
""")

exists = cur.fetchone()[0]
print(f"\n✅ notifications table exists: {exists}")

if exists:
    # Get table structure
    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'notifications'
        ORDER BY ordinal_position
    """)
    columns = cur.fetchall()
    print("\n📊 Table structure:")
    for col in columns:
        print(f"  - {col[0]}: {col[1]} (nullable: {col[2]})")

cur.close()
conn.close()
