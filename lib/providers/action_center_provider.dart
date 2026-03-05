import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';
import 'auth_provider.dart';

/// Model for an action item that needs user attention
class ActionItem {
  final String id;
  final String type; // task, approval, overdue_payment, attendance, notification
  final String title;
  final String? subtitle;
  final String? description;
  final IconData icon;
  final Color color;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime? dueDate;
  final DateTime createdAt;
  final bool isUrgent;

  const ActionItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    required this.icon,
    required this.color,
    this.actionUrl,
    this.data,
    this.dueDate,
    required this.createdAt,
    this.isUrgent = false,
  });

  /// Priority for sorting (lower = more urgent)
  int get sortPriority {
    if (isUrgent) return 0;
    if (dueDate != null) {
      final now = DateTime.now();
      if (dueDate!.isBefore(now)) return 1; // Overdue
      if (dueDate!.difference(now).inHours < 24) return 2; // Due today
    }
    switch (type) {
      case 'approval':
        return 3;
      case 'task':
        return 4;
      case 'overdue_payment':
        return 5;
      default:
        return 10;
    }
  }
}

/// Summary of action items by type
class ActionSummary {
  final int pendingTasks;
  final int overdueTasks;
  final int pendingApprovals;
  final int overduePayments;
  final int unreadNotifications;
  final DateTime? lastUpdated;

  const ActionSummary({
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.pendingApprovals = 0,
    this.overduePayments = 0,
    this.unreadNotifications = 0,
    this.lastUpdated,
  });

  int get totalCount =>
      pendingTasks + overdueTasks + pendingApprovals + overduePayments;

  bool get hasUrgentItems => overdueTasks > 0 || overduePayments > 0;
}

/// Provider for action center summary
final actionSummaryProvider =
    FutureProvider.autoDispose<ActionSummary>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const ActionSummary();

  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  try {
    // Parallel fetch all counts
    final results = await Future.wait([
      // Pending tasks assigned to user
      supabase
          .from('tasks')
          .select('id')
          .eq('assigned_to', user.id)
          .inFilter('status', ['pending', 'in_progress'])
          .isFilter('deleted_at', null)
          .count(CountOption.exact),

      // Overdue tasks
      supabase
          .from('tasks')
          .select('id')
          .eq('assigned_to', user.id)
          .inFilter('status', ['pending', 'in_progress'])
          .lt('due_date', now.toIso8601String())
          .isFilter('deleted_at', null)
          .count(CountOption.exact),

      // Pending approvals (if user can approve)
      supabase
          .from('task_approvals')
          .select('id')
          .eq('status', 'pending')
          .or('approver_id.eq.${user.id},requested_by.eq.${user.id}')
          .count(CountOption.exact),

      // Unread notifications
      supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count(CountOption.exact),
    ]);

    return ActionSummary(
      pendingTasks: results[0].count,
      overdueTasks: results[1].count,
      pendingApprovals: results[2].count,
      unreadNotifications: results[3].count,
      lastUpdated: DateTime.now(),
    );
  } catch (e) {
    AppLogger.error('Failed to fetch action summary', e);
    return const ActionSummary();
  }
});

/// Provider for full list of action items
final actionItemsProvider =
    FutureProvider.autoDispose<List<ActionItem>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final items = <ActionItem>[];

  try {
    // Fetch tasks
    final tasksResponse = await supabase
        .from('tasks')
        .select('id, title, description, priority, status, due_date, created_at, company_id')
        .eq('assigned_to', user.id)
        .inFilter('status', ['pending', 'in_progress'])
        .isFilter('deleted_at', null)
        .order('due_date', ascending: true)
        .limit(20);

    for (final task in tasksResponse as List) {
      final dueDate = task['due_date'] != null
          ? DateTime.parse(task['due_date'])
          : null;
      final isOverdue = dueDate != null && dueDate.isBefore(now);
      final priority = task['priority'] as String? ?? 'medium';

      items.add(ActionItem(
        id: 'task_${task['id']}',
        type: 'task',
        title: task['title'] ?? 'Không có tiêu đề',
        subtitle: _taskSubtitle(task['status'], priority, dueDate, isOverdue),
        description: task['description'],
        icon: Icons.task_alt,
        color: isOverdue
            ? Colors.red
            : priority == 'urgent' || priority == 'high'
                ? Colors.orange
                : Colors.blue,
        actionUrl: '/ceo/tasks/${task['id']}',
        dueDate: dueDate,
        createdAt: DateTime.parse(task['created_at']),
        isUrgent: isOverdue || priority == 'urgent',
        data: task,
      ));
    }

    // Fetch pending approvals
    final approvalsResponse = await supabase
        .from('task_approvals')
        .select('id, type, title, description, status, created_at, task_id')
        .eq('status', 'pending')
        .or('approver_id.eq.${user.id},requested_by.eq.${user.id}')
        .order('created_at', ascending: false)
        .limit(10);

    for (final approval in approvalsResponse as List) {
      items.add(ActionItem(
        id: 'approval_${approval['id']}',
        type: 'approval',
        title: approval['title'] ?? 'Yêu cầu phê duyệt',
        subtitle: 'Loại: ${_approvalTypeLabel(approval['type'])}',
        description: approval['description'],
        icon: Icons.approval,
        color: Colors.amber,
        actionUrl: approval['task_id'] != null
            ? '/ceo/tasks/${approval['task_id']}'
            : null,
        createdAt: DateTime.parse(approval['created_at']),
        isUrgent: true,
        data: approval,
      ));
    }

    // Sort by priority
    items.sort((a, b) {
      final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return items;
  } catch (e) {
    AppLogger.error('Failed to fetch action items', e);
    return [];
  }
});

String _taskSubtitle(
    String? status, String priority, DateTime? dueDate, bool isOverdue) {
  final parts = <String>[];

  if (isOverdue && dueDate != null) {
    final overdueDays = DateTime.now().difference(dueDate).inDays;
    parts.add('Quá hạn ${overdueDays > 0 ? "$overdueDays ngày" : "hôm nay"}');
  } else if (dueDate != null) {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    if (daysLeft == 0) {
      parts.add('Hết hạn hôm nay');
    } else if (daysLeft == 1) {
      parts.add('Hết hạn ngày mai');
    } else if (daysLeft <= 7) {
      parts.add('Còn $daysLeft ngày');
    }
  }

  parts.add(_priorityLabel(priority));
  parts.add(_statusLabel(status));

  return parts.join(' • ');
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'urgent':
      return 'Khẩn cấp';
    case 'high':
      return 'Cao';
    case 'low':
      return 'Thấp';
    default:
      return 'Trung bình';
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Chờ xử lý';
    case 'in_progress':
      return 'Đang làm';
    default:
      return '';
  }
}

String _approvalTypeLabel(String? type) {
  switch (type) {
    case 'report':
      return 'Báo cáo';
    case 'budget':
      return 'Ngân sách';
    case 'proposal':
      return 'Đề xuất';
    default:
      return 'Khác';
  }
}
