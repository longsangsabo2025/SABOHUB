import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/cached_provider.dart';
import '../models/task.dart';
import 'task_provider.dart';

// =============================================================================
// CACHED TASK PROVIDERS - Facebook-style State Management
// =============================================================================
// Tasks update frequently, so we use shorter cache duration (5 minutes)
// =============================================================================

/// Cached All Tasks Provider (5-minute cache)
///
/// Use this instead of `allTasksProvider` for list views.
/// Tasks change frequently, so 5-minute cache is appropriate.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(cachedAllTasksProvider(branchId));
/// ```
final cachedAllTasksProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Task>>,
    AsyncValue<CachedData<List<Task>>>,
    String?>((ref, branchId) {
  final service = ref.watch(taskServiceProvider);

  final notifier = CachedStateNotifier<List<Task>>(
    fetchData: () => service.getAllTasks(branchId: branchId),
    cacheDuration: CacheConfig.short, // 5 minutes - tasks change frequently
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Tasks by Status Provider (5-minute cache)
///
/// Filter tasks by status (todo, in_progress, done, etc.)
/// Maintains separate cache per status + branchId combination.
///
/// Example:
/// ```dart
/// final params = (status: TaskStatus.inProgress, branchId: branchId);
/// final tasksAsync = ref.watch(cachedTasksByStatusProvider(params));
/// ```
final cachedTasksByStatusProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Task>>,
    AsyncValue<CachedData<List<Task>>>,
    ({TaskStatus status, String? branchId})>((ref, params) {
  final service = ref.watch(taskServiceProvider);

  final notifier = CachedStateNotifier<List<Task>>(
    fetchData: () => service.getTasksByStatus(
      params.status,
      branchId: params.branchId,
    ),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Tasks by Assignee Provider (5-minute cache)
///
/// Get tasks assigned to a specific user.
/// Maintains separate cache per userId + branchId combination.
///
/// Example:
/// ```dart
/// final params = (userId: userId, branchId: branchId);
/// final tasksAsync = ref.watch(cachedTasksByAssigneeProvider(params));
/// ```
final cachedTasksByAssigneeProvider = StateNotifierProvider.family<
    CachedStateNotifier<List<Task>>,
    AsyncValue<CachedData<List<Task>>>,
    ({String userId, String? branchId})>((ref, params) {
  final service = ref.watch(taskServiceProvider);

  final notifier = CachedStateNotifier<List<Task>>(
    fetchData: () => service.getTasksByAssignee(
      params.userId,
      branchId: params.branchId,
    ),
    cacheDuration: CacheConfig.short, // 5 minutes
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

/// Cached Task Statistics Provider (5-minute cache)
///
/// Get task statistics (counts by status, completion rate, etc.)
///
/// Example:
/// ```dart
/// final statsAsync = ref.watch(cachedTaskStatsProvider(branchId));
/// ```
final cachedTaskStatsProvider = StateNotifierProvider.family<
    CachedStateNotifier<Map<String, int>>,
    AsyncValue<CachedData<Map<String, int>>>,
    String?>((ref, branchId) {
  final service = ref.watch(taskServiceProvider);

  final notifier = CachedStateNotifier<Map<String, int>>(
    fetchData: () => service.getTaskStats(branchId: branchId),
    cacheDuration: CacheConfig.short, // 5 minutes - stats change frequently
  );

  // Keep alive - prevents disposal on unmount
  ref.keepAlive();

  // Auto-fetch on creation
  notifier.fetch();

  return notifier;
});

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Refresh all tasks for a branch
///
/// Call this after creating/updating/deleting tasks.
///
/// Example:
/// ```dart
/// await taskService.createTask(newTask);
/// refreshAllTasks(ref, branchId);
/// ```
void refreshAllTasks(WidgetRef ref, String? branchId) {
  ref.read(cachedAllTasksProvider(branchId).notifier).refresh();
  ref.read(cachedTaskStatsProvider(branchId).notifier).refresh();
}

/// Refresh tasks by status
///
/// Call this after status changes.
///
/// Example:
/// ```dart
/// await taskService.updateTaskStatus(taskId, TaskStatus.done);
/// refreshTasksByStatus(ref, TaskStatus.done, branchId);
/// ```
void refreshTasksByStatus(
  WidgetRef ref,
  TaskStatus status,
  String? branchId,
) {
  final params = (status: status, branchId: branchId);
  ref.read(cachedTasksByStatusProvider(params).notifier).refresh();

  // Also refresh all tasks and stats
  refreshAllTasks(ref, branchId);
}

/// Refresh tasks for a specific assignee
///
/// Example:
/// ```dart
/// await taskService.assignTask(taskId, userId);
/// refreshTasksByAssignee(ref, userId, branchId);
/// ```
void refreshTasksByAssignee(
  WidgetRef ref,
  String userId,
  String? branchId,
) {
  final params = (userId: userId, branchId: branchId);
  ref.read(cachedTasksByAssigneeProvider(params).notifier).refresh();

  // Also refresh all tasks and stats
  refreshAllTasks(ref, branchId);
}

/// Force invalidate all task caches
///
/// Use sparingly - prefer refresh() which keeps old data while loading.
///
/// Example:
/// ```dart
/// invalidateAllTasks(ref, branchId);
/// ```
void invalidateAllTasks(WidgetRef ref, String? branchId) {
  ref.read(cachedAllTasksProvider(branchId).notifier).invalidate();
  ref.read(cachedTaskStatsProvider(branchId).notifier).invalidate();
}
