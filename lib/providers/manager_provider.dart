import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/manager_kpi_service.dart';
import 'auth_provider.dart';

/// Manager KPI Service Provider
final managerKPIServiceProvider = Provider<ManagerKPIService>((ref) {
  return ManagerKPIService();
});

/// Manager Dashboard KPIs Provider
/// Automatically gets employeeId and companyId from authProvider
final managerDashboardKPIsProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, branchId) async {
  final service = ref.read(managerKPIServiceProvider);
  final currentUser = ref.read(authProvider).user;
  
  if (currentUser == null) {
    throw Exception('No user logged in');
  }
  
  return service.getDashboardKPIs(
    employeeId: currentUser.id,
    companyId: currentUser.companyId!,
    branchId: branchId,
  );
});

/// Manager Team Members Provider
/// Automatically gets employeeId and companyId from authProvider
final managerTeamMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, branchId) async {
  final service = ref.read(managerKPIServiceProvider);
  final currentUser = ref.read(authProvider).user;
  
  if (currentUser == null) {
    throw Exception('No user logged in');
  }
  
  return service.getTeamMembers(
    employeeId: currentUser.id,
    companyId: currentUser.companyId!,
    branchId: branchId,
  );
});

/// Manager Recent Activities Provider
/// Automatically gets employeeId and companyId from authProvider
final managerRecentActivitiesProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({String? branchId, int limit})>((ref, params) async {
  final service = ref.read(managerKPIServiceProvider);
  final currentUser = ref.read(authProvider).user;
  
  if (currentUser == null) {
    throw Exception('No user logged in');
  }
  
  return service.getRecentActivities(
    employeeId: currentUser.id,
    companyId: currentUser.companyId!,
    branchId: params.branchId,
    limit: params.limit,
  );
});
