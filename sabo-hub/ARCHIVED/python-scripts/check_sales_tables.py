"""
Check sales/revenue tables to understand customer revenue tracking
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')

POOLER_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
POOLER_PORT = 6543
POOLER_USER = "postgres.dqddxowyikefqcdiioyh"
POOLER_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD', 'Acookingoil123')
POOLER_DB = "postgres"

def check_sales_tables():
    conn = psycopg2.connect(
        host=POOLER_HOST,
        port=POOLER_PORT,
        user=POOLER_USER,
        password=POOLER_PASSWORD,
        dbname=POOLER_DB,
        sslmode='require'
    )
    print("✓ Connected!")
    cursor = conn.cursor()
    
    # Check sales_orders schema
    print("\n=== SALES_ORDERS TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sales_orders'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]}: {col[1]}")
    
    # Check sell_in_transactions schema
    print("\n=== SELL_IN_TRANSACTIONS TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sell_in_transactions'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]}: {col[1]}")
    
    # Check v_sales_by_customer view
    print("\n=== V_SALES_BY_CUSTOMER VIEW SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'v_sales_by_customer'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    if columns:
        for col in columns:
            print(f"  {col[0]}: {col[1]}")
    else:
        print("  (view not found or no columns)")
    
    # Check daily_revenue schema
    print("\n=== DAILY_REVENUE TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'daily_revenue'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]}: {col[1]}")
    
    # Check revenue_summary schema
    print("\n=== REVENUE_SUMMARY TABLE SCHEMA ===")
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'revenue_summary'
        ORDER BY ordinal_position
    """)
    for col in cursor.fetchall():
        print(f"  {col[0]}: {col[1]}")
    
    # Sample data from sales_orders
    print("\n=== SAMPLE SALES_ORDERS (10 rows) ===")
    cursor.execute("""
        SELECT id, customer_id, total, status, order_date
        FROM sales_orders
        ORDER BY order_date DESC
        LIMIT 10
    """)
    rows = cursor.fetchall()
    if rows:
        for row in rows:
            print(f"  {row}")
    else:
        print("  No data found")
    
    # Count by table
    print("\n=== DATA COUNTS ===")
    for table in ['sales_orders', 'sell_in_transactions', 'daily_revenue', 'revenue_summary', 'deliveries']:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table}: {count} rows")
        except Exception as e:
            print(f"  {table}: Error - {e}")
            conn.rollback()
    
    # Check customer total_debt distribution
    print("\n=== CUSTOMER TOTAL_DEBT DISTRIBUTION ===")
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            COUNT(CASE WHEN total_debt IS NULL OR total_debt = 0 THEN 1 END) as zero_debt,
            COUNT(CASE WHEN total_debt > 0 AND total_debt < 1000000 THEN 1 END) as under_1m,
            COUNT(CASE WHEN total_debt >= 1000000 AND total_debt < 5000000 THEN 1 END) as from_1m_to_5m,
            COUNT(CASE WHEN total_debt >= 5000000 AND total_debt < 20000000 THEN 1 END) as from_5m_to_20m,
            COUNT(CASE WHEN total_debt >= 20000000 THEN 1 END) as over_20m,
            MIN(total_debt) as min_debt,
            MAX(total_debt) as max_debt,
            AVG(total_debt) as avg_debt
        FROM customers
        WHERE deleted_at IS NULL
    """)
    row = cursor.fetchone()
    print(f"  Total customers: {row[0]}")
    print(f"  Zero/null debt: {row[1]}")
    print(f"  Under 1M: {row[2]}")
    print(f"  1M - 5M: {row[3]}")
    print(f"  5M - 20M: {row[4]}")
    print(f"  Over 20M: {row[5]}")
    print(f"  Min debt: {row[6]:,.0f}" if row[6] else "  Min debt: N/A")
    print(f"  Max debt: {row[7]:,.0f}" if row[7] else "  Max debt: N/A")
    print(f"  Avg debt: {row[8]:,.0f}" if row[8] else "  Avg debt: N/A")
    
    # Top 20 customers by total_debt
    print("\n=== TOP 20 CUSTOMERS BY TOTAL_DEBT ===")
    cursor.execute("""
        SELECT name, total_debt
        FROM customers
        WHERE deleted_at IS NULL AND total_debt > 0
        ORDER BY total_debt DESC
        LIMIT 20
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]:,.0f} đ")
    
    cursor.close()
    conn.close()
    print("\n✓ Done!")

if __name__ == "__main__":
    check_sales_tables()
