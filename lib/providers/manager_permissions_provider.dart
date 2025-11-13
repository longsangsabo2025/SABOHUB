import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/manager_permissions.dart';
import '../services/manager_permissions_service.dart';
import 'auth_provider.dart';

/// Manager Permissions Service Provider
final managerPermissionsServiceProvider =
    Provider<ManagerPermissionsService>((ref) {
  return ManagerPermissionsService();
});

/// Manager Permissions Provider
/// Fetches permissions for the current logged-in manager
final managerPermissionsProvider =
    FutureProvider<ManagerPermissions?>((ref) async {
  final authState = ref.watch(authProvider);
  final service = ref.watch(managerPermissionsServiceProvider);

  // Only fetch if user is logged in and is a Manager
  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }

  // Get manager ID from auth state
  final managerId = authState.user!.id;

  try {
    final permissions = await service.getManagerPermissions(managerId);

    // If no permissions found, create default
    if (permissions == null && authState.user!.companyId != null) {
      print('📝 Creating default permissions for manager: $managerId');
      return await service.createDefaultPermissions(
        managerId: managerId,
        companyId: authState.user!.companyId!,
      );
    }

    return permissions;
  } catch (e) {
    print('❌ Error loading manager permissions: $e');
    return null;
  }
});

/// Manager Permissions by Company Provider
/// Useful for CEO viewing specific manager's permissions
final managerPermissionsByCompanyProvider = FutureProvider.family<
    ManagerPermissions?,
    Map<String, String>>((ref, params) async {
  final service = ref.watch(managerPermissionsServiceProvider);
  final managerId = params['managerId']!;
  final companyId = params['companyId']!;

  try {
    return await service.getManagerPermissionsByCompany(managerId, companyId);
  } catch (e) {
    print('❌ Error loading manager permissions: $e');
    return null;
  }
});

/// All Manager Permissions for a Company (CEO View)
final allManagerPermissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, companyId) async {
  print('🏢 [PROVIDER] Fetching all manager permissions for company: $companyId');
  final service = ref.watch(managerPermissionsServiceProvider);

  try {
    final result = await service.getAllManagerPermissions(companyId);
    print('✅ [PROVIDER] Provider returning ${result.length} managers');
    return result;
  } catch (e) {
    print('❌ [PROVIDER] Error loading all manager permissions: $e');
    return [];
  }
});
