import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:http/http.dart' as http;
import '../core/services/supabase_service.dart';
import '../models/management_task.dart';
import '../models/task_attachment.dart';
import '../models/task_comment.dart';
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

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
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
        return [];
      }

      final response = await _supabase.from('tasks').select('*')
          .eq('created_by', userId).order('created_at', ascending: false)
          .limit(100);

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
      final currentUser = _ref.read(currentUserProvider);
      final employeeId = currentUser?.id;
      
      AppLogger.api('🔍 [ManagementTaskService] getTasksAssignedToMe - Current employeeId: $employeeId');
      AppLogger.api('👤 [ManagementTaskService] getTasksAssignedToMe - Current user: ${currentUser?.name} (${currentUser?.role.displayName})');
      
      if (employeeId == null) {
        AppLogger.warn('⚠️ [ManagementTaskService] getTasksAssignedToMe - No employee logged in, returning empty list');
        return [];
      }

      AppLogger.api('📡 [ManagementTaskService] getTasksAssignedToMe - Fetching tasks assigned_to: $employeeId');
      final response = await _supabase.from('tasks').select('*')
          .eq('assigned_to', employeeId).order('created_at', ascending: false)
          .limit(100);

      AppLogger.data('📦 [ManagementTaskService] getTasksAssignedToMe - Raw response: $response');
      AppLogger.data('📊 [ManagementTaskService] getTasksAssignedToMe - Response length: ${(response as List).length}');

      final tasks = (response as List).map((json) {
        // Use the cached fields already in the task record
        final flatJson = Map<String, dynamic>.from(json);
        AppLogger.data('🔄 [ManagementTaskService] getTasksAssignedToMe - Parsing task: ${flatJson['id']} - ${flatJson['title']}');
        return ManagementTask.fromJson(flatJson);
      }).toList();
      
      AppLogger.api('✅ [ManagementTaskService] getTasksAssignedToMe - Successfully returned ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      AppLogger.error('❌ [ManagementTaskService] getTasksAssignedToMe - Error', e, StackTrace.current);
      throw Exception('Failed to fetch assigned tasks: $e');
    }
  }

  /// Get tasks by company ID (for company task board)
  Future<List<ManagementTask>> getTasksByCompany(String companyId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(200);

      return (response as List).map((json) {
        final flatJson = Map<String, dynamic>.from(json);
        return ManagementTask.fromJson(flatJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch company tasks: $e');
    }
  }

  /// Get tasks created by current user (Manager assigning to staff)
  /// Used in Manager Tasks Page - Assign Tasks tab
  Future<List<ManagementTask>> getTasksCreatedByMe() async {
    try {
      // Get employee ID from auth provider (for managers/staff who login via employee system)
      final currentUser = _ref.read(currentUserProvider);
      final employeeId = currentUser?.id;
      
      if (employeeId == null) {
        return [];
      }

      final response = await _supabase.from('tasks').select('*')
          .eq('created_by', employeeId).order('created_at', ascending: false)
          .limit(100);

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
      // Get current user's company_id from authProvider
      final currentUser = _ref.read(currentUserProvider);
      final companyId = currentUser?.companyId;
      
      var query = _supabase.from('task_approvals').select('*')
          .eq('status', 'pending');
      
      // Filter by company_id if available
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      
      final response = await query.order('submitted_at', ascending: false)
          .limit(100);

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
    String? assignedToName,
    String? assignedToRole,
    String? companyId,
    String? branchId,
    DateTime? dueDate,
    String? category,
    String? recurrence,
    List<Map<String, dynamic>>? checklist,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final taskData = {
        'title': title,
        'description': description,
        'priority': priority,
        'status': 'pending',
        'progress': 0,
        'created_by': userId,
        'created_by_name': currentUser?.name ?? 'Unknown',
        'assigned_to': assignedTo,
        if (assignedToName != null) 'assigned_to_name': assignedToName,
        if (assignedToRole != null) 'assigned_to_role': assignedToRole,
        'company_id': companyId,
        'branch_id': branchId,
        'due_date': dueDate?.toIso8601String(),
        if (category != null) 'category': category,
        if (recurrence != null && recurrence != 'none') 'recurrence': recurrence,
        if (checklist != null && checklist.isNotEmpty) 'checklist': checklist,
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

  /// Update task fields (generic update for edit dialog)
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? category,
    String? assignedTo,
    String? companyId,
    int? progress,
    DateTime? dueDate,
    bool clearDueDate = false, // explicitly set due_date to null
    String? recurrence,
    List<Map<String, dynamic>>? checklist,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority;
      if (status != null) updateData['status'] = status;
      if (category != null) updateData['category'] = category;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (companyId != null) updateData['company_id'] = companyId;
      if (progress != null) updateData['progress'] = progress;
      if (clearDueDate) {
        updateData['due_date'] = null;
      } else if (dueDate != null) {
        updateData['due_date'] = dueDate.toIso8601String();
      }
      if (recurrence != null) updateData['recurrence'] = recurrence;
      if (checklist != null) updateData['checklist'] = checklist;

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['progress'] = 100;
      }

      if (updateData.isNotEmpty) {
        await _supabase.from('tasks').update(updateData).eq('id', taskId);
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      // Soft delete - sets deleted_at timestamp
      await _supabase.from('tasks').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
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
        final currentUser = _ref.read(currentUserProvider);
        approverId = currentUser?.id;
      }
      
      
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
        final currentUser = _ref.read(currentUserProvider);
        approverId = currentUser?.id;
      }
      
      
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
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) {
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
      // Get current user's company_id from authProvider
      final currentUser = _ref.read(currentUserProvider);
      final companyId = currentUser?.companyId;
      
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
    final currentUser = _ref.read(currentUserProvider);
    final employeeId = currentUser?.id;
    
    AppLogger.api('🔴 [ManagementTaskService] streamTasksAssignedToMe - Starting stream for employeeId: $employeeId');
    
    if (employeeId == null) {
      AppLogger.warn('⚠️ [ManagementTaskService] streamTasksAssignedToMe - No employee logged in, returning empty stream');
      return Stream.value([]);
    }

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          AppLogger.data('📡 [ManagementTaskService] streamTasksAssignedToMe - Received ${data.length} tasks from stream');
          
          // Filter by assigned_to
          final filtered = data.where((json) => json['assigned_to'] == employeeId).toList();
          
          AppLogger.data('✅ [ManagementTaskService] streamTasksAssignedToMe - Filtered to ${filtered.length} tasks for employee');
          
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
    final currentUser = _ref.read(currentUserProvider);
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
    final userId = _ref.read(currentUserProvider)?.id;
    
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
      final currentUser = _ref.read(currentUserProvider);
      final employeeId = currentUser?.id;
      
      if (employeeId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'task_${taskId}_$timestamp.$extension';
      
      // Convert extension to proper MIME type
      final mimeType = _getMimeType(extension);
      
      // Upload to Supabase Storage
      final storagePath = 'task-attachments/$taskId/$uniqueFileName';
      
      await _supabase.storage.from('documents').uploadBinary(
        storagePath,
        Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          contentType: mimeType,
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
            'file_type': mimeType,
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

  /// Convert file extension to proper MIME type
  String _getMimeType(String extension) {
    const mimeTypes = {
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'rtf': 'application/rtf',
      // Data
      'json': 'application/json',
      'xml': 'application/xml',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      // Archives
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
      // Audio
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'm4a': 'audio/mp4',
      // Video
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'webm': 'video/webm',
      'mkv': 'video/x-matroska',
    };
    
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
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

      // Soft-delete from database
      await _supabase
          .from('task_attachments')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
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
      final currentUser = _ref.read(currentUserProvider);
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

      AppLogger.info('📬 [ManagementTaskService] Notification sent to CEO ($createdBy) for task update');
    } catch (e) {
      // Don't throw - notification failure shouldn't block task update
      AppLogger.warn('⚠️ [ManagementTaskService] Failed to send notification', e);
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
      final currentUser = _ref.read(currentUserProvider);
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

      AppLogger.info('📬 [ManagementTaskService] File upload notification sent to CEO ($createdBy)');
    } catch (e) {
      // Don't throw - notification failure shouldn't block file upload
      AppLogger.warn('⚠️ [ManagementTaskService] Failed to send file upload notification', e);
    }
  }

  // ============================================================================
  // TASK COMMENTS
  // ============================================================================

  Future<List<TaskComment>> getTaskComments(String taskId) async {
    try {
      final response = await _supabase
          .from('task_comments')
          .select('''
            *,
            employees:user_id (
              full_name,
              role,
              avatar_url
            )
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => TaskComment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<TaskComment> addComment({
    required String taskId,
    required String comment,
  }) async {
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Insert the comment
      final insertResponse = await _supabase.from('task_comments').insert({
        'task_id': taskId,
        'user_id': userId,
        'comment': comment,
      }).select('id').single();

      final commentId = insertResponse['id'] as String;

      // Fetch the comment with employee data
      final response = await _supabase
          .from('task_comments')
          .select('''
            *,
            employees:user_id (
              full_name,
              role,
              avatar_url
            )
          ''')
          .eq('id', commentId)
          .single();

      return TaskComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      // Soft delete - sets is_active=false
      await _supabase.from('task_comments').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ============================================================================
  // CHECKLIST (sub-tasks stored as JSONB on tasks table)
  // ============================================================================

  Future<void> updateChecklist({
    required String taskId,
    required List<ChecklistItem> checklist,
  }) async {
    try {
      final done = checklist.where((c) => c.isDone).length;
      final total = checklist.length;
      final autoProgress = total > 0 ? (done / total * 100).round() : 0;

      await _supabase.from('tasks').update({
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'progress': autoProgress,
      }).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  Future<void> toggleChecklistItem({
    required String taskId,
    required List<ChecklistItem> checklist,
    required String itemId,
  }) async {
    final updated = checklist.map((c) {
      if (c.id == itemId) return c.copyWith(isDone: !c.isDone);
      return c;
    }).toList();

    await updateChecklist(taskId: taskId, checklist: updated);
  }

  Future<void> addChecklistItem({
    required String taskId,
    required List<ChecklistItem> currentChecklist,
    required String title,
  }) async {
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    final updated = [...currentChecklist, newItem];
    await updateChecklist(taskId: taskId, checklist: updated);
  }

  Future<void> removeChecklistItem({
    required String taskId,
    required List<ChecklistItem> currentChecklist,
    required String itemId,
  }) async {
    final updated = currentChecklist.where((c) => c.id != itemId).toList();
    await updateChecklist(taskId: taskId, checklist: updated);
  }

  // ============================================================================
  // NOTIFICATIONS (read)
  // ============================================================================

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      AppLogger.warn('Failed to mark notification read', e);
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);
    } catch (e) {
      AppLogger.warn('Failed to mark all notifications read', e);
    }
  }

  // ============================================================================
  // LINK ATTACHMENTS (External URLs)
  // ============================================================================

  /// Add external link as attachment (YouTube, Google Drive, etc.)
  Future<TaskAttachment> addTaskLinkAttachment({
    required String taskId,
    required String linkUrl,
    String? linkTitle,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      final employeeId = currentUser?.id;
      
      if (employeeId == null) {
        throw Exception('User not authenticated');
      }

      // Determine link type and icon
      String fileType = 'link';
      String fileName = linkTitle ?? linkUrl;
      
      if (linkUrl.contains('youtube.com') || linkUrl.contains('youtu.be')) {
        fileType = 'youtube';
        fileName = linkTitle ?? 'YouTube Video';
      } else if (linkUrl.contains('drive.google.com')) {
        fileType = 'google_drive';
        fileName = linkTitle ?? 'Google Drive';
      } else if (linkUrl.contains('docs.google.com')) {
        fileType = 'google_docs';
        fileName = linkTitle ?? 'Google Docs';
      } else if (linkUrl.contains('figma.com')) {
        fileType = 'figma';
        fileName = linkTitle ?? 'Figma Design';
      } else if (linkUrl.contains('canva.com')) {
        fileType = 'canva';
        fileName = linkTitle ?? 'Canva Design';
      }

      // Save to database
      final response = await _supabase
          .from('task_attachments')
          .insert({
            'task_id': taskId,
            'file_name': fileName,
            'file_url': linkUrl,
            'file_size': null, // No file size for links
            'file_type': fileType,
            'uploaded_by': employeeId,
          })
          .select()
          .single();

      // Send notification to task creator
      await _sendFileUploadNotification(taskId: taskId, fileName: fileName);

      return TaskAttachment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add link attachment: $e');
    }
  }

  // ============================================================================
  // DEADLINE EXTENSION REQUEST
  // ============================================================================

  /// Request deadline extension for a task
  Future<void> requestDeadlineExtension({
    required String taskId,
    required String reason,
    required DateTime proposedDate,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get task details
      final taskResponse = await _supabase
          .from('tasks')
          .select('title, company_id, due_date, created_by')
          .eq('id', taskId)
          .single();

      // Create approval request
      await _supabase.from('task_approvals').insert({
        'title': 'Yêu cầu gia hạn: ${taskResponse['title']}',
        'description': reason,
        'type': 'deadline_extension',
        'task_id': taskId,
        'submitted_by': userId,
        'company_id': taskResponse['company_id'],
        'status': 'pending',
      });

      // Send notification to task creator (CEO)
      final createdBy = taskResponse['created_by'] as String?;
      if (createdBy != null) {
        await _supabase.from('notifications').insert({
          'user_id': createdBy,
          'type': 'deadline_extension_request',
          'title': 'Yêu cầu gia hạn',
          'message': '${currentUser?.name ?? "Nhân viên"} yêu cầu gia hạn deadline cho nhiệm vụ "${taskResponse['title']}"',
          'data': {
            'task_id': taskId,
            'requested_by': userId,
            'requested_by_name': currentUser?.name,
            'current_due_date': taskResponse['due_date'],
            'proposed_date': proposedDate.toIso8601String(),
            'reason': reason,
          },
          'is_read': false,
        });
      }

      AppLogger.info('📬 [ManagementTaskService] Deadline extension request submitted for task: $taskId');
    } catch (e) {
      throw Exception('Failed to request deadline extension: $e');
    }
  }

  // ============================================================================
  // CATEGORY STATISTICS
  // ============================================================================

  Future<Map<String, int>> getCategoryStatistics() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('tasks')
          .select('category, status')
          .eq('created_by', userId);

      final stats = <String, int>{};
      for (final task in response as List) {
        final cat = task['category'] as String? ?? 'general';
        stats[cat] = (stats[cat] ?? 0) + 1;
      }
      return stats;
    } catch (e) {
      return {};
    }
  }
}
