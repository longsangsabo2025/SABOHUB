import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')
conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

print("=" * 60)
print("1. DELIVERIES TABLE - ALL COLUMNS")
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
    print(f"  {c[0]:30s} {c[1]:20s} nullable={c[2]:3s} default={c[3]}")
print(f"\nTotal columns: {len(cols)}")

# Check specific columns
for check_col in ['completed_at', 'updated_at', 'started_at', 'route_order', 'total_amount']:
    exists = check_col in col_names
    print(f"  '{check_col}' exists: {exists}")

print("\n" + "=" * 60)
print("2. DELIVERIES - DISTINCT STATUS VALUES")
print("=" * 60)
cur.execute("SELECT status, COUNT(*) FROM deliveries GROUP BY status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  status={r[0]}: {r[1]} rows")

print("\n" + "=" * 60)
print("3. DELIVERIES - DISTINCT PAYMENT_STATUS VALUES")
print("=" * 60)
cur.execute("SELECT payment_status, COUNT(*) FROM deliveries GROUP BY payment_status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  payment_status={r[0]}: {r[1]} rows")

print("\n" + "=" * 60)
print("4. SALES_ORDERS - DISTINCT DELIVERY_STATUS VALUES")
print("=" * 60)
cur.execute("SELECT delivery_status, COUNT(*) FROM sales_orders GROUP BY delivery_status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  delivery_status={r[0]}: {r[1]} rows")

print("\n" + "=" * 60)
print("5. SALES_ORDERS - CHECK payment_status 'pending_transfer' EXISTS")
print("=" * 60)
cur.execute("SELECT payment_status, COUNT(*) FROM sales_orders GROUP BY payment_status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  payment_status={r[0]}: {r[1]} rows")

print("\n" + "=" * 60)
print("6. CHECK FOR 'awaiting_pickup' IN delivery_status")
print("=" * 60)
cur.execute("SELECT COUNT(*) FROM sales_orders WHERE delivery_status = 'awaiting_pickup'")
print(f"  sales_orders with delivery_status='awaiting_pickup': {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM deliveries WHERE status = 'awaiting_pickup'")
print(f"  deliveries with status='awaiting_pickup': {cur.fetchone()[0]}")

print("\n" + "=" * 60)
print("7. DELIVERY_ITEMS TABLE - ALL COLUMNS")
print("=" * 60)
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'delivery_items'
    ORDER BY ordinal_position
""")
di_cols = cur.fetchall()
for c in di_cols:
    print(f"  {c[0]:30s} {c[1]}")
print(f"\nTotal columns: {len(di_cols)}")

print("\n" + "=" * 60)
print("8. CHECK RPC FUNCTIONS FOR DRIVER")
print("=" * 60)
cur.execute("""
    SELECT routine_name FROM information_schema.routines
    WHERE routine_schema = 'public'
    AND routine_name IN ('complete_delivery', 'complete_delivery_debt', 'complete_delivery_transfer',
                         'start_delivery', 'fail_delivery', 'start_journey', 'complete_journey',
                         'deduct_stock_for_order', 'generate_delivery_number')
    ORDER BY routine_name
""")
for r in cur.fetchall():
    print(f"  {r[0]}")

print("\n" + "=" * 60)
print("9. CHECK FK FROM deliveries TO sales_orders")
print("=" * 60)
cur.execute("""
    SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_name = 'deliveries' AND tc.constraint_type = 'FOREIGN KEY'
    ORDER BY tc.constraint_name
""")
for r in cur.fetchall():
    print(f"  {r[0]}: deliveries.{r[1]} -> {r[2]}.{r[3]}")

print("\n" + "=" * 60)
print("10. CHECK IF sales_orders HAS CHECK CONSTRAINT ON payment_status")
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
    print("  No CHECK constraints on sales_orders")

cur.close()
conn.close()
print("\nDone.")
