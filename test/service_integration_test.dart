import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/media_channel.dart';
import 'package:flutter_sabohub/models/task_template.dart';
import 'package:flutter_sabohub/models/management_task.dart';
import 'package:flutter_sabohub/models/schedule.dart';

void main() {
  group('ManagementTask JSON roundtrip with all new fields', () {
    test('full task with checklist, category, recurrence', () {
      final originalJson = {
        'id': 'task-abc-123',
        'title': 'Xây kênh YouTube cho SABO Media',
        'description': 'Bước 1: Tạo account, Bước 2: Upload 10 videos',
        'priority': 'high',
        'status': 'in_progress',
        'progress': 50,
        'category': 'media',
        'recurrence': 'weekly',
        'checklist': [
          {'id': 'cl-1', 'title': 'Tạo account', 'is_done': true},
          {'id': 'cl-2', 'title': 'Thiết kế logo', 'is_done': true},
          {'id': 'cl-3', 'title': 'Lên content plan', 'is_done': false},
          {'id': 'cl-4', 'title': 'Quay 10 videos', 'is_done': false},
        ],
        'due_date': '2026-04-01T00:00:00Z',
        'created_by': 'ceo-001',
        'assigned_to': 'mgr-001',
        'company_id': 'comp-sabo',
        'created_at': '2026-03-01T08:00:00Z',
        'updated_at': '2026-03-01T12:00:00Z',
        'created_by_name': 'Long Sang',
        'created_by_role': 'CEO',
        'assigned_to_name': 'Manager Media',
        'assigned_to_role': 'MANAGER',
        'company_name': 'SABO',
      };

      final task = ManagementTask.fromJson(originalJson);

      expect(task.id, 'task-abc-123');
      expect(task.title, 'Xây kênh YouTube cho SABO Media');
      expect(task.category, TaskCategory.media);
      expect(task.category.value, 'media');
      expect(task.category.label, 'Media');
      expect(task.category.icon, '📱');
      expect(task.recurrence, 'weekly');
      expect(task.isRecurring, true);
      expect(task.checklist.length, 4);
      expect(task.checklistDone, 2);
      expect(task.checklistTotal, 4);
      expect(task.hasChecklist, true);
      expect(task.dueDate, isNotNull);
      expect(task.assignedToName, 'Manager Media');
      expect(task.companyName, 'SABO');

      final toJsonResult = task.toJson();
      expect(toJsonResult['category'], 'media');
      expect(toJsonResult['recurrence'], 'weekly');
      expect(toJsonResult['checklist'], isList);
      expect((toJsonResult['checklist'] as List).length, 4);

      final roundtrip = ManagementTask.fromJson(toJsonResult);
      expect(roundtrip.id, task.id);
      expect(roundtrip.category, task.category);
      expect(roundtrip.checklist.length, task.checklist.length);
      expect(roundtrip.checklistDone, task.checklistDone);
    });

    test('task with empty checklist', () {
      final json = {
        'id': 't-2',
        'title': 'Simple',
        'priority': 'low',
        'status': 'pending',
        'progress': 0,
        'created_by': 'x',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final task = ManagementTask.fromJson(json);
      expect(task.category, TaskCategory.general);
      expect(task.recurrence, 'none');
      expect(task.isRecurring, false);
      expect(task.checklist, isEmpty);
      expect(task.hasChecklist, false);
    });

    test('copyWith preserves new fields', () {
      final task = ManagementTask(
        id: 't-3',
        title: 'Original',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        progress: 0,
        category: TaskCategory.billiards,
        recurrence: 'daily',
        checklist: const [ChecklistItem(id: '1', title: 'Step 1')],
        createdBy: 'ceo',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = task.copyWith(
        title: 'Updated',
        category: TaskCategory.arena,
      );
      expect(updated.title, 'Updated');
      expect(updated.category, TaskCategory.arena);
      expect(updated.recurrence, 'daily');
      expect(updated.checklist.length, 1);
    });
  });

  group('MediaChannel edge cases', () {
    test('progress with zero targets', () {
      final c = MediaChannel(
        id: 'c1', name: 'Test', platform: 'youtube', status: 'active',
        followersCount: 100, targetFollowers: 0,
        videosCount: 10, targetVideos: 0,
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      expect(c.followerProgress, 0);
      expect(c.videoProgress, 0);
    });

    test('all status labels', () {
      final statuses = {
        'active': 'Đang hoạt động',
        'planning': 'Đang lên kế hoạch',
        'paused': 'Tạm dừng',
        'archived': 'Đã lưu trữ',
        'custom': 'custom',
      };
      for (final entry in statuses.entries) {
        final c = MediaChannel(
          id: 'x', name: 'x', platform: 'youtube', status: entry.key,
          createdAt: DateTime(2026), updatedAt: DateTime(2026),
        );
        expect(c.statusLabel, entry.value, reason: 'Status: ${entry.key}');
      }
    });
  });

  group('TaskTemplate edge cases', () {
    test('all recurrence labels', () {
      final patterns = {
        'daily': 'Hằng ngày',
        'weekly': 'Hằng tuần',
        'monthly': 'Hằng tháng',
        null: 'Một lần',
      };
      for (final entry in patterns.entries) {
        final json = {
          'id': 'x',
          'title': 'x',
          'recurrence_pattern': entry.key,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };
        final tpl = TaskTemplate.fromJson(json);
        expect(tpl.recurrenceLabel, entry.value);
      }
    });

    test('all priority labels', () {
      final priorities = {
        'critical': 'Khẩn cấp',
        'high': 'Cao',
        'medium': 'Trung bình',
        'low': 'Thấp',
      };
      for (final entry in priorities.entries) {
        final json = {
          'id': 'x', 'title': 'x', 'priority': entry.key,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };
        final tpl = TaskTemplate.fromJson(json);
        expect(tpl.priorityLabel, entry.value);
      }
    });
  });

  group('Schedule Model Smoke Test', () {
    test('ShiftType values', () {
      expect(ShiftType.morning.label, 'Ca sáng');
      expect(ShiftType.afternoon.label, 'Ca chiều');
      expect(ShiftType.night.label, 'Ca đêm');
      expect(ShiftType.full.label, 'Ca full');
    });

    test('ScheduleStatus values', () {
      expect(ScheduleStatus.scheduled.label, 'Đã lên lịch');
      expect(ScheduleStatus.confirmed.label, 'Đã xác nhận');
      expect(ScheduleStatus.absent.label, 'Vắng mặt');
    });
  });

  group('TaskPriority & TaskStatus', () {
    test('all TaskPriority values parse', () {
      expect(TaskPriority.fromString('critical'), TaskPriority.critical);
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('invalid'), TaskPriority.medium);
    });

    test('all TaskStatus values parse', () {
      expect(TaskStatus.fromString('pending'), TaskStatus.pending);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('overdue'), TaskStatus.overdue);
      expect(TaskStatus.fromString('cancelled'), TaskStatus.cancelled);
      expect(TaskStatus.fromString('invalid'), TaskStatus.pending);
    });
  });
}
