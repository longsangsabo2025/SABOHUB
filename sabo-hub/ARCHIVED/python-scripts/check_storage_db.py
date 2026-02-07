#!/usr/bin/env python3
"""Check Supabase Storage buckets via direct database query"""

import psycopg2

# Connection string from .env - Transaction Pooler
CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def main():
    print("=" * 60)
    print("CHECKING SUPABASE STORAGE BUCKETS VIA DATABASE")
    print("=" * 60)
    
    conn = psycopg2.connect(CONNECTION_STRING)
    cur = conn.cursor()
    
    # Check storage.buckets table
    print("\n📦 Storage Buckets in Supabase:")
    print("-" * 40)
    
    try:
        cur.execute("""
            SELECT id, name, public, created_at 
            FROM storage.buckets 
            ORDER BY name
        """)
        buckets = cur.fetchall()
        
        if buckets:
            for bucket in buckets:
                bucket_id, name, is_public, created = bucket
                public_str = "✅ Public" if is_public else "🔒 Private"
                print(f"  • {name}")
                print(f"    ID: {bucket_id}")
                print(f"    {public_str}")
                print()
        else:
            print("  ⚠️ No buckets found!")
            
    except Exception as e:
        print(f"  ❌ Error querying buckets: {e}")
    
    # Check if 'uploads' bucket exists
    print("\n" + "-" * 40)
    print("Checking specific bucket 'uploads':")
    
    try:
        cur.execute("SELECT * FROM storage.buckets WHERE name = 'uploads'")
        result = cur.fetchone()
        if result:
            print(f"  ✅ 'uploads' bucket exists!")
        else:
            print(f"  ❌ 'uploads' bucket NOT FOUND!")
            print("\n  💡 You need to create this bucket in Supabase Dashboard:")
            print("     1. Go to Storage in Supabase Dashboard")
            print("     2. Click 'New Bucket'")
            print("     3. Name: 'uploads', Public: Yes")
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
