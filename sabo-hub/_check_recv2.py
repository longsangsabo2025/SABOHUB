import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()

# All receivables
print('=== ALL RECEIVABLES (full data) ===')
cur.execute("SELECT id, customer_id, reference_type, reference_id, reference_number, original_amount, paid_amount, status, write_off_amount, due_date FROM receivables ORDER BY created_at")
for r in cur.fetchall():
    print(f'  id={str(r[0])[:8]}, ref_type={r[2]}, ref_id={str(r[3])[:8] if r[3] else None}, ref_num={r[4]}, orig={r[5]:,.0f}, paid={r[6] or 0:,.0f}, status={r[7]}, writeoff={r[8]}, due={r[9]}')

# Check complete_delivery_debt function
print()
print('=== complete_delivery_debt FUNCTION ===')
cur.execute("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'complete_delivery_debt'")
row = cur.fetchone()
if row:
    print(row[0][:3000])

# Check sync_payment_to_receivables function
print()
print('=== sync_payment_to_receivables FUNCTION ===')
cur.execute("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'sync_payment_to_receivables'")
row = cur.fetchone()
if row:
    print(row[0][:3000])

conn.close()
