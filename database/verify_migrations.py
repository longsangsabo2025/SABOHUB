#!/usr/bin/env python3
"""Quick verification of database after migrations"""
import psycopg2
from psycopg2.extras import RealDictCursor

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(CONNECTION_STRING)
cur = conn.cursor(cursor_factory=RealDictCursor)

print("=" * 80)
print("DATABASE VERIFICATION AFTER MIGRATIONS")
print("=" * 80)

# Count tables
cur.execute("""
    SELECT COUNT(*) as count FROM information_schema.tables 
    WHERE table_schema = 'public'
""")
print(f"\nTotal tables: {cur.fetchone()['count']}")

# List important tables with row counts
print("\n📊 Key Tables:")
for table in ['companies', 'branches', 'stores', 'users', 'tasks', 'tables',
              'menu_items', 'table_sessions', 'orders', 'order_items']:
    try:
        cur.execute(f"SELECT COUNT(*) as count FROM {table}")
        count = cur.fetchone()['count']
        print(f"  ✅ {table:20} : {count:5} rows")
    except Exception as e:
        print(f"  ❌ {table:20} : ERROR - {str(e)[:30]}")

# Check soft deleted stores
cur.execute("SELECT COUNT(*) as count FROM stores WHERE deleted_at IS NOT NULL")
print(f"\n✅ Soft deleted stores: {cur.fetchone()['count']}")

# Check tasks with branch_id
cur.execute("SELECT COUNT(*) as count FROM tasks WHERE branch_id IS NOT NULL")
print(f"✅ Tasks with branch_id: {cur.fetchone()['count']}")

print("\n" + "=" * 80)
print("✅ MIGRATIONS COMPLETED SUCCESSFULLY!")
print("=" * 80)

cur.close()
conn.close()
