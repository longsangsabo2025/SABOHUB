"""Verify data consistency between roles - especially finance (kế toán)."""
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

print("=" * 60)
print("DATA CONSISTENCY CHECK")
print("=" * 60)

# 1. Check for paid orders missing paid_amount
cur.execute("""
    SELECT id, order_number, total, paid_amount, payment_status, payment_method
    FROM sales_orders
    WHERE payment_status = 'paid' AND (paid_amount IS NULL OR paid_amount = 0)
    LIMIT 20
""")
missing_paid = cur.fetchall()
print(f"\n1. Paid orders with missing paid_amount: {len(missing_paid)}")
for r in missing_paid:
    print(f"   {r[1]}: total={r[2]}, paid={r[3]}, method={r[5]}")

# 2. Check for paid orders without customer_payments record
cur.execute("""
    SELECT so.id, so.order_number, so.total, so.payment_method, so.payment_status
    FROM sales_orders so
    WHERE so.payment_status = 'paid'
    AND NOT EXISTS (
        SELECT 1 FROM customer_payments cp 
        WHERE cp.customer_id = so.customer_id 
        AND cp.amount = so.total
    )
    LIMIT 20
""")
orphan_paid = cur.fetchall()
print(f"\n2. Paid orders without matching customer_payments: {len(orphan_paid)}")
for r in orphan_paid:
    print(f"   {r[1]}: total={r[2]}, method={r[3]}")

# 3. Check customer total_debt vs calculated debt
cur.execute("""
    WITH calculated_debt AS (
        SELECT customer_id, SUM(total - COALESCE(paid_amount, 0)) as calc_debt
        FROM sales_orders
        WHERE payment_status IN ('unpaid', 'debt', 'partial')
        AND status != 'cancelled'
        GROUP BY customer_id
    )
    SELECT c.id, c.name, c.total_debt as stored_debt, COALESCE(cd.calc_debt, 0) as calc_debt,
           c.total_debt - COALESCE(cd.calc_debt, 0) as mismatch
    FROM customers c
    LEFT JOIN calculated_debt cd ON cd.customer_id = c.id
    WHERE ABS(COALESCE(c.total_debt, 0) - COALESCE(cd.calc_debt, 0)) > 1
    ORDER BY ABS(COALESCE(c.total_debt, 0) - COALESCE(cd.calc_debt, 0)) DESC
    LIMIT 20
""")
debt_mismatches = cur.fetchall()
print(f"\n3. Customers with debt mismatch (stored vs calculated): {len(debt_mismatches)}")
for r in debt_mismatches:
    print(f"   {r[1]}: stored={r[2]}, calculated={r[3]}, diff={r[4]}")

# 4. Payment summary by status
cur.execute("""
    SELECT payment_status, COUNT(*), SUM(total), SUM(COALESCE(paid_amount, 0))
    FROM sales_orders WHERE status != 'cancelled'
    GROUP BY payment_status ORDER BY payment_status
""")
print(f"\n4. Payment status breakdown:")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]} orders, total={r[2]}, paid_amount={r[3]}")

# 5. Check customer_payments vs sales_orders paid amounts
cur.execute("""
    SELECT 
        (SELECT COALESCE(SUM(amount), 0) FROM customer_payments) as payments_total,
        (SELECT COALESCE(SUM(paid_amount), 0) FROM sales_orders WHERE payment_status = 'paid' AND status != 'cancelled') as orders_paid_total,
        (SELECT COALESCE(SUM(total), 0) FROM sales_orders WHERE payment_status = 'paid' AND status != 'cancelled') as orders_total
""")
r = cur.fetchone()
print(f"\n5. Totals comparison:")
print(f"   customer_payments.SUM(amount)     = {r[0]}")
print(f"   sales_orders.SUM(paid_amount)     = {r[1]} (for paid orders)")
print(f"   sales_orders.SUM(total)           = {r[2]} (for paid orders)")

# 6. Check for orders with delivery_status issues
cur.execute("""
    SELECT delivery_status, COUNT(*)
    FROM sales_orders WHERE status != 'cancelled'
    GROUP BY delivery_status ORDER BY delivery_status
""")
print(f"\n6. Delivery status breakdown:")
for r in cur.fetchall():
    print(f"   {r[0]}: {r[1]} orders")

# 7. Check sell_in_transactions table columns (for accounting_service)
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sell_in_transactions' AND column_name LIKE '%amount%'
""")
cols = cur.fetchall()
print(f"\n7. sell_in_transactions amount columns: {[c[0] for c in cols]}")

# 8. Check receivables table columns
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'receivables' AND column_name LIKE '%amount%' OR 
          (table_name = 'receivables' AND column_name = 'balance')
""")
cols = cur.fetchall()
print(f"\n8. receivables amount-related columns: {[c[0] for c in cols]}")

cur.close()
conn.close()
print("\n" + "=" * 60)
print("CHECK COMPLETE")
