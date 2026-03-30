"""
Migration: Create bridge_requests table for SABO Token Bridge
Run once to set up the bridge system database schema.
"""
import psycopg2

CONN = {
    "host": "aws-1-ap-southeast-2.pooler.supabase.com",
    "port": 6543,
    "dbname": "postgres",
    "user": "postgres.dqddxowyikefqcdiioyh",
    "password": "Acookingoil123",
}

SQL = """
-- ============================================================
-- bridge_requests table: tracks withdraw/deposit bridge operations
-- ============================================================

CREATE TABLE IF NOT EXISTS bridge_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id),
  wallet_id UUID NOT NULL REFERENCES token_wallets(id),

  -- Request details
  type TEXT NOT NULL CHECK (type IN ('withdraw', 'deposit')),
  amount DECIMAL(18,4) NOT NULL,
  fee_amount DECIMAL(18,4) NOT NULL DEFAULT 0,
  net_amount DECIMAL(18,4) NOT NULL,

  -- Blockchain info
  wallet_address TEXT,
  tx_hash TEXT,
  block_number BIGINT,
  chain_id INTEGER DEFAULT 8453,

  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  error_message TEXT,

  -- Metadata
  request_id TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  -- Business context
  company_id UUID REFERENCES companies(id),
  branch_id UUID REFERENCES branches(id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_bridge_requests_employee ON bridge_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_bridge_requests_status ON bridge_requests(status);
CREATE INDEX IF NOT EXISTS idx_bridge_requests_type ON bridge_requests(type);
CREATE INDEX IF NOT EXISTS idx_bridge_requests_tx_hash ON bridge_requests(tx_hash);
CREATE INDEX IF NOT EXISTS idx_bridge_requests_wallet ON bridge_requests(wallet_id);

-- RLS
ALTER TABLE bridge_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own bridge requests" ON bridge_requests;
  DROP POLICY IF EXISTS "Users can create own bridge requests" ON bridge_requests;
  DROP POLICY IF EXISTS "Service role full access bridge_requests" ON bridge_requests;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Policies
CREATE POLICY "Users can view own bridge requests" ON bridge_requests
  FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "Users can create own bridge requests" ON bridge_requests
  FOR INSERT WITH CHECK (employee_id = auth.uid());

CREATE POLICY "Service role full access bridge_requests" ON bridge_requests
  FOR ALL USING (auth.role() = 'service_role');

-- Auto-update updated_at trigger (reuse existing function if available)
CREATE OR REPLACE FUNCTION update_bridge_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_bridge_requests_updated_at ON bridge_requests;
CREATE TRIGGER set_bridge_requests_updated_at
  BEFORE UPDATE ON bridge_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_bridge_requests_updated_at();

-- Comment for documentation
COMMENT ON TABLE bridge_requests IS 'SABO Token Bridge: tracks withdraw (off→on-chain) and deposit (on→off-chain) requests';
"""

def main():
    print("🔗 Connecting to Supabase...")
    conn = psycopg2.connect(**CONN)
    conn.autocommit = True
    cur = conn.cursor()

    print("📦 Creating bridge_requests table...")
    cur.execute(SQL)

    # Verify
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'bridge_requests'
        ORDER BY ordinal_position
    """)
    cols = cur.fetchall()
    print(f"\n✅ bridge_requests table created with {len(cols)} columns:")
    for name, dtype in cols:
        print(f"   • {name}: {dtype}")

    # Check indexes
    cur.execute("""
        SELECT indexname FROM pg_indexes
        WHERE tablename = 'bridge_requests'
    """)
    indexes = cur.fetchall()
    print(f"\n📇 Indexes ({len(indexes)}):")
    for (idx,) in indexes:
        print(f"   • {idx}")

    # Check RLS
    cur.execute("""
        SELECT policyname FROM pg_policies
        WHERE tablename = 'bridge_requests'
    """)
    policies = cur.fetchall()
    print(f"\n🔒 RLS Policies ({len(policies)}):")
    for (p,) in policies:
        print(f"   • {p}")

    cur.close()
    conn.close()
    print("\n🎉 Migration complete!")

if __name__ == "__main__":
    main()
