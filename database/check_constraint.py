#!/usr/bin/env python3
"""Check business_type constraint on companies table"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if conn_str and '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("Checking business_type constraint...")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Get constraint definition
    cur.execute("""
        SELECT pg_get_constraintdef(oid) as definition
        FROM pg_constraint
        WHERE conname = 'companies_business_type_check'
        AND conrelid = 'companies'::regclass;
    """)
    
    result = cur.fetchone()
    if result:
        print(f"\nConstraint definition:")
        print(f"  {result[0]}")
        
        # Parse allowed values
        definition = result[0]
        print(f"\n🔍 Current constraint is BLOCKING your insert!")
        print(f"\n💡 Solution: Drop this constraint or update it")
    else:
        print("\n❌ Constraint not found")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
