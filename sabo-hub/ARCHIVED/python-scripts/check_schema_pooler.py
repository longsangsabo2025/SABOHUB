"""
Check database schema using Supabase Transaction Pooler (port 6543)
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')

# Transaction Pooler connection (port 6543)
# From DATABASE_URL: postgresql://postgres.dqddxowyikefqcdiioyh:xxx@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres
POOLER_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
POOLER_PORT = 6543
POOLER_USER = "postgres.dqddxowyikefqcdiioyh"
POOLER_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD', 'Acookingoil123')
POOLER_DB = "postgres"

def check_schema():
    """Connect via transaction pooler and check table schemas"""
    
    # If no password in env, prompt for it
    password = POOLER_PASSWORD
    if not password:
        print("SUPABASE_DB_PASSWORD not found in .env.local")
        print("Please provide the database password:")
        password = input("Password: ").strip()
    
    try:
        conn = psycopg2.connect(
            host=POOLER_HOST,
            port=POOLER_PORT,
            user=POOLER_USER,
            password=password,
            dbname=POOLER_DB,
            sslmode='require'
        )
        print("✓ Connected to Supabase via Transaction Pooler!")
        
        cursor = conn.cursor()
        
        # Get all tables in public schema
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        """)
        tables = cursor.fetchall()
        
        print(f"\n=== PUBLIC SCHEMA TABLES ({len(tables)}) ===")
        for t in tables:
            print(f"  - {t[0]}")
        
        # Check customers table schema
        print("\n=== CUSTOMERS TABLE SCHEMA ===")
        cursor.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'customers'
            ORDER BY ordinal_position
        """)
        columns = cursor.fetchall()
        for col in columns:
            nullable = "NULL" if col[2] == 'YES' else "NOT NULL"
            default = f" DEFAULT {col[3]}" if col[3] else ""
            print(f"  {col[0]}: {col[1]} {nullable}{default}")
        
        # Check orders table schema
        print("\n=== ORDERS TABLE SCHEMA ===")
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'orders'
            ORDER BY ordinal_position
        """)
        columns = cursor.fetchall()
        if columns:
            for col in columns:
                nullable = "NULL" if col[2] == 'YES' else "NOT NULL"
                print(f"  {col[0]}: {col[1]} {nullable}")
        else:
            print("  (table not found or no columns)")
        
        # Check order_items table schema
        print("\n=== ORDER_ITEMS TABLE SCHEMA ===")
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'order_items'
            ORDER BY ordinal_position
        """)
        columns = cursor.fetchall()
        if columns:
            for col in columns:
                nullable = "NULL" if col[2] == 'YES' else "NOT NULL"
                print(f"  {col[0]}: {col[1]} {nullable}")
        else:
            print("  (table not found or no columns)")
        
        # Check for any revenue/sales related tables
        print("\n=== REVENUE/SALES RELATED TABLES ===")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND (table_name LIKE '%order%' OR table_name LIKE '%sale%' 
                 OR table_name LIKE '%revenue%' OR table_name LIKE '%invoice%'
                 OR table_name LIKE '%transaction%')
            ORDER BY table_name
        """)
        tables = cursor.fetchall()
        for t in tables:
            print(f"  - {t[0]}")
        
        cursor.close()
        conn.close()
        print("\n✓ Connection closed")
        
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    check_schema()
