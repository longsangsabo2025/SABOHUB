import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
conn.autocommit = True
cur = conn.cursor()

# 1. Add proof_image_url to customer_payments
print("=== Adding proof_image_url to customer_payments ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'customer_payments' AND column_name = 'proof_image_url'
""")
if cur.fetchone():
    print("  Already exists")
else:
    cur.execute("ALTER TABLE customer_payments ADD COLUMN proof_image_url TEXT")
    print("  ✅ Added")

# 2. Add invoice_image_url to sales_orders
print("\n=== Adding invoice_image_url to sales_orders ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' AND column_name = 'invoice_image_url'
""")
if cur.fetchone():
    print("  Already exists")
else:
    cur.execute("ALTER TABLE sales_orders ADD COLUMN invoice_image_url TEXT")
    print("  ✅ Added")

# 3. Add proof_image_url to payments (for RecordPaymentDialog)
print("\n=== Adding proof_image_url to payments ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'payments' AND column_name = 'proof_image_url'
""")
if cur.fetchone():
    print("  Already exists")
else:
    cur.execute("ALTER TABLE payments ADD COLUMN proof_image_url TEXT")
    print("  ✅ Added")

# 4. Verify columns
print("\n=== Verify customer_payments columns ===")
cur.execute("""
    SELECT column_name, data_type FROM information_schema.columns 
    WHERE table_name = 'customer_payments' ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

print("\n=== Verify sales_orders has invoice_image_url ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' AND column_name = 'invoice_image_url'
""")
print(f"  {'✅ Found' if cur.fetchone() else '❌ Not found'}")

# 5. Check if storage bucket exists
print("\n=== Creating storage buckets ===")
try:
    cur.execute("""
        INSERT INTO storage.buckets (id, name, public) 
        VALUES ('payment-proofs', 'payment-proofs', true)
        ON CONFLICT (id) DO NOTHING
    """)
    print("  ✅ payment-proofs bucket ready")
except Exception as e:
    print(f"  Note: {e}")

try:
    cur.execute("""
        INSERT INTO storage.buckets (id, name, public) 
        VALUES ('invoice-images', 'invoice-images', true)
        ON CONFLICT (id) DO NOTHING
    """)
    print("  ✅ invoice-images bucket ready")
except Exception as e:
    print(f"  Note: {e}")

# 6. Set RLS policies for the buckets
print("\n=== Setting storage policies ===")
for bucket in ['payment-proofs', 'invoice-images']:
    # Allow authenticated users to upload
    try:
        cur.execute(f"""
            CREATE POLICY "Allow authenticated uploads {bucket}" ON storage.objects
            FOR INSERT TO authenticated
            WITH CHECK (bucket_id = '{bucket}')
        """)
        print(f"  ✅ INSERT policy for {bucket}")
    except Exception as e:
        if 'already exists' in str(e):
            print(f"  INSERT policy for {bucket} already exists")
        else:
            print(f"  Note: {e}")

    # Allow public read
    try:
        cur.execute(f"""
            CREATE POLICY "Allow public read {bucket}" ON storage.objects
            FOR SELECT TO public
            USING (bucket_id = '{bucket}')
        """)
        print(f"  ✅ SELECT policy for {bucket}")
    except Exception as e:
        if 'already exists' in str(e):
            print(f"  SELECT policy for {bucket} already exists")
        else:
            print(f"  Note: {e}")

print("\n✅ DB setup complete!")
cur.close()
conn.close()
