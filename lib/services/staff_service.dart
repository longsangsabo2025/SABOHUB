import '../core/services/supabase_service.dart';
import '../models/staff.dart';

/// Staff Service
/// Handles all staff/employee-related database operations
class StaffService {
  final _supabase = supabase.client;

  /// Get all staff members
  Future<List<Staff>> getAllStaff({String? branchId, String? companyId}) async {
    try {
      // Query from employees table (not users)
      var query = _supabase.from('employees').select(
          'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  /// Get staff by ID
  Future<Staff?> getStaffById(String id) async {
    try {
      // Query from employees table (not users)
      final response = await _supabase
          .from('employees')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .eq('id', id)
          .single();

      return Staff.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get staff by role
  Future<List<Staff>> getStaffByRole(String role, {String? branchId}) async {
    try {
      // Query from employees table (not users)
      var query = _supabase
          .from('employees')
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .eq('role', role);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('created_at', ascending: false);

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
  }) async {
    try {
      // Create staff in employees table (not users)
      final response = await _supabase
          .from('employees')
          .insert({
            'full_name': name,
            'email': email,
            'role': role,
            'phone': phone,
            'branch_id': branchId,
            'is_active': true,
          })
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .single();

      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  /// Update staff member
  Future<Staff> updateStaff(String id, Map<String, dynamic> updates) async {
    try {
      // Update in employees table (not users)
      final response = await _supabase
          .from('employees')
          .update(updates)
          .eq('id', id)
          .select(
              'id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .single();

      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  /// Delete staff member (soft delete by setting status to inactive)
  Future<void> deleteStaff(String id) async {
    try {
      await _supabase.from('users').update({'status': 'inactive'}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }

  /// Get staff statistics by branch
  Future<Map<String, dynamic>> getStaffStats({String? branchId}) async {
    try {
      // Query from employees table (not users)
      var query = _supabase.from('employees').select('role, is_active');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query;
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
    // Subscribe to employees table (not users)
    var stream = _supabase
        .from('employees')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return stream.map((data) {
      var filtered = data;
      if (branchId != null) {
        filtered = data.where((item) => item['branch_id'] == branchId).toList();
      }
      return filtered.map((json) => Staff.fromJson(json)).toList();
    });
  }
}
