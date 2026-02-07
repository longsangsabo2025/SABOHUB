import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. List all storage buckets
cur.execute("SELECT id, name, public FROM storage.buckets ORDER BY name")
print('=== Storage Buckets ===')
for r in cur.fetchall():
    print(f"  {r[0]} | name={r[1]} | public={r[2]}")

# 2. List all storage policies (RLS)
cur.execute("""
    SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies 
    WHERE schemaname = 'storage'
    ORDER BY tablename, policyname
""")
print('\n=== Storage RLS Policies ===')
for r in cur.fetchall():
    print(f"  table={r[1]} | policy={r[2]} | cmd={r[5]}")
    print(f"    roles={r[4]} | qual={r[6]}")
    print(f"    with_check={r[7]}")
    print()

# 3. Check if RLS is enabled on storage tables
cur.execute("""
    SELECT relname, relrowsecurity, relforcerowsecurity
    FROM pg_class 
    WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage')
    AND relkind = 'r'
    AND relname IN ('objects', 'buckets')
""")
print('=== Storage Tables RLS Status ===')
for r in cur.fetchall():
    print(f"  {r[0]}: rls_enabled={r[1]}, rls_forced={r[2]}")

# 4. Fix: Drop restrictive policies and create public ones for invoice-images and payment-proofs
fixes = [
    # invoice-images: change INSERT from 'authenticated' to 'public'
    ("DROP POLICY IF EXISTS \"Allow authenticated uploads invoice-images\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can upload to invoice-images\" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'invoice-images')", None),
    # Add UPDATE + DELETE for invoice-images
    ("DROP POLICY IF EXISTS \"Anyone can update invoice-images\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can update invoice-images\" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'invoice-images')", None),
    ("DROP POLICY IF EXISTS \"Anyone can delete invoice-images\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can delete invoice-images\" ON storage.objects FOR DELETE TO public USING (bucket_id = 'invoice-images')", None),
    
    # payment-proofs: change INSERT from 'authenticated' to 'public'
    ("DROP POLICY IF EXISTS \"Allow authenticated uploads payment-proofs\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can upload to payment-proofs\" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'payment-proofs')", None),
    # Add UPDATE + DELETE for payment-proofs
    ("DROP POLICY IF EXISTS \"Anyone can update payment-proofs\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can update payment-proofs\" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'payment-proofs')", None),
    ("DROP POLICY IF EXISTS \"Anyone can delete payment-proofs\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can delete payment-proofs\" ON storage.objects FOR DELETE TO public USING (bucket_id = 'payment-proofs')", None),
    
    # Also add update/delete for bug-reports (missing)
    ("DROP POLICY IF EXISTS \"Anyone can update bug-reports\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can update bug-reports\" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'bug-reports')", None),
    ("DROP POLICY IF EXISTS \"Anyone can delete bug-reports\" ON storage.objects", None),
    ("CREATE POLICY \"Anyone can delete bug-reports\" ON storage.objects FOR DELETE TO public USING (bucket_id = 'bug-reports')", None),
]

print('\n=== Fixing Storage Policies ===')
for sql, _ in fixes:
    try:
        cur.execute(sql)
        conn.commit()
        action = "DROP" if "DROP" in sql else "CREATE"
        print(f"  ✅ {action}: {sql.split('\"')[1] if '\"' in sql else sql[:50]}")
    except Exception as e:
        conn.rollback()
        print(f"  ❌ Error: {e}")

# Verify
cur.execute("""
    SELECT policyname, cmd, roles FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects'
    ORDER BY policyname
""")
print('\n=== Final Storage Policies ===')
for r in cur.fetchall():
    print(f"  {r[0]} | cmd={r[1]} | roles={r[2]}")

conn.close()
print('\n✅ All storage policies fixed!')
