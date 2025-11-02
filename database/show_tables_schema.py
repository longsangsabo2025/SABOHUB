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
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name='tables' 
    ORDER BY ordinal_position
""")

print("TABLES TABLE COLUMNS:")
for col in cur.fetchall():
    print(f"  {col[0]}: {col[1]}")

conn.close()
