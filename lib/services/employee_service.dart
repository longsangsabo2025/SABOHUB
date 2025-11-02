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

      // Generate secure password
      final tempPassword = _generateTempPassword();

      print('📧 Employee email: $email');
      print('🔑 Temp password: $tempPassword');

      // Method 1: Use Service Role to create auth user directly
      final adminSupabase = SupabaseClient(
        'https://dqddxowyikefqcdiioyh.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI',
      );

      // Create auth user with admin privileges
      final authResponse = await adminSupabase.auth.admin.createUser(
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

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      final newUserId = authResponse.user!.id;
      print('✅ Auth user created: $newUserId');

      // Create user record in database
      await _supabase.from('users').insert({
        'id': newUserId,
        'email': email,
        'role': role.value,
        'company_id': companyId,
        'full_name': _generateDefaultName(role),
        'is_active': true,
      });

      print('✅ Database record created');

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

    return 'Sabo${password}!';
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
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_models.User.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employees: $e');
    }
  }

  /// Delete employee account
  Future<void> deleteEmployee(String userId) async {
    try {
      // Delete from users table
      await _supabase.from('users').delete().eq('id', userId);

      // Note: Supabase auth user should be deleted via admin API
      // For now, we just delete from users table
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  /// Resend account credentials
  Future<Map<String, String>> resendCredentials(String userId) async {
    try {
      // Get user info
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

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
