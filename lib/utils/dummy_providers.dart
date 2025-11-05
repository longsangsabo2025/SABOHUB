// TEMPORARY DUMMY FUNCTIONS FOR RIVERPOD 3.x MIGRATION
// These are placeholder functions to prevent compile errors
// Will be properly implemented later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';

// Dummy CachedData class
class CachedData<T> {
  final T data;
  const CachedData(this.data);
}

// Dummy service classes
class DummyStaffService {
  Future<void> updateStaff(
      String staffId, Map<String, dynamic> updates) async {}

  Future<void> deleteStaff(String staffId) async {}

  Future<void> createStaff(Map<String, dynamic> staffData) async {}
}

// Dummy refresh functions
void refreshStaffList(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshManagerAssignedTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshManagerCreatedTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshAllManagementTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshAllManagerData(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshAllTasksCache(WidgetRef ref, String? branchId) {
  // TODO: Implement proper refresh logic
}

void invalidateAllTasksCache(WidgetRef ref, String? branchId) {
  // TODO: Implement proper refresh logic
}

void refreshStores(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

void refreshAllStaffData(WidgetRef ref) {
  // TODO: Implement proper refresh logic
}

// Dummy providers - return empty data
final cachedManagerAssignedTasksProvider = FutureProvider((ref) async => []);
final cachedManagerCreatedTasksProvider = FutureProvider((ref) async => []);
final cachedTaskStatisticsProvider =
    FutureProvider((ref) async => <String, int>{});
final cachedCeoStrategicTasksProvider = FutureProvider((ref) async => []);
final cachedPendingApprovalsProvider = FutureProvider((ref) async => []);
final cachedCompanyTaskStatisticsProvider =
    FutureProvider((ref) async => <String, dynamic>{});
final cachedManagerTeamMembersProvider = FutureProvider((ref) async => []);
final cachedManagerDashboardKPIsProvider =
    FutureProvider((ref) async => <String, dynamic>{});
final cachedStaffStatsProvider = FutureProvider((ref) async => <String, int>{});
final cachedManagerRecentActivitiesProvider = FutureProvider((ref) async => []);
final cachedAllStaffProvider = FutureProvider((ref) async => []);
final cachedStaffListProvider = FutureProvider((ref) async => []);
final simpleAllTasksProvider = FutureProvider((ref) async => []);
final simpleTaskStatsProvider = FutureProvider((ref) async => <String, int>{});

// Store providers
final cachedStoresProvider =
    FutureProvider((ref) async => CachedData<List<Store>>([]));

// Service providers
final staffServiceProvider = Provider((ref) => DummyStaffService());
