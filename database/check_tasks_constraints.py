import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)

cur = conn.cursor()
cur.execute("""
    SELECT con.conname, pg_get_constraintdef(con.oid) 
    FROM pg_constraint con 
    JOIN pg_class rel ON rel.oid = con.conrelid 
    WHERE rel.relname = 'tasks' AND con.contype = 'c'
""")

print("\n✅ Task table constraints:")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]}")

conn.close()
