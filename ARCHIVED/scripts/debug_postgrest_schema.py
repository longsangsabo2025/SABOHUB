#!/usr/bin/env python3
"""
DEBUG: Check what PostgREST actually sees
"""
import os
import requests
from dotenv import load_dotenv
import psycopg2

load_dotenv()

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

print("🔍 DEBUG: What does PostgREST see?")
print("=" * 50)

# Test 1: Direct PostgREST API call
print("\n1️⃣ Testing PostgREST API directly...")
try:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/tasks",
        headers={
            'apikey': ANON_KEY,
            'Authorization': f'Bearer {ANON_KEY}'
        },
        params={'select': 'count'}
    )
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
except Exception as e:
    print(f"   ERROR: {e}")

# Test 2: Check OpenAPI schema
print("\n2️⃣ Checking PostgREST OpenAPI schema...")
try:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/",
        headers={
            'apikey': ANON_KEY,
            'Accept': 'application/openapi+json'
        }
    )
    print(f"   Status: {response.status_code}")
    if response.status_code == 200:
        schema = response.json()
        paths = list(schema.get('paths', {}).keys())
        task_paths = [p for p in paths if 'task' in p.lower()]
        print(f"   Available paths with 'task': {task_paths}")
        
        # Check if /tasks exists
        if '/tasks' in paths:
            print("   ✅ /tasks endpoint exists in schema")
        else:
            print("   ❌ /tasks endpoint NOT in schema")
            print(f"   Available endpoints: {paths[:10]}...")  # First 10
    else:
        print(f"   ERROR getting schema: {response.text}")
except Exception as e:
    print(f"   ERROR: {e}")

# Test 3: Check database directly
print("\n3️⃣ Checking database directly...")
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

cur.execute("SELECT COUNT(*) FROM tasks;")
task_result = cur.fetchone()
task_count = task_result[0] if task_result else 0
print(f"   Tasks in database: {task_count}")

cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'tasks' AND table_schema = 'public'
    ORDER BY ordinal_position;
""")
columns = [row[0] for row in cur.fetchall()]
print(f"   Columns: {columns}")

cur.execute("""
    SELECT COUNT(*) FROM pg_constraint 
    WHERE conrelid = 'tasks'::regclass AND contype = 'f';
""")
fk_result = cur.fetchone()
fk_count = fk_result[0] if fk_result else 0
print(f"   FK constraints: {fk_count}")

# Test 4: Test simple insert via PostgREST
print("\n4️⃣ Testing simple insert via PostgREST...")
test_data = {
    'title': 'DEBUG TEST TASK',
    'description': 'Test from debug script',
    'category': 'general',
    'priority': 'medium',
    'status': 'pending'
}

try:
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/tasks",
        headers={
            'apikey': ANON_KEY,
            'Authorization': f'Bearer {ANON_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        },
        json=test_data
    )
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code == 201:
        print("   ✅ INSERT via PostgREST SUCCESS!")
    else:
        print("   ❌ INSERT via PostgREST FAILED")
        
except Exception as e:
    print(f"   ERROR: {e}")

cur.close()
conn.close()

print("\n" + "=" * 50)
print("DEBUG COMPLETE!")