#!/usr/bin/env python3
"""Recreate employee_login function with correct schema"""

import psycopg2
import os
from dotenv import load_dotenv

def main():
    load_dotenv()
    
    conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_str:
        print("❌ SUPABASE_CONNECTION_STRING not found")
        return False
    
    try:
        print("📄 Reading SQL file...")
        with open('recreate_employee_login.sql', 'r') as f:
            sql = f.read()
        
        print(f"✅ Loaded SQL ({len(sql)} characters)")
        
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        print("⚙️  Recreating employee_login function...")
        cur.execute(sql)
        conn.commit()
        
        print("✅ Function recreated successfully!")
        
        # Verify
        cur.execute("""
            SELECT routine_name 
            FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'employee_login'
        """)
        if cur.fetchone():
            print("✅ Verified: employee_login function exists")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
