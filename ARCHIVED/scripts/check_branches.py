#!/usr/bin/env python3
"""
Check branches table constraints
"""

import os
import psycopg2
from dotenv import load_dotenv

def check_branches():
    load_dotenv()
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not connection_string:
        print("❌ SUPABASE_CONNECTION_STRING not found")
        return
    
    print("🔍 Checking branches table and tasks.branch_id constraint...")
    print("=" * 60)
    
    try:
        conn = psycopg2.connect(connection_string)
        cur = conn.cursor()
        
        # Check if there are any branches
        cur.execute("SELECT COUNT(*) FROM branches;")
        branch_count = cur.fetchone()[0]
        print(f"\n📊 Current branches in database: {branch_count}")
        
        if branch_count > 0:
            cur.execute("SELECT id, name, company_id FROM branches LIMIT 5;")
            branches = cur.fetchall()
            print("\n📋 Existing branches:")
            for branch in branches:
                print(f"   - {branch[1]} (ID: {branch[0]}, Company: {branch[2]})")
        
        # Check tasks.branch_id constraint
        cur.execute("""
            SELECT 
                column_name,
                is_nullable,
                data_type
            FROM information_schema.columns
            WHERE table_name = 'tasks' 
            AND column_name = 'branch_id';
        """)
        
        result = cur.fetchone()
        if result:
            print(f"\n📋 tasks.branch_id constraint:")
            print(f"   Column: {result[0]}")
            print(f"   Nullable: {result[1]}")
            print(f"   Type: {result[2]}")
            
            if result[1] == 'NO':
                print("\n⚠️  branch_id is NOT NULL - tasks MUST have a branch!")
            else:
                print("\n✅ branch_id is nullable - tasks can exist without branch")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    check_branches()
