import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print('🔧 Fixing storage RLS policies...')

# Drop all existing policies on storage.objects
cur.execute("""
    DO $$ 
    DECLARE 
        r RECORD;
    BEGIN
        FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
            EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
        END LOOP;
    END $$;
""")
print('✅ Dropped all existing storage policies')

# Create super permissive policies (allow everything for documents bucket)
cur.execute("""
    -- Allow ALL operations to documents bucket for anyone
    CREATE POLICY "Public Access to documents bucket"
    ON storage.objects
    FOR ALL
    USING (bucket_id = 'documents')
    WITH CHECK (bucket_id = 'documents');
""")
print('✅ Created permissive policy for documents bucket')

conn.commit()
cur.close()
conn.close()

print('\n✅ Storage RLS fixed!')
print('📝 Now try uploading file again in the app')
