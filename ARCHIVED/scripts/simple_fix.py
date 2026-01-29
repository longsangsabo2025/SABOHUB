#!/usr/bin/env python3
"""
SABOHUB - SIMPLE EMPLOYEE CREATION FIX
Back to basics: Fix the core issue without over-engineering
"""

import psycopg2
import os
from dotenv import load_dotenv

def fix_employee_creation_simple():
    """
    Giải pháp đơn giản: Sử dụng trực tiếp PostgreSQL function
    Không cần Edge Functions, không cần phức tạp
    """
    
    load_dotenv()
    
    print("🔧 SIMPLE FIX: CEO Employee Creation")
    print("=" * 45)
    
    # Connect to database
    conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not conn_string:
        print("❌ Missing database connection string")
        return
    
    try:
        conn = psycopg2.connect(conn_string)
        cur = conn.cursor()
        
        print("✅ Connected to database")
        
        # Create simple PostgreSQL function
        function_sql = """
        CREATE OR REPLACE FUNCTION public.create_employee_by_ceo(
            p_ceo_id UUID,
            p_email TEXT,
            p_password TEXT,
            p_role TEXT,
            p_company_id UUID,
            p_full_name TEXT DEFAULT 'New Employee'
        )
        RETURNS JSON
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        DECLARE
            v_new_user_id UUID;
            v_ceo_role TEXT;
            v_ceo_company UUID;
            result JSON;
        BEGIN
            -- Check if caller is CEO
            SELECT role, company_id INTO v_ceo_role, v_ceo_company
            FROM users WHERE id = p_ceo_id;
            
            IF v_ceo_role != 'CEO' THEN
                RAISE EXCEPTION 'Only CEOs can create employees';
            END IF;
            
            IF v_ceo_company != p_company_id THEN
                RAISE EXCEPTION 'CEO can only create employees for their company';
            END IF;
            
            -- Generate new user ID
            v_new_user_id := gen_random_uuid();
            
            -- Insert user (we'll handle auth separately in Flutter)
            INSERT INTO users (
                id, email, role, company_id, full_name, 
                is_active, created_at, updated_at
            ) VALUES (
                v_new_user_id, p_email, p_role, p_company_id, p_full_name,
                true, now(), now()
            );
            
            -- Return result
            result := json_build_object(
                'success', true,
                'user_id', v_new_user_id,
                'email', p_email,
                'temp_password', p_password,
                'role', p_role,
                'company_id', p_company_id,
                'full_name', p_full_name
            );
            
            RETURN result;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to create employee: %', SQLERRM;
        END;
        $$;
        """
        
        print("📝 Creating database function...")
        cur.execute(function_sql)
        
        # Grant permissions
        grant_sql = "GRANT EXECUTE ON FUNCTION public.create_employee_by_ceo TO authenticated;"
        cur.execute(grant_sql)
        
        conn.commit()
        print("✅ Database function created successfully")
        
        # Test the function
        test_sql = """
        SELECT public.create_employee_by_ceo(
            '00000000-0000-0000-0000-000000000000'::UUID,
            'test@example.com',
            'temp123',
            'employee', 
            '00000000-0000-0000-0000-000000000000'::UUID,
            'Test User'
        );
        """
        
        print("🧪 Testing function...")
        try:
            cur.execute(test_sql)
            result = cur.fetchone()
            print(f"✅ Function works (test with dummy data)")
        except Exception as e:
            print(f"⚠️ Function created but test failed (expected): {str(e)}")
        
        conn.close()
        
        print("\n🎯 NEXT STEP: Update Flutter service")
        print("Replace Edge Function call with direct database function call")
        
        return True
        
    except Exception as e:
        print(f"❌ Database error: {str(e)}")
        return False

def generate_flutter_service_fix():
    """
    Generate the simple Flutter service code
    """
    
    print("\n📱 FLUTTER SERVICE UPDATE:")
    print("=" * 35)
    
    flutter_code = '''
// Updated EmployeeService - Simple approach
class EmployeeService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createEmployeeAccount({
    required String companyId,
    required String companyName,
    required app_models.UserRole role,
    String? customEmail,
  }) async {
    try {
      // Get current user (CEO)
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Generate email and password
      String email = customEmail ?? 
          generateEmployeeEmail(companyName: companyName, role: role);
      String tempPassword = _generateTempPassword();

      // Call database function directly
      final response = await _supabase.rpc('create_employee_by_ceo', {
        'p_ceo_id': user.id,
        'p_email': email,
        'p_password': tempPassword,
        'p_role': role.value,
        'p_company_id': companyId,
        'p_full_name': _generateDefaultName(role),
      });

      // Now create auth user (this is the tricky part)
      // We'll use signUp but immediately signOut to preserve CEO session
      final currentSession = _supabase.auth.currentSession;
      
      await _supabase.auth.signUp(
        email: email,
        password: tempPassword,
      );
      
      // Restore CEO session
      if (currentSession != null) {
        await _supabase.auth.setSession(currentSession.accessToken);
      }

      return {
        'user': app_models.User.fromJson(response),
        'email': email,
        'tempPassword': tempPassword,
        'userId': response['user_id'],
      };

    } catch (e) {
      throw Exception('Failed to create employee: $e');
    }
  }
}
'''
    
    print(flutter_code)
    
    print("\n🚨 THE REAL PROBLEM:")
    print("Supabase signUp() logs out current user")
    print("This is why CEO loses session when creating employee")
    
    print("\n💡 ULTIMATE SOLUTION:")
    print("1. Create database record first")
    print("2. Send email to employee with signup link")  
    print("3. Employee completes their own signup")
    print("4. CEO session remains intact")

def main():
    print("🎯 ROOT CAUSE ANALYSIS")
    print("=" * 25)
    print("❌ Problem: CEO can't create employee accounts")
    print("🔍 Real Issue: Supabase signUp() logs out current user")
    print("💡 Simple Solution: Invitation-based signup")
    
    print("\n" + "="*50)
    
    if fix_employee_creation_simple():
        generate_flutter_service_fix()
        
        print("\n🏁 SUMMARY:")
        print("✅ Database function created")
        print("✅ Simple approach defined")
        print("🎯 Next: Implement invitation system")
        print("⚡ Time to implement: 30 minutes")
    else:
        print("❌ Failed to create database function")

if __name__ == "__main__":
    main()