"""
Direct PostgreSQL migration: Add employee info to attendance table
Adds employee_name and employee_role columns for better performance
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('SUPABASE_CONNECTION_STRING')

if not DATABASE_URL:
    print("❌ SUPABASE_CONNECTION_STRING not found in .env file")
    exit(1)

def run_migration():
    """Add employee info to attendance table"""
    print("\n📋 === ADDING EMPLOYEE INFO TO ATTENDANCE TABLE ===\n")
    
    conn = None
    cursor = None
    
    try:
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        print("   ✅ Connected successfully")
        
        # Step 1: Add columns
        print("\n1️⃣ Adding columns to attendance table...")
        cursor.execute("""
            ALTER TABLE attendance 
            ADD COLUMN IF NOT EXISTS employee_name TEXT,
            ADD COLUMN IF NOT EXISTS employee_role TEXT;
        """)
        conn.commit()
        print("   ✅ Columns added: employee_name, employee_role")
        
        # Step 2: Update existing records
        print("\n2️⃣ Updating existing attendance records...")
        cursor.execute("""
            UPDATE attendance a
            SET 
              employee_name = u.full_name,
              employee_role = u.role
            FROM users u
            WHERE a.user_id = u.id AND a.employee_name IS NULL;
        """)
        rows_updated = cursor.rowcount
        conn.commit()
        print(f"   ✅ Updated {rows_updated} attendance records")
        
        # Step 3: Create indexes
        print("\n3️⃣ Creating performance indexes...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_attendance_employee_name 
            ON attendance(employee_name) 
            WHERE employee_name IS NOT NULL;
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_attendance_store_user 
            ON attendance(store_id, user_id);
        """)
        conn.commit()
        print("   ✅ Indexes created for better query performance")
        
        # Step 4: Verify migration
        print("\n4️⃣ Verifying migration...")
        cursor.execute("SELECT COUNT(*) FROM attendance;")
        result = cursor.fetchone()
        total_attendance = result[0] if result else 0
        
        cursor.execute("SELECT COUNT(*) FROM attendance WHERE employee_name IS NOT NULL;")
        result2 = cursor.fetchone()
        attendance_with_names = result2[0] if result2 else 0
        
        # Get sample attendance record
        cursor.execute("""
            SELECT id, employee_name, employee_role, check_in 
            FROM attendance 
            WHERE employee_name IS NOT NULL 
            LIMIT 1;
        """)
        sample = cursor.fetchone()
        
        if sample:
            print("   ✅ Sample attendance record:")
            print(f"      - ID: {sample[0]}")
            print(f"      - Employee: {sample[1]}")
            print(f"      - Role: {sample[2]}")
            print(f"      - Check-in: {sample[3]}")
        
        print("\n✅ === MIGRATION COMPLETED SUCCESSFULLY ===\n")
        
        # Summary
        print("📊 SUMMARY:")
        print(f"   • Total attendance records: {total_attendance}")
        print(f"   • Records with employee info: {attendance_with_names}")
        print("   • New columns: 2 (employee_name, employee_role)")
        print("   • New indexes: 2")
        print("\n💡 NEXT STEPS:")
        print("   1. Update AttendanceService to populate these fields")
        print("   2. Update UI to display names instead of user IDs")
        print("   3. Manager can now see attendance with employee names directly")
        
    except psycopg2.Error as e:
        print(f"\n❌ Database Error: {e}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == "__main__":
    run_migration()
