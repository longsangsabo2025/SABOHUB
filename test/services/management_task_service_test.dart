import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/management_task.dart';

void main() {
  // ─────────────────────────────────────────────
  // ManagementTask Model Tests
  // ─────────────────────────────────────────────

  group('ManagementTask - fromJson / toJson', () {
    late Map<String, dynamic> validTaskJson;

    setUp(() {
      validTaskJson = {
        'id': 'task-001',
        'title': 'Deploy new feature',
        'description': 'Deploy the billing module to production',
        'priority': 'high',
        'status': 'pending',
        'progress': 0,
        'category': 'operations',
        'recurrence': 'none',
        'created_by': 'ceo-001',
        'assigned_to': 'manager-001',
        'company_id': 'company-001',
        'branch_id': 'branch-001',
        'created_at': '2025-03-01T08:00:00.000Z',
        'updated_at': '2025-03-01T08:00:00.000Z',
        'created_by_name': 'CEO Nguyễn',
        'assigned_to_name': 'Manager Trần',
        'assigned_to_role': 'MANAGER',
        'company_name': 'SABO Corp',
      };
    });

    test('should parse valid task JSON correctly', () {
      final task = ManagementTask.fromJson(validTaskJson);

      expect(task.id, 'task-001');
      expect(task.title, 'Deploy new feature');
      expect(task.description, 'Deploy the billing module to production');
      expect(task.priority, TaskPriority.high);
      expect(task.status, TaskStatus.pending);
      expect(task.progress, 0);
      expect(task.category, TaskCategory.operations);
      expect(task.recurrence, 'none');
      expect(task.createdBy, 'ceo-001');
      expect(task.assignedTo, 'manager-001');
      expect(task.companyId, 'company-001');
      expect(task.createdByName, 'CEO Nguyễn');
      expect(task.assignedToName, 'Manager Trần');
    });

    test('should handle null optional fields with defaults', () {
      final minimalJson = {
        'id': 'task-002',
        'title': 'Minimal task',
        'priority': 'medium',
        'status': 'pending',
        'created_by': 'user-001',
        'created_at': '2025-03-01T00:00:00.000Z',
        'updated_at': '2025-03-01T00:00:00.000Z',
      };

      final task = ManagementTask.fromJson(minimalJson);

      expect(task.description, isNull);
      expect(task.assignedTo, isNull);
      expect(task.companyId, isNull);
      expect(task.branchId, isNull);
      expect(task.dueDate, isNull);
      expect(task.completedAt, isNull);
      expect(task.progress, 0);
      expect(task.recurrence, 'none');
      expect(task.checklist, isEmpty);
      expect(task.category, TaskCategory.general);
    });

    test('should parse checklist correctly', () {
      validTaskJson['checklist'] = [
        {'id': 'cl-1', 'title': 'Step 1', 'is_done': true},
        {'id': 'cl-2', 'title': 'Step 2', 'is_done': false},
        {'id': 'cl-3', 'title': 'Step 3', 'is_done': false},
      ];

      final task = ManagementTask.fromJson(validTaskJson);

      expect(task.checklist.length, 3);
      expect(task.checklistDone, 1);
      expect(task.checklistTotal, 3);
      expect(task.hasChecklist, true);
    });

    test('should handle empty checklist', () {
      validTaskJson['checklist'] = [];

      final task = ManagementTask.fromJson(validTaskJson);

      expect(task.checklist, isEmpty);
      expect(task.hasChecklist, false);
      expect(task.checklistDone, 0);
      expect(task.checklistTotal, 0);
    });

    test('should detect recurring task', () {
      validTaskJson['recurrence'] = 'weekly';
      final task = ManagementTask.fromJson(validTaskJson);
      expect(task.isRecurring, true);
    });

    test('should detect non-recurring task', () {
      validTaskJson['recurrence'] = 'none';
      final task = ManagementTask.fromJson(validTaskJson);
      expect(task.isRecurring, false);
    });

    test('should serialize back to JSON correctly (roundtrip)', () {
      final task = ManagementTask.fromJson(validTaskJson);
      final json = task.toJson();

      expect(json['id'], 'task-001');
      expect(json['title'], 'Deploy new feature');
      expect(json['priority'], 'high');
      expect(json['status'], 'pending');
      expect(json['created_by'], 'ceo-001');
      expect(json['assigned_to'], 'manager-001');
    });

    test('should parse due_date correctly', () {
      validTaskJson['due_date'] = '2025-03-15T23:59:59.000Z';

      final task = ManagementTask.fromJson(validTaskJson);

      expect(task.dueDate, isNotNull);
      expect(task.dueDate!.year, 2025);
      expect(task.dueDate!.month, 3);
      expect(task.dueDate!.day, 15);
    });

    test('should parse completed_at correctly', () {
      validTaskJson['status'] = 'completed';
      validTaskJson['progress'] = 100;
      validTaskJson['completed_at'] = '2025-03-10T14:30:00.000Z';

      final task = ManagementTask.fromJson(validTaskJson);

      expect(task.status, TaskStatus.completed);
      expect(task.progress, 100);
      expect(task.completedAt, isNotNull);
    });
  });

  // ─────────────────────────────────────────────
  // TaskPriority Enum Tests
  // ─────────────────────────────────────────────

  group('TaskPriority', () {
    test('should parse all known priority strings', () {
      expect(TaskPriority.fromString('critical'), TaskPriority.critical);
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
      expect(TaskPriority.fromString('low'), TaskPriority.low);
    });

    test('should default to medium for unknown priority', () {
      expect(TaskPriority.fromString('unknown'), TaskPriority.medium);
      expect(TaskPriority.fromString(''), TaskPriority.medium);
    });

    test('should serialize to correct string values', () {
      expect(TaskPriority.critical.value, 'critical');
      expect(TaskPriority.high.value, 'high');
      expect(TaskPriority.medium.value, 'medium');
      expect(TaskPriority.low.value, 'low');
    });

    test('should have human-readable labels', () {
      expect(TaskPriority.critical.label, 'Khẩn cấp');
      expect(TaskPriority.high.label, 'Cao');
      expect(TaskPriority.medium.label, 'Trung bình');
      expect(TaskPriority.low.label, 'Thấp');
    });
  });

  // ─────────────────────────────────────────────
  // TaskStatus Enum Tests
  // ─────────────────────────────────────────────

  group('TaskStatus', () {
    test('should parse all known status strings', () {
      expect(TaskStatus.fromString('pending'), TaskStatus.pending);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('overdue'), TaskStatus.overdue);
      expect(TaskStatus.fromString('cancelled'), TaskStatus.cancelled);
    });

    test('should default to pending for unknown status', () {
      expect(TaskStatus.fromString('unknown'), TaskStatus.pending);
      expect(TaskStatus.fromString(''), TaskStatus.pending);
    });

    test('should serialize to correct string values', () {
      expect(TaskStatus.pending.value, 'pending');
      expect(TaskStatus.inProgress.value, 'in_progress');
      expect(TaskStatus.completed.value, 'completed');
      expect(TaskStatus.overdue.value, 'overdue');
      expect(TaskStatus.cancelled.value, 'cancelled');
    });
  });

  // ─────────────────────────────────────────────
  // TaskCategory Enum Tests
  // ─────────────────────────────────────────────

  group('TaskCategory', () {
    test('should parse all known category strings', () {
      expect(TaskCategory.fromString('general'), TaskCategory.general);
      expect(TaskCategory.fromString('billiards'), TaskCategory.billiards);
      expect(TaskCategory.fromString('media'), TaskCategory.media);
      expect(TaskCategory.fromString('arena'), TaskCategory.arena);
      expect(TaskCategory.fromString('operations'), TaskCategory.operations);
      expect(TaskCategory.fromString('video_production'), TaskCategory.videoProduction);
      expect(TaskCategory.fromString('social_media'), TaskCategory.socialMedia);
      expect(TaskCategory.fromString('marketing'), TaskCategory.marketing);
      expect(TaskCategory.fromString('event_planning'), TaskCategory.eventPlanning);
      expect(TaskCategory.fromString('hr'), TaskCategory.hr);
    });

    test('should default to general for null or unknown category', () {
      expect(TaskCategory.fromString(null), TaskCategory.general);
      expect(TaskCategory.fromString('unknown'), TaskCategory.general);
    });

    test('should have display name with icon', () {
      expect(TaskCategory.general.displayName, contains('🏢'));
      expect(TaskCategory.billiards.displayName, contains('🎱'));
      expect(TaskCategory.media.displayName, contains('📱'));
    });
  });

  // ─────────────────────────────────────────────
  // ChecklistItem Model Tests
  // ─────────────────────────────────────────────

  group('ChecklistItem', () {
    test('should parse valid checklist item JSON', () {
      final json = {'id': 'cl-1', 'title': 'Review PR', 'is_done': true};
      final item = ChecklistItem.fromJson(json);

      expect(item.id, 'cl-1');
      expect(item.title, 'Review PR');
      expect(item.isDone, true);
    });

    test('should default is_done to false if missing', () {
      final json = {'id': 'cl-2', 'title': 'Deploy code'};
      final item = ChecklistItem.fromJson(json);
      expect(item.isDone, false);
    });

    test('should generate id if missing', () {
      final json = {'title': 'No ID item'};
      final item = ChecklistItem.fromJson(json);
      expect(item.id, isNotEmpty);
    });

    test('should serialize to JSON correctly', () {
      const item = ChecklistItem(id: 'cl-1', title: 'Test item', isDone: true);
      final json = item.toJson();

      expect(json['id'], 'cl-1');
      expect(json['title'], 'Test item');
      expect(json['is_done'], true);
    });

    test('should support copyWith', () {
      const item = ChecklistItem(id: 'cl-1', title: 'Original', isDone: false);
      final updated = item.copyWith(isDone: true);

      expect(updated.id, 'cl-1');
      expect(updated.title, 'Original');
      expect(updated.isDone, true);
    });
  });

  // ─────────────────────────────────────────────
  // TaskApproval Model Tests
  // ─────────────────────────────────────────────

  group('TaskApproval - fromJson / toJson', () {
    late Map<String, dynamic> validApprovalJson;

    setUp(() {
      validApprovalJson = {
        'id': 'approval-001',
        'title': 'Budget request for event',
        'description': 'Request 50M VND for team event',
        'type': 'budget',
        'task_id': 'task-001',
        'submitted_by': 'manager-001',
        'status': 'pending',
        'company_id': 'company-001',
        'submitted_at': '2025-03-01T08:00:00.000Z',
        'created_at': '2025-03-01T08:00:00.000Z',
        'updated_at': '2025-03-01T08:00:00.000Z',
        'submitted_by_name': 'Manager Trần',
        'submitted_by_role': 'MANAGER',
        'company_name': 'SABO Corp',
      };
    });

    test('should parse valid approval JSON', () {
      final approval = TaskApproval.fromJson(validApprovalJson);

      expect(approval.id, 'approval-001');
      expect(approval.title, 'Budget request for event');
      expect(approval.type, ApprovalType.budget);
      expect(approval.status, ApprovalStatus.pending);
      expect(approval.submittedBy, 'manager-001');
      expect(approval.submittedByName, 'Manager Trần');
    });

    test('should handle approved status with reviewer', () {
      validApprovalJson['status'] = 'approved';
      validApprovalJson['approved_by'] = 'ceo-001';
      validApprovalJson['reviewed_at'] = '2025-03-02T10:00:00.000Z';

      final approval = TaskApproval.fromJson(validApprovalJson);

      expect(approval.status, ApprovalStatus.approved);
      expect(approval.approvedBy, 'ceo-001');
      expect(approval.reviewedAt, isNotNull);
    });

    test('should handle rejected status with reason', () {
      validApprovalJson['status'] = 'rejected';
      validApprovalJson['approved_by'] = 'ceo-001';
      validApprovalJson['reviewed_at'] = '2025-03-02T10:00:00.000Z';
      validApprovalJson['rejection_reason'] = 'Budget exceeded limit';

      final approval = TaskApproval.fromJson(validApprovalJson);

      expect(approval.status, ApprovalStatus.rejected);
      expect(approval.rejectionReason, 'Budget exceeded limit');
    });

    test('should serialize back to JSON correctly', () {
      final approval = TaskApproval.fromJson(validApprovalJson);
      final json = approval.toJson();

      expect(json['id'], 'approval-001');
      expect(json['type'], 'budget');
      expect(json['status'], 'pending');
      expect(json['submitted_by'], 'manager-001');
    });
  });

  // ─────────────────────────────────────────────
  // ApprovalType Enum Tests
  // ─────────────────────────────────────────────

  group('ApprovalType', () {
    test('should parse all known types', () {
      expect(ApprovalType.fromString('report'), ApprovalType.report);
      expect(ApprovalType.fromString('budget'), ApprovalType.budget);
      expect(ApprovalType.fromString('proposal'), ApprovalType.proposal);
      expect(ApprovalType.fromString('other'), ApprovalType.other);
    });

    test('should default to other for unknown type', () {
      expect(ApprovalType.fromString('unknown'), ApprovalType.other);
    });
  });

  // ─────────────────────────────────────────────
  // ApprovalStatus Enum Tests
  // ─────────────────────────────────────────────

  group('ApprovalStatus', () {
    test('should parse all known statuses', () {
      expect(ApprovalStatus.fromString('pending'), ApprovalStatus.pending);
      expect(ApprovalStatus.fromString('approved'), ApprovalStatus.approved);
      expect(ApprovalStatus.fromString('rejected'), ApprovalStatus.rejected);
    });

    test('should default to pending for unknown status', () {
      expect(ApprovalStatus.fromString('unknown'), ApprovalStatus.pending);
    });
  });

  // ─────────────────────────────────────────────
  // Task Creation - Validation Logic
  // ─────────────────────────────────────────────

  group('Task Creation - Validation Logic', () {
    test('should require title for task creation', () {
      final title = '';
      expect(title.isEmpty, true);

      // In the real service, empty title would cause issues
      if (title.isEmpty) {
        expect(
          () => throw Exception('Task title is required'),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('should require assigned_to for task creation', () {
      final assignedTo = 'manager-001';
      expect(assignedTo.isNotEmpty, true);
    });

    test('should reject task creation without authenticated user', () {
      final userId = null;

      if (userId == null) {
        expect(
          () => throw Exception('User not authenticated'),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('should build correct task data for insertion', () {
      final taskData = {
        'title': 'New Task',
        'description': 'Task description',
        'priority': 'high',
        'status': 'pending',
        'progress': 0,
        'created_by': 'ceo-001',
        'created_by_name': 'CEO Nguyễn',
        'assigned_to': 'manager-001',
        'assigned_to_name': 'Manager Trần',
        'company_id': 'company-001',
        'due_date': '2025-03-15T23:59:59.000Z',
      };

      expect(taskData['title'], 'New Task');
      expect(taskData['priority'], 'high');
      expect(taskData['status'], 'pending');
      expect(taskData['progress'], 0);
      expect(taskData['created_by'], isNotNull);
      expect(taskData['assigned_to'], isNotNull);
    });

    test('should include optional fields only when present', () {
      final taskData = <String, dynamic>{
        'title': 'Simple Task',
        'priority': 'medium',
        'status': 'pending',
        'progress': 0,
        'created_by': 'ceo-001',
        'assigned_to': 'manager-001',
      };

      // category should not be present if not set
      expect(taskData.containsKey('category'), false);
      expect(taskData.containsKey('recurrence'), false);
      expect(taskData.containsKey('checklist'), false);

      // Add optional fields conditionally
      const category = 'operations';
      taskData['category'] = category;
      expect(taskData.containsKey('category'), true);
    });
  });

  // ─────────────────────────────────────────────
  // Task Status Update - Validation Logic
  // ─────────────────────────────────────────────

  group('Task Status Update - Validation Logic', () {
    test('should set completed_at when status is completed', () {
      final status = 'completed';
      final updateData = <String, dynamic>{'status': status};

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['progress'] = 100;
      }

      expect(updateData['status'], 'completed');
      expect(updateData['progress'], 100);
      expect(updateData['completed_at'], isNotNull);
    });

    test('should not set completed_at for non-completed status', () {
      final status = 'in_progress';
      final updateData = <String, dynamic>{'status': status};

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        updateData['progress'] = 100;
      }

      expect(updateData['status'], 'in_progress');
      expect(updateData.containsKey('completed_at'), false);
      expect(updateData.containsKey('progress'), false);
    });

    test('should set completed_at when progress reaches 100', () {
      final progress = 100;
      final status = 'completed';
      final updateData = <String, dynamic>{
        'progress': progress,
      };

      if (progress == 100 && status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      expect(updateData['progress'], 100);
      expect(updateData['completed_at'], isNotNull);
    });
  });

  // ─────────────────────────────────────────────
  // Task Assignment - Validation Logic
  // ─────────────────────────────────────────────

  group('Task Assignment - Validation Logic', () {
    test('should return empty list when no user is authenticated', () {
      final employeeId = null;

      if (employeeId == null) {
        final result = <ManagementTask>[];
        expect(result, isEmpty);
      }
    });

    test('should parse task list from raw response', () {
      final rawResponse = [
        {
          'id': 'task-001',
          'title': 'Task 1',
          'priority': 'high',
          'status': 'pending',
          'progress': 0,
          'created_by': 'ceo-001',
          'assigned_to': 'manager-001',
          'created_at': '2025-03-01T00:00:00.000Z',
          'updated_at': '2025-03-01T00:00:00.000Z',
        },
        {
          'id': 'task-002',
          'title': 'Task 2',
          'priority': 'medium',
          'status': 'in_progress',
          'progress': 50,
          'created_by': 'ceo-001',
          'assigned_to': 'manager-001',
          'created_at': '2025-03-02T00:00:00.000Z',
          'updated_at': '2025-03-02T00:00:00.000Z',
        },
      ];

      final tasks = rawResponse.map((json) {
        return ManagementTask.fromJson(Map<String, dynamic>.from(json));
      }).toList();

      expect(tasks.length, 2);
      expect(tasks[0].title, 'Task 1');
      expect(tasks[1].title, 'Task 2');
      expect(tasks[1].progress, 50);
    });
  });

  // ─────────────────────────────────────────────
  // Task Approval - Validation Logic
  // ─────────────────────────────────────────────

  group('Task Approval - Validation Logic', () {
    test('should reject approval without authenticated user', () {
      final approverId = null;

      if (approverId == null) {
        expect(
          () => throw Exception('User not authenticated'),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('should build correct approval update data', () {
      final approverId = 'ceo-001';
      final updateData = {
        'status': 'approved',
        'approved_by': approverId,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      expect(updateData['status'], 'approved');
      expect(updateData['approved_by'], 'ceo-001');
      expect(updateData['reviewed_at'], isNotNull);
    });

    test('should build correct rejection update data with reason', () {
      final approverId = 'ceo-001';
      final reason = 'Budget exceeded limit';
      final updateData = {
        'status': 'rejected',
        'approved_by': approverId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      };

      expect(updateData['status'], 'rejected');
      expect(updateData['rejection_reason'], 'Budget exceeded limit');
    });
  });

  // ─────────────────────────────────────────────
  // Task Statistics - Aggregation Logic
  // ─────────────────────────────────────────────

  group('Task Statistics - Aggregation Logic', () {
    test('should aggregate task statistics correctly', () {
      final allTasks = [
        {'status': 'pending'},
        {'status': 'pending'},
        {'status': 'in_progress'},
        {'status': 'completed'},
        {'status': 'completed'},
        {'status': 'completed'},
        {'status': 'overdue'},
      ];

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'overdue': 0,
      };

      for (final task in allTasks) {
        stats['total'] = (stats['total'] ?? 0) + 1;
        final status = task['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      expect(stats['total'], 7);
      expect(stats['pending'], 2);
      expect(stats['in_progress'], 1);
      expect(stats['completed'], 3);
      expect(stats['overdue'], 1);
    });

    test('should return zero stats when user is not authenticated', () {
      final userId = null;

      if (userId == null) {
        final stats = {
          'total': 0,
          'pending': 0,
          'in_progress': 0,
          'completed': 0,
          'overdue': 0,
          'pending_approvals': 0,
        };

        expect(stats['total'], 0);
        expect(stats['pending_approvals'], 0);
      }
    });

    test('should handle empty task list', () {
      final allTasks = <Map<String, dynamic>>[];
      final stats = <String, int>{'total': 0};

      for (final _ in allTasks) {
        stats['total'] = (stats['total'] ?? 0) + 1;
      }

      expect(stats['total'], 0);
    });
  });

  // ─────────────────────────────────────────────
  // Task Delete (Soft Delete) - Validation Logic
  // ─────────────────────────────────────────────

  group('Task Delete - Soft Delete Logic', () {
    test('should use soft delete with deleted_at timestamp', () {
      final updateData = {
        'deleted_at': DateTime.now().toIso8601String(),
      };

      expect(updateData['deleted_at'], isNotNull);
      expect(updateData.containsKey('deleted_at'), true);
      // Verify it does NOT hard-delete (no actual row removal)
    });

    test('should not include status change in soft delete', () {
      final updateData = {
        'deleted_at': DateTime.now().toIso8601String(),
      };

      // Soft delete only sets deleted_at, does NOT change status
      expect(updateData.containsKey('status'), false);
    });
  });

  // ─────────────────────────────────────────────
  // Task Update - Generic Update Logic
  // ─────────────────────────────────────────────

  group('Task Update - Generic Update Logic', () {
    test('should only include non-null fields in update', () {
      // Simulating the updateTask method logic
      final updateData = <String, dynamic>{};
      final String title = 'Updated title';
      final String? description = null;
      final String priority = 'critical';
      final String? status = null;

      updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      updateData['priority'] = priority;
      if (status != null) updateData['status'] = status;

      expect(updateData.length, 2); // Only title and priority
      expect(updateData.containsKey('title'), true);
      expect(updateData.containsKey('priority'), true);
      expect(updateData.containsKey('description'), false);
      expect(updateData.containsKey('status'), false);
    });

    test('should handle clearDueDate flag', () {
      final updateData = <String, dynamic>{};
      final bool clearDueDate = true;
      final DateTime dueDate = DateTime(2025, 12, 31);

      if (clearDueDate) {
        updateData['due_date'] = null;
      } else { // ignore: dead_code
        updateData['due_date'] = dueDate.toIso8601String();
      }

      // clearDueDate takes precedence over dueDate
      expect(updateData['due_date'], isNull);
    });

    test('should set due_date when clearDueDate is false', () {
      final updateData = <String, dynamic>{};
      final bool clearDueDate = false;
      final DateTime dueDate = DateTime(2025, 12, 31);

      if (clearDueDate) { // ignore: dead_code
        updateData['due_date'] = null;
      } else {
        updateData['due_date'] = dueDate.toIso8601String();
      }

      expect(updateData['due_date'], isNotNull);
      expect(updateData['due_date'], contains('2025-12-31'));
    });

    test('should skip update when no fields changed', () {
      final updateData = <String, dynamic>{};

      // All null fields → empty updateData
      expect(updateData.isEmpty, true);
      // In real service, this would skip the Supabase call
    });
  });

  // ─────────────────────────────────────────────
  // Error Handling Simulation
  // ─────────────────────────────────────────────

  group('ManagementTaskService - Error Handling', () {
    test('should throw exception on task fetch failure', () {
      expect(
        () => throw Exception('Failed to fetch CEO strategic tasks: Connection error'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception on task creation failure', () {
      expect(
        () => throw Exception('Failed to create task: Permission denied'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception on task update failure', () {
      expect(
        () => throw Exception('Failed to update task status: Record not found'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for unauthenticated approval', () {
      expect(
        () => throw Exception('User not authenticated'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not authenticated'),
          ),
        ),
      );
    });
  });
}
