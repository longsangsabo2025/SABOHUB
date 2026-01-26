import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user.dart' as app_user;

/// Supabase Client Provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Company Employees Provider
/// Fetches all employees for a specific company from employees table only
/// (Custom Auth: Managers, Shift Leaders, Staff)
final companyEmployeesProvider =
    FutureProvider.family<List<app_user.User>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    // Fetch from employees table only (new employee auth system)
    final employeesResponse = await supabase
        .from('employees')
        .select('*')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('created_at', ascending: false) as List;

    // Convert employees to User objects using fromJson 
    final employeesData = employeesResponse
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();

    return employeesData;
  } catch (e) {
    return [];
  }
});

/// Company Employees Stats Provider
/// Returns employee count by role for a specific company from employees table only
final companyEmployeesStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    // Fetch from employees table only
    final employeesResponse = await supabase
        .from('employees')
        .select('role')
        .eq('company_id', companyId)
        .eq('is_active', true) as List;
    
    int managerCount = 0;
    int shiftLeaderCount = 0;
    int staffCount = 0;

    for (var emp in employeesResponse) {
      final role = emp['role'] as String?;
      if (role == 'MANAGER') {
        managerCount++;
      } else if (role == 'SHIFT_LEADER') {
        shiftLeaderCount++;
      } else if (role == 'STAFF') {
        staffCount++;
      }
    }

    return {
      'total': employeesResponse.length,
      'manager': managerCount,
      'shift_leader': shiftLeaderCount,
      'staff': staffCount,
    };
  } catch (e) {
    return {
      'total': 0,
      'manager': 0,
      'shift_leader': 0,
      'staff': 0,
    };
  }
});

/// Active Company Employees Provider
/// Fetches only active employees for a specific company from employees table only
final activeCompanyEmployeesProvider =
    FutureProvider.family<List<app_user.User>, String>((ref, companyId) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    // Fetch from employees table only
    final employeesResponse = await supabase
        .from('employees')
        .select('*')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('created_at', ascending: false) as List;

    final employeesData = employeesResponse
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();

    return employeesData;
  } catch (e) {
    return [];
  }
});

/// Employees by Role Provider
/// Fetches employees filtered by company and role from employees table only
final employeesByRoleProvider = FutureProvider.family<List<app_user.User>,
    ({String companyId, app_user.UserRole role})>((ref, params) async {
  final supabase = ref.watch(supabaseProvider);

  try {
    String roleString;
    switch (params.role) {
      case app_user.UserRole.superAdmin:
        roleString = 'SUPER_ADMIN';
        break;
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
      case app_user.UserRole.driver:
        roleString = 'DRIVER';
        break;
      case app_user.UserRole.warehouse:
        roleString = 'WAREHOUSE';
        break;
    }

    // Fetch from employees table only (skip CEO and Super Admin as they are only in users table)
    if (params.role == app_user.UserRole.ceo || params.role == app_user.UserRole.superAdmin) {
      return []; // No CEOs or Super Admins in employees table
    }
    
    final employeesResponse = await supabase
        .from('employees')
        .select('*')
        .eq('company_id', params.companyId)
        .eq('role', roleString)
        .eq('is_active', true)
        .order('full_name', ascending: true) as List;

    final employeesData = employeesResponse
        .map((json) => app_user.User.fromJson(json as Map<String, dynamic>))
        .toList();

    return employeesData;
  } catch (e) {
    return [];
  }
});

/// Refresh employees helper
void refreshCompanyEmployees(WidgetRef ref, String companyId) {
  ref.invalidate(companyEmployeesProvider(companyId));
  ref.invalidate(companyEmployeesStatsProvider(companyId));
  ref.invalidate(activeCompanyEmployeesProvider(companyId));
}
