import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/manager_permissions.dart';

/// Manager Permissions Service
/// Handles fetching and managing permissions for Managers
class ManagerPermissionsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get permissions for a specific manager
  /// Returns null if no permissions found (should create default)
  Future<ManagerPermissions?> getManagerPermissions(String managerId) async {
    try {
      final response = await _supabase
          .from('manager_permissions')
          .select('*')
          .eq('manager_id', managerId)
          .maybeSingle();

      if (response == null) {
        print('⚠️ No permissions found for manager: $managerId');
        return null;
      }

      return ManagerPermissions.fromJson(response);
    } catch (e) {
      print('❌ Error fetching manager permissions: $e');
      rethrow;
    }
  }

  /// Get permissions by manager ID and company ID
  Future<ManagerPermissions?> getManagerPermissionsByCompany(
    String managerId,
    String companyId,
  ) async {
    try {
      final response = await _supabase
          .from('manager_permissions')
          .select('*')
          .eq('manager_id', managerId)
          .eq('company_id', companyId)
          .maybeSingle();

      if (response == null) {
        print(
            '⚠️ No permissions found for manager $managerId in company $companyId');
        return null;
      }

      return ManagerPermissions.fromJson(response);
    } catch (e) {
      print('❌ Error fetching manager permissions: $e');
      rethrow;
    }
  }

  /// Create default permissions for a new manager
  /// Called when permissions don't exist yet
  Future<ManagerPermissions> createDefaultPermissions({
    required String managerId,
    required String companyId,
    String? grantedBy,
  }) async {
    try {
      final data = {
        'manager_id': managerId,
        'company_id': companyId,
        'can_view_overview': true,
        'can_view_employees': true,
        'can_view_tasks': true,
        'can_view_attendance': true,
        'can_create_task': true,
        'can_edit_task': true,
        'can_approve_attendance': true,
        'granted_by': grantedBy,
        'notes': 'Default permissions created automatically',
      };

      final response =
          await _supabase.from('manager_permissions').insert(data).select().single();

      return ManagerPermissions.fromJson(response);
    } catch (e) {
      print('❌ Error creating default permissions: $e');
      rethrow;
    }
  }

  /// Update manager permissions (CEO only)
  Future<ManagerPermissions> updatePermissions({
    required String permissionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _supabase
          .from('manager_permissions')
          .update(updates)
          .eq('id', permissionId)
          .select()
          .single();

      return ManagerPermissions.fromJson(response);
    } catch (e) {
      print('❌ Error updating permissions: $e');
      rethrow;
    }
  }

  /// Get all managers with their permissions for a company (CEO view)
  Future<List<Map<String, dynamic>>> getAllManagerPermissions(
      String companyId) async {
    try {
      print('🔍 [PERMISSIONS] Fetching permissions for company: $companyId');
      
      // First, get all permissions for the company
      final permissions = await _supabase
          .from('manager_permissions')
          .select('*')
          .eq('company_id', companyId)
          .order('granted_at', ascending: false);

      print('📊 [PERMISSIONS] Found ${(permissions as List).length} permission records');
      
      if ((permissions as List).isEmpty) {
        print('⚠️ [PERMISSIONS] No permissions found for company');
        return [];
      }

      // Get all unique manager IDs
      final managerIds = (permissions as List)
          .map((p) => p['manager_id'] as String)
          .toSet()
          .toList();

      print('👥 [PERMISSIONS] Manager IDs: $managerIds');

      // Fetch all employee names in one query using 'in' filter
      final employees = await _supabase
          .from('employees')
          .select('id, full_name')
          .filter('id', 'in', '(${managerIds.join(',')})');

      print('📝 [PERMISSIONS] Found ${(employees as List).length} employees');
      print('📝 [PERMISSIONS] Employee data: $employees');

      // Create a map of manager_id -> name for quick lookup
      final Map<String, String> managerNames = {};
      for (var emp in (employees as List)) {
        managerNames[emp['id'] as String] = emp['full_name'] as String;
      }

      print('🗺️ [PERMISSIONS] Manager names map: $managerNames');

      // Combine permissions with names
      final result = permissions.map<Map<String, dynamic>>((perm) {
        final result = Map<String, dynamic>.from(perm);
        result['manager_id'] = perm['manager_id'];
        result['manager_name'] = managerNames[perm['manager_id']] ?? 'Unknown';
        return result;
      }).toList();
      
      print('✅ [PERMISSIONS] Returning ${result.length} manager permissions');
      return result;
    } catch (e) {
      print('❌ Error fetching all manager permissions: $e');
      rethrow;
    }
  }

  /// Check if manager has specific permission
  Future<bool> hasPermission(String managerId, String permissionKey) async {
    try {
      final permissions = await getManagerPermissions(managerId);
      if (permissions == null) return false;

      // Map permission key to actual field
      switch (permissionKey) {
        case 'view_overview':
          return permissions.canViewOverview;
        case 'view_employees':
          return permissions.canViewEmployees;
        case 'view_tasks':
          return permissions.canViewTasks;
        case 'view_documents':
          return permissions.canViewDocuments;
        case 'view_ai_assistant':
          return permissions.canViewAiAssistant;
        case 'view_attendance':
          return permissions.canViewAttendance;
        case 'view_accounting':
          return permissions.canViewAccounting;
        case 'view_employee_docs':
          return permissions.canViewEmployeeDocs;
        case 'view_business_law':
          return permissions.canViewBusinessLaw;
        case 'view_settings':
          return permissions.canViewSettings;
        case 'create_employee':
          return permissions.canCreateEmployee;
        case 'edit_employee':
          return permissions.canEditEmployee;
        case 'delete_employee':
          return permissions.canDeleteEmployee;
        case 'create_task':
          return permissions.canCreateTask;
        case 'edit_task':
          return permissions.canEditTask;
        case 'delete_task':
          return permissions.canDeleteTask;
        case 'approve_attendance':
          return permissions.canApproveAttendance;
        case 'edit_company_info':
          return permissions.canEditCompanyInfo;
        default:
          return false;
      }
    } catch (e) {
      print('❌ Error checking permission: $e');
      return false;
    }
  }
}
