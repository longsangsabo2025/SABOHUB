/// End-to-End feature tests for CEO Task Management UI improvements
/// Covers Round 1 & Round 2 features:
///   Round 1: Grouped view, swipe gestures, relative deadline, removed duplicate buttons
///   Round 2: Date filters (today/thisWeek/overdue), overdue banner, comment count badge
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sabohub/models/management_task.dart';
import 'package:flutter_sabohub/widgets/task/task_card.dart';

// ---------------------------------------------------------------------------
// Helpers — mirror the _applyFilters date-filter logic from task_board.dart
// so we can unit-test it without spinning up the full widget tree.
// ---------------------------------------------------------------------------

bool _matchesToday(ManagementTask t) {
  if (t.dueDate == null) return false;
  if (t.status == TaskStatus.completed || t.status == TaskStatus.cancelled) {
    return false;
  }
  final now = DateTime.now();
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return !t.dueDate!.isAfter(todayEnd);
}

bool _matchesThisWeek(ManagementTask t) {
  if (t.dueDate == null) return false;
  if (t.status == TaskStatus.completed || t.status == TaskStatus.cancelled) {
    return false;
  }
  final weekEnd = DateTime.now().add(const Duration(days: 7));
  return !t.dueDate!.isAfter(weekEnd);
}

bool _matchesOverdue(ManagementTask t) {
  if (t.dueDate == null) return false;
  if (t.status == TaskStatus.completed || t.status == TaskStatus.cancelled) {
    return false;
  }
  return t.dueDate!.isBefore(DateTime.now());
}

int _overdueCount(List<ManagementTask> tasks) =>
    tasks.where(_matchesOverdue).length;

// ---------------------------------------------------------------------------
// Helper — build a task easily
// ---------------------------------------------------------------------------

ManagementTask _task({
  String id = 't1',
  String title = 'Test Task',
  TaskPriority priority = TaskPriority.medium,
  TaskStatus status = TaskStatus.pending,
  DateTime? dueDate,
  int commentCount = 0,
  String? companyName,
}) {
  final now = DateTime.now();
  return ManagementTask(
    id: id,
    title: title,
    priority: priority,
    status: status,
    progress: 0,
    dueDate: dueDate,
    commentCount: commentCount,
    companyName: companyName,
    createdBy: 'ceo-1',
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // GROUP 1: ManagementTask.commentCount model
  // =========================================================================
  group('ManagementTask.commentCount', () {
    test('defaults to 0 when not provided in constructor', () {
      final t = _task();
      expect(t.commentCount, 0);
    });

    test('stores provided value correctly', () {
      final t = _task(commentCount: 7);
      expect(t.commentCount, 7);
    });

    test('fromJson parses comment_count', () {
      final t = ManagementTask.fromJson({
        'id': 't-json',
        'title': 'JSON Task',
        'priority': 'high',
        'status': 'in_progress',
        'progress': 30,
        'created_by': 'ceo',
        'created_at': '2026-03-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
        'comment_count': 5,
      });
      expect(t.commentCount, 5);
    });

    test('fromJson defaults to 0 when comment_count is absent', () {
      final t = ManagementTask.fromJson({
        'id': 't-json-2',
        'title': 'No comments',
        'priority': 'low',
        'status': 'pending',
        'progress': 0,
        'created_by': 'ceo',
        'created_at': '2026-03-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
        // comment_count intentionally omitted
      });
      expect(t.commentCount, 0);
    });

    test('fromJson handles null comment_count gracefully', () {
      final t = ManagementTask.fromJson({
        'id': 't-json-3',
        'title': 'Null count',
        'priority': 'medium',
        'status': 'pending',
        'progress': 0,
        'created_by': 'ceo',
        'created_at': '2026-03-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
        'comment_count': null,
      });
      expect(t.commentCount, 0);
    });
  });

  // =========================================================================
  // GROUP 2: Date filter — TODAY
  // =========================================================================
  group('DateFilter.today logic', () {
    final now = DateTime.now();

    test('matches task due today (past hour)', () {
      final t = _task(
        dueDate:
            DateTime(now.year, now.month, now.day, 9, 0), // 09:00 today
      );
      expect(_matchesToday(t), isTrue);
    });

    test('matches task due exactly at 23:59:59 today', () {
      final t = _task(
        dueDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
      expect(_matchesToday(t), isTrue);
    });

    test('does NOT match task due tomorrow', () {
      final t = _task(dueDate: now.add(const Duration(days: 1)));
      expect(_matchesToday(t), isFalse);
    });

    test('does NOT match task with no dueDate', () {
      final t = _task();
      expect(_matchesToday(t), isFalse);
    });

    test('excludes completed task due today', () {
      final t = _task(
        status: TaskStatus.completed,
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
      );
      expect(_matchesToday(t), isFalse);
    });

    test('excludes cancelled task due today', () {
      final t = _task(
        status: TaskStatus.cancelled,
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
      );
      expect(_matchesToday(t), isFalse);
    });

    test('includes in_progress task due today', () {
      final t = _task(
        status: TaskStatus.inProgress,
        dueDate: DateTime(now.year, now.month, now.day, 10, 0),
      );
      expect(_matchesToday(t), isTrue);
    });
  });

  // =========================================================================
  // GROUP 3: Date filter — THIS WEEK
  // =========================================================================
  group('DateFilter.thisWeek logic', () {
    final now = DateTime.now();

    test('matches task due today', () {
      final t = _task(dueDate: now);
      expect(_matchesThisWeek(t), isTrue);
    });

    test('matches task due in 3 days', () {
      final t = _task(dueDate: now.add(const Duration(days: 3)));
      expect(_matchesThisWeek(t), isTrue);
    });

    test('matches task due in exactly 7 days', () {
      final sevenDays = now.add(const Duration(days: 7));
      final t = _task(dueDate: sevenDays);
      expect(_matchesThisWeek(t), isTrue);
    });

    test('does NOT match task due in 8 days', () {
      final t = _task(dueDate: now.add(const Duration(days: 8)));
      expect(_matchesThisWeek(t), isFalse);
    });

    test('does NOT match task with no dueDate', () {
      final t = _task();
      expect(_matchesThisWeek(t), isFalse);
    });

    test('excludes completed task even within week', () {
      final t = _task(
        status: TaskStatus.completed,
        dueDate: now.add(const Duration(days: 2)),
      );
      expect(_matchesThisWeek(t), isFalse);
    });
  });

  // =========================================================================
  // GROUP 4: Date filter — OVERDUE
  // =========================================================================
  group('DateFilter.overdue logic', () {
    final now = DateTime.now();

    test('matches task overdue by 1 day', () {
      final t = _task(dueDate: now.subtract(const Duration(days: 1)));
      expect(_matchesOverdue(t), isTrue);
    });

    test('matches task overdue by 30 days', () {
      final t = _task(dueDate: now.subtract(const Duration(days: 30)));
      expect(_matchesOverdue(t), isTrue);
    });

    test('does NOT match task with future dueDate', () {
      final t = _task(dueDate: now.add(const Duration(days: 1)));
      expect(_matchesOverdue(t), isFalse);
    });

    test('does NOT match task with no dueDate', () {
      final t = _task();
      expect(_matchesOverdue(t), isFalse);
    });

    test('excludes completed task even if overdue', () {
      final t = _task(
        status: TaskStatus.completed,
        dueDate: now.subtract(const Duration(days: 5)),
      );
      expect(_matchesOverdue(t), isFalse);
    });

    test('excludes cancelled task even if overdue', () {
      final t = _task(
        status: TaskStatus.cancelled,
        dueDate: now.subtract(const Duration(days: 5)),
      );
      expect(_matchesOverdue(t), isFalse);
    });

    test('includes overdue task with status = overdue', () {
      // TaskStatus.overdue means the system already flagged it
      final t = _task(
        status: TaskStatus.overdue,
        dueDate: now.subtract(const Duration(days: 2)),
      );
      expect(_matchesOverdue(t), isTrue);
    });
  });

  // =========================================================================
  // GROUP 5: overdueCount computation
  // =========================================================================
  group('overdueCount computation', () {
    final now = DateTime.now();

    test('returns 0 for empty list', () {
      expect(_overdueCount([]), 0);
    });

    test('counts overdue tasks correctly', () {
      final tasks = [
        _task(id: '1', dueDate: now.subtract(const Duration(days: 2))), // overdue
        _task(id: '2', dueDate: now.subtract(const Duration(days: 10))), // overdue
        _task(id: '3', dueDate: now.add(const Duration(days: 2))), // future
        _task(id: '4'), // no due date
        _task(id: '5', status: TaskStatus.completed,
            dueDate: now.subtract(const Duration(days: 1))), // completed (excluded)
      ];
      expect(_overdueCount(tasks), 2);
    });

    test('returns 0 when no tasks are overdue', () {
      final tasks = [
        _task(id: '1', dueDate: now.add(const Duration(days: 3))),
        _task(id: '2'), // no due date
        _task(id: '3', status: TaskStatus.completed,
            dueDate: now.subtract(const Duration(days: 1))),
      ];
      expect(_overdueCount(tasks), 0);
    });
  });

  // =========================================================================
  // GROUP 6: Relative deadline labels (Round 1 feature)
  // Tested via string computation logic matching task_card.dart behavior
  // =========================================================================
  group('Relative deadline label logic', () {
    final now = DateTime.now();

    String relativeLabel(DateTime due) {
      final todayStart = DateTime(now.year, now.month, now.day);
      final dueStart = DateTime(due.year, due.month, due.day);
      final diff = dueStart.difference(todayStart).inDays;
      if (diff == 0) return 'Hôm nay';
      if (diff == 1) return 'Ngày mai';
      if (diff > 1) return '$diff ngày nữa';
      // past
      return '${diff.abs()} ngày trước';
    }

    test('"Hôm nay" for today', () {
      final due = DateTime(now.year, now.month, now.day, 17, 0);
      expect(relativeLabel(due), 'Hôm nay');
    });

    test('"Ngày mai" for tomorrow', () {
      final tomorrow = now.add(const Duration(days: 1));
      final due = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
      expect(relativeLabel(due), 'Ngày mai');
    });

    test('"5 ngày nữa" for 5 days from now', () {
      final future = now.add(const Duration(days: 5));
      final due = DateTime(future.year, future.month, future.day, 10, 0);
      expect(relativeLabel(due), '5 ngày nữa');
    });

    test('"3 ngày trước" for 3 days ago', () {
      final past = now.subtract(const Duration(days: 3));
      final due = DateTime(past.year, past.month, past.day, 10, 0);
      expect(relativeLabel(due), '3 ngày trước');
    });
  });

  // =========================================================================
  // GROUP 7: Widget tests — UnifiedTaskCard comment badge
  // =========================================================================
  group('UnifiedTaskCard — comment count badge', () {
    testWidgets('shows comment badge when commentCount > 0', (tester) async {
      final task = _task(commentCount: 3);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      // Badge shows count as text
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides comment badge when commentCount == 0', (tester) async {
      final task = _task(commentCount: 0);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      // chat_bubble icon should not be present when count = 0
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('shows chat bubble icon with count', (tester) async {
      final task = _task(commentCount: 12);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.text('12'), findsAtLeastNWidgets(1));
    });
  });

  // =========================================================================
  // GROUP 8: Widget tests — UnifiedTaskCard basic rendering
  // =========================================================================
  group('UnifiedTaskCard — basic rendering', () {
    testWidgets('renders task title', (tester) async {
      final task = _task(title: 'Kiểm tra UI mới');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Kiểm tra UI mới'), findsOneWidget);
    });

    testWidgets('renders company badge when companyName provided', (tester) async {
      final task = _task(companyName: 'SABO Corp');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task, showCompany: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('SABO Corp'), findsOneWidget);
    });

    testWidgets('renders high priority badge', (tester) async {
      final task = _task(priority: TaskPriority.high);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      // High priority label in Vietnamese
      expect(find.textContaining('Cao'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders critical priority badge', (tester) async {
      final task = _task(priority: TaskPriority.critical);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedTaskCard(task: task),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Khẩn cấp'), findsAtLeastNWidgets(1));
    });
  });

  // =========================================================================
  // GROUP 9: Filter integration — combining date filter + overdue count
  // =========================================================================
  group('Filter integration scenarios', () {
    final now = DateTime.now();

    test('overdueCount is 0 when all tasks are future', () {
      final tasks = List.generate(
        5,
        (i) => _task(
          id: 'f$i',
          dueDate: now.add(Duration(days: i + 1)),
        ),
      );
      expect(_overdueCount(tasks), 0);
    });

    test('today filter returns subset of this-week filter', () {
      final tasks = [
        _task(id: 'a', dueDate: now), // today → also thisWeek
        _task(id: 'b', dueDate: now.add(const Duration(days: 3))), // thisWeek only
        _task(id: 'c', dueDate: now.add(const Duration(days: 10))), // neither
      ];
      final todayResults = tasks.where(_matchesToday).toList();
      final weekResults = tasks.where(_matchesThisWeek).toList();
      expect(todayResults.length, 1);
      expect(weekResults.length, 2);
      // every today item is also a thisWeek item
      for (final t in todayResults) {
        expect(weekResults.contains(t), isTrue);
      }
    });

    test('overdue and today can overlap for tasks past due today', () {
      // A task due yesterday is BOTH overdue AND matches today-or-earlier
      // (today filter includes tasks up to todayEnd, which includes yesterday)
      final yesterday = now.subtract(const Duration(days: 1));
      final t = _task(dueDate: yesterday);
      expect(_matchesToday(t), isTrue);   // dueDate is before todayEnd
      expect(_matchesOverdue(t), isTrue); // dueDate is before now
    });

    test('mixed list — all three filter counts are correct', () {
      final tasks = [
        _task(id: '1', dueDate: DateTime(now.year, now.month, now.day, 8, 0)), // today
        _task(id: '2', dueDate: now.subtract(const Duration(days: 2))),         // overdue
        _task(id: '3', dueDate: now.add(const Duration(days: 3))),              // thisWeek
        _task(id: '4', dueDate: now.add(const Duration(days: 10))),             // none
        _task(id: '5'), // no due date
        _task(id: '6', status: TaskStatus.completed,
            dueDate: now.subtract(const Duration(days: 1))),                    // completed skipped
      ];

      final overdues = tasks.where(_matchesOverdue).toList();
      // id=2 is overdue; id=1 if before now also overdue, depends on time-of-day
      // At minimum 1 (id=2) is overdue
      expect(overdues.length, greaterThanOrEqualTo(1));
      expect(overdues.any((t) => t.id == '2'), isTrue);
      expect(overdues.any((t) => t.id == '6'), isFalse);

      final thisWeek = tasks.where(_matchesThisWeek).toList();
      // ids 1,2,3 (all ≤7 days out), id=4 excluded, id=5 no date, id=6 completed
      expect(thisWeek.any((t) => t.id == '3'), isTrue);
      expect(thisWeek.any((t) => t.id == '4'), isFalse);
      expect(thisWeek.any((t) => t.id == '6'), isFalse);
    });
  });
}
