import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user.dart' as app_models;
import '../providers/auth_provider.dart';

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(ref: ref);
});

/// Employee Service
/// Handles employee account creation and management
class EmployeeService {
  final _supabase = Supabase.instance.client;
  final Ref? _ref;

  EmployeeService({Ref? ref}) : _ref = ref;

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Get existing user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id, email, name, role, is_active')
          .eq('email', email)
          .maybeSingle();
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Generate email based on role and company
  String generateEmployeeEmail({
    required String companyName,
    required app_models.UserRole role,
    int? sequence,
  }) {
    // Normalize company name (remove spaces, special chars, lowercase)
    final normalizedCompany = companyName.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

    // Role prefix
    String rolePrefix;
    switch (role) {
      case app_models.UserRole.manager:
        rolePrefix = 'manager';
        break;
      case app_models.UserRole.shiftLeader:
        rolePrefix = 'shiftleader';
        break;
      case app_models.UserRole.staff:
        rolePrefix = 'staff';
        break;
      case app_models.UserRole.ceo:
        rolePrefix = 'ceo';
        break;
    }

    // Generate email
    if (sequence != null && sequence > 1) {
      return '$rolePrefix$sequence$normalizedCompany@sabohub.com';
    }
    return '$rolePrefix$normalizedCompany@sabohub.com';
  }

  /// Create employee account INSTANTLY - CEO tạo tài khoản ngay lập tức
  /// Employee có thể login ngay với credentials được tạo
  Future<Map<String, dynamic>> createEmployeeAccount({
    required String companyId,
    required String companyName,
    required app_models.UserRole role,
    String? customEmail,
  }) async {
    try {
      // Verify CEO is logged in (check both demo and real auth)
      app_models.User? currentUser;

      if (_ref != null) {
        // Check demo authentication first
        final authState = _ref.read(authProvider);
        currentUser = authState.user;
      }

      // Fallback to Supabase auth if no demo user
      if (currentUser == null) {
        final supabaseUser = _supabase.auth.currentUser;
        if (supabaseUser == null) {
          throw Exception('Please login as CEO first');
        }
      }

      // Verify user is CEO
      if (currentUser != null && currentUser.role != app_models.UserRole.ceo) {
        throw Exception('Only CEO can create employee accounts');
      }

      print('🔍 Creating employee account...');
      print('CEO: ${currentUser?.email ?? _supabase.auth.currentUser?.email}');

      // Generate unique email
      String email = customEmail ??
          generateEmployeeEmail(companyName: companyName, role: role);

      // Ensure email is unique
      if (customEmail == null) {
        int sequence = 1;
        while (await _emailExists(email)) {
          sequence++;
          email = generateEmployeeEmail(
            companyName: companyName,
            role: role,
            sequence: sequence,
          );
        }
      }

      // Check if email already exists before creating
      if (await emailExists(email)) {
        throw Exception(
            'Email $email đã được sử dụng. Vui lòng thử email khác.');
      }

      // Generate secure password
      final tempPassword = _generateTempPassword();

      print('📧 Employee email: $email');
      print('🔑 Temp password: $tempPassword');

      // Retry mechanism for auth creation
      int retryCount = 0;
      const maxRetries = 3;
      UserResponse? authResponse;

      while (retryCount < maxRetries) {
        try {
          // Method 1: Use Service Role to create auth user directly
          final adminSupabase = SupabaseClient(
            'https://dqddxowyikefqcdiioyh.supabase.co',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI',
          );

          // Create auth user with admin privileges
          authResponse = await adminSupabase.auth.admin.createUser(
            AdminUserAttributes(
              email: email,
              password: tempPassword,
              emailConfirm: true, // Skip email confirmation
              userMetadata: {
                'role': role.value,
                'company_id': companyId,
                'full_name': _generateDefaultName(role),
              },
            ),
          );

          if (authResponse.user != null) {
            break; // Success, exit retry loop
          }
        } catch (e) {
          retryCount++;
          print('⚠️ Auth creation attempt $retryCount failed: $e');
          if (retryCount >= maxRetries) {
            throw Exception(
                'Failed to create auth user after $maxRetries attempts: $e');
          }
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      if (authResponse?.user == null) {
        throw Exception('Failed to create auth user');
      }

      final newUserId = authResponse!.user!.id;
      print('✅ Auth user created: $newUserId');

      // Database insertion with retry and duplicate handling
      retryCount = 0;
      while (retryCount < maxRetries) {
        try {
          // Check if user already exists in database
          final existingUser = await _supabase
              .from('users')
              .select('id')
              .eq('id', newUserId)
              .maybeSingle();

          if (existingUser != null) {
            print('⚠️ User already exists in database, updating instead...');
            // Update existing record
            await _supabase.from('users').update({
              'email': email,
              'role': role.value,
              'company_id': companyId,
              'full_name': _generateDefaultName(role),
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', newUserId);
          } else {
            // Create new user record in database
            await _supabase.from('users').insert({
              'id': newUserId,
              'email': email,
              'role': role.value,
              'company_id': companyId,
              'full_name': _generateDefaultName(role),
              'is_active': true,
            });
          }

          print('✅ Database record created/updated');
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          print('⚠️ Database insertion attempt $retryCount failed: $e');

          if (e.toString().contains('23505') &&
              e.toString().contains('users_pkey')) {
            // If it's a duplicate key error, try to handle it gracefully
            print('🔄 Handling duplicate key, attempting to update record...');
            try {
              await _supabase.from('users').update({
                'email': email,
                'role': role.value,
                'company_id': companyId,
                'full_name': _generateDefaultName(role),
                'is_active': true,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', newUserId);
              print('✅ Successfully updated existing record');
              break;
            } catch (updateError) {
              print('❌ Update also failed: $updateError');
            }
          }

          if (retryCount >= maxRetries) {
            throw Exception(
                'Failed to create database record after $maxRetries attempts: $e');
          }
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      // Return complete user data
      final newUser = app_models.User(
        id: newUserId,
        name: _generateDefaultName(role),
        email: email,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return {
        'success': true,
        'user': newUser,
        'email': email,
        'tempPassword': tempPassword,
        'userId': newUserId,
        'message': 'Employee can login immediately with these credentials',
      };
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Failed to create employee: $e');
    }
  }

  /// Check if email already exists
  Future<bool> _emailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Generate temporary password (8 chars, alphanumeric)
  String _generateTempPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var password = '';

    for (var i = 0; i < 8; i++) {
      password += chars[(random + i) % chars.length];
    }

    return 'Sabo$password!';
  }

  /// Generate default name based on role
  String _generateDefaultName(app_models.UserRole role) {
    switch (role) {
      case app_models.UserRole.manager:
        return 'Quản lý';
      case app_models.UserRole.shiftLeader:
        return 'Trưởng ca';
      case app_models.UserRole.staff:
        return 'Nhân viên';
      case app_models.UserRole.ceo:
        return 'CEO';
    }
  }

  /// Get all employees for a company
  Future<List<app_models.User>> getCompanyEmployees(String companyId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_models.User.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employees: $e');
    }
  }

  /// Update employee information
  Future<void> updateEmployee({
    required String employeeId,
    String? name,
    String? email,
    String? phone,
    app_models.UserRole? role,
    String? branchId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['full_name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role.value;
      if (branchId != null) updates['branch_id'] = branchId;

      await _supabase.from('users').update(updates).eq('id', employeeId);

      print('✅ Employee updated successfully: $employeeId');
    } catch (e) {
      print('❌ Failed to update employee: $e');
      throw Exception('Failed to update employee: $e');
    }
  }

  /// Deactivate/Activate employee account
  Future<void> toggleEmployeeStatus(String userId, bool isActive) async {
    try {
      await _supabase.from('users').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ Employee status updated: $userId -> $isActive');
    } catch (e) {
      print('❌ Failed to update employee status: $e');
      throw Exception('Failed to update employee status: $e');
    }
  }

  /// Delete employee account
  Future<void> deleteEmployee(String userId) async {
    try {
      // Delete from users table
      await _supabase.from('users').delete().eq('id', userId);

      // Note: Supabase auth user should be deleted via admin API
      // For now, we just delete from users table
      print('✅ Employee deleted: $userId');
    } catch (e) {
      print('❌ Failed to delete employee: $e');
      throw Exception('Failed to delete employee: $e');
    }
  }

  /// Resend account credentials
  Future<Map<String, String>> resendCredentials(String userId) async {
    try {
      // Get user info
      final response =
          await _supabase.from('users').select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at').eq('id', userId).single();

      final user = app_models.User.fromJson(response);

      // Generate new temporary password
      final newPassword = _generateTempPassword();

      // Update password in Supabase Auth
      // Note: This requires admin privileges
      // For now, return the new password to be set manually

      return {'email': user.email, 'tempPassword': newPassword};
    } catch (e) {
      throw Exception('Failed to resend credentials: $e');
    }
  }
}
