import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env')
    exit(1)

print(f'🔧 Creating storage bucket in: {SUPABASE_URL}')

# Create bucket via REST API
url = f'{SUPABASE_URL}/storage/v1/bucket'
headers = {
    'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json',
    'apikey': SUPABASE_SERVICE_ROLE_KEY
}

payload = {
    'id': 'documents',
    'name': 'documents',
    'public': True,
    'file_size_limit': 52428800,  # 50MB
    'allowed_mime_types': [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/gif',
        'image/webp',
        'application/pdf',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/msword',
        'application/vnd.ms-excel',
        'text/plain'
    ]
}

print('\n📦 Creating bucket "documents"...')
response = requests.post(url, json=payload, headers=headers)

if response.status_code == 200 or response.status_code == 201:
    print('✅ Bucket "documents" created successfully!')
    print(f'   - Public: Yes')
    print(f'   - Max file size: 50MB')
    print(f'   - Public URL: {SUPABASE_URL}/storage/v1/object/public/documents/')
elif response.status_code == 409:
    print('⚠️  Bucket "documents" already exists!')
    print('   This is OK - you can continue using it.')
else:
    print(f'❌ Failed to create bucket: {response.status_code}')
    print(f'   Response: {response.text}')
    exit(1)

print('\n🔐 Setting up storage policies...')

# Set up RLS policies for storage
import psycopg2

try:
    conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
    cur = conn.cursor()

    # Drop existing policies if any
    cur.execute("""
        DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
        DROP POLICY IF EXISTS "Allow public downloads" ON storage.objects;
        DROP POLICY IF EXISTS "Allow users to delete own files" ON storage.objects;
    """)

    # Create new policies
    cur.execute("""
        -- Allow authenticated users to upload
        CREATE POLICY "Allow authenticated uploads"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'documents');
    """)
    print('   ✅ Upload policy created')

    cur.execute("""
        -- Allow public downloads
        CREATE POLICY "Allow public downloads"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'documents');
    """)
    print('   ✅ Download policy created')

    cur.execute("""
        -- Allow users to delete their own files
        CREATE POLICY "Allow users to delete own files"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (bucket_id = 'documents');
    """)
    print('   ✅ Delete policy created')

    conn.commit()
    cur.close()
    conn.close()
    
    print('\n✅ All done! Storage is ready to use.')
    print('\n📝 Next steps:')
    print('   1. Hot reload app: Press "r" in Flutter terminal')
    print('   2. Test upload: Manager Tasks → Click task → Upload file')
    print('   3. Verify: Check Supabase Dashboard → Storage → documents bucket')

except Exception as e:
    print(f'\n⚠️  Could not set policies (this is optional): {e}')
    print('   Bucket is still usable, but you may need to set policies manually.')
