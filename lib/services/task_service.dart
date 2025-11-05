import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
// import 'notification_service.dart'; // Commented out for now

/// Task Service
/// Handles all task-related database operations
class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // final _notificationService = NotificationService(); // Commented out for now

  /// Get all tasks
  Future<List<Task>> getAllTasks({String? branchId}) async {
    try {
      final query = _supabase.from('tasks').select('*');

      if (branchId != null) {
        query.eq('branch_id', branchId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) => _taskFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status,
      {String? branchId}) async {
    try {
      final query = _supabase
          .from('tasks')
          .select('*')
          .eq('status', status.name);

      if (branchId != null) {
        query.eq('branch_id', branchId);
      }

      final response = await query.order('due_date', ascending: true);

      return (response as List).map((json) => _taskFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  /// Get tasks assigned to a user
  Future<List<Task>> getTasksByAssignee(String userId,
      {String? branchId}) async {
    try {
      final query = _supabase
          .from('tasks')
          .select('*')
          .eq('assigned_to', userId);

      if (branchId != null) {
        query.eq('branch_id', branchId);
      }

      final response = await query.order('due_date', ascending: true);

      return (response as List).map((json) => _taskFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by assignee: $e');
    }
  }

  /// Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert({
            'branch_id': task.branchId,
            'company_id': task.companyId,
            'title': task.title,
            'description': task.description,
            'category': task.category.name,
            'priority': task.priority.name,
            'status': task.status.toDbValue(),
            'recurrence': task.recurrence.name,
            'assigned_to': task.assignedTo,
            'assigned_to_name': task.assignedToName,
            'due_date': task.dueDate.toIso8601String(),
            'created_by': task.createdBy,
            'created_by_name': task.createdByName,
            'notes': task.notes,
          })
          .select('*')
          .single();

      final createdTask = _taskFromJson(response);

      // Send notification to assigned user (commented out for now)
      // if (task.assignedTo != null) {
      //   await _notificationService.sendTaskAssignedNotification(
      //     userId: task.assignedTo!,
      //     taskTitle: task.title,
      //     dueDate: task.dueDate,
      //     createdByName: task.createdByName,
      //   );
      // }

      return createdTask;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update a task
  Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select('*')
          .single();

      return _taskFromJson(response);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Update task status
  Future<Task> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toDbValue(),
      };

      if (status == TaskStatus.completed) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select('*')
          .single();

      return _taskFromJson(response);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStats({String? branchId}) async {
    try {
      final query = _supabase.from('tasks').select('*');

      if (branchId != null) {
        query.eq('branch_id', branchId);
      }

      final response = await query;
      final tasks =
          (response as List).map((json) => _taskFromJson(json)).toList();

      return {
        'total': tasks.length,
        'todo': tasks.where((t) => t.status == TaskStatus.todo).length,
        'inProgress':
            tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed':
            tasks.where((t) => t.status == TaskStatus.completed).length,
        'overdue': tasks.where((t) => t.isOverdue).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch task stats: $e');
    }
  }

  /// Get all tasks for a company
  Future<List<Task>> getTasksByCompany(String companyId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => _taskFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by company: $e');
    }
  }

  /// Get task statistics for a company
  Future<Map<String, int>> getCompanyTaskStats(String companyId) async {
    try {
      final response =
          await _supabase.from('tasks').select('*').eq('company_id', companyId);

      final tasks =
          (response as List).map((json) => _taskFromJson(json)).toList();

      final stats = {
        'total': tasks.length,
        'todo': tasks.where((t) => t.status == TaskStatus.todo).length,
        'inProgress':
            tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed':
            tasks.where((t) => t.status == TaskStatus.completed).length,
        'overdue': tasks.where((t) => t.isOverdue).length,
      };

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch company task stats: $e');
    }
  }

  /// Subscribe to task changes
  Stream<List<Task>> subscribeToTasks({String? branchId}) {
    final query = _supabase.from('tasks').stream(primaryKey: ['id']);

    return query.map((data) {
      final filtered = branchId != null
          ? data.where((json) => json['branch_id'] == branchId).toList()
          : data;
      return filtered.map((json) => _taskFromJson(json)).toList();
    });
  }

  /// Convert JSON to Task model
  Task _taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      branchId: json['branch_id'] as String?,
      companyId: json['company_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.other,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.fromDbValue(json['status'] as String),
      recurrence: TaskRecurrence.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => TaskRecurrence.none,
      ),
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
    );
  }
}
