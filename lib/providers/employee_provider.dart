import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user.dart' as app_user;

/// Supabase Client Provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Company Employees Provider
/// Fetches all employees for a specific company
final companyEmployeesProvider =
    FutureProvider.family<List<app_user.User>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('users')
        .select('*')
        .eq('company_id', companyId)
        .order('created_at', ascending: false) as List;

    return response
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error fetching company employees: $e');
    return [];
  }
});

/// Company Employees Stats Provider
/// Returns employee count by role for a specific company
final companyEmployeesStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    // Fetch all employees for this company
    final response = await supabase
        .from('users')
        .select('role')
        .eq('company_id', companyId) as List;

    final employees = response;
    int managerCount = 0;
    int shiftLeaderCount = 0;
    int staffCount = 0;

    for (var emp in employees) {
      final role = emp['role'] as String?;
      if (role == 'manager') {
        managerCount++;
      } else if (role == 'shift_leader') {
        shiftLeaderCount++;
      } else if (role == 'staff') {
        staffCount++;
      }
    }

    return {
      'total': employees.length,
      'manager': managerCount,
      'shift_leader': shiftLeaderCount,
      'staff': staffCount,
    };
  } catch (e) {
    print('Error fetching employee stats: $e');
    return {
      'total': 0,
      'manager': 0,
      'shift_leader': 0,
      'staff': 0,
    };
  }
});

/// Active Company Employees Provider
/// Fetches only active employees for a specific company
final activeCompanyEmployeesProvider =
    FutureProvider.family<List<app_user.User>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    final response = await supabase
        .from('users')
        .select('*')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('created_at', ascending: false) as List;

    return response
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error fetching active employees: $e');
    return [];
  }
});

/// Employees by Role Provider
/// Fetches employees filtered by company and role
final employeesByRoleProvider = FutureProvider.family<List<app_user.User>,
    ({String companyId, app_user.UserRole role})>((ref, params) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    String roleString;
    switch (params.role) {
      case app_user.UserRole.manager:
        roleString = 'MANAGER';
        break;
      case app_user.UserRole.shiftLeader:
        roleString = 'SHIFT_LEADER';
        break;
      case app_user.UserRole.staff:
        roleString = 'STAFF';
        break;
      case app_user.UserRole.ceo:
        roleString = 'CEO';
        break;
    }

    final response = await supabase
        .from('users')
        .select('*')
        .eq('company_id', params.companyId)
        .eq('role', roleString)
        .order('name', ascending: true) as List;

    return response
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error fetching employees by role: $e');
    return [];
  }
});

/// Refresh employees helper
void refreshCompanyEmployees(WidgetRef ref, String companyId) {
  ref.invalidate(companyEmployeesProvider(companyId));
  ref.invalidate(companyEmployeesStatsProvider(companyId));
  ref.invalidate(activeCompanyEmployeesProvider(companyId));
}
