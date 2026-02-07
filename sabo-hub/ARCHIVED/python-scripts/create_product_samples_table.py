"""
Create product_samples table for tracking sample product deliveries to customers
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')

# SQL to create the product_samples table
CREATE_TABLE_SQL = """
-- Product Samples table for tracking sample deliveries to customers
CREATE TABLE IF NOT EXISTS product_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    -- Sample details
    quantity INTEGER NOT NULL DEFAULT 1,
    unit VARCHAR(50) DEFAULT 'cái',
    
    -- Product info (cached in case product is deleted)
    product_name VARCHAR(255),
    product_sku VARCHAR(100),
    
    -- Tracking info
    sent_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_by_id UUID REFERENCES employees(id),
    sent_by_name VARCHAR(255),
    received_date TIMESTAMPTZ,
    received_by VARCHAR(255),
    
    -- Status: pending, delivered, received, feedback_received, converted
    status VARCHAR(50) DEFAULT 'pending',
    
    -- Customer feedback
    feedback_rating INTEGER CHECK (feedback_rating >= 1 AND feedback_rating <= 5),
    feedback_notes TEXT,
    feedback_date TIMESTAMPTZ,
    
    -- If customer made a purchase after sampling
    converted_to_order BOOLEAN DEFAULT FALSE,
    order_id UUID REFERENCES sales_orders(id),
    
    -- Notes
    notes TEXT,
    delivery_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_product_samples_company ON product_samples(company_id);
CREATE INDEX IF NOT EXISTS idx_product_samples_customer ON product_samples(customer_id);
CREATE INDEX IF NOT EXISTS idx_product_samples_product ON product_samples(product_id);
CREATE INDEX IF NOT EXISTS idx_product_samples_sent_date ON product_samples(sent_date);
CREATE INDEX IF NOT EXISTS idx_product_samples_status ON product_samples(status);
CREATE INDEX IF NOT EXISTS idx_product_samples_sent_by ON product_samples(sent_by_id);

-- Disable RLS - App filters by company_id in code (same as products, customers tables)
ALTER TABLE product_samples DISABLE ROW LEVEL SECURITY;

-- Add comment
COMMENT ON TABLE product_samples IS 'Tracks product samples sent to customers for trial/testing';
"""

def main():
    conn_string = os.getenv('VITE_SUPABASE_POOLER_URL')
    if not conn_string:
        print("❌ VITE_SUPABASE_POOLER_URL not found in .env")
        return
    
    print("🔄 Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cur = conn.cursor()
    
    try:
        print("📝 Creating product_samples table...")
        cur.execute(CREATE_TABLE_SQL)
        print("✅ Table created successfully!")
        
        # Verify table exists
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'product_samples'
            ORDER BY ordinal_position
        """)
        columns = cur.fetchall()
        
        print("\n📊 Table structure:")
        for col in columns:
            print(f"  • {col[0]}: {col[1]} (nullable: {col[2]})")
        
        print(f"\n✅ Total columns: {len(columns)}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()
