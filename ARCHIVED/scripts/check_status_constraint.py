#!/usr/bin/env python3
"""
Script to check the tasks_status_check constraint
"""

import os
import psycopg2
from dotenv import load_dotenv

def check_status_constraint():
    load_dotenv()
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not connection_string:
        print("❌ SUPABASE_CONNECTION_STRING not found")
        return
    
    print("🔍 Checking tasks table status constraint...")
    print("=" * 60)
    
    try:
        conn = psycopg2.connect(connection_string)
        cur = conn.cursor()
        
        # Get the check constraint definition
        cur.execute("""
            SELECT
                conname as constraint_name,
                pg_get_constraintdef(c.oid) as constraint_definition
            FROM pg_constraint c
            JOIN pg_namespace n ON n.oid = c.connamespace
            JOIN pg_class cl ON cl.oid = c.conrelid
            WHERE cl.relname = 'tasks'
            AND c.contype = 'c'
            AND conname LIKE '%status%';
        """)
        
        results = cur.fetchall()
        
        if results:
            print("\n📋 Status Check Constraint:")
            for row in results:
                print(f"   Name: {row[0]}")
                print(f"   Definition: {row[1]}")
        else:
            print("\n❌ No status check constraint found")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    check_status_constraint()
