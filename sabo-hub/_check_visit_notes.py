import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

# 1. Check store_visits columns (note-related)
cur.execute("""
    SELECT column_name, data_type, column_default, is_nullable
    FROM information_schema.columns 
    WHERE table_name='store_visits' 
    ORDER BY ordinal_position
""")
print('store_visits ALL columns:')
for row in cur.fetchall():
    print(f'  {row[0]:30s} | {row[1]:20s} | nullable={row[3]} | default={row[2]}')

# 2. Check the check_out_store function definition
cur.execute("""
    SELECT prosrc FROM pg_proc WHERE proname = 'check_out_store'
""")
row = cur.fetchone()
if row:
    print('\n\n=== check_out_store RPC BODY ===')
    print(row[0])
else:
    print('\n\ncheck_out_store RPC NOT FOUND')

# 3. Check check_in_store function definition
cur.execute("""
    SELECT prosrc FROM pg_proc WHERE proname = 'check_in_store'
""")
row = cur.fetchone()
if row:
    print('\n\n=== check_in_store RPC BODY ===')
    print(row[0])

# 4. Check existing visits with notes
cur.execute("""
    SELECT id, outcomes, issues_reported, customer_feedback, next_visit_notes, feedback, visit_rating, objectives
    FROM store_visits 
    WHERE outcomes IS NOT NULL 
       OR issues_reported IS NOT NULL 
       OR customer_feedback IS NOT NULL 
       OR feedback IS NOT NULL
    LIMIT 10
""")
print('\n\nVisits with any notes:')
cols = [desc[0] for desc in cur.description]
for row in cur.fetchall():
    data = dict(zip(cols, row))
    non_null = {k: v for k, v in data.items() if v is not None and k != 'id'}
    if non_null:
        print(f'  visit={str(data["id"])[:8]}... | {non_null}')

conn.close()
print('\nDone.')
