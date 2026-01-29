#!/usr/bin/env python3
"""
Make branch_id nullable in tasks table
This allows creating tasks without requiring a branch
"""

import os
import psycopg2
from dotenv import load_dotenv

def make_tasks_branch_id_nullable():
    load_dotenv()
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not connection_string:
        print("SUPABASE_CONNECTION_STRING not found in .env file")
        return
    
    print("Checking tasks table branch_id constraint...")
    print("=" * 60)
    
    conn = None
    cur = None
    
    try:
        conn = psycopg2.connect(connection_string)
        cur = conn.cursor()
        
        # Check current constraint
        print("\nCurrent branch_id constraint:")
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
            print(f"   Column: {result[0]}")
            print(f"   Nullable: {result[1]}")
            print(f"   Type: {result[2]}")
            
            if result[1] == 'NO':
                print("\nbranch_id is NOT NULL - needs to be changed")
                print("\nMaking branch_id nullable...")
                
                # Make the column nullable
                cur.execute("""
                    ALTER TABLE tasks 
                    ALTER COLUMN branch_id DROP NOT NULL;
                """)
                
                conn.commit()
                print("Successfully made branch_id nullable!")
                
                # Verify the change
                cur.execute("""
                    SELECT is_nullable
                    FROM information_schema.columns
                    WHERE table_name = 'tasks' 
                    AND column_name = 'branch_id';
                """)
                
                verify_result = cur.fetchone()
                if verify_result:
                    print(f"\nVerification: branch_id is_nullable = {verify_result[0]}")
                
            else:
                print("\nbranch_id is already nullable - no changes needed")
        
        else:
            print("branch_id column not found in tasks table")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 60)
        print("Script completed successfully!")
        
    except psycopg2.Error as e:
        print(f"\nDatabase error: {e}")
        print(f"   Error code: {e.pgcode}")
        print(f"   Error details: {e.pgerror}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"\nError: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    make_tasks_branch_id_nullable()
