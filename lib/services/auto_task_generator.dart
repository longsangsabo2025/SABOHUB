import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/supabase_service.dart';
import '../models/task_template.dart';
import '../providers/auth_provider.dart';

final autoTaskGeneratorProvider =
    Provider((ref) => AutoTaskGenerator(ref));

class AutoTaskGenerator {
  final _supabase = supabase.client;
  final Ref _ref;

  AutoTaskGenerator(this._ref);

  Future<AutoGenResult> generateTodayTasks() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return AutoGenResult.empty();

    final companyId = user.companyId;
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T').first;

    var query = _supabase
        .from('task_templates')
        .select('*')
        .eq('is_active', true)
        .not('recurrence_pattern', 'is', null);

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query;
    final templates = (response as List)
        .map((j) => TaskTemplate.fromJson(j))
        .toList();

    int created = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final template in templates) {
      if (!_isDueToday(template, today)) {
        continue;
      }

      final alreadyExists = await _taskExistsToday(
        template.id,
        todayStr,
        companyId,
      );

      if (alreadyExists) {
        skipped++;
        continue;
      }

      try {
        final assignee = template.assignedUserId;
        if (assignee == null || assignee.isEmpty) {
          skipped++;
          continue;
        }

        final dueDate = today.add(const Duration(hours: 23, minutes: 59));

        await _supabase.from('tasks').insert({
          'title': template.title,
          'description': template.description,
          'priority': template.priority,
          'status': 'pending',
          'progress': 0,
          'created_by': user.id,
          'assigned_to': assignee,
          'company_id': companyId,
          'due_date': dueDate.toIso8601String(),
          if (template.category != null) 'category': template.category,
          if (template.recurrencePattern != null)
            'recurrence': template.recurrencePattern,
          if (template.checklistItems != null &&
              template.checklistItems!.isNotEmpty)
            'checklist': template.checklistItems!
                .map((item) => {
                      'id':
                          '${DateTime.now().millisecondsSinceEpoch}_${item['id'] ?? ''}',
                      'title': item['title'],
                      'is_done': false,
                    })
                .toList(),
          'template_id': template.id,
        });

        await _supabase.from('task_templates').update({
          'last_generated_at': DateTime.now().toIso8601String(),
        }).eq('id', template.id);

        created++;
      } catch (e) {
        errors.add('${template.title}: $e');
      }
    }

    return AutoGenResult(
      totalTemplates: templates.length,
      created: created,
      skipped: skipped,
      errors: errors,
    );
  }

  bool _isDueToday(TaskTemplate template, DateTime today) {
    switch (template.recurrencePattern) {
      case 'daily':
        return true;
      case 'weekly':
        final scheduledDays = template.scheduledDays;
        if (scheduledDays == null || scheduledDays.isEmpty) {
          return today.weekday == DateTime.monday;
        }
        return scheduledDays.contains(today.weekday);
      case 'monthly':
        final scheduledDays = template.scheduledDays;
        if (scheduledDays == null || scheduledDays.isEmpty) {
          return today.day == 1;
        }
        return scheduledDays.contains(today.day);
      default:
        return false;
    }
  }

  Future<bool> _taskExistsToday(
    String templateId,
    String todayStr,
    String? companyId,
  ) async {
    try {
      var query = _supabase
          .from('tasks')
          .select('id')
          .eq('template_id', templateId)
          .gte('created_at', '${todayStr}T00:00:00')
          .lt('created_at', '${todayStr}T23:59:59');

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final result = await query;
      return (result as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<TodayTaskStats> getTodayStats() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return TodayTaskStats.empty();

    final companyId = user.companyId;
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    var query = _supabase
        .from('tasks')
        .select('id, title, status, priority, progress, assigned_to, '
            'assigned_to_name, category, due_date, checklist, recurrence')
        .gte('created_at', '${todayStr}T00:00:00');

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final response = await query.order('created_at', ascending: false);
    final tasks = List<Map<String, dynamic>>.from(response);

    final total = tasks.length;
    final completed =
        tasks.where((t) => t['status'] == 'completed').length;
    final inProgress =
        tasks.where((t) => t['status'] == 'in_progress').length;
    final pending =
        tasks.where((t) => t['status'] == 'pending').length;

    final byAssignee = <String, List<Map<String, dynamic>>>{};
    for (final t in tasks) {
      final name = t['assigned_to_name'] as String? ?? 'Chưa giao';
      byAssignee.putIfAbsent(name, () => []).add(t);
    }

    return TodayTaskStats(
      total: total,
      completed: completed,
      inProgress: inProgress,
      pending: pending,
      tasks: tasks,
      byAssignee: byAssignee,
    );
  }

  Future<int> getRecurringTemplateCount() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return 0;

    var query = _supabase
        .from('task_templates')
        .select('id')
        .eq('is_active', true)
        .not('recurrence_pattern', 'is', null);

    if (user.companyId != null) {
      query = query.eq('company_id', user.companyId!);
    }

    final result = await query;
    return (result as List).length;
  }
}

class AutoGenResult {
  final int totalTemplates;
  final int created;
  final int skipped;
  final List<String> errors;

  const AutoGenResult({
    required this.totalTemplates,
    required this.created,
    required this.skipped,
    required this.errors,
  });

  factory AutoGenResult.empty() => const AutoGenResult(
        totalTemplates: 0,
        created: 0,
        skipped: 0,
        errors: [],
      );

  bool get hasErrors => errors.isNotEmpty;
  String get summary =>
      'Đã tạo $created task${skipped > 0 ? ', bỏ qua $skipped (đã tồn tại hoặc chưa giao)' : ''}';
}

class TodayTaskStats {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final List<Map<String, dynamic>> tasks;
  final Map<String, List<Map<String, dynamic>>> byAssignee;

  const TodayTaskStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.tasks,
    required this.byAssignee,
  });

  factory TodayTaskStats.empty() => const TodayTaskStats(
        total: 0,
        completed: 0,
        inProgress: 0,
        pending: 0,
        tasks: [],
        byAssignee: {},
      );

  double get completionRate => total > 0 ? completed / total : 0;
}
