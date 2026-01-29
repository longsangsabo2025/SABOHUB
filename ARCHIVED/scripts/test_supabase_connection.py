#!/usr/bin/env python3
"""
Test Supabase Connection
Kiểm tra kết nối và xem cấu trúc database
"""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

print("="*60)
print("🔍 SUPABASE CONNECTION TEST")
print("="*60)

# Check environment variables
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')

print(f"\n1. Environment Variables:")
print(f"   URL: {SUPABASE_URL}")
print(f"   Key: {SUPABASE_KEY[:30]}..." if SUPABASE_KEY else "   Key: NOT SET")

# Test import
print(f"\n2. Import supabase library...")
try:
    from supabase import create_client
    print("   ✅ Import successful")
except ImportError as e:
    print(f"   ❌ Import failed: {e}")
    exit(1)

# Test connection
print(f"\n3. Connect to Supabase...")
try:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("   ✅ Connection successful")
except Exception as e:
    print(f"   ❌ Connection failed: {e}")
    exit(1)

# Test query - List all tables
print(f"\n4. Query database...")
try:
    # Try to get employees
    print("   Trying employees table...")
    response = supabase.table('employees').select('*').limit(1).execute()
    
    if response.data:
        print(f"   ✅ Found {len(response.data)} employee(s)")
        print(f"   Columns: {list(response.data[0].keys())}")
        print(f"   Sample data: {response.data[0]}")
    else:
        print("   ⚠️  Employees table empty")
        
        # Try to see table schema by checking error
        try:
            response = supabase.table('employees').select('id,user_id,full_name,role,email,phone,company_id,branch_id').limit(1).execute()
            print(f"   Columns exist: id, user_id, full_name, role, email, phone, company_id, branch_id")
        except Exception as e:
            print(f"   Error checking schema: {e}")
            
except Exception as e:
    print(f"   ❌ Query failed: {e}")

# Test attendance table
print(f"\n5. Check attendance table...")
try:
    response = supabase.table('attendance').select('*').limit(1).execute()
    
    if response.data:
        print(f"   ✅ Found {len(response.data)} attendance record(s)")
        print(f"   Columns: {list(response.data[0].keys())}")
    else:
        print("   ⚠️  Attendance table empty")
        
except Exception as e:
    print(f"   ❌ Query failed: {e}")

# Test tasks table
print(f"\n6. Check tasks table...")
try:
    response = supabase.table('tasks').select('*').limit(1).execute()
    
    if response.data:
        print(f"   ✅ Found {len(response.data)} task(s)")
        print(f"   Columns: {list(response.data[0].keys())}")
    else:
        print("   ⚠️  Tasks table empty")
        
except Exception as e:
    print(f"   ❌ Query failed: {e}")

# Summary
print("\n" + "="*60)
print("✅ CONNECTION TEST COMPLETE")
print("="*60)
print("\nNext steps:")
print("1. If tables are empty, create test data via app")
print("2. Update test_daily_report_generation.py with correct column names")
print("3. Run the daily report test")
