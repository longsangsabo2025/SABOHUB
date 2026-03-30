"""Fix DB data consistency issues found during role sync audit."""
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
print("FIX 1: Set paid_amount = total for paid orders")
print("=" * 60)

# Count affected
cur.execute("""
    SELECT COUNT(*) FROM sales_orders
    WHERE payment_status = 'paid' 
    AND (paid_amount IS NULL OR paid_amount = 0)
    AND total > 0
""")
count = cur.fetchone()[0]
print(f"Orders to fix: {count}")

# Fix them
cur.execute("""
    UPDATE sales_orders
    SET paid_amount = total, updated_at = NOW()
    WHERE payment_status = 'paid' 
    AND (paid_amount IS NULL OR paid_amount = 0)
    AND total > 0
""")
print(f"Updated: {cur.rowcount} rows")

print("\n" + "=" * 60)
print("FIX 2: Recalculate customers.total_debt")
print("=" * 60)

# Calculate what total_debt SHOULD be for each customer
# Debt = sum of (total - paid_amount) for orders in debt/partial status
cur.execute("""
    WITH calculated_debt AS (
        SELECT customer_id, SUM(total - COALESCE(paid_amount, 0)) as calc_debt
        FROM sales_orders
        WHERE payment_status IN ('debt', 'partial')
        AND status != 'cancelled'
        GROUP BY customer_id
    )
    SELECT c.id, c.name, c.total_debt as old_debt, COALESCE(cd.calc_debt, 0) as new_debt
    FROM customers c
    LEFT JOIN calculated_debt cd ON cd.customer_id = c.id
    WHERE ABS(COALESCE(c.total_debt, 0) - COALESCE(cd.calc_debt, 0)) > 1
""")
mismatches = cur.fetchall()
print(f"Customers with debt mismatch: {len(mismatches)}")
for r in mismatches:
    print(f"  {r[1]}: {r[2]} -> {r[3]}")

# Update all customers.total_debt to match calculated
cur.execute("""
    WITH calculated_debt AS (
        SELECT customer_id, SUM(total - COALESCE(paid_amount, 0)) as calc_debt
        FROM sales_orders
        WHERE payment_status IN ('debt', 'partial')
        AND status != 'cancelled'
        GROUP BY customer_id
    )
    UPDATE customers c
    SET total_debt = COALESCE(cd.calc_debt, 0), updated_at = NOW()
    FROM (
        SELECT c2.id, COALESCE(cd2.calc_debt, 0) as calc_debt
        FROM customers c2
        LEFT JOIN calculated_debt cd2 ON cd2.customer_id = c2.id
        WHERE ABS(COALESCE(c2.total_debt, 0) - COALESCE(cd2.calc_debt, 0)) > 1
    ) cd
    WHERE c.id = cd.id
""")
print(f"Updated: {cur.rowcount} customers")

conn.commit()

print("\n" + "=" * 60)
print("VERIFICATION")
print("=" * 60)

# Verify no more mismatches
cur.execute("""
    SELECT COUNT(*) FROM sales_orders
    WHERE payment_status = 'paid' 
    AND (paid_amount IS NULL OR paid_amount = 0)
    AND total > 0
""")
print(f"Paid orders still missing paid_amount: {cur.fetchone()[0]}")

cur.execute("""
    WITH calculated_debt AS (
        SELECT customer_id, SUM(total - COALESCE(paid_amount, 0)) as calc_debt
        FROM sales_orders
        WHERE payment_status IN ('debt', 'partial')
        AND status != 'cancelled'
        GROUP BY customer_id
    )
    SELECT COUNT(*)
    FROM customers c
    LEFT JOIN calculated_debt cd ON cd.customer_id = c.id
    WHERE ABS(COALESCE(c.total_debt, 0) - COALESCE(cd.calc_debt, 0)) > 1
""")
print(f"Customers with debt mismatch: {cur.fetchone()[0]}")

# Payment status final breakdown
cur.execute("""
    SELECT payment_status, COUNT(*), SUM(total), SUM(COALESCE(paid_amount, 0))
    FROM sales_orders WHERE status != 'cancelled'
    GROUP BY payment_status ORDER BY payment_status
""")
print(f"\nPayment status final breakdown:")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} orders, total={r[2]}, paid_amount={r[3]}")

cur.close()
conn.close()
print("\nDONE!")
