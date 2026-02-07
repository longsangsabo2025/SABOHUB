"""
Apply Storage Policies via Transaction Pooler
"""
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

# SQL để tạo policies cho phép anon upload (employee không có Supabase Auth)
POLICY_SQL = """
-- ============================================================
-- SABOHUB Storage Policies
-- Employee KHÔNG có Supabase Auth session (dùng custom auth)
-- Nên cần cho phép anon upload
-- ============================================================

-- Xóa policies cũ nếu có
DROP POLICY IF EXISTS "Public read access for product-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for customer-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for company-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for uploads" ON storage.objects;

DROP POLICY IF EXISTS "Authenticated users can upload to product-images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to customer-images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to company-images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to uploads" ON storage.objects;

DROP POLICY IF EXISTS "Anyone can upload to product-images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload to customer-images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload to company-images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload to uploads" ON storage.objects;

DROP POLICY IF EXISTS "Anyone can update uploads" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can delete uploads" ON storage.objects;

DROP POLICY IF EXISTS "Public read for product-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public read for customer-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read for company-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read for uploads" ON storage.objects;

-- ============================================================
-- PUBLIC READ (SELECT) - Ai cũng đọc được
-- ============================================================
CREATE POLICY "Public read for product-images"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

CREATE POLICY "Public read for avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Public read for customer-images"
ON storage.objects FOR SELECT
USING (bucket_id = 'customer-images');

CREATE POLICY "Public read for company-images"
ON storage.objects FOR SELECT
USING (bucket_id = 'company-images');

CREATE POLICY "Public read for uploads"
ON storage.objects FOR SELECT
USING (bucket_id = 'uploads');

-- ============================================================
-- UPLOAD (INSERT) - Cho phép tất cả (anon + authenticated)
-- Employee dùng anon key vì họ không có Supabase Auth session
-- ============================================================
CREATE POLICY "Anyone can upload to product-images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Anyone can upload to avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Anyone can upload to customer-images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'customer-images');

CREATE POLICY "Anyone can upload to company-images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'company-images');

CREATE POLICY "Anyone can upload to uploads"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'uploads');

-- ============================================================
-- UPDATE & DELETE - Cho phép tất cả
-- ============================================================
CREATE POLICY "Anyone can update uploads"
ON storage.objects FOR UPDATE
USING (bucket_id IN ('product-images', 'avatars', 'customer-images', 'company-images', 'uploads'));

CREATE POLICY "Anyone can delete uploads"
ON storage.objects FOR DELETE
USING (bucket_id IN ('product-images', 'avatars', 'customer-images', 'company-images', 'uploads'));
"""

def main():
    print("=" * 60)
    print("SABOHUB - Apply Storage Policies via Pooler")
    print("=" * 60)
    
    try:
        print("\n🔌 Connecting to database...")
        conn = psycopg2.connect(POOLER_URL)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("✅ Connected!")
        
        print("\n📝 Applying storage policies...")
        cursor.execute(POLICY_SQL)
        
        print("✅ Policies applied successfully!")
        
        # Verify policies
        print("\n📋 Verifying policies...")
        cursor.execute("""
            SELECT policyname, tablename, cmd 
            FROM pg_policies 
            WHERE schemaname = 'storage' AND tablename = 'objects'
            ORDER BY policyname;
        """)
        
        policies = cursor.fetchall()
        print(f"\nFound {len(policies)} policies on storage.objects:")
        for policy in policies:
            print(f"  - {policy[0]} ({policy[2]})")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 60)
        print("✅ DONE! Storage policies configured for employee upload")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        raise

if __name__ == "__main__":
    main()
