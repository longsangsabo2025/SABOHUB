import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')
conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

print("=" * 60)
print("ACTUAL DELIVERIES TABLE COLUMNS (corrected)")
print("=" * 60)
cur.execute("""
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deliveries'
    ORDER BY ordinal_position
""")
cols = cur.fetchall()
col_names = [c[0] for c in cols]
for c in cols:
    print(f"  {c[0]:30s} {c[1]:25s} nullable={c[2]:3s}")
print(f"\nTotal columns: {len(cols)}")

# Columns that DO NOT exist:
missing = ['branch_id','customer_id','customer_name','customer_phone','customer_address',
           'driver_name','vehicle_id','estimated_arrival','actual_arrival','delivery_type',
           'priority','delivery_fee','cod_amount','payment_status','payment_method',
           'delivery_notes','proof_photo_url','signature_url','lat','lng']
print("\nColumns from prior schema that DON'T actually exist:")
for m in missing:
    exists = m in col_names
    print(f"  {m}: {'EXISTS' if exists else 'MISSING'}")

print("\n" + "=" * 60)
print("DELIVERY_STOPS TABLE (if exists)")
print("=" * 60)
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'delivery_stops'
    ORDER BY ordinal_position
""")
ds_cols = cur.fetchall()
if ds_cols:
    for c in ds_cols:
        print(f"  {c[0]:30s} {c[1]}")
else:
    print("  Table does not exist")

print("\n" + "=" * 60)
print("DELIVERY_ITEMS TABLE COLUMNS")
print("=" * 60)
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'delivery_items'
    ORDER BY ordinal_position
""")
di_cols = cur.fetchall()
if di_cols:
    for c in di_cols:
        print(f"  {c[0]:30s} {c[1]}")
    print(f"\nTotal: {len(di_cols)}")
else:
    print("  Table does not exist")

print("\n" + "=" * 60)
print("DELIVERIES - DISTINCT STATUS VALUES")
print("=" * 60)
cur.execute("SELECT status, COUNT(*) FROM deliveries GROUP BY status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  status='{r[0]}': {r[1]} rows")

print("\n" + "=" * 60)
print("SALES_ORDERS - DISTINCT DELIVERY_STATUS")
print("=" * 60)
cur.execute("SELECT delivery_status, COUNT(*) FROM sales_orders GROUP BY delivery_status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  delivery_status='{r[0]}': {r[1]} rows")

print("\n" + "=" * 60)
print("SALES_ORDERS - DISTINCT PAYMENT_STATUS")
print("=" * 60)
cur.execute("SELECT payment_status, COUNT(*) FROM sales_orders GROUP BY payment_status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  payment_status='{r[0]}': {r[1]} rows")

print("\n" + "=" * 60)
print("CHECK 'awaiting_pickup' IN BOTH TABLES")
print("=" * 60)
cur.execute("SELECT COUNT(*) FROM sales_orders WHERE delivery_status = 'awaiting_pickup'")
print(f"  sales_orders with delivery_status='awaiting_pickup': {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM deliveries WHERE status = 'awaiting_pickup'")
print(f"  deliveries with status='awaiting_pickup': {cur.fetchone()[0]}")

print("\n" + "=" * 60)
print("FK FROM deliveries")
print("=" * 60)
cur.execute("""
    SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND kcu.table_schema = 'public'
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name AND ccu.table_schema = 'public'
    WHERE tc.table_name = 'deliveries' AND tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
    ORDER BY tc.constraint_name
""")
for r in cur.fetchall():
    print(f"  {r[0]}: deliveries.{r[1]} -> {r[2]}.{r[3]}")

print("\n" + "=" * 60)
print("CHECK CONSTRAINTS ON sales_orders")  
print("=" * 60)
cur.execute("""
    SELECT con.conname, pg_get_constraintdef(con.oid)
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE rel.relname = 'sales_orders' AND nsp.nspname = 'public' AND con.contype = 'c'
""")
checks = cur.fetchall()
if checks:
    for r in checks:
        print(f"  {r[0]}: {r[1]}")
else:
    print("  No CHECK constraints")

print("\n" + "=" * 60)
print("RPC FUNCTIONS FOR DRIVER")
print("=" * 60)
cur.execute("""
    SELECT routine_name FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name LIKE '%deliver%' OR routine_name LIKE '%journey%' OR routine_name LIKE '%route%'
    ORDER BY routine_name
""")
for r in cur.fetchall():
    print(f"  {r[0]}")

print("\n" + "=" * 60)
print("SAMPLE DELIVERY DATA (first 3)")
print("=" * 60)
cur.execute("SELECT id, delivery_number, order_id, status, driver_id, route_order FROM deliveries LIMIT 3")
for r in cur.fetchall():
    print(f"  id={r[0]}, num={r[1]}, order_id={r[2]}, status={r[3]}, driver_id={r[4]}, route_order={r[5]}")

cur.close()
conn.close()
print("\nDone.")
