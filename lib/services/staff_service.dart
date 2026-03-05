import '../core/repositories/impl/employee_repository.dart';
import '../core/services/supabase_service.dart';
import '../models/staff.dart';

/// Staff Service
/// Handles all staff/employee-related database operations
class StaffService {
  final _supabase = supabase.client;
  final EmployeeRepository _repo = EmployeeRepository();

  /// Get all staff members
  Future<List<Staff>> getAllStaff({String? branchId, String? companyId}) async {
    try {
      final response = await _repo.getEmployees(
        companyId: companyId,
        limit: 200,
      );

      var filtered = response;
      if (branchId != null) {
        filtered = filtered
            .where((row) => row['branch_id'] == branchId)
            .toList();
      }

      return filtered.map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  /// Get staff by ID
  Future<Staff?> getStaffById(String id) async {
    try {
      final response = await _repo.getEmployeeById(id);
      if (response == null) return null;
      return Staff.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get staff by role
  Future<List<Staff>> getStaffByRole(String role, {String? branchId, String? companyId}) async {
    try {
      // Query from employees table (not users)
      var query = _supabase
          .from('employees')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .eq('role', role);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('created_at', ascending: false).limit(200);

      return (response as List).map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff by role: $e');
    }
  }

  /// Create new staff member
  Future<Staff> createStaff({
    required String name,
    required String email,
    required String role,
    String? phone,
    String? branchId,
    String? companyId,
  }) async {
    try {
      final response = await _repo.createEmployee({
        'full_name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'branch_id': branchId,
        if (companyId != null) 'company_id': companyId,
        'is_active': true,
      });

      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  /// Update staff member
  Future<Staff> updateStaff(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _repo.updateEmployee(id, updates);
      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  /// Delete staff member (soft delete via repository)
  Future<void> deleteStaff(String id) async {
    try {
      await _repo.deleteEmployee(id);
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }

  /// Get staff statistics by branch/company
  Future<Map<String, dynamic>> getStaffStats({String? branchId, String? companyId}) async {
    try {
      // Query from employees table (not users)
      var query = _supabase.from('employees').select('role, is_active');

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.limit(500);
      final staffList = response as List;

      // Count by role
      final totalStaff = staffList.length;
      final managers = staffList.where((s) => s['role'] == 'MANAGER').length;
      final shiftLeaders =
          staffList.where((s) => s['role'] == 'SHIFT_LEADER').length;
      final staff = staffList.where((s) => s['role'] == 'STAFF').length;

      // Count by status (is_active)
      final activeStaff =
          staffList.where((s) => s['is_active'] == true).length;
      final inactiveStaff =
          staffList.where((s) => s['is_active'] == false).length;

      return {
        'totalStaff': totalStaff,
        'managers': managers,
        'shiftLeaders': shiftLeaders,
        'staff': staff,
        'activeStaff': activeStaff,
        'inactiveStaff': inactiveStaff,
        'onLeave': 0, // employees table không có on_leave status
      };
    } catch (e) {
      return {
        'totalStaff': 0,
        'managers': 0,
        'shiftLeaders': 0,
        'staff': 0,
        'activeStaff': 0,
        'inactiveStaff': 0,
        'onLeave': 0,
      };
    }
  }

  /// Subscribe to staff changes
  Stream<List<Staff>> subscribeToStaff({String? branchId}) {
    final stream = _repo.subscribeToEmployees();

    return stream.map((data) {
      var filtered = data;
      if (branchId != null) {
        filtered = data.where((item) => item['branch_id'] == branchId).toList();
      }
      return filtered.map((json) => Staff.fromJson(json)).toList();
    });
  }
}
