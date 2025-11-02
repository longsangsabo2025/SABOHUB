import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../models/management_task.dart';
import 'management_task_provider.dart';

// =============================================================================
// CACHED MANAGEMENT TASK PROVIDERS - Facebook-style State Management
// =============================================================================
// Tasks change frequently (5-minute cache)
// =============================================================================

/// Cached CEO Strategic Tasks Provider (5-minute cache)
///
/// CEO's strategic tasks that are assigned to managers.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(cachedCeoStrategicTasksProvider);
/// ```
final cachedCeoStrategicTasksProvider = StateNotifierProvider<
    CachedStateNotifier<List<ManagementTask>>,
    AsyncValue<CachedData<List<ManagementTask>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<List<ManagementTask>>(
    fetchData: () => service.getCEOStrategicTasks(),
    cacheDuration: CacheConfig.short, // 5 minutes - tasks change frequently
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Manager Assigned Tasks Provider (5-minute cache)
///
/// Tasks assigned TO the current manager from CEO.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(cachedManagerAssignedTasksProvider);
/// ```
final cachedManagerAssignedTasksProvider = StateNotifierProvider<
    CachedStateNotifier<List<ManagementTask>>,
    AsyncValue<CachedData<List<ManagementTask>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<List<ManagementTask>>(
    fetchData: () => service.getTasksAssignedToMe(),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Manager Created Tasks Provider (5-minute cache)
///
/// Tasks created BY the current manager (assigned to staff).
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(cachedManagerCreatedTasksProvider);
/// ```
final cachedManagerCreatedTasksProvider = StateNotifierProvider<
    CachedStateNotifier<List<ManagementTask>>,
    AsyncValue<CachedData<List<ManagementTask>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<List<ManagementTask>>(
    fetchData: () => service.getTasksCreatedByMe(),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Pending Approvals Provider (5-minute cache)
///
/// Approval requests waiting for CEO review.
///
/// Example:
/// ```dart
/// final approvalsAsync = ref.watch(cachedPendingApprovalsProvider);
/// ```
final cachedPendingApprovalsProvider = StateNotifierProvider<
    CachedStateNotifier<List<TaskApproval>>,
    AsyncValue<CachedData<List<TaskApproval>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<List<TaskApproval>>(
    fetchData: () => service.getPendingApprovals(),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Task Statistics Provider (5-minute cache)
///
/// Overall task statistics for dashboards.
///
/// Example:
/// ```dart
/// final statsAsync = ref.watch(cachedTaskStatisticsProvider);
/// ```
final cachedTaskStatisticsProvider = StateNotifierProvider<
    CachedStateNotifier<Map<String, int>>,
    AsyncValue<CachedData<Map<String, int>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<Map<String, int>>(
    fetchData: () => service.getTaskStatistics(),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

/// Cached Company Task Statistics Provider (5-minute cache)
///
/// Task statistics grouped by company.
///
/// Example:
/// ```dart
/// final statsAsync = ref.watch(cachedCompanyTaskStatisticsProvider);
/// ```
final cachedCompanyTaskStatisticsProvider = StateNotifierProvider<
    CachedStateNotifier<List<Map<String, dynamic>>>,
    AsyncValue<CachedData<List<Map<String, dynamic>>>>>((ref) {
  final service = ref.watch(managementTaskServiceProvider);

  final notifier = CachedStateNotifier<List<Map<String, dynamic>>>(
    fetchData: () => service.getCompanyTaskStatistics(),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  ref.keepAlive();
  notifier.fetch();

  return notifier;
});

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Refresh CEO strategic tasks
///
/// Call after creating/updating/deleting tasks.
///
/// Example:
/// ```dart
/// await taskService.createTask(task);
/// refreshCeoStrategicTasks(ref);
/// ```
void refreshCeoStrategicTasks(WidgetRef ref) {
  ref.read(cachedCeoStrategicTasksProvider.notifier).refresh();
  ref.read(cachedTaskStatisticsProvider.notifier).refresh();
  ref.read(cachedCompanyTaskStatisticsProvider.notifier).refresh();
}

/// Refresh manager assigned tasks
void refreshManagerAssignedTasks(WidgetRef ref) {
  ref.read(cachedManagerAssignedTasksProvider.notifier).refresh();
}

/// Refresh manager created tasks
void refreshManagerCreatedTasks(WidgetRef ref) {
  ref.read(cachedManagerCreatedTasksProvider.notifier).refresh();
}

/// Refresh pending approvals
void refreshPendingApprovals(WidgetRef ref) {
  ref.read(cachedPendingApprovalsProvider.notifier).refresh();
}

/// Refresh task statistics
void refreshTaskStatistics(WidgetRef ref) {
  ref.read(cachedTaskStatisticsProvider.notifier).refresh();
  ref.read(cachedCompanyTaskStatisticsProvider.notifier).refresh();
}

/// Refresh all management tasks (use after major changes)
///
/// Example:
/// ```dart
/// await taskService.deleteTask(taskId);
/// refreshAllManagementTasks(ref);
/// ```
void refreshAllManagementTasks(WidgetRef ref) {
  refreshCeoStrategicTasks(ref);
  refreshManagerAssignedTasks(ref);
  refreshManagerCreatedTasks(ref);
  refreshPendingApprovals(ref);
  refreshTaskStatistics(ref);
}
