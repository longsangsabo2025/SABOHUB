import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)

cur = conn.cursor()

# Get column info
cur.execute("""
    SELECT column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'tasks'
    ORDER BY ordinal_position
""")

print("\n📋 Tasks table columns:")
for row in cur.fetchall():
    print(f"  - {row[0]}: {row[1]} (default: {row[2]})")

# Get constraints
cur.execute("""
    SELECT con.conname, pg_get_constraintdef(con.oid) 
    FROM pg_constraint con 
    JOIN pg_class rel ON rel.oid = con.conrelid 
    WHERE rel.relname = 'tasks' AND con.contype = 'c'
""")

print("\n✅ Task table check constraints:")
for row in cur.fetchall():
    print(f"  {row[0]}:\n    {row[1]}")

conn.close()
