"""Add invoice_printed columns to sales_orders table"""
import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

statements = [
    "ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS invoice_printed BOOLEAN DEFAULT false",
    "ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS invoice_printed_at TIMESTAMPTZ",
]

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    for i, sql in enumerate(statements, 1):
        try:
            cur.execute(sql)
            print(f"✅ Step {i}/{len(statements)}: Success")
        except Exception as e:
            print(f"❌ Step {i}/{len(statements)}: {e}")
    
    # Verify
    cur.execute("""
        SELECT column_name, data_type, column_default
        FROM information_schema.columns 
        WHERE table_name = 'sales_orders' 
        AND column_name IN ('invoice_printed', 'invoice_printed_at')
        ORDER BY column_name
    """)
    rows = cur.fetchall()
    print(f"\n📋 Verification ({len(rows)} columns found):")
    for r in rows:
        print(f"  - {r[0]}: {r[1]} (default: {r[2]})")
    
    cur.close()
    conn.close()
    print("\n✅ Done!")
except Exception as e:
    print(f"❌ Connection error: {e}")
