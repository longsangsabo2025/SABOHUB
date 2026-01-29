#!/usr/bin/env python3
"""
Migration script to create labor_contracts table with RLS policies
"""

import os
import psycopg2

# Database connection using transaction pooler
DB_CONNECTION = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def create_labor_contracts_table():
    """Create labor_contracts table with proper structure and RLS"""
    
    conn = psycopg2.connect(DB_CONNECTION)
    cur = conn.cursor()
    
    try:
        print("🚀 Creating labor_contracts table...")
        
        # Create table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS labor_contracts (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
                contract_type TEXT NOT NULL,
                contract_number TEXT NOT NULL,
                position TEXT NOT NULL,
                department TEXT,
                start_date DATE NOT NULL,
                end_date DATE,
                probation_end_date DATE,
                basic_salary NUMERIC(15,2),
                allowances JSONB,
                benefits TEXT[],
                working_hours TEXT,
                job_description TEXT,
                signed_date DATE,
                signed_location TEXT,
                file_url TEXT,
                status TEXT DEFAULT 'active',
                notes TEXT,
                created_by UUID NOT NULL REFERENCES users(id),
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
        """)
        print("✅ Table created")
        
        # Create indexes
        cur.execute("CREATE INDEX IF NOT EXISTS idx_labor_contracts_employee_id ON labor_contracts(employee_id);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_labor_contracts_company_id ON labor_contracts(company_id);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_labor_contracts_contract_type ON labor_contracts(contract_type);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_labor_contracts_status ON labor_contracts(status);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_labor_contracts_end_date ON labor_contracts(end_date);")
        print("✅ Indexes created")
        
        # Enable RLS
        cur.execute("ALTER TABLE labor_contracts ENABLE ROW LEVEL SECURITY;")
        print("✅ RLS enabled")
        
        # Drop existing policies if any
        cur.execute("DROP POLICY IF EXISTS labor_contracts_select_policy ON labor_contracts;")
        cur.execute("DROP POLICY IF EXISTS labor_contracts_insert_policy ON labor_contracts;")
        cur.execute("DROP POLICY IF EXISTS labor_contracts_update_policy ON labor_contracts;")
        cur.execute("DROP POLICY IF EXISTS labor_contracts_delete_policy ON labor_contracts;")
        
        # Create RLS policies
        cur.execute("""
            CREATE POLICY labor_contracts_select_policy ON labor_contracts
            FOR SELECT
            USING (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY labor_contracts_insert_policy ON labor_contracts
            FOR INSERT
            WITH CHECK (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY labor_contracts_update_policy ON labor_contracts
            FOR UPDATE
            USING (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY labor_contracts_delete_policy ON labor_contracts
            FOR DELETE
            USING (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        print("✅ RLS policies created")
        
        # Create trigger for updated_at
        cur.execute("""
            CREATE OR REPLACE FUNCTION update_labor_contracts_updated_at()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = NOW();
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        """)
        
        cur.execute("""
            DROP TRIGGER IF EXISTS labor_contracts_updated_at_trigger ON labor_contracts;
        """)
        
        cur.execute("""
            CREATE TRIGGER labor_contracts_updated_at_trigger
            BEFORE UPDATE ON labor_contracts
            FOR EACH ROW
            EXECUTE FUNCTION update_labor_contracts_updated_at();
        """)
        print("✅ Trigger created")
        
        conn.commit()
        
        # Verify structure
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'labor_contracts'
            ORDER BY ordinal_position;
        """)
        columns = cur.fetchall()
        print(f"\n📊 Table structure ({len(columns)} columns):")
        for col in columns:
            print(f"  - {col[0]}: {col[1]}")
        
        # Verify indexes
        cur.execute("""
            SELECT indexname 
            FROM pg_indexes 
            WHERE tablename = 'labor_contracts';
        """)
        indexes = cur.fetchall()
        print(f"\n📌 Indexes ({len(indexes)} total):")
        for idx in indexes:
            print(f"  - {idx[0]}")
        
        # Verify RLS policies
        cur.execute("""
            SELECT policyname, cmd 
            FROM pg_policies 
            WHERE tablename = 'labor_contracts';
        """)
        policies = cur.fetchall()
        print(f"\n🔐 RLS Policies ({len(policies)} total):")
        for policy in policies:
            print(f"  - {policy[0]} ({policy[1]})")
        
        print("\n✅ labor_contracts table migration completed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    create_labor_contracts_table()
