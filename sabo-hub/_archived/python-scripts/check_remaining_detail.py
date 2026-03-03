"""
Deep check remaining tables with stale data.
"""
import psycopg2

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()

CID = '9f8921df-3760-44b5-9a7f-20f8484b0300'
TODAY = '2026-02-24'

print("=" * 60)
print("CHI TIET BANG CON DATA CU")
print("=" * 60)

# 1. deliveries (139) - linked to old orders?
print("\n--- DELIVERIES (139) ---")
cur.execute("""
    SELECT COUNT(*) FROM deliveries 
    WHERE company_id = %s 
    AND order_id NOT IN (SELECT id FROM sales_orders WHERE company_id = %s)
""", (CID, CID))
orphan_deliveries = cur.fetchone()[0]
print(f"  Deliveries orphan (order da xoa): {orphan_deliveries}")
cur.execute("SELECT COUNT(*) FROM deliveries WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Deliveries truoc hom nay: {cur.fetchone()[0]}")

# 2. inventory_movements (353)
print("\n--- INVENTORY_MOVEMENTS (353) ---")
cur.execute("SELECT COUNT(*) FROM inventory_movements WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 3. stock_movements (998)
print("\n--- STOCK_MOVEMENTS (998) ---")
cur.execute("SELECT COUNT(*) FROM stock_movements WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 4. receivables (51)
print("\n--- RECEIVABLES (51) ---")
cur.execute("SELECT COUNT(*) FROM receivables WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")
cur.execute("""
    SELECT r.amount, r.status, r.created_at, c.name 
    FROM receivables r JOIN customers c ON r.customer_id = c.id
    WHERE r.company_id = %s ORDER BY r.created_at DESC LIMIT 5
""", (CID,))
for r in cur.fetchall():
    print(f"  - {r[3][:30]}: {r[0]:,.0f}d, status={r[1]}, date={r[2]}")

# 5. customer_payments (38)
print("\n--- CUSTOMER_PAYMENTS (38) ---")
cur.execute("SELECT COUNT(*) FROM customer_payments WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 6. sales_reports (107)
print("\n--- SALES_REPORTS (107) ---")
cur.execute("SELECT COUNT(*) FROM sales_reports WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 7. sales_order_history (38)
print("\n--- SALES_ORDER_HISTORY (38) ---")
try:
    cur.execute("""
        SELECT COUNT(*) FROM sales_order_history 
        WHERE order_id NOT IN (SELECT id FROM sales_orders)
    """)
    print(f"  Orphan (order da xoa): {cur.fetchone()[0]}")
except:
    conn.rollback()
    print("  Khong the truy van")

# 8. sell_out_transactions (8)
print("\n--- SELL_OUT_TRANSACTIONS (8) ---")
cur.execute("SELECT COUNT(*) FROM sell_out_transactions WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 9. market_analysis (52)
print("\n--- MARKET_ANALYSIS (52) ---")
cur.execute("SELECT COUNT(*) FROM market_analysis WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
print(f"  Truoc hom nay: {cur.fetchone()[0]}")

# 10. customer_visits (1), customer_contacts (1), competitor_reports (2)
print("\n--- CUSTOMER_VISITS (1) ---")
cur.execute("SELECT COUNT(*) FROM customer_visits WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")

print("\n--- CUSTOMER_CONTACTS (1) ---")
cur.execute("SELECT COUNT(*) FROM customer_contacts WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")

# 11. surveys (2), distributor_promotions (2)
print("\n--- SURVEYS (2) ---")
cur.execute("SELECT COUNT(*) FROM surveys WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")

# 12. salary_structures (55) - config, keep
print("\n--- SALARY_STRUCTURES (55) ---")
print("  Config data, nen giu lai")

# 13. business_targets (16)
print("\n--- BUSINESS_TARGETS (16) ---")
cur.execute("SELECT COUNT(*) FROM business_targets WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")

# 14. sales_targets (1)
print("\n--- SALES_TARGETS (1) ---")
cur.execute("SELECT COUNT(*) FROM sales_targets WHERE company_id = %s", (CID,))
print(f"  Total: {cur.fetchone()[0]}")

# 15. Check last_order_date stale
print("\n--- CUSTOMERS: STALE FIELDS ---")
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_order_date < %s", (CID, TODAY))
print(f"  last_order_date truoc hom nay: {cur.fetchone()[0]} (nen reset)")
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_visit_date IS NOT NULL", (CID,))
print(f"  last_visit_date != null: {cur.fetchone()[0]} (co the giu)")

# 16. Views (v_*) are auto-calculated, no need to clean
print("\n--- VIEWS (v_*) ---")
print("  Auto-calculated, khong can clean")

# Summary: tables that should be cleaned
print("\n" + "=" * 60)
print("TONG KET - CAN DON DEP THEM:")
print("=" * 60)
print("  1. deliveries: 139 (orphan, linked to deleted orders)")
print("  2. inventory_movements: 353 (lich su cu)")
print("  3. stock_movements: 998 (lich su cu)")
print("  4. receivables: 51 (cong no cu)")
print("  5. customer_payments: 38 (thanh toan cu)")
print("  6. sales_reports: 107 (bao cao cu)")
print("  7. sales_order_history: 38 (lich su don cu)")
print("  8. sell_out_transactions: 8")
print("  9. market_analysis: 52")
print(" 10. customer_visits: 1, customer_contacts: 1")
print(" 11. last_order_date: 110 KH (nen reset null)")

conn.close()
