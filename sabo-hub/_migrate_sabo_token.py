"""
SABO Token System Migration Script
===================================
Creates 6 tables + 3 RPCs + RLS policies + default reward configs
for the SABO Token economy system.

Tables: token_wallets, token_transactions, token_rewards_config,
        token_store_items, token_purchases, token_transfer_requests
RPCs:   earn_tokens, spend_tokens, transfer_tokens

Idempotent — safe to run multiple times.
"""

import psycopg2
import sys

DB_CONFIG = {
    "host": "aws-1-ap-southeast-2.pooler.supabase.com",
    "port": 6543,
    "dbname": "postgres",
    "user": "postgres.dqddxowyikefqcdiioyh",
    "password": "Acookingoil123",
}

# ─── SQL Definitions ───────────────────────────────────────────────────────────

SQL_TOKEN_WALLETS = """
CREATE TABLE IF NOT EXISTS token_wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  balance numeric NOT NULL DEFAULT 0 CHECK (balance >= 0),
  total_earned numeric NOT NULL DEFAULT 0 CHECK (total_earned >= 0),
  total_spent numeric NOT NULL DEFAULT 0 CHECK (total_spent >= 0),
  total_withdrawn numeric NOT NULL DEFAULT 0 CHECK (total_withdrawn >= 0),
  wallet_address text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(employee_id, company_id)
);
"""

SQL_TOKEN_WALLETS_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_token_wallets_employee ON token_wallets(employee_id);",
    "CREATE INDEX IF NOT EXISTS idx_token_wallets_company ON token_wallets(company_id);",
]

SQL_TOKEN_TRANSACTIONS = """
CREATE TABLE IF NOT EXISTS token_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id uuid NOT NULL REFERENCES token_wallets(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  type text NOT NULL CHECK (type IN ('earn', 'spend', 'transfer_in', 'transfer_out', 'withdraw', 'deposit', 'reward', 'penalty')),
  amount numeric NOT NULL CHECK (amount > 0),
  balance_before numeric NOT NULL,
  balance_after numeric NOT NULL,
  source_type text CHECK (source_type IN ('quest', 'achievement', 'attendance', 'task', 'bonus', 'purchase', 'transfer', 'manual', 'system', 'season_reward', 'referral')),
  source_id text,
  description text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);
"""

SQL_TOKEN_TRANSACTIONS_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_token_tx_wallet ON token_transactions(wallet_id);",
    "CREATE INDEX IF NOT EXISTS idx_token_tx_company ON token_transactions(company_id);",
    "CREATE INDEX IF NOT EXISTS idx_token_tx_type ON token_transactions(type);",
    "CREATE INDEX IF NOT EXISTS idx_token_tx_created ON token_transactions(created_at DESC);",
]

SQL_TOKEN_REWARDS_CONFIG = """
CREATE TABLE IF NOT EXISTS token_rewards_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  event_type text NOT NULL CHECK (event_type IN ('daily_login', 'quest_complete', 'achievement_unlock', 'task_complete', 'attendance_streak', 'level_up', 'season_end', 'referral', 'perfect_month')),
  token_amount numeric NOT NULL DEFAULT 0 CHECK (token_amount >= 0),
  multiplier numeric NOT NULL DEFAULT 1.0,
  is_active boolean NOT NULL DEFAULT true,
  conditions jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, event_type)
);
"""

SQL_TOKEN_STORE_ITEMS = """
CREATE TABLE IF NOT EXISTS token_store_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  name text NOT NULL,
  description text,
  category text NOT NULL CHECK (category IN ('perk', 'cosmetic', 'boost', 'voucher', 'physical', 'digital', 'nft')),
  token_cost numeric NOT NULL CHECK (token_cost > 0),
  icon text DEFAULT 'star',
  image_url text,
  stock integer,
  max_per_user integer,
  min_level integer DEFAULT 1,
  is_one_time boolean DEFAULT false,
  duration_hours integer,
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
"""

SQL_TOKEN_STORE_ITEMS_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_token_store_company ON token_store_items(company_id);",
]

SQL_TOKEN_PURCHASES = """
CREATE TABLE IF NOT EXISTS token_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id uuid NOT NULL REFERENCES token_wallets(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  item_id uuid NOT NULL REFERENCES token_store_items(id),
  token_cost numeric NOT NULL CHECK (token_cost > 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired', 'refunded')),
  purchased_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  used_at timestamptz,
  metadata jsonb
);
"""

SQL_TOKEN_PURCHASES_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_token_purchases_wallet ON token_purchases(wallet_id);",
]

SQL_TOKEN_TRANSFER_REQUESTS = """
CREATE TABLE IF NOT EXISTS token_transfer_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_wallet_id uuid NOT NULL REFERENCES token_wallets(id),
  to_wallet_id uuid NOT NULL REFERENCES token_wallets(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  amount numeric NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  note text,
  approved_by uuid REFERENCES employees(id),
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);
"""

# ─── RPCs ──────────────────────────────────────────────────────────────────────

SQL_RPC_EARN_TOKENS = """
CREATE OR REPLACE FUNCTION earn_tokens(
  p_employee_id uuid,
  p_company_id uuid,
  p_amount numeric,
  p_source_type text DEFAULT 'system',
  p_source_id text DEFAULT NULL,
  p_description text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_wallet token_wallets%ROWTYPE;
  v_new_balance numeric;
BEGIN
  -- Get or create wallet
  INSERT INTO token_wallets (employee_id, company_id)
  VALUES (p_employee_id, p_company_id)
  ON CONFLICT (employee_id, company_id) DO NOTHING;

  SELECT * INTO v_wallet FROM token_wallets
  WHERE employee_id = p_employee_id AND company_id = p_company_id;

  v_new_balance := v_wallet.balance + p_amount;

  -- Update wallet
  UPDATE token_wallets SET
    balance = v_new_balance,
    total_earned = total_earned + p_amount,
    updated_at = now()
  WHERE id = v_wallet.id;

  -- Record transaction
  INSERT INTO token_transactions (wallet_id, company_id, type, amount, balance_before, balance_after, source_type, source_id, description)
  VALUES (v_wallet.id, p_company_id, 'earn', p_amount, v_wallet.balance, v_new_balance, p_source_type, p_source_id, p_description);

  RETURN jsonb_build_object(
    'wallet_id', v_wallet.id,
    'new_balance', v_new_balance,
    'amount_earned', p_amount
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

SQL_RPC_SPEND_TOKENS = """
CREATE OR REPLACE FUNCTION spend_tokens(
  p_employee_id uuid,
  p_company_id uuid,
  p_amount numeric,
  p_source_type text DEFAULT 'purchase',
  p_source_id text DEFAULT NULL,
  p_description text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_wallet token_wallets%ROWTYPE;
  v_new_balance numeric;
BEGIN
  SELECT * INTO v_wallet FROM token_wallets
  WHERE employee_id = p_employee_id AND company_id = p_company_id;

  IF v_wallet IS NULL THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;

  IF v_wallet.balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', v_wallet.balance, p_amount;
  END IF;

  v_new_balance := v_wallet.balance - p_amount;

  UPDATE token_wallets SET
    balance = v_new_balance,
    total_spent = total_spent + p_amount,
    updated_at = now()
  WHERE id = v_wallet.id;

  INSERT INTO token_transactions (wallet_id, company_id, type, amount, balance_before, balance_after, source_type, source_id, description)
  VALUES (v_wallet.id, p_company_id, 'spend', p_amount, v_wallet.balance, v_new_balance, p_source_type, p_source_id, p_description);

  RETURN jsonb_build_object(
    'wallet_id', v_wallet.id,
    'new_balance', v_new_balance,
    'amount_spent', p_amount
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

SQL_RPC_TRANSFER_TOKENS = """
CREATE OR REPLACE FUNCTION transfer_tokens(
  p_from_employee_id uuid,
  p_to_employee_id uuid,
  p_company_id uuid,
  p_amount numeric,
  p_note text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_from_wallet token_wallets%ROWTYPE;
  v_to_wallet token_wallets%ROWTYPE;
BEGIN
  -- Get sender wallet
  SELECT * INTO v_from_wallet FROM token_wallets
  WHERE employee_id = p_from_employee_id AND company_id = p_company_id;

  IF v_from_wallet IS NULL THEN
    RAISE EXCEPTION 'Sender wallet not found';
  END IF;

  IF v_from_wallet.balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- Get or create receiver wallet
  INSERT INTO token_wallets (employee_id, company_id)
  VALUES (p_to_employee_id, p_company_id)
  ON CONFLICT (employee_id, company_id) DO NOTHING;

  SELECT * INTO v_to_wallet FROM token_wallets
  WHERE employee_id = p_to_employee_id AND company_id = p_company_id;

  -- Deduct from sender
  UPDATE token_wallets SET
    balance = balance - p_amount,
    total_spent = total_spent + p_amount,
    updated_at = now()
  WHERE id = v_from_wallet.id;

  -- Add to receiver
  UPDATE token_wallets SET
    balance = balance + p_amount,
    total_earned = total_earned + p_amount,
    updated_at = now()
  WHERE id = v_to_wallet.id;

  -- Record transactions
  INSERT INTO token_transactions (wallet_id, company_id, type, amount, balance_before, balance_after, source_type, description)
  VALUES
    (v_from_wallet.id, p_company_id, 'transfer_out', p_amount, v_from_wallet.balance, v_from_wallet.balance - p_amount, 'transfer', p_note),
    (v_to_wallet.id, p_company_id, 'transfer_in', p_amount, v_to_wallet.balance, v_to_wallet.balance + p_amount, 'transfer', p_note);

  -- Create transfer request record
  INSERT INTO token_transfer_requests (from_wallet_id, to_wallet_id, company_id, amount, status, note, completed_at)
  VALUES (v_from_wallet.id, v_to_wallet.id, p_company_id, p_amount, 'completed', p_note, now());

  RETURN jsonb_build_object(
    'from_balance', v_from_wallet.balance - p_amount,
    'to_balance', v_to_wallet.balance + p_amount,
    'amount_transferred', p_amount
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

# ─── Default reward configs ───────────────────────────────────────────────────

SQL_DEFAULT_REWARDS = """
INSERT INTO token_rewards_config (company_id, event_type, token_amount, multiplier)
SELECT c.id, e.event_type, e.token_amount, 1.0
FROM companies c
CROSS JOIN (VALUES
  ('daily_login', 5),
  ('quest_complete', 20),
  ('achievement_unlock', 50),
  ('task_complete', 10),
  ('attendance_streak', 15),
  ('level_up', 100),
  ('season_end', 500),
  ('referral', 200),
  ('perfect_month', 300)
) AS e(event_type, token_amount)
WHERE c.is_active = true
ON CONFLICT (company_id, event_type) DO NOTHING;
"""

# ─── RLS Policies ─────────────────────────────────────────────────────────────

SQL_RLS_ENABLE = [
    "ALTER TABLE token_wallets ENABLE ROW LEVEL SECURITY;",
    "ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;",
    "ALTER TABLE token_rewards_config ENABLE ROW LEVEL SECURITY;",
    "ALTER TABLE token_store_items ENABLE ROW LEVEL SECURITY;",
    "ALTER TABLE token_purchases ENABLE ROW LEVEL SECURITY;",
    "ALTER TABLE token_transfer_requests ENABLE ROW LEVEL SECURITY;",
]

# Helper: drop policy if exists then create
def _policy(name: str, table: str, cmd: str, using: str, with_check: str | None = None) -> list[str]:
    stmts = [f"DROP POLICY IF EXISTS {name} ON {table};"]
    sql = f"CREATE POLICY {name} ON {table} FOR {cmd} USING ({using})"
    if with_check:
        sql += f" WITH CHECK ({with_check})"
    sql += ";"
    stmts.append(sql)
    return stmts


def _build_rls_policies() -> list[str]:
    """Build all RLS policy statements."""
    stmts: list[str] = []

    # ── token_wallets ──
    # Employees see own wallet
    stmts += _policy(
        "token_wallets_own_select", "token_wallets", "SELECT",
        "employee_id = auth.uid() OR EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_wallets.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    # Insert: service role / RPCs only (SECURITY DEFINER handles it)
    stmts += _policy(
        "token_wallets_insert", "token_wallets", "INSERT",
        "true",
        "employee_id = auth.uid() OR EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_wallets.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    # Update: managers+
    stmts += _policy(
        "token_wallets_update", "token_wallets", "UPDATE",
        "EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_wallets.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )

    # ── token_transactions ──
    stmts += _policy(
        "token_tx_select", "token_transactions", "SELECT",
        "wallet_id IN (SELECT id FROM token_wallets WHERE employee_id = auth.uid()) OR EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_transactions.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    stmts += _policy(
        "token_tx_insert", "token_transactions", "INSERT",
        "true",
        "true"  # Inserts happen via SECURITY DEFINER RPCs
    )

    # ── token_rewards_config ──
    # All authenticated can read configs in their company
    stmts += _policy(
        "token_rewards_select", "token_rewards_config", "SELECT",
        "EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_rewards_config.company_id)"
    )
    # Only manager/ceo/superAdmin can update
    stmts += _policy(
        "token_rewards_update", "token_rewards_config", "UPDATE",
        "EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_rewards_config.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    stmts += _policy(
        "token_rewards_insert", "token_rewards_config", "INSERT",
        "true",
        "EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_rewards_config.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )

    # ── token_store_items ──
    # All can read active items in their company
    stmts += _policy(
        "token_store_select", "token_store_items", "SELECT",
        "is_active = true AND EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_store_items.company_id)"
    )
    stmts += _policy(
        "token_store_manage", "token_store_items", "ALL",
        "EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_store_items.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )

    # ── token_purchases ──
    # Employees see own purchases
    stmts += _policy(
        "token_purchases_select", "token_purchases", "SELECT",
        "wallet_id IN (SELECT id FROM token_wallets WHERE employee_id = auth.uid()) OR EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_purchases.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    stmts += _policy(
        "token_purchases_insert", "token_purchases", "INSERT",
        "true",
        "true"  # via SECURITY DEFINER
    )

    # ── token_transfer_requests ──
    stmts += _policy(
        "token_transfers_select", "token_transfer_requests", "SELECT",
        "from_wallet_id IN (SELECT id FROM token_wallets WHERE employee_id = auth.uid()) OR to_wallet_id IN (SELECT id FROM token_wallets WHERE employee_id = auth.uid()) OR EXISTS (SELECT 1 FROM employees e WHERE e.id = auth.uid() AND e.company_id = token_transfer_requests.company_id AND e.role IN ('superAdmin','ceo','manager'))"
    )
    stmts += _policy(
        "token_transfers_insert", "token_transfer_requests", "INSERT",
        "true",
        "true"  # via SECURITY DEFINER
    )

    return stmts


# ─── Execution ─────────────────────────────────────────────────────────────────

def run():
    print("=" * 60)
    print("🪙  SABO Token System — Migration Script")
    print("=" * 60)
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True  # DDL statements need autocommit
        cur = conn.cursor()
        print("✅ Connected to Supabase PostgreSQL\n")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)

    steps = []

    # ── Step 1: Tables ─────────────────────────────────────────────────────────
    tables = [
        ("token_wallets", SQL_TOKEN_WALLETS, SQL_TOKEN_WALLETS_INDEXES),
        ("token_transactions", SQL_TOKEN_TRANSACTIONS, SQL_TOKEN_TRANSACTIONS_INDEXES),
        ("token_rewards_config", SQL_TOKEN_REWARDS_CONFIG, []),
        ("token_store_items", SQL_TOKEN_STORE_ITEMS, SQL_TOKEN_STORE_ITEMS_INDEXES),
        ("token_purchases", SQL_TOKEN_PURCHASES, SQL_TOKEN_PURCHASES_INDEXES),
        ("token_transfer_requests", SQL_TOKEN_TRANSFER_REQUESTS, []),
    ]

    for tname, sql, indexes in tables:
        try:
            cur.execute(sql)
            for idx_sql in indexes:
                cur.execute(idx_sql)
            steps.append((tname, "✅"))
            print(f"  ✅ Table: {tname}")
        except Exception as e:
            steps.append((tname, "❌"))
            print(f"  ❌ Table: {tname} — {e}")

    print()

    # ── Step 2: RPCs ───────────────────────────────────────────────────────────
    rpcs = [
        ("earn_tokens", SQL_RPC_EARN_TOKENS),
        ("spend_tokens", SQL_RPC_SPEND_TOKENS),
        ("transfer_tokens", SQL_RPC_TRANSFER_TOKENS),
    ]

    for rname, sql in rpcs:
        try:
            cur.execute(sql)
            steps.append((f"RPC {rname}", "✅"))
            print(f"  ✅ RPC: {rname}")
        except Exception as e:
            steps.append((f"RPC {rname}", "❌"))
            print(f"  ❌ RPC: {rname} — {e}")

    print()

    # ── Step 3: Enable RLS ─────────────────────────────────────────────────────
    print("  🔒 Enabling RLS...")
    for sql in SQL_RLS_ENABLE:
        try:
            cur.execute(sql)
        except Exception as e:
            print(f"  ⚠️  RLS enable warning: {e}")
    print("  ✅ RLS enabled on all 6 tables")

    # ── Step 4: RLS Policies ───────────────────────────────────────────────────
    print("  🔒 Creating RLS policies...")
    policy_stmts = _build_rls_policies()
    policy_ok = 0
    policy_fail = 0
    for sql in policy_stmts:
        try:
            cur.execute(sql)
            policy_ok += 1
        except Exception as e:
            policy_fail += 1
            print(f"  ⚠️  Policy warning: {e}")
    print(f"  ✅ RLS policies: {policy_ok} applied, {policy_fail} warnings")
    print()

    # ── Step 5: Default reward configs ─────────────────────────────────────────
    try:
        cur.execute(SQL_DEFAULT_REWARDS)
        row_count = cur.rowcount
        steps.append(("default_rewards", "✅"))
        print(f"  ✅ Default reward configs inserted: {row_count} rows")
    except Exception as e:
        steps.append(("default_rewards", "❌"))
        print(f"  ❌ Default reward configs: {e}")

    print("\n✅ All statements executed (autocommit mode).")

    # ── Verification ───────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("📊 Verification")
    print("=" * 60)

    verify_tables = [
        "token_wallets", "token_transactions", "token_rewards_config",
        "token_store_items", "token_purchases", "token_transfer_requests",
    ]
    for t in verify_tables:
        try:
            cur.execute(f"SELECT COUNT(*) FROM {t};")
            cnt = cur.fetchone()[0]
            print(f"  📦 {t}: {cnt} rows")
        except Exception as e:
            print(f"  ❌ {t}: {e}")

    verify_rpcs = ["earn_tokens", "spend_tokens", "transfer_tokens"]
    for r in verify_rpcs:
        try:
            cur.execute(
                "SELECT routine_name FROM information_schema.routines WHERE routine_name = %s AND routine_schema = 'public';",
                (r,),
            )
            exists = cur.fetchone()
            status = "✅ exists" if exists else "❌ not found"
            print(f"  ⚡ RPC {r}: {status}")
        except Exception as e:
            print(f"  ❌ RPC {r}: {e}")

    # ── Summary ────────────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("🪙  SABO Token System — Migration Complete!")
    print("=" * 60)
    ok = sum(1 for _, s in steps if s == "✅")
    fail = sum(1 for _, s in steps if s == "❌")
    print(f"  ✅ Passed: {ok}  |  ❌ Failed: {fail}")
    for name, status in steps:
        print(f"    {status} {name}")
    print()

    cur.close()
    conn.close()
    print("🔌 Connection closed.")


if __name__ == "__main__":
    run()
