import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
import '../../providers/management_task_provider_cached.dart';

/// CEO Tasks Page
/// CEO can create strategic tasks, assign to managers, and monitor company-wide progress
class CEOTasksPage extends ConsumerStatefulWidget {
  const CEOTasksPage({super.key});

  @override
  ConsumerState<CEOTasksPage> createState() => _CEOTasksPageState();
}

class _CEOTasksPageState extends ConsumerState<CEOTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy');

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
          _buildStatsOverview(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStrategicTasksTab(),
                _buildApprovalTab(),
                _buildCompanyOverviewTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add),
        label: const Text('Tạo nhiệm vụ'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Quản lý công việc',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới dữ liệu',
          onPressed: () {
            // ✅ Refresh cached providers
            refreshAllManagementTasks(ref);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔄 Đã làm mới dữ liệu từ database!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Hồ sơ cá nhân',
          onPressed: () {
            context.push('/profile');
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // TODO: Implement filter
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search
          },
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(cachedTaskStatisticsProvider);

        return statsAsync.when(
          loading: () => Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Lỗi tải thống kê: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          data: (cachedStats) {
            final stats = cachedStats.data;
            final inProgress = stats['in_progress'] ?? 0;
            final pending = stats['pending'] ?? 0;
            final completed = stats['completed'] ?? 0;
            final overdue = stats['overdue'] ?? 0;

            return Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Đang thực hiện',
                      inProgress.toString(),
                      Colors.blue,
                      Icons.pending_actions,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Chờ phê duyệt',
                      pending.toString(),
                      Colors.orange,
                      Icons.approval,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Hoàn thành',
                      completed.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Quá hạn',
                      overdue.toString(),
                      Colors.red,
                      Icons.warning,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Nhiệm vụ chiến lược'),
          Tab(text: 'Chờ phê duyệt'),
          Tab(text: 'Tổng quan công ty'),
        ],
      ),
    );
  }

  Widget _buildStrategicTasksTab() {
    final strategicTasksAsync = ref.watch(cachedCeoStrategicTasksProvider);

    return strategicTasksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải nhiệm vụ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      data: (cachedTasks) {
        final tasks = cachedTasks.data;
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhiệm vụ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để tạo nhiệm vụ chiến lược mới',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...tasks.map((task) => _buildStrategicTaskCard(task)),
          ],
        );
      },
    );
  }

  Widget _buildStrategicTaskCard(ManagementTask task) {
    final priority = task.priority;
    final status = task.status;
    final progress = task.progress;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  _buildPriorityBadge(priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task.companyName ?? 'Chưa xác định',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${task.assignedToName ?? "Chưa giao"} - ${task.assignedToRole ?? ""}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusBadge(status),
                  const Spacer(),
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate != null
                        ? _dateFormat.format(task.dueDate!)
                        : 'Chưa có hạn',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 70
                            ? Colors.green
                            : progress >= 40
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalTab() {
    final approvalsAsync = ref.watch(cachedPendingApprovalsProvider);

    return approvalsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải yêu cầu phê duyệt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      data: (cachedApprovals) {
        final approvals = cachedApprovals.data;
        if (approvals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu chờ phê duyệt',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...approvals.map((item) => _buildApprovalCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildApprovalCard(TaskApproval item) {
    final type = item.type;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getApprovalTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getApprovalTypeColor(type),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.submittedByName ?? item.submittedBy,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  item.companyName ?? 'Chưa xác định',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(item.submittedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleApproval(item, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproval(item, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Phê duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getApprovalTypeColor(ApprovalType type) {
    switch (type) {
      case ApprovalType.report:
        return Colors.blue.shade700;
      case ApprovalType.budget:
        return Colors.purple.shade700;
      case ApprovalType.proposal:
        return Colors.teal.shade700;
      case ApprovalType.other:
        return Colors.grey.shade700;
    }
  }

  Widget _buildCompanyOverviewTab() {
    final companyStatsAsync = ref.watch(cachedCompanyTaskStatisticsProvider);

    return companyStatsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải thống kê công ty',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      data: (cachedCompanies) {
        final companies = cachedCompanies.data;
        if (companies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu công ty',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...companies.map((company) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCompanyProgressCard(
                    companyName:
                        company['company_name'] as String? ?? 'Không xác định',
                    tasksTotal: company['total'] as int? ?? 0,
                    tasksCompleted: company['completed'] as int? ?? 0,
                    tasksInProgress: company['in_progress'] as int? ?? 0,
                    tasksOverdue: company['overdue'] as int? ?? 0,
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildCompanyProgressCard({
    required String companyName,
    required int tasksTotal,
    required int tasksCompleted,
    required int tasksInProgress,
    required int tasksOverdue,
  }) {
    final completionRate =
        tasksTotal > 0 ? (tasksCompleted / tasksTotal * 100).round() : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completionRate%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                      'Tổng', tasksTotal.toString(), Colors.grey),
                ),
                Expanded(
                  child: _buildMiniStat(
                      'Hoàn thành', tasksCompleted.toString(), Colors.green),
                ),
                Expanded(
                  child: _buildMiniStat(
                      'Đang làm', tasksInProgress.toString(), Colors.blue),
                ),
                Expanded(
                  child: _buildMiniStat(
                      'Quá hạn', tasksOverdue.toString(), Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 80 ? Colors.green : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    String label = priority.label;

    switch (priority) {
      case TaskPriority.critical:
        color = Colors.red;
        break;
      case TaskPriority.high:
        color = Colors.orange;
        break;
      case TaskPriority.medium:
        color = Colors.blue;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.completed:
        color = Colors.green;
        label = 'Hoàn thành';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        label = 'Đang thực hiện';
        break;
      case TaskStatus.pending:
        color = Colors.orange;
        label = 'Chờ xử lý';
        break;
      case TaskStatus.overdue:
        color = Colors.red;
        label = 'Quá hạn';
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        label = 'Đã hủy';
        break;
    }

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
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showTaskDetails(ManagementTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                task.description ?? 'Không có mô tả',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Độ ưu tiên', task.priority.label),
              _buildDetailRow('Trạng thái', _getStatusLabel(task.status)),
              _buildDetailRow(
                  'Người thực hiện', task.assignedToName ?? 'Chưa giao'),
              if (task.assignedToRole != null)
                _buildDetailRow('Vai trò', task.assignedToRole!),
              _buildDetailRow('Công ty', task.companyName ?? 'Chưa xác định'),
              if (task.branchName != null)
                _buildDetailRow('Chi nhánh', task.branchName!),
              _buildDetailRow(
                  'Hạn hoàn thành',
                  task.dueDate != null
                      ? _dateFormat.format(task.dueDate!)
                      : 'Chưa có hạn'),
              _buildDetailRow('Tiến độ', '${task.progress}%'),
              if (task.completedAt != null)
                _buildDetailRow(
                    'Hoàn thành lúc', _dateFormat.format(task.completedAt!)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Edit task
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Send reminder
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('Nhắc nhở'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Chờ xử lý';
      case TaskStatus.inProgress:
        return 'Đang thực hiện';
      case TaskStatus.completed:
        return 'Hoàn thành';
      case TaskStatus.overdue:
        return 'Quá hạn';
      case TaskStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedManagerId;
    String? selectedCompanyId;
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime? selectedDueDate;

    // Load managers and companies
    final service = ref.read(managementTaskServiceProvider);
    final managersFuture = service.getManagers();
    final companiesFuture = service.getCompanies();

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: Future.wait([managersFuture, companiesFuture]),
        builder: (context, snapshot) {
          final managers = snapshot.hasData
              ? snapshot.data![0] as List<Map<String, dynamic>>
              : <Map<String, dynamic>>[];
          final companies = snapshot.hasData
              ? snapshot.data![1] as List<Map<String, dynamic>>
              : <Map<String, dynamic>>[];

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Tạo nhiệm vụ mới'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên nhiệm vụ *',
                          border: OutlineInputBorder(),
                          hintText: 'Ví dụ: Mở rộng thị trường miền Bắc',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả chi tiết',
                          border: OutlineInputBorder(),
                          hintText: 'Mô tả nhiệm vụ và yêu cầu cụ thể',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Manager Dropdown - Real data
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Giao cho Manager *',
                            border: OutlineInputBorder(),
                            hintText: 'Chọn người thực hiện',
                          ),
                          value: selectedManagerId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('-- Chọn Manager --'),
                            ),
                            ...managers.map((manager) {
                              return DropdownMenuItem(
                                value: manager['id'] as String,
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        manager['full_name'] as String,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (manager['company_name'] != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${manager['company_name']})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => selectedManagerId = value);
                          },
                        ),
                      const SizedBox(height: 16),

                      // Company Dropdown - Real data
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Công ty',
                          border: OutlineInputBorder(),
                          hintText: 'Chọn công ty',
                        ),
                        value: selectedCompanyId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('-- Không chọn công ty --'),
                          ),
                          ...companies.map((company) {
                            return DropdownMenuItem(
                              value: company['id'] as String,
                              child: Row(
                                children: [
                                  const Icon(Icons.business, size: 16),
                                  const SizedBox(width: 8),
                                  Text(company['name'] as String),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedCompanyId = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Priority Dropdown
                      DropdownButtonFormField<TaskPriority>(
                        decoration: const InputDecoration(
                          labelText: 'Mức độ ưu tiên *',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedPriority,
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(priority.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedPriority = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Due Date Picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ??
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDueDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hạn hoàn thành',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedDueDate != null
                                ? _dateFormat.format(selectedDueDate!)
                                : 'Chọn ngày',
                            style: TextStyle(
                              color: selectedDueDate != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        '* Trường bắt buộc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validation
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên nhiệm vụ'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final service = ref.read(managementTaskServiceProvider);

                      // Validate assignedTo is required
                      if (selectedManagerId == null) {
                        throw Exception('Vui lòng chọn người thực hiện');
                      }

                      await service.createTask(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        priority: selectedPriority.value,
                        assignedTo: selectedManagerId!,
                        companyId: selectedCompanyId,
                        dueDate: selectedDueDate,
                      );

                      if (mounted) {
                        Navigator.pop(context); // Close loading

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã tạo nhiệm vụ thành công'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Refresh all data
                        refreshAllManagementTasks(ref);
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // Close loading

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                  child: const Text('Tạo nhiệm vụ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Future<void> _handleApproval(TaskApproval item, bool isApproved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Phê duyệt' : 'Từ chối'),
        content: Text(
          isApproved
              ? 'Bạn có chắc chắn muốn phê duyệt yêu cầu "${item.title}"?'
              : 'Bạn có chắc chắn muốn từ chối yêu cầu "${item.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
            ),
            child: Text(isApproved ? 'Phê duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(managementTaskServiceProvider);

      if (isApproved) {
        await service.approveTaskApproval(item.id);
      } else {
        await service.rejectTaskApproval(item.id, reason: 'Từ chối bởi CEO');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved ? 'Đã phê duyệt thành công' : 'Đã từ chối yêu cầu',
            ),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );

        // Refresh data
        refreshAllManagementTasks(ref);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
