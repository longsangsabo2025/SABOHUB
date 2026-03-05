import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/manager_permissions.dart';
import '../services/manager_permissions_service.dart';
import '../utils/app_logger.dart';
import 'auth_provider.dart';

/// Manager Permissions Service Provider
final managerPermissionsServiceProvider =
    Provider<ManagerPermissionsService>((ref) {
  return ManagerPermissionsService();
});

/// Manager Permissions Provider
/// Fetches permissions for the current logged-in manager
final managerPermissionsProvider =
    FutureProvider.autoDispose<ManagerPermissions?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(managerPermissionsServiceProvider);

  // Only fetch if user is logged in and is a Manager
  if (user == null) {
    return null;
  }

  // Get manager ID from auth state
  final managerId = user.id;

  try {
    final permissions = await service.getManagerPermissions(managerId);

    // If no permissions found, create default
    if (permissions == null && user.companyId != null) {
      AppLogger.info('Creating default permissions for manager: $managerId');
      return await service.createDefaultPermissions(
        managerId: managerId,
        companyId: user.companyId!,
      );
    }

    return permissions;
  } catch (e) {
    AppLogger.error('Error loading manager permissions', e);
    return null;
  }
});

/// Manager Permissions by Company Provider
/// Useful for CEO viewing specific manager's permissions
final managerPermissionsByCompanyProvider = FutureProvider.autoDispose.family<
    ManagerPermissions?,
    Map<String, String>>((ref, params) async {
  final service = ref.watch(managerPermissionsServiceProvider);
  final managerId = params['managerId']!;
  final companyId = params['companyId']!;

  try {
    return await service.getManagerPermissionsByCompany(managerId, companyId);
  } catch (e) {
    AppLogger.error('Error loading manager permissions', e);
    return null;
  }
});

/// All Manager Permissions for a Company (CEO View)
final allManagerPermissionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, companyId) async {
  AppLogger.state('Fetching all manager permissions for company: $companyId');
  final service = ref.watch(managerPermissionsServiceProvider);

  try {
    final result = await service.getAllManagerPermissions(companyId);
    AppLogger.state('Provider returning ${result.length} managers');
    return result;
  } catch (e) {
    AppLogger.error('Error loading all manager permissions', e);
    return [];
  }
});
