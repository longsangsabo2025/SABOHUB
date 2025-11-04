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
  Future<void> updateStaff(String staffId, Map<String, dynamic> updates) async {
    print('DummyStaffService.updateStaff called - TODO: implement');
  }

  Future<void> deleteStaff(String staffId) async {
    print('DummyStaffService.deleteStaff called - TODO: implement');
  }

  Future<void> createStaff(Map<String, dynamic> staffData) async {
    print('DummyStaffService.createStaff called - TODO: implement');
  }
}

// Dummy refresh functions
void refreshStaffList(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshStaffList called - TODO: implement');
}

void refreshManagerAssignedTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshManagerAssignedTasks called - TODO: implement');
}

void refreshManagerCreatedTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshManagerCreatedTasks called - TODO: implement');
}

void refreshAllManagementTasks(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshAllManagementTasks called - TODO: implement');
}

void refreshAllManagerData(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshAllManagerData called - TODO: implement');
}

void refreshAllTasksCache(WidgetRef ref, String? branchId) {
  // TODO: Implement proper refresh logic
  print('refreshAllTasksCache called - TODO: implement');
}

void invalidateAllTasksCache(WidgetRef ref, String? branchId) {
  // TODO: Implement proper refresh logic
  print('invalidateAllTasksCache called - TODO: implement');
}

void refreshStores(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshStores called - TODO: implement');
}

void refreshAllStaffData(WidgetRef ref) {
  // TODO: Implement proper refresh logic
  print('refreshAllStaffData called - TODO: implement');
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
