#!/usr/bin/env python3
"""Check Supabase Storage policies"""

import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def main():
    print("=" * 60)
    print("CHECKING SUPABASE STORAGE POLICIES")
    print("=" * 60)
    
    conn = psycopg2.connect(CONNECTION_STRING)
    cur = conn.cursor()
    
    # Check storage.objects policies
    print("\n📋 Storage Policies for 'uploads' bucket:")
    print("-" * 50)
    
    try:
        cur.execute("""
            SELECT 
                pol.polname as policy_name,
                pol.polcmd as command,
                CASE pol.polcmd
                    WHEN 'r' THEN 'SELECT'
                    WHEN 'a' THEN 'INSERT'
                    WHEN 'w' THEN 'UPDATE'
                    WHEN 'd' THEN 'DELETE'
                    WHEN '*' THEN 'ALL'
                END as operation,
                pol.polpermissive as permissive,
                pg_get_expr(pol.polqual, pol.polrelid) as using_expr,
                pg_get_expr(pol.polwithcheck, pol.polrelid) as with_check
            FROM pg_policy pol
            JOIN pg_class cls ON pol.polrelid = cls.oid
            JOIN pg_namespace nsp ON cls.relnamespace = nsp.oid
            WHERE nsp.nspname = 'storage' 
              AND cls.relname = 'objects'
            ORDER BY pol.polname
        """)
        
        policies = cur.fetchall()
        
        if policies:
            for policy in policies:
                name, cmd, op, permissive, using_expr, with_check = policy
                print(f"\n  📌 {name}")
                print(f"     Operation: {op}")
                print(f"     Permissive: {permissive}")
                if using_expr:
                    print(f"     USING: {using_expr[:100]}...")
                if with_check:
                    print(f"     WITH CHECK: {with_check[:100]}...")
        else:
            print("  ⚠️ No policies found on storage.objects!")
            print("  This means RLS might be blocking all operations.")
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    # Check if RLS is enabled
    print("\n" + "-" * 50)
    print("📊 RLS Status on storage.objects:")
    
    try:
        cur.execute("""
            SELECT relrowsecurity, relforcerowsecurity 
            FROM pg_class 
            WHERE relname = 'objects' 
              AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage')
        """)
        result = cur.fetchone()
        if result:
            rls_enabled, force_rls = result
            print(f"  RLS Enabled: {rls_enabled}")
            print(f"  Force RLS: {force_rls}")
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    # Check bucket-specific settings
    print("\n" + "-" * 50)
    print("📦 Bucket 'uploads' details:")
    
    try:
        cur.execute("""
            SELECT id, name, public, file_size_limit, allowed_mime_types
            FROM storage.buckets
            WHERE name = 'uploads'
        """)
        bucket = cur.fetchone()
        if bucket:
            print(f"  ID: {bucket[0]}")
            print(f"  Name: {bucket[1]}")
            print(f"  Public: {bucket[2]}")
            print(f"  File Size Limit: {bucket[3]}")
            print(f"  Allowed MIME Types: {bucket[4]}")
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
