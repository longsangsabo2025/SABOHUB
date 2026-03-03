"""
SABOHUB CLEANUP PHASE 2 - Don dep tat ca bang lien quan
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
print("CLEANUP PHASE 2 - Don dep bang lien quan")
print("=" * 60)

# Helper function for safe delete
def safe_delete(table, where_clause, params, description):
    try:
        cur.execute("SAVEPOINT sp_" + table)
        cur.execute(f"DELETE FROM {table} WHERE {where_clause}", params)
        count = cur.rowcount
        cur.execute("RELEASE SAVEPOINT sp_" + table)
        print(f"  [{table}] Xoa {count} records - {description}")
        return count
    except Exception as e:
        cur.execute("ROLLBACK TO SAVEPOINT sp_" + table)
        print(f"  [{table}] LOI: {str(e)[:60]}")
        return 0

def safe_delete_all(table, description):
    return safe_delete(table, "company_id = %s", (CID,), description)

def safe_delete_before(table, description):
    return safe_delete(table, "company_id = %s AND DATE(created_at) < %s", (CID, TODAY), description)

# 1. Deliveries - xoa truoc hom nay
print("\n1. DELIVERIES")
safe_delete_before("deliveries", "giao hang cu")

# 2. Inventory movements
print("\n2. INVENTORY_MOVEMENTS")
safe_delete_before("inventory_movements", "lich su nhap/xuat cu")

# 3. Stock movements
print("\n3. STOCK_MOVEMENTS")
safe_delete_all("stock_movements", "lich su kho cu")

# 4. Receivables (cong no cu - da reset total_debt = 0)
print("\n4. RECEIVABLES")
safe_delete_all("receivables", "cong no cu")

# 5. Customer payments
print("\n5. CUSTOMER_PAYMENTS")
safe_delete_all("customer_payments", "thanh toan cu")

# 6. Sales reports
print("\n6. SALES_REPORTS")
safe_delete_all("sales_reports", "bao cao cu")

# 7. Sales order history (orphan hoac cu)
print("\n7. SALES_ORDER_HISTORY")
safe_delete(
    "sales_order_history",
    "order_id IN (SELECT id FROM sales_orders WHERE company_id = %s AND DATE(created_at) < %s)",
    (CID, TODAY),
    "lich su don cu"
)
# Also clean orphaned ones
safe_delete(
    "sales_order_history",
    "order_id NOT IN (SELECT id FROM sales_orders)",
    (),
    "orphan records"
)

# 8. Sell out transactions
print("\n8. SELL_OUT_TRANSACTIONS")
safe_delete_all("sell_out_transactions", "giao dich cu")

# 9. Market analysis
print("\n9. MARKET_ANALYSIS")
safe_delete_all("market_analysis", "phan tich cu")

# 10. Customer visits
print("\n10. CUSTOMER_VISITS")
safe_delete_all("customer_visits", "tham khach cu")

# 11. Customer contacts - giu lai vi la thong tin lien he
print("\n11. CUSTOMER_CONTACTS")
print("  GIU LAI - thong tin lien he, khong phai data test")

# 12. Competitor reports 
print("\n12. COMPETITOR_REPORTS")
safe_delete_all("competitor_reports", "bao cao doi thu cu")

# 13. Surveys - config/template, co the giu hoac xoa
print("\n13. SURVEYS")
safe_delete_all("surveys", "khao sat test")

# 14. Distributor promotions
print("\n14. DISTRIBUTOR_PROMOTIONS")
safe_delete_all("distributor_promotions", "khuyen mai test")

# 15. Business targets - co the la config, xoa vì test
print("\n15. BUSINESS_TARGETS")
safe_delete_all("business_targets", "muc tieu test")

# 16. Sales targets
print("\n16. SALES_TARGETS")
safe_delete_all("sales_targets", "chi tieu test")

# 17. Reset customer stale fields
print("\n17. RESET CUSTOMER FIELDS")
cur.execute("""
    UPDATE customers SET 
        last_order_date = NULL,
        last_visit_date = NULL
    WHERE company_id = %s
""", (CID,))
print(f"  Reset last_order_date + last_visit_date: {cur.rowcount} KH")

# Verify
print("\n" + "=" * 60)
print("KET QUA SAU CLEANUP PHASE 2")
print("=" * 60)

check_tables = [
    "deliveries", "inventory_movements", "stock_movements", 
    "receivables", "customer_payments", "sales_reports",
    "sell_out_transactions", "market_analysis", "customer_visits",
    "competitor_reports", "surveys", "distributor_promotions",
    "business_targets", "sales_targets"
]

for t in check_tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {t} WHERE company_id = %s", (CID,))
        count = cur.fetchone()[0]
        status = "SACH" if count == 0 else f"CON {count}"
        print(f"  {t:<30} {status}")
    except:
        conn.rollback()

cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_order_date IS NOT NULL", (CID,))
print(f"  KH co last_order_date: {cur.fetchone()[0]}")

conn.commit()
print("\nDA COMMIT - Phase 2 hoan tat!")
conn.close()
