#!/usr/bin/env python3
"""
Add completed_at column to tasks table
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def main():
    try:
        conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
        cur = conn.cursor()
        
        print("📋 Checking tasks table structure...")
        
        # Check if column exists
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'completed_at'
        """)
        
        if cur.fetchone():
            print("✅ Column 'completed_at' already exists!")
        else:
            print("➕ Adding 'completed_at' column...")
            
            # Add the column
            cur.execute("""
                ALTER TABLE tasks 
                ADD COLUMN completed_at TIMESTAMPTZ
            """)
            
            conn.commit()
            print("✅ Column 'completed_at' added successfully!")
        
        # Show current table structure
        print("\n📊 Current tasks table columns:")
        cur.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            ORDER BY ordinal_position
        """)
        
        for row in cur.fetchall():
            nullable = "NULL" if row[2] == 'YES' else "NOT NULL"
            print(f"   - {row[0]}: {row[1]} ({nullable})")
        
        cur.close()
        conn.close()
        
        print("\n✅ All done! Now hot reload the app (press 'r' in Flutter terminal)")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        raise

if __name__ == "__main__":
    main()
