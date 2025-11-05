import '../core/services/supabase_service.dart';
import '../models/branch.dart';

/// Branch Service
/// Handles all branch-related database operations
class BranchService {
  final _supabase = supabase.client;

  /// Get all branches
  Future<List<Branch>> getAllBranches({String? companyId}) async {
    try {
      var query = _supabase.from('branches').select(
          'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at');

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch branches: $e');
    }
  }

  /// Get active branches only
  Future<List<Branch>> getActiveBranches({String? companyId}) async {
    try {
      var query = _supabase
          .from('branches')
          .select(
              'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at')
          .eq('is_active', true);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active branches: $e');
    }
  }

  /// Get branch by ID
  Future<Branch?> getBranchById(String id) async {
    try {
      final response = await _supabase
          .from('branches')
          .select(
              'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at')
          .eq('id', id)
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new branch
  Future<Branch> createBranch({
    required String companyId,
    required String name,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _supabase
          .from('branches')
          .insert({
            'company_id': companyId,
            'name': name,
            'address': address,
            'phone': phone,
            'email': email,
            'is_active': true,
          })
          .select(
              'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at')
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create branch: $e');
    }
  }

  /// Update branch
  Future<Branch> updateBranch(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('branches')
          .update(updates)
          .eq('id', id)
          .select(
              'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at')
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update branch: $e');
    }
  }

  /// Deactivate branch (soft delete)
  Future<Branch> deactivateBranch(String id) async {
    try {
      final response = await _supabase
          .from('branches')
          .update({'is_active': false})
          .eq('id', id)
          .select(
              'id, company_id, name, address, phone, email, manager_id, is_active, created_at, updated_at')
          .single();

      return Branch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to deactivate branch: $e');
    }
  }

  /// Delete branch (hard delete)
  Future<void> deleteBranch(String id) async {
    try {
      await _supabase.from('branches').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete branch: $e');
    }
  }

  /// Get branch statistics
  Future<Map<String, dynamic>> getBranchStats(String branchId) async {
    try {
      // Get employee count for this branch
      final employeesResponse =
          await _supabase.from('users').select('id').eq('branch_id', branchId);

      // Get table count for this branch
      final tablesResponse =
          await _supabase.from('tables').select('id').eq('branch_id', branchId);

      // Get monthly revenue from daily_revenue
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final revenueResponse = await _supabase
          .from('daily_revenue')
          .select('amount')
          .eq('branch_id', branchId)
          .gte('date', firstDayOfMonth.toIso8601String());

      double monthlyRevenue = 0.0;
      for (var record in revenueResponse) {
        monthlyRevenue += (record['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'employeeCount': (employeesResponse as List).length,
        'tableCount': (tablesResponse as List).length,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      return {
        'employeeCount': 0,
        'tableCount': 0,
        'monthlyRevenue': 0.0,
      };
    }
  }

  /// Subscribe to branch changes
  Stream<List<Branch>> subscribeToBranches({String? companyId}) {
    var query = _supabase
        .from('branches')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return query.map((data) {
      final filtered = companyId != null
          ? data.where((json) => json['company_id'] == companyId).toList()
          : data;
      return filtered.map((json) => Branch.fromJson(json)).toList();
    });
  }
}
