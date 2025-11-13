import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/company_service.dart';
import '../services/task_service.dart';
import '../models/company.dart';
import '../models/task.dart';
import 'cached_data_providers.dart';

/// Company Actions Provider with automatic cache invalidation
final companyActionsProvider = Provider<CompanyActions>((ref) {
  return CompanyActions(ref);
});

class CompanyActions {
  final Ref ref;
  final CompanyService _service = CompanyService();

  CompanyActions(this.ref);

  /// Create company and invalidate cache
  Future<Company> createCompany({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? businessType,
  }) async {
    final company = await _service.createCompany(
      name: name,
      address: address,
      phone: phone,
      email: email,
      businessType: businessType,
    );

    // Invalidate cache
    ref.invalidate(cachedCompaniesProvider);
    
    return company;
  }

  /// Update company and invalidate cache
  Future<Company> updateCompany(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final company = await _service.updateCompany(id, updates);

    // Invalidate caches
    ref.invalidate(cachedCompaniesProvider);
    ref.invalidate(cachedCompanyProvider(id));
    
    return company;
  }

  /// Delete company (soft delete) and invalidate cache
  Future<void> deleteCompany(String id) async {
    await _service.deleteCompany(id);

    // Invalidate caches
    ref.invalidate(cachedCompaniesProvider);
    ref.invalidate(cachedCompanyProvider(id));
  }

  /// Restore company and invalidate cache
  Future<void> restoreCompany(String id) async {
    await _service.restoreCompany(id);

    // Invalidate caches
    ref.invalidate(cachedCompaniesProvider);
    ref.invalidate(cachedCompanyProvider(id));
  }

  /// Permanently delete company (admin only) and invalidate cache
  Future<void> permanentlyDeleteCompany(String id) async {
    await _service.permanentlyDeleteCompany(id);

    // Invalidate caches
    ref.invalidate(cachedCompaniesProvider);
    ref.invalidate(cachedCompanyProvider(id));
  }
}

/// Task Actions Provider with automatic cache invalidation
final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref);
});

class TaskActions {
  final Ref ref;
  final TaskService _service = TaskService();

  TaskActions(this.ref);

  /// Create task and invalidate cache
  Future<Task> createTask(Task task) async {
    final createdTask = await _service.createTask(task);

    // Invalidate task-related caches
    _invalidateTaskCaches(task.companyId);
    
    return createdTask;
  }

  /// Update task and invalidate cache
  Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    final updatedTask = await _service.updateTask(taskId, updates);

    // Invalidate caches
    _invalidateTaskCaches(updatedTask.companyId);
    
    return updatedTask;
  }

  /// Update task status and invalidate cache
  Future<Task> updateTaskStatus(String taskId, TaskStatus status) async {
    final updatedTask = await _service.updateTaskStatus(taskId, status);

    // Invalidate caches
    _invalidateTaskCaches(updatedTask.companyId);
    
    return updatedTask;
  }

  /// Delete task (soft delete) and invalidate cache
  Future<void> deleteTask(String taskId) async {
    await _service.deleteTask(taskId);

    // Invalidate all task caches (we don't know which company)
    _invalidateTaskCaches(null);
  }

  /// Restore task and invalidate cache
  Future<void> restoreTask(String taskId) async {
    await _service.restoreTask(taskId);

    // Invalidate all task caches
    _invalidateTaskCaches(null);
  }

  /// Permanently delete task (admin only) and invalidate cache
  Future<void> permanentlyDeleteTask(String taskId) async {
    await _service.permanentlyDeleteTask(taskId);

    // Invalidate all task caches
    _invalidateTaskCaches(null);
  }

  /// Helper to invalidate task-related caches
  void _invalidateTaskCaches(String? companyId) {
    // Invalidate cached task providers if they exist
    // Note: Add more providers as needed
    // Example pattern - implement when task cache providers exist
    // ref.invalidate(cachedTasksProvider);
    // if (companyId != null) {
    //   ref.invalidate(cachedCompanyTasksProvider(companyId));
    // }
  }
}
