import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
conn.autocommit = True
cur = conn.cursor()

# Check the FK on payment_allocations
print("=== payment_allocations constraints ===")
cur.execute("""
    SELECT conname, pg_get_constraintdef(oid)
    FROM pg_constraint
    WHERE conrelid = 'payment_allocations'::regclass
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# Check if there's a 'payments' table
print("\n=== Tables matching 'payment' ===")
cur.execute("""
    SELECT table_name FROM information_schema.tables 
    WHERE table_name LIKE '%payment%' AND table_schema = 'public'
""")
for r in cur.fetchall():
    print(f"  {r[0]}")

# Fix: drop old FK and create correct one pointing to customer_payments
print("\n=== Fixing FK ===")
try:
    cur.execute("ALTER TABLE payment_allocations DROP CONSTRAINT IF EXISTS payment_allocations_payment_id_fkey")
    print("  Dropped old FK")
except Exception as e:
    print(f"  Error dropping: {e}")

try:
    cur.execute("""
        ALTER TABLE payment_allocations 
        ADD CONSTRAINT payment_allocations_payment_id_fkey 
        FOREIGN KEY (payment_id) REFERENCES customer_payments(id) ON DELETE CASCADE
    """)
    print("  Created FK to customer_payments")
except Exception as e:
    print(f"  Error creating FK: {e}")

# Verify
print("\n=== Updated constraints ===")
cur.execute("""
    SELECT conname, pg_get_constraintdef(oid)
    FROM pg_constraint
    WHERE conrelid = 'payment_allocations'::regclass
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

cur.close()
conn.close()
