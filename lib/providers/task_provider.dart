import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../services/task_service.dart';

/// Task Service Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

/// All Tasks Provider
final allTasksProvider =
    FutureProvider.family<List<Task>, String?>((ref, branchId) async {
  final service = ref.read(taskServiceProvider);
  return service.getAllTasks(branchId: branchId);
});

/// Tasks by Status Provider
final tasksByStatusProvider =
    FutureProvider.family<List<Task>, ({TaskStatus status, String? branchId})>(
        (ref, params) async {
  final service = ref.read(taskServiceProvider);
  return service.getTasksByStatus(params.status, branchId: params.branchId);
});

/// Tasks by Assignee Provider
final tasksByAssigneeProvider =
    FutureProvider.family<List<Task>, ({String userId, String? branchId})>(
        (ref, params) async {
  final service = ref.read(taskServiceProvider);
  return service.getTasksByAssignee(params.userId, branchId: params.branchId);
});

/// Task Statistics Provider
final taskStatsProvider =
    FutureProvider.family<Map<String, int>, String?>((ref, branchId) async {
  final service = ref.read(taskServiceProvider);
  return service.getTaskStats(branchId: branchId);
});

/// Task Stream Provider
final taskStreamProvider =
    StreamProvider.family<List<Task>, String?>((ref, branchId) {
  final service = ref.read(taskServiceProvider);
  return service.subscribeToTasks(branchId: branchId);
});

/// Selected Task ID Provider
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);
