import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:http/http.dart' as http;
import '../core/services/supabase_service.dart';
import '../models/management_task.dart';
import '../models/task_attachment.dart';
import '../providers/auth_provider.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// 
/// Service này phục vụ CẢ CEO VÀ MANAGER:
/// 
/// **CEO Methods** (OK to use auth.currentUser):
/// - getCEOStrategicTasks() - Chỉ CEO dùng
/// - createTask() - Chỉ CEO dùng
/// - getTaskStatistics() - CEO dashboard
/// - getCompanyTaskStatistics() - CEO dashboard
/// 
/// **Manager/Employee Methods** (PHẢI dùng authProvider):
/// - getTasksAssignedToMe() - ✅ Đã dùng authProvider
/// - getTasksCreatedByMe() - ✅ Đã dùng authProvider
/// - approveTaskApproval() - ⚠️ Cần fix - Manager có thể approve
/// - rejectTaskApproval() - ⚠️ Cần fix - Manager có thể reject
/// 
/// **Shared Methods** (Cả CEO và Manager dùng):
/// - updateTaskProgress() - Cần truyền userId parameter
/// - updateTaskStatus() - Cần truyền userId parameter
/// - deleteTask() - Cần truyền userId parameter

/// Management Task Service
/// Handles CEO and Manager task operations
class ManagementTaskService {
  final _supabase = supabase.client;
  final Ref _ref;
  
  ManagementTaskService(this._ref);

  /// Get strategic tasks created by CEO
  /// Used in CEO Tasks Page - Strategic Tasks tab
  Future<List<ManagementTask>> getCEOStrategicTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // In dev mode without auth, return empty list instead of throwing
        return [];
      }

      final response = await _supabase.from('tasks').select('*')
          .eq('created_by', userId).order('created_at', ascending: false);

      return (response as List).map((json) {
        // Use the cached fields already in the task record
        final flatJson = Map<String, dynamic>.from(json);
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
      // Get employee ID from auth provider (for managers/staff who login via employee system)
      final currentUser = _ref.read(authProvider).user;
      final employeeId = currentUser?.id;
      
      print('🔍 [ManagementTaskService] getTasksAssignedToMe - Current employeeId: $employeeId');
      print('👤 [ManagementTaskService] getTasksAssignedToMe - Current user: ${currentUser?.name} (${currentUser?.role.displayName})');
      
      if (employeeId == null) {
        print('⚠️ [ManagementTaskService] getTasksAssignedToMe - No employee logged in, returning empty list');
        return [];
      }

      print('📡 [ManagementTaskService] getTasksAssignedToMe - Fetching tasks assigned_to: $employeeId');
      final response = await _supabase.from('tasks').select('*')
          .eq('assigned_to', employeeId).order('created_at', ascending: false);

      print('📦 [ManagementTaskService] getTasksAssignedToMe - Raw response: $response');
      print('📊 [ManagementTaskService] getTasksAssignedToMe - Response length: ${(response as List).length}');

      final tasks = (response as List).map((json) {
        // Use the cached fields already in the task record
        final flatJson = Map<String, dynamic>.from(json);
        print('🔄 [ManagementTaskService] getTasksAssignedToMe - Parsing task: ${flatJson['id']} - ${flatJson['title']}');
        return ManagementTask.fromJson(flatJson);
      }).toList();
      
      print('✅ [ManagementTaskService] getTasksAssignedToMe - Successfully returned ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      print('❌ [ManagementTaskService] getTasksAssignedToMe - Error: $e');
      print('📍 [ManagementTaskService] getTasksAssignedToMe - Stack trace: ${StackTrace.current}');
      throw Exception('Failed to fetch assigned tasks: $e');
    }
  }

  /// Get tasks created by current user (Manager assigning to staff)
  /// Used in Manager Tasks Page - Assign Tasks tab
  Future<List<ManagementTask>> getTasksCreatedByMe() async {
    try {
      // Get employee ID from auth provider (for managers/staff who login via employee system)
      final currentUser = _ref.read(authProvider).user;
      final employeeId = currentUser?.id;
      
      if (employeeId == null) {
        return [];
      }

      final response = await _supabase.from('tasks').select('*')
          .eq('created_by', employeeId).order('created_at', ascending: false);

      return (response as List).map((json) {
        // Use the cached fields already in the task record
        final flatJson = Map<String, dynamic>.from(json);
        return ManagementTask.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch created tasks: $e');
    }
  }

  /// Get pending approvals for CEO - filtered by user's company
  /// Used in CEO Tasks Page - Approvals tab
  Future<List<TaskApproval>> getPendingApprovals() async {
    try {
      // Get current user's company_id from metadata
      final user = _supabase.auth.currentUser;
      final companyId = user?.userMetadata?['company_id'] as String?;
      
      var query = _supabase.from('task_approvals').select('*')
          .eq('status', 'pending');
      
      // Filter by company_id if available
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      
      final response = await query.order('submitted_at', ascending: false);

      return (response as List).map((json) {
        // Use the cached fields already in the task_approvals record
        final flatJson = Map<String, dynamic>.from(json);
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

      final response = await _supabase.from('tasks').insert(taskData).select().single();

      // Use the data as-is since we have cached fields
      return ManagementTask.fromJson(response);
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
      
      // Send notification to task creator (CEO)
      await _sendTaskUpdateNotification(
        taskId: taskId,
        progress: progress,
        status: status,
      );
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
      
      // Send notification to task creator (CEO)
      await _sendTaskUpdateNotification(
        taskId: taskId,
        progress: status == 'completed' ? 100 : null,
        status: status,
      );
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
  /// Can be called by both CEO (has auth) and Manager (uses employee system)
  /// 
  /// [approvalId] - ID của approval request
  /// [userId] - OPTIONAL: ID của người approve (CEO id hoặc employee id)
  ///            Nếu không truyền, sẽ thử lấy từ authProvider (Manager) hoặc auth (CEO)
  Future<void> approveTaskApproval(String approvalId, {String? userId}) async {
    try {
      String? approverId = userId;
      
      // Nếu không truyền userId, thử lấy từ authProvider (Manager/Employee)
      if (approverId == null) {
        final currentUser = _ref.read(authProvider).user;
        approverId = currentUser?.id;
      }
      
      // Nếu vẫn null, thử lấy từ Supabase Auth (CEO)
      approverId ??= _supabase.auth.currentUser?.id;
      
      if (approverId == null) throw Exception('User not authenticated');

      await _supabase.from('task_approvals').update({
        'status': 'approved',
        'approved_by': approverId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', approvalId);
    } catch (e) {
      throw Exception('Failed to approve task: $e');
    }
  }

  /// Reject a task approval request
  /// Can be called by both CEO (has auth) and Manager (uses employee system)
  /// 
  /// [approvalId] - ID của approval request
  /// [reason] - Lý do từ chối
  /// [userId] - OPTIONAL: ID của người reject (CEO id hoặc employee id)
  ///            Nếu không truyền, sẽ thử lấy từ authProvider (Manager) hoặc auth (CEO)
  Future<void> rejectTaskApproval(
    String approvalId, {
    String? reason,
    String? userId,
  }) async {
    try {
      String? approverId = userId;
      
      // Nếu không truyền userId, thử lấy từ authProvider (Manager/Employee)
      if (approverId == null) {
        final currentUser = _ref.read(authProvider).user;
        approverId = currentUser?.id;
      }
      
      // Nếu vẫn null, thử lấy từ Supabase Auth (CEO)
      approverId ??= _supabase.auth.currentUser?.id;
      
      if (approverId == null) throw Exception('User not authenticated');

      await _supabase.from('task_approvals').update({
        'status': 'rejected',
        'approved_by': approverId,
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
  /// Only shows statistics for the user's company (not all companies)
  Future<List<Map<String, dynamic>>> getCompanyTaskStatistics() async {
    try {
      // Get current user's company_id from metadata
      final user = _supabase.auth.currentUser;
      final companyId = user?.userMetadata?['company_id'] as String?;
      
      if (companyId == null) {
        return [];
      }

      // Get the user's company info
      final companyResponse = await _supabase
          .from('companies')
          .select('id, name')
          .eq('id', companyId)
          .maybeSingle();

      if (companyResponse == null) {
        return [];
      }

      // Get tasks for this company only
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

      return [{
        'company_id': companyId,
        'company_name': companyResponse['name'],
        'total': total,
        'completed': completed,
        'in_progress': inProgress,
        'overdue': overdue,
      }];
    } catch (e) {
      throw Exception('Failed to fetch company statistics: $e');
    }
  }

  /// Get all managers for task assignment dropdown
  /// ⚠️ IMPORTANT: ALL EMPLOYEES (including managers) are in employees table
  /// users table = CEO ONLY (Supabase Auth)
  /// employees table = ALL STAFF (Manager, Shift Leader, Staff)
  Future<List<Map<String, dynamic>>> getManagers() async {
    try {
      // Get managers from employees table ONLY
      final employeesResponse = await _supabase
          .from('employees')
          .select('id, full_name, role, company_id')
          .eq('role', 'MANAGER')
          .eq('is_active', true)
          .order('full_name', ascending: true);

      final employees = employeesResponse as List;

      // If no managers, return empty list
      if (employees.isEmpty) {
        return [];
      }

      // Get company names separately to avoid relationship conflicts
      final companyIds = employees
          .where((e) => e['company_id'] != null)
          .map((e) => e['company_id'])
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
      return employees.map((employee) {
        return {
          'id': employee['id'],
          'full_name': employee['full_name'],
          'role': employee['role'],
          'company_id': employee['company_id'],
          'company_name': employee['company_id'] != null
              ? companyNames[employee['company_id']]
              : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch managers: $e');
    }
  }

  /// Get all companies for CEO task creation
  /// CEO can see ALL companies, so no filtering by user's company_id
  Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      // CEO can see ALL companies, so no filtering by user's company_id
      final response = await _supabase
          .from('companies')
          .select('id, name')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return []; // Return empty list instead of throwing
    }
  }

  /// Stream tasks assigned to current user (Manager) - REALTIME
  /// Used in Manager Tasks Page - From CEO tab
  Stream<List<ManagementTask>> streamTasksAssignedToMe() {
    // Get employee ID from auth provider
    final currentUser = _ref.read(authProvider).user;
    final employeeId = currentUser?.id;
    
    print('🔴 [ManagementTaskService] streamTasksAssignedToMe - Starting stream for employeeId: $employeeId');
    
    if (employeeId == null) {
      print('⚠️ [ManagementTaskService] streamTasksAssignedToMe - No employee logged in, returning empty stream');
      return Stream.value([]);
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          print('📡 [ManagementTaskService] streamTasksAssignedToMe - Received ${data.length} tasks from stream');
          
          // Filter by assigned_to
          final filtered = data.where((json) => json['assigned_to'] == employeeId).toList();
          
          print('✅ [ManagementTaskService] streamTasksAssignedToMe - Filtered to ${filtered.length} tasks for employee');
          
          return filtered.map((json) {
            final flatJson = Map<String, dynamic>.from(json);
            return ManagementTask.fromJson(flatJson);
          }).toList();
        });
  }

  /// Stream tasks created by current user (Manager) - REALTIME
  /// Used in Manager Tasks Page - Assign Tasks tab
  Stream<List<ManagementTask>> streamTasksCreatedByMe() {
    // Get employee ID from auth provider
    final currentUser = _ref.read(authProvider).user;
    final employeeId = currentUser?.id;
    
    if (employeeId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          // Filter by created_by
          final filtered = data.where((json) => json['created_by'] == employeeId).toList();
          
          return filtered.map((json) {
            final flatJson = Map<String, dynamic>.from(json);
            return ManagementTask.fromJson(flatJson);
          }).toList();
        });
  }

  /// Stream CEO strategic tasks - REALTIME
  /// Used in CEO Tasks Page - Strategic Tasks tab
  Stream<List<ManagementTask>> streamCEOStrategicTasks() {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          // Filter by created_by (CEO)
          final filtered = data.where((json) => json['created_by'] == userId).toList();
          
          return filtered.map((json) {
            final flatJson = Map<String, dynamic>.from(json);
            return ManagementTask.fromJson(flatJson);
          }).toList();
        });
  }

  // ============================================================================
  // TASK ATTACHMENTS (File uploads)
  // ============================================================================

  /// Get attachments for a task
  Future<List<TaskAttachment>> getTaskAttachments(String taskId) async {
    try {
      final response = await _supabase
          .from('task_attachments')
          .select('*')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return TaskAttachment.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch task attachments: $e');
    }
  }

  /// Upload file attachment to task
  Future<TaskAttachment> uploadTaskAttachment({
    required String taskId,
    required String fileName,
    required List<int> fileBytes,
    String? fileType,
  }) async {
    try {
      // Get current user (employee ID)
      final currentUser = _ref.read(authProvider).user;
      final employeeId = currentUser?.id;
      
      if (employeeId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final uniqueFileName = 'task_${taskId}_${timestamp}.$extension';
      
      // Upload to Supabase Storage
      final storagePath = 'task-attachments/$taskId/$uniqueFileName';
      
      await _supabase.storage.from('documents').uploadBinary(
        storagePath,
        Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          contentType: fileType,
          upsert: false,
        ),
      );

      // Get public URL
      final fileUrl = _supabase.storage.from('documents').getPublicUrl(storagePath);

      // Save to database
      final response = await _supabase
          .from('task_attachments')
          .insert({
            'task_id': taskId,
            'file_name': fileName,
            'file_url': fileUrl,
            'file_size': fileBytes.length,
            'file_type': fileType,
            'uploaded_by': employeeId,
          })
          .select()
          .single();

      // Send notification to task creator (CEO)
      await _sendFileUploadNotification(taskId: taskId, fileName: fileName);

      return TaskAttachment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  /// Delete attachment
  Future<void> deleteTaskAttachment(String attachmentId, String fileUrl) async {
    try {
      // Extract storage path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final storagePathIndex = pathSegments.indexOf('documents') + 1;
      final storagePath = pathSegments.sublist(storagePathIndex).join('/');

      // Delete from storage
      await _supabase.storage.from('documents').remove([storagePath]);

      // Delete from database
      await _supabase
          .from('task_attachments')
          .delete()
          .eq('id', attachmentId);
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  /// Download attachment
  Future<List<int>> downloadTaskAttachment(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download attachment: $e');
    }
  }

  /// Send notification to task creator (CEO) about task update
  Future<void> _sendTaskUpdateNotification({
    required String taskId,
    int? progress,
    String? status,
  }) async {
    try {
      // Get task details to find creator (CEO)
      final taskResponse = await _supabase
          .from('tasks')
          .select('title, created_by, assigned_to')
          .eq('id', taskId)
          .single();

      final createdBy = taskResponse['created_by'] as String?;
      if (createdBy == null) return; // No creator to notify

      // Get current user (Manager who is updating)
      final currentUser = _ref.read(authProvider).user;
      final managerName = currentUser?.name ?? 'Manager';

      // Build notification message
      String message;
      if (status == 'completed') {
        message = '$managerName đã hoàn thành nhiệm vụ "${taskResponse['title']}"';
      } else if (progress != null) {
        message = '$managerName đã cập nhật tiến độ lên $progress% cho nhiệm vụ "${taskResponse['title']}"';
      } else if (status == 'in_progress') {
        message = '$managerName đã bắt đầu thực hiện nhiệm vụ "${taskResponse['title']}"';
      } else {
        message = '$managerName đã cập nhật nhiệm vụ "${taskResponse['title']}"';
      }

      // Create notification
      await _supabase.from('notifications').insert({
        'user_id': createdBy,
        'type': 'task_update',
        'title': 'Cập nhật nhiệm vụ',
        'message': message,
        'data': {
          'task_id': taskId,
          'progress': progress,
          'status': status,
          'updated_by': currentUser?.id,
          'updated_by_name': managerName,
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('📬 [ManagementTaskService] Notification sent to CEO ($createdBy) for task update');
    } catch (e) {
      // Don't throw - notification failure shouldn't block task update
      print('⚠️ [ManagementTaskService] Failed to send notification: $e');
    }
  }

  /// Send notification to task creator (CEO) about file upload
  Future<void> _sendFileUploadNotification({
    required String taskId,
    required String fileName,
  }) async {
    try {
      // Get task details to find creator (CEO)
      final taskResponse = await _supabase
          .from('tasks')
          .select('title, created_by')
          .eq('id', taskId)
          .single();

      final createdBy = taskResponse['created_by'] as String?;
      if (createdBy == null) return; // No creator to notify

      // Get current user (Manager who uploaded)
      final currentUser = _ref.read(authProvider).user;
      final managerName = currentUser?.name ?? 'Manager';

      // Create notification
      await _supabase.from('notifications').insert({
        'user_id': createdBy,
        'type': 'task_file_upload',
        'title': 'File đính kèm mới',
        'message': '$managerName đã tải lên file "$fileName" cho nhiệm vụ "${taskResponse['title']}"',
        'data': {
          'task_id': taskId,
          'file_name': fileName,
          'uploaded_by': currentUser?.id,
          'uploaded_by_name': managerName,
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('📬 [ManagementTaskService] File upload notification sent to CEO ($createdBy)');
    } catch (e) {
      // Don't throw - notification failure shouldn't block file upload
      print('⚠️ [ManagementTaskService] Failed to send file upload notification: $e');
    }
  }
}
