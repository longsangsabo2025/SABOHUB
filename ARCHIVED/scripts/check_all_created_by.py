import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

# Transaction pooler connection
conn_string = os.getenv("SUPABASE_CONNECTION_STRING")
conn = psycopg2.connect(conn_string)

cur = conn.cursor()

print("\n🔍 CHECKING ALL TABLES WITH created_by COLUMN\n")
print("=" * 80)

# Get all tables with created_by column
cur.execute("""
    SELECT table_name 
    FROM information_schema.columns 
    WHERE column_name = 'created_by' 
    AND table_schema = 'public'
    ORDER BY table_name
""")

tables = cur.fetchall()
print(f"\n📋 Found {len(tables)} tables with created_by column:\n")

for (table_name,) in tables:
    print(f"\n{'='*80}")
    print(f"📊 TABLE: {table_name}")
    print(f"{'='*80}")
    
    # Count NULL vs NOT NULL
    cur.execute(f"""
        SELECT 
            COUNT(*) as total,
            COUNT(created_by) as has_owner,
            COUNT(*) - COUNT(created_by) as no_owner
        FROM {table_name}
    """)
    
    total, has_owner, no_owner = cur.fetchone()
    
    print(f"Total rows: {total}")
    print(f"✅ Has owner (created_by NOT NULL): {has_owner}")
    print(f"❌ No owner (created_by IS NULL): {no_owner}")
    
    if no_owner > 0:
        print(f"\n⚠️  WARNING: {no_owner} rows without owner!")
        
        # Show sample data
        cur.execute(f"""
            SELECT id, 
                   COALESCE(name, full_name, title, 'N/A') as name,
                   created_by
            FROM {table_name}
            WHERE created_by IS NULL
            LIMIT 5
        """)
        
        rows = cur.fetchall()
        if rows:
            print("\nSample rows without owner:")
            for row in rows:
                print(f"  - ID: {row[0]}, Name: {row[1]}, created_by: {row[2]}")

print("\n" + "="*80)
print("\n✅ Check complete!\n")

cur.close()
conn.close()
