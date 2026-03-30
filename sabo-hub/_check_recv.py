import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()

# Check receivables table structure
cur.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'receivables' ORDER BY ordinal_position")
print('=== RECEIVABLES TABLE COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} (nullable={r[2]})')

# Check if receivables have sales_order_id
print()
print('=== ALL RECEIVABLES (full data) ===')
cur.execute("SELECT id, customer_id, reference_number, original_amount, paid_amount, status, source_type, sales_order_id, write_off_amount FROM receivables ORDER BY created_at")
for r in cur.fetchall():
    print(f'  id={str(r[0])[:8]}, ref={r[2]}, orig={r[3]:,.0f}, paid={r[4]:,.0f}, status={r[5]}, source={r[6]}, so_id={str(r[7])[:8] if r[7] else None}, writeoff={r[8]}')

# Check complete_delivery_debt function
print()
print('=== complete_delivery_debt FUNCTION ===')
cur.execute("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'complete_delivery_debt'")
row = cur.fetchone()
if row:
    print(row[0][:2000])

# Check sync_payment_to_receivables function
print()
print('=== sync_payment_to_receivables FUNCTION ===')
cur.execute("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'sync_payment_to_receivables'")
row = cur.fetchone()
if row:
    print(row[0][:2000])

conn.close()
