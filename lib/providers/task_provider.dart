import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../utils/app_logger.dart';

/// Task Service Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

/// All Tasks Provider
final allTasksProvider =
    FutureProvider.autoDispose.family<List<Task>, String?>((ref, branchId) async {
  final service = ref.read(taskServiceProvider);
  return service.getAllTasks(branchId: branchId);
});

/// Company Tasks Provider
final companyTasksProvider =
    FutureProvider.autoDispose.family<List<Task>, String>((ref, companyId) async {
  AppLogger.state('companyTasksProvider called with companyId: $companyId');
  final service = ref.read(taskServiceProvider);
  AppLogger.api('Calling service.getTasksByCompany...');
  final tasks = await service.getTasksByCompany(companyId);
  AppLogger.state('Service returned ${tasks.length} tasks');
  return tasks;
});

/// Company Task Stats Provider
final companyTaskStatsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String>((ref, companyId) async {
  final service = ref.read(taskServiceProvider);
  return service.getCompanyTaskStats(companyId);
});

/// Tasks by Status Provider
final tasksByStatusProvider =
    FutureProvider.autoDispose.family<List<Task>, ({TaskStatus status, String? branchId})>(
        (ref, params) async {
  final service = ref.read(taskServiceProvider);
  return service.getTasksByStatus(params.status, branchId: params.branchId);
});

/// Tasks by Assignee Provider
final tasksByAssigneeProvider =
    FutureProvider.autoDispose.family<List<Task>, ({String userId, String? branchId})>(
        (ref, params) async {
  final service = ref.read(taskServiceProvider);
  return service.getTasksByAssignee(params.userId, branchId: params.branchId);
});

/// Task Statistics Provider
final taskStatsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String?>((ref, branchId) async {
  final service = ref.read(taskServiceProvider);
  return service.getTaskStats(branchId: branchId);
});

/// Task Stream Provider
final taskStreamProvider =
    StreamProvider.autoDispose.family<List<Task>, String?>((ref, branchId) {
  final service = ref.read(taskServiceProvider);
  return service.subscribeToTasks(branchId: branchId);
});

/// Selected Task ID Provider
class SelectedTaskIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTaskId(String? taskId) {
    state = taskId;
  }
}

final selectedTaskIdProvider =
    NotifierProvider<SelectedTaskIdNotifier, String?>(
  () => SelectedTaskIdNotifier(),
);
