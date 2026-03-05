import '../../models/task.dart';

/// Abstract interface cho TaskService.
///
/// Cho phép:
/// - Mock trong unit tests
/// - Swap implementation (e.g. offline-first) mà không sửa code dùng
/// - Enforce contract rõ ràng
///
/// Tất cả code mới nên depend on [ITaskService] thay vì [TaskService].
abstract class ITaskService {
  /// Get all tasks, optionally filtered by branch/company.
  Future<List<Task>> getAllTasks({String? branchId, String? companyId});

  /// Get tasks filtered by status.
  Future<List<Task>> getTasksByStatus(
    TaskStatus status, {
    String? branchId,
    String? companyId,
  });

  /// Get tasks assigned to a specific user.
  Future<List<Task>> getTasksByAssignee(
    String userId, {
    String? branchId,
    String? companyId,
  });

  /// Get all tasks for a company.
  Future<List<Task>> getTasksByCompany(String companyId);

  /// Create a new task.
  Future<Task> createTask(Task task);

  /// Update task fields.
  Future<Task> updateTask(String taskId, Map<String, dynamic> updates);

  /// Update only the task status.
  Future<Task> updateTaskStatus(String taskId, TaskStatus status);

  /// Soft delete a task.
  Future<void> deleteTask(String taskId);

  /// Restore a soft-deleted task.
  Future<void> restoreTask(String taskId);

  /// Get task statistics (total, todo, inProgress, completed, overdue).
  Future<Map<String, int>> getTaskStats({String? branchId});

  /// Get task statistics for a specific company.
  Future<Map<String, int>> getCompanyTaskStats(String companyId);

  /// Real-time stream of tasks.
  Stream<List<Task>> subscribeToTasks({String? branchId});
}
