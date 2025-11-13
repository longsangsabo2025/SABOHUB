#!/usr/bin/env python3
"""
Quick check tables và tạo profiles nếu cần
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

print('📋 Checking all tables...')
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name;
""")

tables = [row[0] for row in cur.fetchall()]
print('Available tables:', tables)

print('\n🔍 Checking for profiles table...')
if 'profiles' in tables:
    print('✅ profiles table exists')
    cur.execute("SELECT COUNT(*) FROM profiles;")
    result = cur.fetchone()
    count = result[0] if result else 0
    print(f'   Records: {count}')
else:
    print('❌ profiles table NOT found')
    print('🔨 Creating profiles table...')
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS profiles (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            email TEXT,
            full_name TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    """)
    
    # Enable RLS
    cur.execute("ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;")
    
    # Add policy
    cur.execute("""
        CREATE POLICY "Allow users to view own profile" ON profiles
        FOR ALL USING (auth.uid() = user_id);
    """)
    
    conn.commit()
    print('✅ Created profiles table with RLS')

# Also check the bad request issue with tasks query
print('\n🔍 Checking tasks select query issue...')
try:
    # Test the problematic query pattern
    test_query = """
        SELECT *, 
               created_by_name,
               company:companies(id,name),
               branch:branches(id,name)
        FROM tasks 
        LIMIT 1;
    """
    cur.execute(test_query)
    result = cur.fetchone()
    print('✅ Tasks query works fine in SQL')
except Exception as e:
    print(f'❌ Tasks query error: {e}')

cur.close()
conn.close()

print('\n✨ Check complete!')