import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_user.dart';

/// Employee Authentication Service
/// Handles login for non-auth users (MANAGER, SHIFT_LEADER, STAFF)
class EmployeeAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Login employee with company name, username, and password
  Future<EmployeeLoginResult> login({
    required String companyName,
    required String username,
    required String password,
  }) async {
    try {
      // Call employee_login function
      final response = await _supabase.rpc('employee_login', params: {
        'p_company_name': companyName,
        'p_username': username,
        'p_password': password,
      });

      // Parse response
      if (response == null) {
        return EmployeeLoginResult.error('Lỗi kết nối server');
      }

      final data = response as Map<String, dynamic>;
      final success = data['success'] as bool;

      if (!success) {
        final error = data['error'] as String? ?? 'Đăng nhập thất bại';
        return EmployeeLoginResult.error(error);
      }

      // Parse employee data
      final employeeData = data['employee'] as Map<String, dynamic>;
      final employee = EmployeeUser.fromJson(employeeData);

      return EmployeeLoginResult.success(employee);
    } catch (e) {
      return EmployeeLoginResult.error('Lỗi: ${e.toString()}');
    }
  }

  /// Create employee (CEO only)
  /// Creates both employee record and Supabase auth user
  Future<CreateEmployeeResult> createEmployee({
    required String companyId,
    required String username,
    required String password,
    required String fullName,
    required EmployeeRole role,
    String? email,
    String? phone,
    String? branchId,
  }) async {
    try {
      // Call database function to create employee with auth user
      final response = await _supabase.rpc('create_employee_with_auth', params: {
        'p_company_id': companyId,
        'p_username': username,
        'p_password': password,
        'p_full_name': fullName,
        'p_role': role.value,
        'p_email': email,
        'p_phone': phone,
        'p_branch_id': branchId,
      });

      final data = response as Map<String, dynamic>;
      final success = data['success'] as bool;

      if (!success) {
        final error = data['error'] as String? ?? 'Tạo tài khoản thất bại';
        return CreateEmployeeResult.error(error);
      }

      // Parse employee data
      final employeeData = data['employee'] as Map<String, dynamic>;
      final employee = EmployeeUser.fromJson(employeeData);
      
      return CreateEmployeeResult.success(employee);
    } catch (e) {
      if (e.toString().contains('unique_username_per_company')) {
        return CreateEmployeeResult.error(
            'Tên đăng nhập đã tồn tại trong công ty này');
      }
      return CreateEmployeeResult.error('Lỗi tạo tài khoản: ${e.toString()}');
    }
  }

  /// Update employee
  Future<bool> updateEmployee({
    required String employeeId,
    String? fullName,
    String? email,
    String? phone,
    String? branchId,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (branchId != null) updates['branch_id'] = branchId;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) return true;

      await _supabase
          .from('employees')
          .update(updates)
          .eq('id', employeeId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change employee password
  Future<bool> changePassword({
    required String employeeId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Hash new password
      final newPasswordHash = await _hashPassword(newPassword);

      await _supabase
          .from('employees')
          .update({'password_hash': newPasswordHash})
          .eq('id', employeeId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete employee (CEO only)
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _supabase
          .from('employees')
          .delete()
          .eq('id', employeeId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all employees for a company
  Future<List<EmployeeUser>> getCompanyEmployees(String companyId) async {
    try {
      final response = await _supabase
          .from('employees')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmployeeUser.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Hash password using Supabase function
  Future<String> _hashPassword(String password) async {
    try {
      final response = await _supabase.rpc('hash_password', params: {
        'p_password': password,
      });
      return response as String;
    } catch (e) {
      // Fallback: In production, always use server-side hashing
      throw Exception('Password hashing failed');
    }
  }

  /// Check if username is available in company
  Future<bool> isUsernameAvailable({
    required String companyId,
    required String username,
  }) async {
    try {
      final response = await _supabase
          .from('employees')
          .select('id')
          .eq('company_id', companyId)
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return false;
    }
  }
}

/// Employee Login Result
class EmployeeLoginResult {
  final bool success;
  final EmployeeUser? employee;
  final String? error;

  const EmployeeLoginResult._({
    required this.success,
    this.employee,
    this.error,
  });

  factory EmployeeLoginResult.success(EmployeeUser employee) {
    return EmployeeLoginResult._(
      success: true,
      employee: employee,
    );
  }

  factory EmployeeLoginResult.error(String error) {
    return EmployeeLoginResult._(
      success: false,
      error: error,
    );
  }
}

/// Create Employee Result
class CreateEmployeeResult {
  final bool success;
  final EmployeeUser? employee;
  final String? error;

  const CreateEmployeeResult._({
    required this.success,
    this.employee,
    this.error,
  });

  factory CreateEmployeeResult.success(EmployeeUser employee) {
    return CreateEmployeeResult._(
      success: true,
      employee: employee,
    );
  }

  factory CreateEmployeeResult.error(String error) {
    return CreateEmployeeResult._(
      success: false,
      error: error,
    );
  }
}
