import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
import 'task_detail_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class KanbanBoardPage extends ConsumerStatefulWidget {
  const KanbanBoardPage({super.key});

  @override
  ConsumerState<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends ConsumerState<KanbanBoardPage> {
  final _dateFormat = DateFormat('dd/MM');

  static const _columns = [
    ('pending', 'Chờ xử lý', Colors.orange),
    ('in_progress', 'Đang thực hiện', Colors.blue),
    ('completed', 'Hoàn thành', Colors.green),
    ('overdue', 'Quá hạn', Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(ceoStrategicTasksProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Kanban Board'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface87,
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildBoard(tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  List<ManagementTask> _getColumnTasks(
      List<ManagementTask> tasks, String statusValue) {
    final now = DateTime.now();
    if (statusValue == 'overdue') {
      return tasks.where((t) {
        if (t.status.value == 'overdue') return true;
        if (t.status.value == 'completed' || t.status.value == 'cancelled') {
          return false;
        }
        return t.dueDate != null && t.dueDate!.isBefore(now);
      }).toList();
    }
    return tasks.where((t) {
      if (t.status.value != statusValue) return false;
      if (statusValue == 'pending' || statusValue == 'in_progress') {
        return t.dueDate == null || !t.dueDate!.isBefore(now);
      }
      return true;
    }).toList();
  }

  Widget _buildBoard(List<ManagementTask> tasks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((col) {
              final columnTasks = _getColumnTasks(tasks, col.$1);
              return Expanded(
                child: _buildColumn(col.$1, col.$2, col.$3, columnTasks),
              );
            }).toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((col) {
              final columnTasks = _getColumnTasks(tasks, col.$1);
              return SizedBox(
                width: 300,
                child: _buildColumn(col.$1, col.$2, col.$3, columnTasks),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildColumn(
      String statusValue, String title, Color color, List<ManagementTask> tasks) {
    return DragTarget<ManagementTask>(
      onAcceptWithDetails: (details) async {
        final task = details.data;
        if (task.status.value == statusValue) return;
        try {
          await ref.read(managementTaskServiceProvider).updateTaskStatus(
                taskId: task.id,
                status: statusValue,
              );
          ref.invalidate(ceoStrategicTasksProvider);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e')),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isHovering
                ? color.withValues(alpha: 0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColumnHeader(title, color, tasks.length),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) => _buildDraggableCard(tasks[i], color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeader(String title, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableCard(ManagementTask task, Color columnColor) {
    return Draggable<ManagementTask>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 280,
          child: _buildTaskCard(task, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCard(task),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
          );
        },
        child: _buildTaskCard(task),
      ),
    );
  }

  Widget _buildTaskCard(ManagementTask task, {bool isDragging = false}) {
    final priorityColor = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    }[task.priority.value] ?? Colors.grey;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: isDragging ? 0.15 : 0.05),
            blurRadius: isDragging ? 12 : 4,
            offset: isDragging ? const Offset(0, 4) : Offset.zero,
          ),
        ],
        border: Border(
          left: BorderSide(color: priorityColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (task.category != TaskCategory.general)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(task.category.displayName,
                      style: const TextStyle(fontSize: 10)),
                ),
              if (task.isRecurring)
                const Icon(Icons.repeat, size: 14, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 4),
          Text(task.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (task.assignedToName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(task.assignedToName!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (task.hasChecklist)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${task.checklistDone}/${task.checklistTotal}',
                    style: TextStyle(
                        fontSize: 11,
                        color: task.checklistDone == task.checklistTotal
                            ? Colors.green
                            : Colors.grey.shade600),
                  ),
                ),
              if (task.dueDate != null)
                Text(_dateFormat.format(task.dueDate!),
                    style: TextStyle(
                        fontSize: 11,
                        color: task.dueDate!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.grey.shade600)),
              const Spacer(),
              if (task.progress > 0)
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    value: task.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.green),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 4,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
