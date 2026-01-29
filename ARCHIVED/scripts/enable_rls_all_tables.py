"""
CRITICAL: Enable RLS on All Tables
This fixes major security vulnerabilities
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

def enable_rls_all_tables():
    """Enable RLS on all critical tables"""
    print("🚨 CRITICAL SECURITY FIX: Enabling RLS")
    print("="*60)
    
    tables_to_fix = [
        'companies',
        'branches',
        'tasks',
        'documents',
        'contracts',
        'shifts',
    ]
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    for table in tables_to_fix:
        print(f"\n📋 Enabling RLS on: {table}")
        try:
            cur.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;")
            conn.commit()
            print(f"   ✅ RLS enabled on {table}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
            conn.rollback()
    
    # Verify
    print("\n" + "="*60)
    print("✅ VERIFICATION")
    print("="*60)
    
    for table in tables_to_fix:
        cur.execute(f"""
            SELECT rowsecurity
            FROM pg_tables
            WHERE tablename = '{table}'
            AND schemaname = 'public';
        """)
        
        result = cur.fetchone()
        if result and result[0]:
            print(f"   ✅ {table}: RLS ENABLED")
        else:
            print(f"   ❌ {table}: RLS STILL DISABLED")
    
    cur.close()
    conn.close()
    
    print("\n🎉 RLS ENABLEMENT COMPLETE")
    print("\n⚠️  WARNING: Tables now have RLS but NO POLICIES")
    print("   Users may not be able to access data until policies are added!")
    print("   Run next: create_basic_rls_policies.py")

if __name__ == "__main__":
    enable_rls_all_tables()
