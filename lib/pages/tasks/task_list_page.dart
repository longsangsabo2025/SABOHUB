import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../tasks/task_form_page.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Đang kiểm tra đăng nhập...'),
      );
    }

    if (authState.error != null) {
      return Scaffold(
        body: Center(child: Text('Lỗi xác thực: ${authState.error}')),
      );
    }

    if (authState.user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return _buildMainContent();
  }

  Widget _buildMainContent() {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Nhiệm vụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => _navigateToCreateTask(context),
            icon: const Icon(Icons.add_task, color: Colors.blue),
            tooltip: 'Tạo nhiệm vụ mới',
          ),
          IconButton(
            onPressed: () => _refreshTasks(),
            icon: const Icon(Icons.refresh, color: Colors.blue),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Cần làm'),
            Tab(text: 'Đang làm'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList(null), // Tất cả
          _buildTasksList(TaskStatus.todo),
          _buildTasksList(TaskStatus.inProgress),
          _buildTasksList(TaskStatus.completed),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTask(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhiệm vụ'),
      ),
    );
  }

  Widget _buildTasksList(TaskStatus? status) {
    return Consumer(
      builder: (context, ref, child) {
        final tasksAsync = status == null 
          ? ref.watch(allTasksProvider(null))
          : ref.watch(tasksByStatusProvider((status: status, branchId: null)));

        return tasksAsync.when(
          loading: () => const LoadingIndicator(message: 'Đang tải nhiệm vụ...'),
          error: (error, stack) => _buildErrorWidget(error.toString()),
          data: (tasks) => _buildTasksListView(tasks, status),
        );
      },
    );
  }

  Widget _buildTasksListView(List<Task> tasks, TaskStatus? status) {
    if (tasks.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              
              // Status and Category row
              Row(
                children: [
                  _buildStatusChip(task.status),
                  const SizedBox(width: 8),
                  _buildCategoryChip(task.category),
                  const Spacer(),
                  if (task.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Quá hạn',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignedToName ?? 'Chưa giao',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(task.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: task.isDueSoon ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),

              // Action buttons
              if (task.status != TaskStatus.completed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (task.status == TaskStatus.todo)
                      _buildActionButton(
                        'Bắt đầu',
                        Icons.play_arrow,
                        Colors.blue,
                        () => _updateTaskStatus(task, TaskStatus.inProgress),
                      ),
                    if (task.status == TaskStatus.inProgress) ...[
                      _buildActionButton(
                        'Hoàn thành',
                        Icons.check,
                        Colors.green,
                        () => _updateTaskStatus(task, TaskStatus.completed),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        'Tạm dừng',
                        Icons.pause,
                        Colors.orange,
                        () => _updateTaskStatus(task, TaskStatus.todo),
                      ),
                    ],
                    const Spacer(),
                    _buildActionButton(
                      'Sửa',
                      Icons.edit,
                      Colors.grey[600]!,
                      () => _editTask(task),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 12,
          color: priority.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: status.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TaskCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontSize: 12,
          color: category.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(TaskStatus? status) {
    String message;
    IconData icon;
    
    switch (status) {
      case TaskStatus.todo:
        message = 'Không có nhiệm vụ cần làm';
        icon = Icons.task_alt;
        break;
      case TaskStatus.inProgress:
        message = 'Không có nhiệm vụ đang thực hiện';
        icon = Icons.hourglass_empty;
        break;
      case TaskStatus.completed:
        message = 'Chưa có nhiệm vụ hoàn thành';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'Chưa có nhiệm vụ nào';
        icon = Icons.assignment_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTask(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo nhiệm vụ đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _refreshTasks(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Quá hạn ${difference.inDays.abs()} ngày';
    } else if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Ngày mai';
    } else {
      return '${difference.inDays} ngày nữa';
    }
  }

  void _navigateToCreateTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormPage(),
      ),
    ).then((result) {
      if (result == true) {
        _refreshTasks();
      }
    });
  }

  void _editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormPage(task: task),
      ),
    ).then((result) {
      if (result == true) {
        _refreshTasks();
      }
    });
  }

  void _updateTaskStatus(Task task, TaskStatus newStatus) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateTaskStatus(task.id, newStatus);
      _showSnackBar('Cập nhật trạng thái thành công', Colors.green);
      _refreshTasks();
    } catch (e) {
      _showSnackBar('Lỗi cập nhật: $e', Colors.red);
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mô tả: ${task.description}'),
              const SizedBox(height: 8),
              Text('Danh mục: ${task.category.label}'),
              const SizedBox(height: 8),
              Text('Ưu tiên: ${task.priority.label}'),
              const SizedBox(height: 8),
              Text('Trạng thái: ${task.status.label}'),
              const SizedBox(height: 8),
              Text('Người thực hiện: ${task.assignedToName ?? 'Chưa giao'}'),
              const SizedBox(height: 8),
              Text('Hạn: ${_formatDueDate(task.dueDate)}'),
              if (task.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text('Ghi chú: ${task.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (task.status != TaskStatus.completed)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editTask(task);
              },
              child: const Text('Chỉnh sửa'),
            ),
        ],
      ),
    );
  }

  void _refreshTasks() {
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksByStatusProvider);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
