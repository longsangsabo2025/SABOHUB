#!/usr/bin/env python3
"""
Script to make company_id nullable in the branches table
This allows creating branches without requiring a company association
"""

import os
import psycopg2
from dotenv import load_dotenv

def make_company_id_nullable():
    # Load environment variables
    load_dotenv()
    
    # Get connection string from environment
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not connection_string:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env file")
        return
    
    print("🔍 Checking branches table company_id constraint...")
    print("=" * 60)
    
    conn = None
    cur = None
    
    try:
        # Connect to database using connection string
        conn = psycopg2.connect(connection_string)
        cur = conn.cursor()
        
        # Check current constraint
        print("\n📋 Current company_id constraint:")
        cur.execute("""
            SELECT 
                column_name,
                is_nullable,
                data_type
            FROM information_schema.columns
            WHERE table_name = 'branches' 
            AND column_name = 'company_id';
        """)
        
        result = cur.fetchone()
        if result:
            print(f"   Column: {result[0]}")
            print(f"   Nullable: {result[1]}")
            print(f"   Type: {result[2]}")
            
            if result[1] == 'NO':
                print("\n⚠️  company_id is NOT NULL - needs to be changed")
                print("\n🔧 Making company_id nullable...")
                
                # Make the column nullable
                cur.execute("""
                    ALTER TABLE branches 
                    ALTER COLUMN company_id DROP NOT NULL;
                """)
                
                conn.commit()
                print("✅ Successfully made company_id nullable!")
                
                # Verify the change
                cur.execute("""
                    SELECT is_nullable
                    FROM information_schema.columns
                    WHERE table_name = 'branches' 
                    AND column_name = 'company_id';
                """)
                
                verify_result = cur.fetchone()
                if verify_result:
                    print(f"\n✅ Verification: company_id is_nullable = {verify_result[0]}")
                
            else:
                print("\n✅ company_id is already nullable - no changes needed")
        
        else:
            print("❌ company_id column not found in branches table")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 60)
        print("✅ Script completed successfully!")
        
    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        print(f"   Error details: {e.pgerror}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"\n❌ Error: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    make_company_id_nullable()
