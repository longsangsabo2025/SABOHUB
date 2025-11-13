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
      final query = _supabase
          .from('tasks')
          .select('*')
          .isFilter('deleted_at', null); // Filter out soft deleted

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
          .eq('status', status.name)
          .isFilter('deleted_at', null); // ✅ Filter out soft deleted tasks

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
          .eq('assigned_to', userId)
          .isFilter('deleted_at', null); // ✅ Filter out soft deleted tasks

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
    print('🔍 DEBUG: Starting task creation...');
    print('🔍 Task title: ${task.title}');
    print('🔍 Task assigned_to: ${task.assignedTo}');
    print('🔍 Task created_by: ${task.createdBy}');
    
    try {
      final insertData = {
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
        'assigned_to_role': task.assignedToRole,
        'due_date': task.dueDate?.toIso8601String(),
        'created_by': task.createdBy,
        'created_by_name': task.createdByName,
        'notes': task.notes,
        'progress': 0,
      };
      
      print('🔍 DEBUG: Insert data prepared');
      print('🔍 DEBUG: Calling .from("tasks").insert()...');
      
      final response = await _supabase
          .from('tasks')
          .insert(insertData)
          .select()
          .single();
          
      print('🔍 DEBUG: Insert successful! Response: $response');

      final createdTask = _taskFromJson(response);
      print('🔍 DEBUG: Task parsed successfully: ${createdTask.id}');

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
      print('❌ DEBUG: Exception caught!');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Exception message: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Check if it's PostgREST specific error
      if (e.toString().contains('PGRST')) {
        print('❌ POSTGREST ERROR DETECTED!');
        print('❌ This is a PostgREST schema cache issue');
        print('❌ Error suggests: ${e.toString().split('hint:').last}');
      }
      
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

  /// Delete a task (soft delete)
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Restore a soft deleted task
  Future<void> restoreTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'deleted_at': null,
      }).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to restore task: $e');
    }
  }

  /// Permanently delete a task (admin only)
  Future<void> permanentlyDeleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to permanently delete task: $e');
    }
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStats({String? branchId}) async {
    try {
      final query = _supabase
          .from('tasks')
          .select('*')
          .isFilter('deleted_at', null); // ✅ Filter out soft deleted tasks

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
      print('🔍 [TaskService] Fetching tasks for company: $companyId');
      
      // NOTE: Cannot use JOIN without foreign keys
      // Name fields should be populated by database triggers or app logic
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('company_id', companyId)
          .isFilter('deleted_at', null) // ✅ CRITICAL: Filter out soft deleted tasks
          .order('created_at', ascending: false);

      print('📦 [TaskService] Raw response: ${response}');
      print('📊 [TaskService] Response length: ${(response as List).length}');
      
      if ((response as List).isEmpty) {
        print('⚠️ [TaskService] No tasks found for company $companyId');
        return [];
      }
      
      final tasks = (response as List).map((json) {
        print('🔄 [TaskService] Parsing task: ${json['id']} - ${json['title']}');
        return _taskFromJson(json);
      }).toList();
      
      print('✅ [TaskService] Successfully parsed ${tasks.length} tasks');
      return tasks;
    } catch (e, stackTrace) {
      print('❌ [TaskService] Error fetching tasks: $e');
      print('📍 [TaskService] Stack trace: $stackTrace');
      throw Exception('Failed to fetch tasks by company: $e');
    }
  }

  /// Get task statistics for a company
  Future<Map<String, int>> getCompanyTaskStats(String companyId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('company_id', companyId)
          .isFilter('deleted_at', null); // ✅ Filter out soft deleted tasks

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
      assignedToRole: json['assigned_to_role'] as String?, // NEW: Get role from DB
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
}
