import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("SELECT conname, pg_get_constraintdef(c.oid) FROM pg_constraint c WHERE c.conrelid = 'xp_transactions'::regclass AND c.contype = 'c'")
for r in cur.fetchall():
    print(r[0])
    print(r[1])
cur.execute("SELECT DISTINCT source_type FROM xp_transactions")
print("\nExisting source_types:", [r[0] for r in cur.fetchall()])
cur.close(); conn.close()
