import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/auto_task_generator.dart';
import 'task_detail_page.dart';
import '../../models/management_task.dart';

final _todayStatsProvider = FutureProvider<TodayTaskStats>((ref) {
  return ref.read(autoTaskGeneratorProvider).getTodayStats();
});

final _templateCountProvider = FutureProvider<int>((ref) {
  return ref.read(autoTaskGeneratorProvider).getRecurringTemplateCount();
});

class CEOTodayPage extends ConsumerStatefulWidget {
  const CEOTodayPage({super.key});

  @override
  ConsumerState<CEOTodayPage> createState() => _CEOTodayPageState();
}

class _CEOTodayPageState extends ConsumerState<CEOTodayPage> {
  bool _isGenerating = false;
  AutoGenResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_todayStatsProvider);
    final templateCountAsync = ref.watch(_templateCountProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hôm nay'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              _buildGenerateButton(templateCountAsync),
              const SizedBox(height: 8),

              if (_lastResult != null) _buildResultBanner(_lastResult!),
              const SizedBox(height: 16),

              statsAsync.when(
                data: (stats) => _buildStatsAndTasks(stats),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Lỗi: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(_todayStatsProvider);
    ref.invalidate(_templateCountProvider);
  }

  Widget _buildGenerateButton(AsyncValue<int> templateCountAsync) {
    final count = templateCountAsync.when(
      data: (v) => v,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rocket_launch,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giao việc hôm nay',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('$count template lặp lại đang hoạt động',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isGenerating || count == 0 ? null : _generateTasks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(count == 0
                      ? 'Chưa có template — Tạo template trước'
                      : 'Tạo task cho hôm nay'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTasks() async {
    setState(() => _isGenerating = true);
    try {
      final result =
          await ref.read(autoTaskGeneratorProvider).generateTodayTasks();
      setState(() => _lastResult = result);
      _refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            backgroundColor:
                result.hasErrors ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Widget _buildResultBanner(AutoGenResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hasErrors
            ? Colors.orange.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result.hasErrors
              ? Colors.orange.shade200
              : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.hasErrors ? Icons.warning_amber : Icons.check_circle,
            color: result.hasErrors ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(result.summary,
                style: const TextStyle(fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _lastResult = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndTasks(TodayTaskStats stats) {
    if (stats.total == 0) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressHeader(stats),
        const SizedBox(height: 16),
        _buildStatCards(stats),
        const SizedBox(height: 20),
        _buildAssigneeBreakdown(stats),
        const SizedBox(height: 20),
        _buildTaskList(stats),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có task hôm nay',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Bấm "Tạo task cho hôm nay" để bắt đầu',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(TodayTaskStats stats) {
    final pct = (stats.completionRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Tiến độ hôm nay',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade800)),
              const Spacer(),
              Text('$pct%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: pct == 100 ? Colors.green : Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.completionRate,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                  pct == 100 ? Colors.green : Colors.blue),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.completed}/${stats.total} task hoàn thành',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(TodayTaskStats stats) {
    return Row(
      children: [
        _miniCard('Chờ xử lý', '${stats.pending}', Colors.orange),
        const SizedBox(width: 10),
        _miniCard('Đang làm', '${stats.inProgress}', Colors.blue),
        const SizedBox(width: 10),
        _miniCard('Xong', '${stats.completed}', Colors.green),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeBreakdown(TodayTaskStats stats) {
    if (stats.byAssignee.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theo nhân viên',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...stats.byAssignee.entries.map((entry) {
            final name = entry.key;
            final tasks = entry.value;
            final done =
                tasks.where((t) => t['status'] == 'completed').length;
            final total = tasks.length;
            final pct = total > 0 ? done / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                                done == total
                                    ? Colors.green
                                    : Colors.blue),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$done/$total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: done == total
                              ? Colors.green
                              : Colors.grey.shade700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskList(TodayTaskStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tất cả task hôm nay',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ...stats.tasks.map(_buildTaskRow),
      ],
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task) {
    final status = task['status'] as String? ?? 'pending';
    final priority = task['priority'] as String? ?? 'medium';
    final title = task['title'] as String? ?? '';
    final assignee = task['assigned_to_name'] as String? ?? '';
    final category = task['category'] as String?;
    final progress = (task['progress'] as num?)?.toInt() ?? 0;

    final statusColor = {
      'completed': Colors.green,
      'in_progress': Colors.blue,
      'pending': Colors.orange,
    }[status] ??
        Colors.grey;

    final statusIcon = {
      'completed': Icons.check_circle,
      'in_progress': Icons.play_circle_filled,
      'pending': Icons.radio_button_unchecked,
    }[status] ??
        Icons.help;

    final priorityColor = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    }[priority] ??
        Colors.grey;

    final categoryEmoji = {
      'media': '📱',
      'billiards': '🎱',
      'arena': '🎮',
      'operations': '⚙️',
      'general': '🏢',
    }[category ?? 'general'] ??
        '🏢';

    return GestureDetector(
      onTap: () {
        try {
          final mgTask = ManagementTask.fromJson(task);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskDetailPage(task: mgTask)),
          );
        } catch (_) {}
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: priorityColor, width: 3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4)
          ],
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (category != null && category != 'general')
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(categoryEmoji,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              decoration: status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: status == 'completed'
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(assignee,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (progress > 0 && status != 'completed')
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Text('$progress%',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.green),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
