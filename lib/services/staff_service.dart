import '../core/services/supabase_service.dart';
import '../models/staff.dart';

/// Staff Service
/// Handles all staff/employee-related database operations
class StaffService {
  final _supabase = supabase.client;

  /// Get all staff members
  Future<List<Staff>> getAllStaff({String? branchId}) async {
    try {
      var query = _supabase.from('users').select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
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
      final response =
          await _supabase.from('users').select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at').eq('id', id).single();

      return Staff.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get staff by role
  Future<List<Staff>> getStaffByRole(String role, {String? branchId}) async {
    try {
      var query = _supabase.from('users').select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at').eq('role', role);

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
      final response = await _supabase
          .from('users')
          .insert({
            'full_name': name,
            'name': name,
            'email': email,
            'role': role,
            'phone': phone,
            'branch_id': branchId,
            'status': 'active',
          })
          .select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
          .single();

      return Staff.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  /// Update staff member
  Future<Staff> updateStaff(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', id)
          .select('id, full_name, email, role, phone, avatar_url, branch_id, company_id, is_active, created_at, updated_at')
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
      var query = _supabase.from('users').select('role, status');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query;
      final staffList = response as List;

      // Count by role
      final totalStaff = staffList.length;
      final managers = staffList.where((s) => s['role'] == 'manager').length;
      final shiftLeaders =
          staffList.where((s) => s['role'] == 'shift_leader').length;
      final staff = staffList.where((s) => s['role'] == 'staff').length;

      // Count by status
      final activeStaff =
          staffList.where((s) => s['status'] == 'active').length;
      final inactiveStaff =
          staffList.where((s) => s['status'] == 'inactive').length;
      final onLeave = staffList.where((s) => s['status'] == 'on_leave').length;

      return {
        'totalStaff': totalStaff,
        'managers': managers,
        'shiftLeaders': shiftLeaders,
        'staff': staff,
        'activeStaff': activeStaff,
        'inactiveStaff': inactiveStaff,
        'onLeave': onLeave,
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
    var stream = _supabase
        .from('users')
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
