#!/usr/bin/env python3
"""Drop employee_login function to allow recreation with fixed schema"""

import psycopg2
import os
from dotenv import load_dotenv

def main():
    load_dotenv()
    
    # Get connection string from .env
    conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_str:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env")
        return False
    
    try:
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        print("🗑️  Dropping old employee_login function...")
        cur.execute("DROP FUNCTION IF EXISTS public.employee_login(text, text, text)")
        conn.commit()
        
        print("✅ Function dropped successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
