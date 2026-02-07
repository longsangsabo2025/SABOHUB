"""
Add tier column to customers table for manual customer classification
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')

ADD_TIER_SQL = """
-- Add tier column for manual customer classification
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tier VARCHAR(20) DEFAULT 'bronze';

-- Add tier threshold revenue column (for reference, but can be set manually)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tier_revenue_threshold NUMERIC(15,2);

-- Add constraint for valid tier values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'customers_tier_check'
    ) THEN
        ALTER TABLE customers ADD CONSTRAINT customers_tier_check 
        CHECK (tier IN ('diamond', 'gold', 'silver', 'bronze'));
    END IF;
END $$;

-- Add comment
COMMENT ON COLUMN customers.tier IS 'Customer tier: diamond (Kim cương), gold (Vàng), silver (Bạc), bronze (Đồng). Can be set manually.';

-- Create index for tier filtering
CREATE INDEX IF NOT EXISTS idx_customers_tier ON customers(tier);
"""

def main():
    conn_string = os.getenv('VITE_SUPABASE_POOLER_URL')
    if not conn_string:
        print("❌ VITE_SUPABASE_POOLER_URL not found")
        return
    
    print("🔄 Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cur = conn.cursor()
    
    try:
        print("📝 Adding tier column...")
        cur.execute(ADD_TIER_SQL)
        print("✅ Tier column added!")
        
        # Verify
        cur.execute("""
            SELECT column_name, data_type, column_default 
            FROM information_schema.columns 
            WHERE table_name = 'customers' AND column_name IN ('tier', 'tier_revenue_threshold')
        """)
        cols = cur.fetchall()
        print("\n📊 New columns:")
        for col in cols:
            print(f"  • {col[0]}: {col[1]} (default: {col[2]})")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()
