import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../services/manager_kpi_service.dart';

/// Manager KPI Service Provider
final managerKPIServiceProvider = Provider<ManagerKPIService>((ref) {
  return ManagerKPIService();
});

/// Cached Manager Dashboard KPIs Provider
final cachedManagerDashboardKPIsProvider = StateNotifierProvider.family<
    CachedStateNotifier<Map<String, dynamic>>,
    AsyncValue<CachedData<Map<String, dynamic>>>,
    String?>((ref, branchId) {
  final service = ref.read(managerKPIServiceProvider);
  final notifier = CachedStateNotifier<Map<String, dynamic>>(
    fetchData: () => service.getDashboardKPIs(branchId: branchId),
    cacheDuration: CacheConfig.short, // 5 min - Real-time KPIs
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Cached Manager Team Members Provider
final cachedManagerTeamMembersProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>,
    String?>((ref, branchId) {
  final service = ref.read(managerKPIServiceProvider);
  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getTeamMembers(branchId: branchId),
    cacheDuration: CacheConfig.medium, // 15 min - Team data changes moderately
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Cached Manager Recent Activities Provider
final cachedManagerRecentActivitiesProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>,
    ({String? branchId, int limit})>((ref, params) {
  final service = ref.read(managerKPIServiceProvider);
  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getRecentActivities(
      branchId: params.branchId,
      limit: params.limit,
    ),
    cacheDuration: CacheConfig.short, // 5 min - Real-time activities
  );
  ref.keepAlive();
  notifier.fetch();
  return notifier;
});

/// Helper: Refresh all manager data
void refreshAllManagerData(WidgetRef ref, {String? branchId}) {
  ref.read(cachedManagerDashboardKPIsProvider(branchId).notifier).fetch();
  ref.read(cachedManagerTeamMembersProvider(branchId).notifier).fetch();
  ref
      .read(
          cachedManagerRecentActivitiesProvider((branchId: branchId, limit: 10))
              .notifier)
      .fetch();
}

/// Helper: Refresh manager dashboard KPIs
void refreshManagerDashboardKPIs(WidgetRef ref, {String? branchId}) {
  ref.read(cachedManagerDashboardKPIsProvider(branchId).notifier).fetch();
}

/// Helper: Refresh manager team members
void refreshManagerTeam(WidgetRef ref, {String? branchId}) {
  ref.read(cachedManagerTeamMembersProvider(branchId).notifier).fetch();
}

/// Helper: Refresh manager activities
void refreshManagerActivities(WidgetRef ref,
    {String? branchId, int limit = 10}) {
  ref
      .read(cachedManagerRecentActivitiesProvider(
          (branchId: branchId, limit: limit)).notifier)
      .fetch();
}
