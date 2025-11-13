import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
import '../../services/management_task_service.dart';

/// CEO Task Management Page
/// Full CRUD operations for all tasks in the system
class CEOTaskManagementPage extends ConsumerStatefulWidget {
  const CEOTaskManagementPage({super.key});

  @override
  ConsumerState<CEOTaskManagementPage> createState() =>
      _CEOTaskManagementPageState();
}

class _CEOTaskManagementPageState
    extends ConsumerState<CEOTaskManagementPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterPriority = 'all';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(ceoStrategicTasksStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // Apply filters
                final filteredTasks = _applyFilters(tasks);

                if (filteredTasks.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildTaskList(filteredTasks);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhiệm vụ'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Quản lý tất cả nhiệm vụ',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới',
          onPressed: () {
            ref.invalidate(ceoStrategicTasksStreamProvider);
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhiệm vụ...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Trạng thái: ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tất cả', 'all', _filterStatus,
                          (value) {
                        setState(() => _filterStatus = value);
                      }),
                      _buildFilterChip('Chờ', 'pending', _filterStatus,
                          (value) {
                        setState(() => _filterStatus = value);
                      }),
                      _buildFilterChip('Đang làm', 'in_progress', _filterStatus,
                          (value) {
                        setState(() => _filterStatus = value);
                      }),
                      _buildFilterChip(
                          'Hoàn thành', 'completed', _filterStatus, (value) {
                        setState(() => _filterStatus = value);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Ưu tiên: ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tất cả', 'all', _filterPriority,
                          (value) {
                        setState(() => _filterPriority = value);
                      }),
                      _buildFilterChip('Cao', 'high', _filterPriority, (value) {
                        setState(() => _filterPriority = value);
                      }),
                      _buildFilterChip(
                          'Trung bình', 'medium', _filterPriority, (value) {
                        setState(() => _filterPriority = value);
                      }),
                      _buildFilterChip('Thấp', 'low', _filterPriority, (value) {
                        setState(() => _filterPriority = value);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue,
      ),
    );
  }

  List<ManagementTask> _applyFilters(List<ManagementTask> tasks) {
    return tasks.where((task) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery) ||
          (task.description?.toLowerCase().contains(_searchQuery) ?? false);

      // Status filter
      final matchesStatus = _filterStatus == 'all' ||
          task.status.value.toLowerCase() == _filterStatus;

      // Priority filter
      final matchesPriority = _filterPriority == 'all' ||
          task.priority.value.toLowerCase() == _filterPriority;

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không có nhiệm vụ nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút bên dưới để tạo nhiệm vụ mới',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<ManagementTask> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(ManagementTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTaskDetailsDialog(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityBadge(task.priority),
                  const SizedBox(width: 8),
                  _buildStatusBadge(task.status),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () => _showEditTaskDialog(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => _confirmDeleteTask(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${task.progress}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getProgressColor(task.progress),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: task.progress / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(task.progress),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Giao cho: ${task.assignedToName ?? 'Chưa giao'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate != null
                        ? _dateFormat.format(task.dueDate!)
                        : 'Chưa có hạn',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Colors.red.shade700;
      case TaskPriority.high:
        return Colors.red.shade600;
      case TaskPriority.medium:
        return Colors.orange.shade600;
      case TaskPriority.low:
        return Colors.blue.shade600;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey.shade600;
      case TaskStatus.inProgress:
        return Colors.blue.shade600;
      case TaskStatus.completed:
        return Colors.green.shade600;
      case TaskStatus.overdue:
        return Colors.red.shade600;
      case TaskStatus.cancelled:
        return Colors.orange.shade800;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 75) return Colors.green.shade600;
    if (progress >= 50) return Colors.orange.shade600;
    if (progress >= 25) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  void _showTaskDetailsDialog(ManagementTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết nhiệm vụ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tiêu đề', task.title),
              _buildDetailRow('Mô tả', task.description ?? 'Không có'),
              _buildDetailRow('Ưu tiên', task.priority.label),
              _buildDetailRow('Trạng thái', task.status.label),
              _buildDetailRow('Tiến độ', '${task.progress}%'),
              _buildDetailRow('Giao cho', task.assignedToName ?? 'Chưa giao'),
              _buildDetailRow(
                'Hạn',
                task.dueDate != null
                    ? _dateFormat.format(task.dueDate!)
                    : 'Chưa có',
              ),
              _buildDetailRow(
                'Ngày tạo',
                _dateFormat.format(task.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTaskDialog(task);
            },
            child: const Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    // Implement create task dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng tạo nhiệm vụ - sử dụng dialog có sẵn'),
      ),
    );
  }

  void _showEditTaskDialog(ManagementTask task) {
    // Implement edit task dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chỉnh sửa: ${task.title}'),
      ),
    );
  }

  void _confirmDeleteTask(ManagementTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhiệm vụ "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTask(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(ManagementTask task) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.deleteTask(task.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xóa nhiệm vụ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
