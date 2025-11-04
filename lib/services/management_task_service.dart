import '../core/services/supabase_service.dart';
import '../models/management_task.dart';

/// Management Task Service
/// Handles CEO and Manager task operations
class ManagementTaskService {
  final _supabase = supabase.client;

  /// Get strategic tasks created by CEO
  /// Used in CEO Tasks Page - Strategic Tasks tab
  Future<List<ManagementTask>> getCEOStrategicTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // In dev mode without auth, return empty list instead of throwing
        return [];
      }

      final response = await _supabase.from('tasks').select('''
            *,
            created_by_user:users!tasks_created_by_fkey(id, full_name, role),
            assigned_to_user:users!tasks_assigned_to_fkey(id, full_name, role),
            company:companies(id, name),
            branch:branches(id, name)
          ''').eq('created_by', userId).order('created_at', ascending: false);

      return (response as List).map((json) {
        // Flatten the nested JSON structure
        final flatJson = Map<String, dynamic>.from(json);
        if (json['created_by_user'] != null) {
          flatJson['created_by_name'] = json['created_by_user']['full_name'];
          flatJson['created_by_role'] = json['created_by_user']['role'];
        }
        if (json['assigned_to_user'] != null) {
          flatJson['assigned_to_name'] = json['assigned_to_user']['full_name'];
          flatJson['assigned_to_role'] = json['assigned_to_user']['role'];
        }
        if (json['company'] != null) {
          flatJson['company_name'] = json['company']['name'];
        }
        if (json['branch'] != null) {
          flatJson['branch_name'] = json['branch']['name'];
        }
        return ManagementTask.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch CEO strategic tasks: $e');
    }
  }

  /// Get tasks assigned to current user (Manager)
  /// Used in Manager Tasks Page - From CEO tab
  Future<List<ManagementTask>> getTasksAssignedToMe() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // In dev mode without auth, return empty list
        return [];
      }

      final response = await _supabase.from('tasks').select('''
            *,
            created_by_user:users!tasks_created_by_fkey(id, full_name, role),
            assigned_to_user:users!tasks_assigned_to_fkey(id, full_name, role),
            company:companies(id, name),
            branch:branches(id, name)
          ''').eq('assigned_to', userId).order('created_at', ascending: false);

      return (response as List).map((json) {
        final flatJson = Map<String, dynamic>.from(json);
        if (json['created_by_user'] != null) {
          flatJson['created_by_name'] = json['created_by_user']['full_name'];
          flatJson['created_by_role'] = json['created_by_user']['role'];
        }
        if (json['assigned_to_user'] != null) {
          flatJson['assigned_to_name'] = json['assigned_to_user']['full_name'];
          flatJson['assigned_to_role'] = json['assigned_to_user']['role'];
        }
        if (json['company'] != null) {
          flatJson['company_name'] = json['company']['name'];
        }
        if (json['branch'] != null) {
          flatJson['branch_name'] = json['branch']['name'];
        }
        return ManagementTask.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch assigned tasks: $e');
    }
  }

  /// Get tasks created by current user (Manager assigning to staff)
  /// Used in Manager Tasks Page - Assign Tasks tab
  Future<List<ManagementTask>> getTasksCreatedByMe() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // In dev mode without auth, return empty list
        return [];
      }

      final response = await _supabase.from('tasks').select('''
            *,
            created_by_user:users!tasks_created_by_fkey(id, full_name, role),
            assigned_to_user:users!tasks_assigned_to_fkey(id, full_name, role),
            company:companies(id, name),
            branch:branches(id, name)
          ''').eq('created_by', userId).order('created_at', ascending: false);

      return (response as List).map((json) {
        final flatJson = Map<String, dynamic>.from(json);
        if (json['created_by_user'] != null) {
          flatJson['created_by_name'] = json['created_by_user']['full_name'];
          flatJson['created_by_role'] = json['created_by_user']['role'];
        }
        if (json['assigned_to_user'] != null) {
          flatJson['assigned_to_name'] = json['assigned_to_user']['full_name'];
          flatJson['assigned_to_role'] = json['assigned_to_user']['role'];
        }
        if (json['company'] != null) {
          flatJson['company_name'] = json['company']['name'];
        }
        if (json['branch'] != null) {
          flatJson['branch_name'] = json['branch']['name'];
        }
        return ManagementTask.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch created tasks: $e');
    }
  }

  /// Get pending approvals for CEO
  /// Used in CEO Tasks Page - Approvals tab
  Future<List<TaskApproval>> getPendingApprovals() async {
    try {
      final response = await _supabase.from('task_approvals').select('''
            *,
            submitted_by_user:users!task_approvals_submitted_by_fkey(id, full_name, role),
            company:companies(id, name)
          ''').eq('status', 'pending').order('submitted_at', ascending: false);

      return (response as List).map((json) {
        final flatJson = Map<String, dynamic>.from(json);
        if (json['submitted_by_user'] != null) {
          flatJson['submitted_by_name'] =
              json['submitted_by_user']['full_name'];
          flatJson['submitted_by_role'] = json['submitted_by_user']['role'];
        }
        if (json['company'] != null) {
          flatJson['company_name'] = json['company']['name'];
        }
        return TaskApproval.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending approvals: $e');
    }
  }

  /// Create a new task
  Future<ManagementTask> createTask({
    required String title,
    String? description,
    required String priority,
    required String assignedTo,
    String? companyId,
    String? branchId,
    DateTime? dueDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final taskData = {
        'title': title,
        'description': description,
        'priority': priority,
        'status': 'pending',
        'progress': 0,
        'created_by': userId,
        'assigned_to': assignedTo,
        'company_id': companyId,
        'branch_id': branchId,
        'due_date': dueDate?.toIso8601String(),
      };

      final response = await _supabase.from('tasks').insert(taskData).select('''
            *,
            created_by_user:users!tasks_created_by_fkey(id, full_name, role),
            assigned_to_user:users!tasks_assigned_to_fkey(id, full_name, role),
            company:companies(id, name),
            branch:branches(id, name)
          ''').single();

      final flatJson = Map<String, dynamic>.from(response);
      if (response['created_by_user'] != null) {
        flatJson['created_by_name'] = response['created_by_user']['full_name'];
        flatJson['created_by_role'] = response['created_by_user']['role'];
      }
      if (response['assigned_to_user'] != null) {
        flatJson['assigned_to_name'] =
            response['assigned_to_user']['full_name'];
        flatJson['assigned_to_role'] = response['assigned_to_user']['role'];
      }
      if (response['company'] != null) {
        flatJson['company_name'] = response['company']['name'];
      }
      if (response['branch'] != null) {
        flatJson['branch_name'] = response['branch']['name'];
      }

      return ManagementTask.fromJson(flatJson);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update task progress and status
  Future<void> updateTaskProgress({
    required String taskId,
    required int progress,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'progress': progress,
      };

      if (status != null) {
        updateData['status'] = status;
      }

      if (progress == 100 && status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('tasks').update(updateData).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task progress: $e');
    }
  }

  /// Update task status
  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': status};

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['progress'] = 100;
      }

      await _supabase.from('tasks').update(updateData).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Approve a task approval request
  Future<void> approveTaskApproval(String approvalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('task_approvals').update({
        'status': 'approved',
        'approved_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', approvalId);
    } catch (e) {
      throw Exception('Failed to approve task: $e');
    }
  }

  /// Reject a task approval request
  Future<void> rejectTaskApproval(
    String approvalId, {
    String? reason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('task_approvals').update({
        'status': 'rejected',
        'approved_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', approvalId);
    } catch (e) {
      throw Exception('Failed to reject task: $e');
    }
  }

  /// Get task statistics for CEO dashboard
  Future<Map<String, int>> getTaskStatistics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // In dev mode without auth, return default stats
        return {
          'total': 0,
          'pending': 0,
          'in_progress': 0,
          'completed': 0,
          'overdue': 0,
          'pending_approvals': 0,
        };
      }

      // Get all tasks created by CEO
      final allTasks = await _supabase
          .from('tasks')
          .select('status')
          .eq('created_by', userId);

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'overdue': 0,
      };

      for (final task in allTasks as List) {
        stats['total'] = (stats['total'] ?? 0) + 1;
        final status = task['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      // Get pending approvals count
      final pendingApprovals = await _supabase
          .from('task_approvals')
          .select('id')
          .eq('status', 'pending');

      stats['pending_approvals'] = (pendingApprovals as List).length;

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch task statistics: $e');
    }
  }

  /// Get company task statistics for CEO overview
  Future<List<Map<String, dynamic>>> getCompanyTaskStatistics() async {
    try {
      // Get all companies
      final companies = await _supabase.from('companies').select('id, name');

      final results = <Map<String, dynamic>>[];

      for (final company in companies as List) {
        final companyId = company['id'] as String;

        // Get tasks for this company
        final tasks = await _supabase
            .from('tasks')
            .select('status')
            .eq('company_id', companyId);

        int total = 0;
        int completed = 0;
        int inProgress = 0;
        int overdue = 0;

        for (final task in tasks as List) {
          total++;
          final status = task['status'] as String;
          switch (status) {
            case 'completed':
              completed++;
              break;
            case 'in_progress':
              inProgress++;
              break;
            case 'overdue':
              overdue++;
              break;
          }
        }

        results.add({
          'company_id': companyId,
          'company_name': company['name'],
          'total': total,
          'completed': completed,
          'in_progress': inProgress,
          'overdue': overdue,
        });
      }

      return results;
    } catch (e) {
      throw Exception('Failed to fetch company statistics: $e');
    }
  }

  /// Get all managers for task assignment dropdown
  /// Returns list of users with role='manager'
  Future<List<Map<String, dynamic>>> getManagers() async {
    try {
      // Get all managers first
      final usersResponse = await _supabase
          .from('users')
          .select('id, full_name, role, company_id')
          .eq('role', 'MANAGER')
          .order('full_name', ascending: true);

      final users = usersResponse as List;

      // If no managers, return empty list
      if (users.isEmpty) {
        return [];
      }

      // Get company names separately to avoid relationship conflicts
      final companyIds = users
          .where((u) => u['company_id'] != null)
          .map((u) => u['company_id'])
          .toSet()
          .toList();

      Map<String, String> companyNames = {};
      if (companyIds.isNotEmpty) {
        final companiesResponse = await _supabase
            .from('companies')
            .select('id, name')
            .inFilter('id', companyIds);

        for (var company in companiesResponse as List) {
          companyNames[company['id']] = company['name'];
        }
      }

      // Combine data
      return users.map((user) {
        return {
          'id': user['id'],
          'full_name': user['full_name'],
          'role': user['role'],
          'company_id': user['company_id'],
          'company_name': user['company_id'] != null
              ? companyNames[user['company_id']]
              : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch managers: $e');
    }
  }

  /// Get all companies for CEO task creation
  /// CEO can create tasks for ANY company
  Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      print('🏢 Fetching all companies for CEO...');

      // CEO can see ALL companies, so no filtering by user's company_id
      final response = await _supabase
          .from('companies')
          .select('id, name')
          .order('name', ascending: true);

      print('✅ Fetched ${response.length} companies from database');
      print('📋 Companies: $response');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Failed to fetch companies: $e');
      return []; // Return empty list instead of throwing
    }
  }
}
