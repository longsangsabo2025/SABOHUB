import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

# Get all tables with RLS enabled
cur.execute("""
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' AND rowsecurity = true
    ORDER BY tablename
""")
tables = [r[0] for r in cur.fetchall()]
print(f"Found {len(tables)} tables with RLS enabled\n")

success = 0
failed = 0
for t in tables:
    try:
        cur.execute(f'ALTER TABLE "{t}" DISABLE ROW LEVEL SECURITY')
        conn.commit()
        print(f"  ✅ {t}")
        success += 1
    except Exception as e:
        print(f"  ❌ {t}: {e}")
        conn.rollback()
        failed += 1

# Verify
print(f"\n=== Result: {success} disabled, {failed} failed ===\n")
cur.execute("""
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' AND rowsecurity = true
    ORDER BY tablename
""")
remaining = cur.fetchall()
if remaining:
    print(f"⚠️ Still have RLS enabled: {[r[0] for r in remaining]}")
else:
    print("✅ All public tables: RLS disabled")

conn.close()
