import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../utils/dummy_providers.dart';
import '../../widgets/multi_account_switcher.dart';

/// Manager Tasks Page
/// Three main sections: Tasks from CEO, Assign to Staff, My Tasks
class ManagerTasksPage extends ConsumerStatefulWidget {
  const ManagerTasksPage({super.key});

  @override
  ConsumerState<ManagerTasksPage> createState() => _ManagerTasksPageState();
}

class _ManagerTasksPageState extends ConsumerState<ManagerTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFromCEOTab(),
                _buildAssignTasksTab(),
                _buildMyTasksTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showCreateTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo công việc'),
              backgroundColor: Colors.green.shade600,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Quản lý Công việc',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        // Multi-Account Switcher
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            // Filter tasks
          },
          icon: const Icon(Icons.filter_list, color: Colors.black87),
        ),
        IconButton(
          onPressed: () {
            // Search tasks
          },
          icon: const Icon(Icons.search, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.green.shade700,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.arrow_downward),
            text: 'Từ CEO',
          ),
          Tab(
            icon: Icon(Icons.assignment_turned_in),
            text: 'Giao việc',
          ),
          Tab(
            icon: Icon(Icons.work),
            text: 'Việc của tôi',
          ),
        ],
      ),
    );
  }

  // TAB 1: Tasks from CEO
  Widget _buildFromCEOTab() {
    final tasksAsync = ref.watch(cachedManagerAssignedTasksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refreshManagerAssignedTasks(ref);
      },
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải nhiệm vụ: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => refreshManagerAssignedTasks(ref),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cachedTasks) {
          final ceoTasks = cachedTasks;

          if (ceoTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhiệm vụ từ CEO',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(
                'Công việc được giao từ CEO',
                '${ceoTasks.length} công việc',
              ),
              const SizedBox(height: 12),
              ...ceoTasks.map((task) =>
                  _buildManagementTaskCard(task, showAssignedBy: true)),
            ],
          );
        },
      ),
    );
  }

  // TAB 2: Assign tasks to staff
  Widget _buildAssignTasksTab() {
    final tasksAsync = ref.watch(cachedManagerCreatedTasksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refreshManagerCreatedTasks(ref);
      },
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải nhiệm vụ: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => refreshManagerCreatedTasks(ref),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cachedTasks) {
          final assignedTasks = cachedTasks;

          if (assignedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa giao công việc nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để tạo công việc mới',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(
                'Công việc đã giao cho nhân viên',
                '${assignedTasks.length} công việc',
              ),
              const SizedBox(height: 12),
              _buildQuickStats(),
              const SizedBox(height: 16),
              ...assignedTasks.map((task) => _buildManagementTaskCard(task)),
            ],
          );
        },
      ),
    );
  }

  // TAB 3: Manager's personal tasks
  Widget _buildMyTasksTab() {
    final tasksAsync = ref.watch(cachedManagerAssignedTasksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refreshManagerAssignedTasks(ref);
      },
      child: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải nhiệm vụ: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => refreshManagerAssignedTasks(ref),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cachedTasks) {
          final myTasks = cachedTasks;

          if (myTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhiệm vụ cá nhân',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(
                'Công việc của tôi',
                '${myTasks.length} công việc',
              ),
              const SizedBox(height: 12),
              _buildPersonalProgress(),
              const SizedBox(height: 16),
              ...myTasks.map((task) => _buildManagementTaskCard(task)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Đang làm', '2', Icons.hourglass_empty, Colors.orange),
          _buildStatItem('Chờ xử lý', '1', Icons.pending, Colors.blue),
          _buildStatItem('Hoàn thành', '12', Icons.check_circle, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalProgress() {
    final completedTasks = 8;
    final totalTasks = 11;
    final progress = completedTasks / totalTasks;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ công việc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$completedTasks/$totalTasks',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% hoàn thành',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Build card for ManagementTask (from provider)
  Widget _buildManagementTaskCard(
    ManagementTask task, {
    bool showAssignedBy = false,
  }) {
    final String priority = task.priority.toString();
    final String status = task.status.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor(priority).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Show task details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chi tiết: ${task.title}')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityBadge(priority),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // Show options
                    },
                    icon: const Icon(Icons.more_vert, size: 20),
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
                  color: Colors.black87,
                ),
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate != null
                        ? _dateFormat.format(task.dueDate!)
                        : 'Chưa có hạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (showAssignedBy) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Giao bởi: ${task.createdBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    final label = _getPriorityLabel(priority);

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
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'taskpriority.high':
        return Colors.red.shade600;
      case 'medium':
      case 'taskpriority.medium':
        return Colors.orange.shade600;
      case 'low':
      case 'taskpriority.low':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'taskpriority.high':
        return 'Cao';
      case 'medium':
      case 'taskpriority.medium':
        return 'Trung bình';
      case 'low':
      case 'taskpriority.low':
        return 'Thấp';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'taskstatus.pending':
        return Colors.grey.shade600;
      case 'in_progress':
      case 'inprogress':
      case 'taskstatus.inprogress':
        return Colors.blue.shade600;
      case 'completed':
      case 'taskstatus.completed':
        return Colors.green.shade600;
      case 'overdue':
      case 'taskstatus.overdue':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'taskstatus.pending':
        return 'Chờ xử lý';
      case 'in_progress':
      case 'inprogress':
      case 'taskstatus.inprogress':
        return 'Đang làm';
      case 'completed':
      case 'taskstatus.completed':
        return 'Hoàn thành';
      case 'overdue':
      case 'taskstatus.overdue':
        return 'Quá hạn';
      default:
        return 'Không xác định';
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo công việc mới'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // Add more fields: priority, due date, assignee
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Create task
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
