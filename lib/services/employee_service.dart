import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/repositories/impl/employee_repository.dart';
import '../models/user.dart' as app_models;
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(ref: ref);
});

/// Employee Service
/// Handles employee account creation and management
class EmployeeService {
  final _supabase = Supabase.instance.client;
  final EmployeeRepository _repo = EmployeeRepository();
  final Ref? _ref;

  EmployeeService({Ref? ref}) : _ref = ref;

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final result = await _supabase
          .from('employees')
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
          .from('employees')
          .select('id, email, full_name, role, is_active')
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
      case app_models.UserRole.superAdmin:
        rolePrefix = 'superadmin';
        break;
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
      case app_models.UserRole.driver:
        rolePrefix = 'driver';
        break;
      case app_models.UserRole.warehouse:
        rolePrefix = 'warehouse';
        break;
      case app_models.UserRole.finance:
        rolePrefix = 'finance';
        break;
      case app_models.UserRole.shareholder:
        rolePrefix = 'shareholder';
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
  /// ⚠️ IMPORTANT: Employees được tạo vào bảng 'employees', KHÔNG phải 'auth.users'
  Future<Map<String, dynamic>> createEmployeeAccount({
    required String companyId,
    required String companyName,
    required app_models.UserRole role,
    String? customEmail,
    String? fullName,
  }) async {
    try {
      // Verify CEO is logged in (check both demo and real auth)
      app_models.User? currentUser;

      if (_ref != null) {
        // Check demo authentication first
        final user = _ref.read(currentUserProvider);
        currentUser = user;
      }

      // Fallback: if authState has no user, reject
      if (currentUser == null) {
        throw Exception('Please login as CEO first');
      }

      // Verify user is CEO
      if (currentUser.role != app_models.UserRole.ceo) {
        throw Exception('Only CEO can create employee accounts');
      }

      // Generate unique email
      String email = customEmail ??
          generateEmployeeEmail(companyName: companyName, role: role);

      // Ensure email is unique
      if (customEmail == null) {
        int sequence = 1;
        while (await _emailExistsInEmployees(email)) {
          sequence++;
          email = generateEmployeeEmail(
            companyName: companyName,
            role: role,
            sequence: sequence,
          );
        }
      }

      // Check if email already exists in employees table
      if (await _emailExistsInEmployees(email)) {
        throw Exception(
            'Email $email đã được sử dụng. Vui lòng thử email khác.');
      }

      // Generate secure password
      final tempPassword = _generateTempPassword();

      // Generate bcrypt hash for password (will be done server-side via RPC)
      // Call Supabase function to hash password and create employee
      final result = await _supabase.rpc('create_employee_with_password', params: {
        'p_email': email,
        'p_password': tempPassword,
        'p_full_name': fullName ?? _generateDefaultName(role),
        'p_role': role.toUpperString(), // MANAGER, SHIFT_LEADER, STAFF
        'p_company_id': companyId,
        'p_is_active': true,
      }).select();

      if (result.isEmpty) {
        throw Exception('Failed to create employee account');
      }

      final employeeData = result.first;
      final newUserId = employeeData['id'];

      // Return complete user data
      final newUser = app_models.User(
        id: newUserId,
        name: fullName ?? _generateDefaultName(role),
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
      // Fallback: If RPC doesn't exist, create directly with warning
      AppLogger.warn('RPC function not found, creating employee without password hash');
      
      // Generate unique email if needed
      String email = customEmail ??
          generateEmployeeEmail(companyName: companyName, role: role);
      
      if (customEmail == null) {
        int sequence = 1;
        while (await _emailExistsInEmployees(email)) {
          sequence++;
          email = generateEmployeeEmail(
            companyName: companyName,
            role: role,
            sequence: sequence,
          );
        }
      }

      final tempPassword = _generateTempPassword();

      // Hash password before fallback insert
      final hashResult = await _supabase.rpc('hash_password', params: {'p_password': tempPassword});
      final passwordHash = hashResult as String;
      
      // Insert directly into employees table via repository with hashed password
      final response = await _repo.createEmployee({
        'email': email,
        'full_name': fullName ?? _generateDefaultName(role),
        'role': role.toUpperString(),
        'company_id': companyId,
        'is_active': true,
        'password_hash': passwordHash,
      });

      final newUser = app_models.User(
        id: response['id'],
        name: response['full_name'],
        email: response['email'],
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return {
        'success': true,
        'user': newUser,
        'email': email,
        'tempPassword': tempPassword,
        'userId': response['id'],
        'message': 'Employee created. Password needs to be set manually.',
      };
    }
  }

  /// Check if email exists in employees table
  Future<bool> _emailExistsInEmployees(String email) async {
    try {
      final response = await _supabase
          .from('employees')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Generate temporary password (12 chars, cryptographically secure)
  String _generateTempPassword() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate default name based on role
  String _generateDefaultName(app_models.UserRole role) {
    switch (role) {
      case app_models.UserRole.superAdmin:
        return 'Super Admin';
      case app_models.UserRole.manager:
        return 'Quản lý';
      case app_models.UserRole.shiftLeader:
        return 'Trưởng ca';
      case app_models.UserRole.staff:
        return 'Nhân viên';
      case app_models.UserRole.ceo:
        return 'CEO';
      case app_models.UserRole.driver:
        return 'Tài xế';
      case app_models.UserRole.warehouse:
        return 'Nhân viên kho';
      case app_models.UserRole.shareholder:
        return 'Cổ đông';
      case app_models.UserRole.finance:
        return 'Kế toán';
    }
  }

  /// Get ALL employees across all companies (for CEO view)
  /// Returns all active employees from all companies
  Future<List<app_models.User>> getAllEmployees() async {
    try {
      final response = await _repo.getEmployees(isActive: true);

      return response
          .map((json) => app_models.User.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all employees: $e');
    }
  }

  /// Get all employees for a company from employees table only
  /// Note: CEOs are in users table, employees are in employees table
  Future<List<app_models.User>> getCompanyEmployees(String companyId) async {
    try {
      final response = await _repo.getEmployees(
        companyId: companyId,
        isActive: true,
      );

      return response
          .map((json) => app_models.User.fromJson(json))
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
      final updates = <String, dynamic>{};

      if (name != null) updates['full_name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role.toUpperString();
      if (branchId != null) updates['branch_id'] = branchId;

      await _repo.updateEmployee(employeeId, updates);
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  /// Deactivate/Activate employee account
  Future<void> toggleEmployeeStatus(String userId, bool isActive) async {
    try {
      await _repo.toggleEmployeeStatus(userId, isActive);
    } catch (e) {
      throw Exception('Failed to update employee status: $e');
    }
  }

  /// Delete employee account (soft delete)
  /// Sets is_deleted=true via repository to preserve data integrity
  Future<void> deleteEmployee(String userId) async {
    try {
      await _repo.deleteEmployee(userId);
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  /// Resend account credentials
  Future<Map<String, String>> resendCredentials(String userId) async {
    try {
      // Get employee info via repository
      final response = await _repo.getEmployeeById(userId);
      if (response == null) {
        throw Exception('Employee not found');
      }

      final user = app_models.User.fromJson(response);

      // Generate new temporary password
      final newPassword = _generateTempPassword();

      // Save new password via RPC (server-side hashing)
      await _supabase.rpc('change_employee_password', params: {
        'p_employee_id': userId,
        'p_new_password': newPassword,
      });

      return {'email': user.email ?? user.id, 'tempPassword': newPassword};
    } catch (e) {
      throw Exception('Failed to resend credentials: $e');
    }
  }
}
