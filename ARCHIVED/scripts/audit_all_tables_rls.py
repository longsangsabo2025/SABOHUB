"""
Complete RLS Audit - All Critical Tables
Check RLS status and policies for all tables
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

def audit_all_tables():
    """Audit RLS for all critical tables"""
    print("="*70)
    print("🔒 COMPLETE RLS SECURITY AUDIT")
    print("="*70)
    
    tables = [
        'companies',
        'employees', 
        'branches',
        'tasks',
        'documents',
        'contracts',
        'attendance',
        'shifts',
    ]
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    results = []
    
    for table in tables:
        print(f"\n📋 TABLE: {table}")
        print("-"*70)
        
        # Check RLS enabled
        cur.execute(f"""
            SELECT rowsecurity
            FROM pg_tables
            WHERE tablename = '{table}'
            AND schemaname = 'public';
        """)
        
        rls_result = cur.fetchone()
        rls_enabled = rls_result[0] if rls_result else False
        
        # Count policies
        cur.execute(f"""
            SELECT COUNT(*)
            FROM pg_policies
            WHERE tablename = '{table}';
        """)
        
        policy_count = cur.fetchone()[0]
        
        # Check for deleted_at column
        cur.execute(f"""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = '{table}'
            AND column_name = 'deleted_at';
        """)
        
        has_soft_delete = cur.fetchone() is not None
        
        # List policy names
        cur.execute(f"""
            SELECT policyname, cmd
            FROM pg_policies
            WHERE tablename = '{table}'
            ORDER BY policyname;
        """)
        
        policies = cur.fetchall()
        
        # Display results
        rls_status = "✅ ENABLED" if rls_enabled else "❌ DISABLED"
        soft_delete = "✅ YES" if has_soft_delete else "❌ NO"
        
        print(f"   RLS: {rls_status}")
        print(f"   Soft Delete: {soft_delete}")
        print(f"   Policies: {policy_count}")
        
        if policies:
            print(f"   Policy List:")
            for policy in policies:
                print(f"      - {policy[0]} ({policy[1]})")
        
        results.append({
            'table': table,
            'rls_enabled': rls_enabled,
            'has_soft_delete': has_soft_delete,
            'policy_count': policy_count,
            'policies': policies
        })
    
    cur.close()
    conn.close()
    
    # Summary
    print("\n" + "="*70)
    print("📊 AUDIT SUMMARY")
    print("="*70)
    
    print("\n1️⃣  RLS STATUS:")
    for r in results:
        status = "✅" if r['rls_enabled'] else "❌"
        print(f"   {status} {r['table']:<15} - RLS {'ENABLED' if r['rls_enabled'] else 'DISABLED'}")
    
    print("\n2️⃣  SOFT DELETE SUPPORT:")
    for r in results:
        status = "✅" if r['has_soft_delete'] else "❌"
        print(f"   {status} {r['table']:<15} - {'Has' if r['has_soft_delete'] else 'Missing'} deleted_at column")
    
    print("\n3️⃣  POLICY COVERAGE:")
    for r in results:
        status = "✅" if r['policy_count'] > 0 else "⚠️ "
        print(f"   {status} {r['table']:<15} - {r['policy_count']} policies")
    
    # Issues
    print("\n4️⃣  CRITICAL ISSUES:")
    issues = []
    
    for r in results:
        if not r['rls_enabled']:
            issues.append(f"❌ {r['table']}: RLS NOT ENABLED")
        if r['policy_count'] == 0:
            issues.append(f"⚠️  {r['table']}: NO RLS POLICIES")
        if not r['has_soft_delete'] and r['table'] in ['companies', 'employees', 'branches']:
            issues.append(f"⚠️  {r['table']}: NO SOFT DELETE SUPPORT")
    
    if issues:
        for issue in issues:
            print(f"   {issue}")
    else:
        print("   ✅ No critical issues found!")
    
    print("\n" + "="*70)
    print("✅ AUDIT COMPLETE")
    print("="*70)
    
    return results

if __name__ == "__main__":
    audit_all_tables()
