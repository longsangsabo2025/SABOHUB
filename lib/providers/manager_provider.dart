import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/manager_kpi_service.dart';

/// Manager KPI Service Provider
final managerKPIServiceProvider = Provider<ManagerKPIService>((ref) {
  return ManagerKPIService();
});

/// Manager Dashboard KPIs Provider
final managerDashboardKPIsProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, branchId) async {
  final service = ref.read(managerKPIServiceProvider);
  return service.getDashboardKPIs(branchId: branchId);
});

/// Manager Team Members Provider
final managerTeamMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, branchId) async {
  final service = ref.read(managerKPIServiceProvider);
  return service.getTeamMembers(branchId: branchId);
});

/// Manager Recent Activities Provider
final managerRecentActivitiesProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({String? branchId, int limit})>((ref, params) async {
  final service = ref.read(managerKPIServiceProvider);
  return service.getRecentActivities(
      branchId: params.branchId, limit: params.limit);
});
