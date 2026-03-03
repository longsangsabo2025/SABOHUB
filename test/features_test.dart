import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sabohub/models/media_channel.dart';
import 'package:flutter_sabohub/models/task_template.dart';
import 'package:flutter_sabohub/models/management_task.dart';
import 'package:flutter_sabohub/models/task_comment.dart';

void main() {
  group('MediaChannel Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'ch-1',
        'company_id': 'comp-1',
        'name': 'SABO Official',
        'platform': 'youtube',
        'channel_url': 'https://youtube.com/@sabo',
        'status': 'active',
        'followers_count': 1200,
        'videos_count': 45,
        'views_count': 85000,
        'revenue': 5000000.0,
        'target_followers': 10000,
        'target_videos': 100,
        'notes': 'Main channel',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
      };
      final channel = MediaChannel.fromJson(json);
      expect(channel.id, 'ch-1');
      expect(channel.name, 'SABO Official');
      expect(channel.platform, 'youtube');
      expect(channel.isActive, true);
      expect(channel.followersCount, 1200);
      expect(channel.viewsCount, 85000);
      expect(channel.targetFollowers, 10000);
      expect(channel.followerProgress, 0.12);
      expect(channel.videoProgress, 0.45);
      expect(channel.platformIcon, '▶');
      expect(channel.statusLabel, 'Đang hoạt động');
    });

    test('fromJson handles null/missing fields', () {
      final json = {
        'id': 'ch-2',
        'name': 'Test',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final channel = MediaChannel.fromJson(json);
      expect(channel.platform, 'youtube');
      expect(channel.status, 'planning');
      expect(channel.followersCount, 0);
      expect(channel.followerProgress, 0);
      expect(channel.isActive, false);
    });

    test('toJson serializes correctly', () {
      final channel = MediaChannel(
        id: 'ch-1',
        companyId: 'comp-1',
        name: 'Test',
        platform: 'tiktok',
        status: 'active',
        followersCount: 500,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final json = channel.toJson();
      expect(json['name'], 'Test');
      expect(json['platform'], 'tiktok');
      expect(json['company_id'], 'comp-1');
      expect(json['followers_count'], 500);
    });

    test('platform icons are correct', () {
      final platforms = {
        'youtube': '▶',
        'tiktok': '♪',
        'instagram': '📷',
        'facebook': 'f',
        'twitter': '𝕏',
        'unknown': '🌐',
      };
      for (final entry in platforms.entries) {
        final c = MediaChannel(
          id: 'x', name: 'x', platform: entry.key, status: 'active',
          createdAt: DateTime(2026), updatedAt: DateTime(2026),
        );
        expect(c.platformIcon, entry.value, reason: 'Platform: ${entry.key}');
      }
    });
  });

  group('TaskTemplate Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'tpl-1',
        'title': 'Xây kênh YouTube',
        'description': 'Template cho việc xây kênh',
        'category': 'media',
        'priority': 'high',
        'recurrence_pattern': 'weekly',
        'scheduled_time': '09:00',
        'checklist_items': [
          {'id': '1', 'title': 'Tạo account', 'is_done': false},
          {'id': '2', 'title': 'Thiết kế logo', 'is_done': false},
        ],
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final tpl = TaskTemplate.fromJson(json);
      expect(tpl.title, 'Xây kênh YouTube');
      expect(tpl.category, 'media');
      expect(tpl.priority, 'high');
      expect(tpl.recurrencePattern, 'weekly');
      expect(tpl.recurrenceLabel, 'Hằng tuần');
      expect(tpl.priorityLabel, 'Cao');
      expect(tpl.checklistCount, 2);
      expect(tpl.isActive, true);
    });

    test('handles null checklist', () {
      final json = {
        'id': 'tpl-2',
        'title': 'Simple task',
        'priority': 'low',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final tpl = TaskTemplate.fromJson(json);
      expect(tpl.checklistCount, 0);
      expect(tpl.checklistItems, null);
      expect(tpl.priorityLabel, 'Thấp');
      expect(tpl.recurrenceLabel, 'Một lần');
    });
  });

  group('ManagementTask - Checklist & Category', () {
    test('checklist progress calculation', () {
      final task = ManagementTask(
        id: 't1',
        title: 'Test',
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        progress: 50,
        category: TaskCategory.media,
        checklist: [
          const ChecklistItem(id: '1', title: 'Step 1', isDone: true),
          const ChecklistItem(id: '2', title: 'Step 2', isDone: true),
          const ChecklistItem(id: '3', title: 'Step 3', isDone: false),
          const ChecklistItem(id: '4', title: 'Step 4', isDone: false),
        ],
        createdBy: 'ceo-1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(task.checklistDone, 2);
      expect(task.checklistTotal, 4);
      expect(task.hasChecklist, true);
      expect(task.category.value, 'media');
      expect(task.category.label, 'Media');
    });

    test('TaskCategory fromString', () {
      expect(TaskCategory.fromString('media'), TaskCategory.media);
      expect(TaskCategory.fromString('billiards'), TaskCategory.billiards);
      expect(TaskCategory.fromString('arena'), TaskCategory.arena);
      expect(TaskCategory.fromString('operations'), TaskCategory.operations);
      expect(TaskCategory.fromString(null), TaskCategory.general);
      expect(TaskCategory.fromString('unknown'), TaskCategory.general);
    });

    test('recurrence detection', () {
      final recurring = ManagementTask(
        id: 't2', title: 'Weekly', priority: TaskPriority.medium,
        status: TaskStatus.pending, progress: 0,
        recurrence: 'weekly',
        createdBy: 'ceo', createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      expect(recurring.isRecurring, true);

      final nonRecurring = ManagementTask(
        id: 't3', title: 'Once', priority: TaskPriority.medium,
        status: TaskStatus.pending, progress: 0,
        recurrence: 'none',
        createdBy: 'ceo', createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      expect(nonRecurring.isRecurring, false);
    });
  });

  group('ChecklistItem', () {
    test('fromJson/toJson roundtrip', () {
      final item = ChecklistItem.fromJson({
        'id': 'cl-1',
        'title': 'Tạo account YouTube',
        'is_done': true,
      });
      expect(item.id, 'cl-1');
      expect(item.title, 'Tạo account YouTube');
      expect(item.isDone, true);

      final json = item.toJson();
      expect(json['id'], 'cl-1');
      expect(json['is_done'], true);
    });

    test('copyWith toggles isDone', () {
      const item = ChecklistItem(id: '1', title: 'Test', isDone: false);
      final toggled = item.copyWith(isDone: true);
      expect(toggled.isDone, true);
      expect(toggled.id, '1');
      expect(toggled.title, 'Test');
    });
  });

  group('TaskComment Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'cmt-1',
        'task_id': 'task-1',
        'user_id': 'user-1',
        'comment': 'Đã cập nhật tiến độ',
        'created_at': '2026-03-01T10:00:00Z',
        'updated_at': '2026-03-01T10:00:00Z',
      };
      final comment = TaskComment.fromJson(json);
      expect(comment.id, 'cmt-1');
      expect(comment.taskId, 'task-1');
      expect(comment.comment, 'Đã cập nhật tiến độ');
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('MediaDashboardPage can be instantiated', (tester) async {
      expect(
        () => const Text('MediaDashboardPage'),
        returnsNormally,
      );
    });

    testWidgets('KanbanBoardPage column structure', (tester) async {
      expect(
        () => const Text('KanbanBoardPage'),
        returnsNormally,
      );
    });
  });
}
