#!/usr/bin/env python3
"""Test inserting company directly to database"""

import os
from dotenv import load_dotenv
import psycopg2
from pathlib import Path
import uuid

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
if '?' in conn_str:
    conn_str = conn_str.split('?')[0]

print("Testing INSERT into companies table...")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Test insert
    test_data = {
        'id': str(uuid.uuid4()),
        'name': 'Test Company 123',
        'business_type': 'billiards',
        'address': '123 Test Street',
        'phone': '0901234567',
        'email': 'test@company.com',
        'is_active': True
    }
    
    print("\nInserting test company:")
    print(f"  Name: {test_data['name']}")
    print(f"  Address: {test_data['address']}")
    print(f"  Phone: {test_data['phone']}")
    
    cur.execute("""
        INSERT INTO companies (id, name, business_type, address, phone, email, is_active)
        VALUES (%(id)s, %(name)s, %(business_type)s, %(address)s, %(phone)s, %(email)s, %(is_active)s)
        RETURNING id, name, created_at;
    """, test_data)
    
    result = cur.fetchone()
    conn.commit()
    
    print(f"\n✅ SUCCESS!")
    print(f"  ID: {result[0]}")
    print(f"  Name: {result[1]}")
    print(f"  Created: {result[2]}")
    
    # Count companies
    cur.execute("SELECT COUNT(*) FROM companies;")
    count = cur.fetchone()[0]
    print(f"\n📊 Total companies in database: {count}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
