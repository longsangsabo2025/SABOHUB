import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/management_task.dart';
import '../services/management_task_service.dart';

/// Management Task Service Provider
final managementTaskServiceProvider = Provider<ManagementTaskService>((ref) {
  return ManagementTaskService(ref);
});

/// CEO Strategic Tasks Provider
/// Fetches all tasks created by CEO
final ceoStrategicTasksProvider =
    FutureProvider<List<ManagementTask>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getCEOStrategicTasks();
});

/// Manager Assigned Tasks Provider
/// Fetches tasks assigned to current manager from CEO
final managerAssignedTasksProvider =
    FutureProvider<List<ManagementTask>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getTasksAssignedToMe();
});

/// Manager Created Tasks Provider
/// Fetches tasks created by current manager (assigned to staff)
final managerCreatedTasksProvider =
    FutureProvider<List<ManagementTask>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getTasksCreatedByMe();
});

/// Pending Approvals Provider
/// Fetches approval requests waiting for CEO review
final pendingApprovalsProvider =
    FutureProvider<List<TaskApproval>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getPendingApprovals();
});

/// Task Statistics Provider
/// Fetches task statistics for CEO dashboard
final taskStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getTaskStatistics();
});

/// Company Task Statistics Provider
/// Fetches task statistics grouped by company
final companyTaskStatisticsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getCompanyTaskStatistics();
});

/// Task Refresh Notifier
/// Used to manually refresh task lists after create/update/delete operations
final taskRefreshProvider =
    NotifierProvider<_TaskRefreshNotifier, int>(() => _TaskRefreshNotifier());

class _TaskRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() {
    state = state + 1;
  }
}

/// Helper function to refresh all task providers
void refreshAllTasks(WidgetRef ref) {
  ref.invalidate(ceoStrategicTasksProvider);
  ref.invalidate(managerAssignedTasksProvider);
  ref.invalidate(managerCreatedTasksProvider);
  ref.invalidate(pendingApprovalsProvider);
  ref.invalidate(taskStatisticsProvider);
  ref.invalidate(companyTaskStatisticsProvider);
}

// ============================================================================
// REALTIME STREAM PROVIDERS (Auto-update without refresh)
// ============================================================================

/// CEO Strategic Tasks Stream Provider (REALTIME)
/// Auto-updates when tasks are created/modified/deleted
final ceoStrategicTasksStreamProvider =
    StreamProvider<List<ManagementTask>>((ref) {
  final service = ref.read(managementTaskServiceProvider);
  return service.streamCEOStrategicTasks();
});

/// Manager Assigned Tasks Stream Provider (REALTIME)
/// Auto-updates when tasks assigned to current manager change
final managerAssignedTasksStreamProvider =
    StreamProvider<List<ManagementTask>>((ref) {
  final service = ref.read(managementTaskServiceProvider);
  return service.streamTasksAssignedToMe();
});

/// Manager Created Tasks Stream Provider (REALTIME)
/// Auto-updates when tasks created by current manager change
final managerCreatedTasksStreamProvider =
    StreamProvider<List<ManagementTask>>((ref) {
  final service = ref.read(managementTaskServiceProvider);
  return service.streamTasksCreatedByMe();
});
