"""
Create referral commission system tables
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-nexus/.env')

conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

try:
    # 1. Create referrers table - người giới thiệu
    cur.execute('''
        CREATE TABLE IF NOT EXISTS referrers (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
            name VARCHAR(255) NOT NULL,
            phone VARCHAR(20),
            email VARCHAR(255),
            bank_name VARCHAR(100),
            bank_account VARCHAR(50),
            bank_holder VARCHAR(255),
            commission_rate DECIMAL(5,2) DEFAULT 0,
            commission_type VARCHAR(20) DEFAULT 'all_orders' CHECK (commission_type IN ('first_order', 'all_orders')),
            notes TEXT,
            status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
            total_earned DECIMAL(15,2) DEFAULT 0,
            total_paid DECIMAL(15,2) DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    ''')
    print("✅ Created referrers table")

    # 2. Add referrer_id to customers table
    cur.execute('''
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'customers' AND column_name = 'referrer_id'
            ) THEN
                ALTER TABLE customers ADD COLUMN referrer_id UUID REFERENCES referrers(id) ON DELETE SET NULL;
            END IF;
        END $$;
    ''')
    print("✅ Added referrer_id to customers table")

    # 3. Create commissions table - bảng hoa hồng
    cur.execute('''
        CREATE TABLE IF NOT EXISTS commissions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
            referrer_id UUID NOT NULL REFERENCES referrers(id) ON DELETE CASCADE,
            customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
            order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
            order_code VARCHAR(50),
            order_amount DECIMAL(15,2) NOT NULL,
            commission_rate DECIMAL(5,2) NOT NULL,
            commission_amount DECIMAL(15,2) NOT NULL,
            status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'paid', 'cancelled')),
            approved_at TIMESTAMPTZ,
            approved_by UUID,
            paid_at TIMESTAMPTZ,
            paid_by UUID,
            payment_note TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    ''')
    print("✅ Created commissions table")

    # 4. Create indexes
    cur.execute('CREATE INDEX IF NOT EXISTS idx_referrers_company ON referrers(company_id)')
    cur.execute('CREATE INDEX IF NOT EXISTS idx_referrers_status ON referrers(status)')
    cur.execute('CREATE INDEX IF NOT EXISTS idx_customers_referrer ON customers(referrer_id)')
    cur.execute('CREATE INDEX IF NOT EXISTS idx_commissions_referrer ON commissions(referrer_id)')
    cur.execute('CREATE INDEX IF NOT EXISTS idx_commissions_status ON commissions(status)')
    cur.execute('CREATE INDEX IF NOT EXISTS idx_commissions_company ON commissions(company_id)')
    print("✅ Created indexes")

    conn.commit()
    print("\n🎉 Referral system tables created successfully!")

    # Show table info
    cur.execute('''
        SELECT column_name, data_type, column_default
        FROM information_schema.columns 
        WHERE table_name = 'referrers'
        ORDER BY ordinal_position
    ''')
    print("\n📋 Referrers table columns:")
    for row in cur.fetchall():
        print(f"  - {row[0]}: {row[1]}")

except Exception as e:
    conn.rollback()
    print(f"❌ Error: {e}")
finally:
    cur.close()
    conn.close()
