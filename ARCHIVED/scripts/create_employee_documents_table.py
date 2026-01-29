#!/usr/bin/env python3
"""
Migration script to create employee_documents table with RLS policies
"""

import os
import psycopg2

# Database connection using transaction pooler
DB_CONNECTION = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def create_employee_documents_table():
    """Create employee_documents table with proper structure and RLS"""
    
    conn = psycopg2.connect(DB_CONNECTION)
    cur = conn.cursor()
    
    try:
        print("🚀 Creating employee_documents table...")
        
        # Create table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS employee_documents (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
                type TEXT NOT NULL,
                title TEXT NOT NULL,
                document_number TEXT,
                description TEXT,
                file_url TEXT,
                file_type TEXT,
                file_size INTEGER,
                issue_date TIMESTAMPTZ,
                expiry_date TIMESTAMPTZ,
                upload_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                uploaded_by UUID NOT NULL REFERENCES users(id),
                notes TEXT,
                is_verified BOOLEAN DEFAULT FALSE,
                verified_date TIMESTAMPTZ,
                verified_by UUID REFERENCES users(id),
                status TEXT DEFAULT 'active',
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
        """)
        print("✅ Table created")
        
        # Create indexes
        cur.execute("CREATE INDEX IF NOT EXISTS idx_employee_documents_employee_id ON employee_documents(employee_id);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_employee_documents_company_id ON employee_documents(company_id);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_employee_documents_type ON employee_documents(type);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_employee_documents_expiry_date ON employee_documents(expiry_date);")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_employee_documents_status ON employee_documents(status);")
        print("✅ Indexes created")
        
        # Enable RLS
        cur.execute("ALTER TABLE employee_documents ENABLE ROW LEVEL SECURITY;")
        print("✅ RLS enabled")
        
        # Drop existing policies if any
        cur.execute("DROP POLICY IF EXISTS employee_documents_select_policy ON employee_documents;")
        cur.execute("DROP POLICY IF EXISTS employee_documents_insert_policy ON employee_documents;")
        cur.execute("DROP POLICY IF EXISTS employee_documents_update_policy ON employee_documents;")
        cur.execute("DROP POLICY IF EXISTS employee_documents_delete_policy ON employee_documents;")
        
        # Create RLS policies - users can only see documents from their company
        cur.execute("""
            CREATE POLICY employee_documents_select_policy ON employee_documents
            FOR SELECT
            USING (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY employee_documents_insert_policy ON employee_documents
            FOR INSERT
            WITH CHECK (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY employee_documents_update_policy ON employee_documents
            FOR UPDATE
            USING (
                company_id IN (
                    SELECT company_id FROM users WHERE id = auth.uid()
                )
            );
        """)
        
        cur.execute("""
            CREATE POLICY employee_documents_delete_policy ON employee_documents
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
            CREATE OR REPLACE FUNCTION update_employee_documents_updated_at()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = NOW();
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        """)
        
        cur.execute("""
            DROP TRIGGER IF EXISTS employee_documents_updated_at_trigger ON employee_documents;
        """)
        
        cur.execute("""
            CREATE TRIGGER employee_documents_updated_at_trigger
            BEFORE UPDATE ON employee_documents
            FOR EACH ROW
            EXECUTE FUNCTION update_employee_documents_updated_at();
        """)
        print("✅ Trigger created")
        
        conn.commit()
        
        # Verify structure
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'employee_documents'
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
            WHERE tablename = 'employee_documents';
        """)
        indexes = cur.fetchall()
        print(f"\n📌 Indexes ({len(indexes)} total):")
        for idx in indexes:
            print(f"  - {idx[0]}")
        
        # Verify RLS policies
        cur.execute("""
            SELECT policyname, cmd 
            FROM pg_policies 
            WHERE tablename = 'employee_documents';
        """)
        policies = cur.fetchall()
        print(f"\n🔐 RLS Policies ({len(policies)} total):")
        for policy in policies:
            print(f"  - {policy[0]} ({policy[1]})")
        
        print("\n✅ employee_documents table migration completed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    create_employee_documents_table()
