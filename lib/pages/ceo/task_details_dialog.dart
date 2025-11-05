import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import 'edit_task_dialog.dart';

class TaskDetailsDialog extends ConsumerWidget {
  final Task task;

  const TaskDetailsDialog({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết công việc',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Xem thông tin chi tiết',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    _buildSection(
                      context,
                      'Tiêu đề',
                      Icons.title,
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    if (task.description.isNotEmpty)
                      _buildSection(
                        context,
                        'Mô tả',
                        Icons.description,
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),

                    if (task.description.isNotEmpty) const SizedBox(height: 24),

                    // Status & Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSection(
                            context,
                            'Trạng thái',
                            Icons.flag,
                            _buildStatusChip(context, task.status),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSection(
                            context,
                            'Mức độ',
                            Icons.priority_high,
                            _buildPriorityChip(context, task.priority),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Section
                    _buildSection(
                      context,
                      'Danh mục',
                      Icons.category,
                      _buildCategoryChip(context, task.category),
                    ),

                    const SizedBox(height: 24),

                    // Assigned To Section
                    if (task.assignedToName != null &&
                        task.assignedToName!.isNotEmpty)
                      _buildSection(
                        context,
                        'Người được giao',
                        Icons.person,
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                task.assignedToName![0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              task.assignedToName!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),

                    if (task.assignedToName != null &&
                        task.assignedToName!.isNotEmpty)
                      const SizedBox(height: 24),

                    // Due Date Section
                    _buildSection(
                      context,
                      'Hạn hoàn thành',
                      Icons.calendar_today,
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: _isDueDateOverdue(task.dueDate)
                                ? Colors.red
                                : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: _isDueDateOverdue(task.dueDate)
                                      ? Colors.red
                                      : null,
                                  fontWeight: _isDueDateOverdue(task.dueDate)
                                      ? FontWeight.bold
                                      : null,
                                ),
                          ),
                          if (_isDueDateOverdue(task.dueDate)) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '(Quá hạn)',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Created By Section
                    if (task.createdByName.isNotEmpty)
                      _buildSection(
                        context,
                        'Người tạo',
                        Icons.person_outline,
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: Text(
                                task.createdByName[0].toUpperCase(),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              task.createdByName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),

                    if (task.createdByName.isNotEmpty)
                      const SizedBox(height: 24),

                    // Created At Section
                    _buildSection(
                      context,
                      'Ngày tạo',
                      Icons.access_time,
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notes Section
                    if (task.notes != null && task.notes!.isNotEmpty)
                      _buildSection(
                        context,
                        'Ghi chú',
                        Icons.notes,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            task.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Đóng'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      // Close this dialog first
                      Navigator.of(context).pop(false);

                      // Open edit dialog
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => EditTaskDialog(
                          task: task,
                          companyId: task.companyId ?? '', // Use companyId from task
                        ),
                      );

                      // If edit was successful, notify parent to refresh
                      if (result == true && context.mounted) {
                        // Return true to indicate data changed
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, TaskStatus status) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.todo:
        color = Colors.orange;
        label = 'Cần làm';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        label = 'Đang thực hiện';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = 'Hoàn thành';
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        label = 'Đã hủy';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildPriorityChip(BuildContext context, TaskPriority priority) {
    Color color;
    String label;
    IconData icon;

    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        label = 'Thấp';
        icon = Icons.arrow_downward;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Trung bình';
        icon = Icons.remove;
        break;
      case TaskPriority.high:
        color = Colors.red;
        label = 'Cao';
        icon = Icons.arrow_upward;
        break;
      case TaskPriority.urgent:
        color = Colors.purple;
        label = 'Khẩn cấp';
        icon = Icons.priority_high;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildCategoryChip(BuildContext context, TaskCategory category) {
    String label;

    switch (category) {
      case TaskCategory.operations:
        label = 'Vận hành';
        break;
      case TaskCategory.maintenance:
        label = 'Bảo trì';
        break;
      case TaskCategory.inventory:
        label = 'Kho hàng';
        break;
      case TaskCategory.customerService:
        label = 'Khách hàng';
        break;
      case TaskCategory.other:
        label = 'Khác';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: Theme.of(context).primaryColor),
    );
  }

  bool _isDueDateOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}
