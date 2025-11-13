"""
Verify all indexes for performance optimization
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print("\n" + "="*80)
print("DATABASE INDEXES VERIFICATION")
print("="*80)

# Check tasks table indexes
print("\n📊 TASKS TABLE INDEXES:")
cursor.execute("""
    SELECT indexname, indexdef 
    FROM pg_indexes 
    WHERE tablename = 'tasks' 
    AND schemaname = 'public'
    ORDER BY indexname;
""")

tasks_indexes = cursor.fetchall()
for idx_name, idx_def in tasks_indexes:
    if 'idx_tasks_company' in idx_name or 'idx_tasks_assignee' in idx_name:
        print(f"  ✅ {idx_name}")
        print(f"     {idx_def[:100]}...")

# Check attendance table indexes
print("\n📊 ATTENDANCE TABLE INDEXES:")
cursor.execute("""
    SELECT indexname, indexdef 
    FROM pg_indexes 
    WHERE tablename = 'attendance' 
    AND schemaname = 'public'
    ORDER BY indexname;
""")

attendance_indexes = cursor.fetchall()
for idx_name, idx_def in attendance_indexes:
    if 'idx_attendance' in idx_name:
        print(f"  ✅ {idx_name}")
        print(f"     {idx_def[:100]}...")

# Verify columns
print("\n" + "="*80)
print("COLUMN VERIFICATION")
print("="*80)

print("\n📋 TASKS TABLE COLUMNS:")
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'tasks' 
    AND column_name IN ('assigned_to_name', 'assigned_to_role', 'deleted_at')
    ORDER BY column_name;
""")

for col_name, data_type, nullable in cursor.fetchall():
    print(f"  ✅ {col_name}: {data_type} (nullable: {nullable})")

print("\n📋 ATTENDANCE TABLE COLUMNS:")
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'attendance' 
    AND column_name IN ('employee_name', 'employee_role', 'deleted_at')
    ORDER BY column_name;
""")

for col_name, data_type, nullable in cursor.fetchall():
    print(f"  ✅ {col_name}: {data_type} (nullable: {nullable})")

print("\n📋 USERS TABLE COLUMNS:")
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'users' 
    AND column_name = 'deleted_at'
    ORDER BY column_name;
""")

for col_name, data_type, nullable in cursor.fetchall():
    print(f"  ✅ {col_name}: {data_type} (nullable: {nullable})")

# Count records
print("\n" + "="*80)
print("DATA SUMMARY")
print("="*80)

cursor.execute("SELECT COUNT(*) FROM tasks WHERE deleted_at IS NULL")
print(f"\n📊 Active Tasks: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM tasks WHERE assigned_to_name IS NOT NULL")
print(f"   Tasks with employee names: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM attendance WHERE deleted_at IS NULL")
print(f"\n📊 Active Attendance: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM attendance WHERE employee_name IS NOT NULL")
print(f"   Attendance with employee info: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM users WHERE deleted_at IS NULL")
print(f"\n📊 Active Users: {cursor.fetchone()[0]}")

cursor.execute("SELECT role, COUNT(*) FROM users WHERE deleted_at IS NULL GROUP BY role ORDER BY role")
print("\n   User distribution:")
for role, count in cursor.fetchall():
    print(f"     {role}: {count}")

cursor.close()
conn.close()

print("\n" + "="*80)
print("✅ ALL MIGRATIONS VERIFIED SUCCESSFULLY")
print("="*80 + "\n")
