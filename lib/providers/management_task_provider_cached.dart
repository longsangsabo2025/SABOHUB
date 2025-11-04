// MINIMAL IMPLEMENTATIONS FOR RIVERPOD 3.x MIGRATION// TEMPORARILY DISABLED FOR RIVERPOD 3.x MIGRATION

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy cached providers to prevent import errors
final cachedManagerAssignedTasksProvider = FutureProvider((ref) async => []);
final cachedManagerCreatedTasksProvider = FutureProvider((ref) async => []);
final cachedTaskStatisticsProvider =
    FutureProvider((ref) async => <String, int>{});
final cachedCeoStrategicTasksProvider = FutureProvider((ref) async => []);
final cachedPendingApprovalsProvider = FutureProvider((ref) async => []);
final cachedCompanyTaskStatisticsProvider =
    FutureProvider((ref) async => <String, dynamic>{});
final cachedManagerTeamMembersProvider = FutureProvider((ref) async => []);

// Dummy refresh functions
void refreshManagerAssignedTasks(WidgetRef ref) {
  ref.invalidate(cachedManagerAssignedTasksProvider);
}

void refreshManagerCreatedTasks(WidgetRef ref) {
  ref.invalidate(cachedManagerCreatedTasksProvider);
}

void refreshAllManagementTasks(WidgetRef ref) {
  ref.invalidate(cachedManagerAssignedTasksProvider);
  ref.invalidate(cachedManagerCreatedTasksProvider);
}
