import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
import '../../utils/dummy_providers.dart';
import 'ceo_profile_page.dart';
import 'smart_task_creation_page.dart';

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
    _tabController =
        TabController(length: 4, vsync: this); // ✅ Changed from 3 to 4
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
                _buildQuickActionsTab(), // ✅ New first tab
                _buildStrategicTasksTab(),
                _buildApprovalTab(),
                _buildCompanyOverviewTab(),
              ],
            ),
          ),
        ],
      ),
      // ✅ Removed FloatingActionButton - actions now in Quick Actions tab
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEOProfilePage(),
              ),
            );
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
            final stats = cachedStats;
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        isScrollable: true, // ✅ Enable scrolling for 4 tabs
        tabs: const [
          Tab(text: 'Hành động nhanh'),
          Tab(text: 'Nhiệm vụ chiến lược'),
          Tab(text: 'Chờ phê duyệt'),
          Tab(text: 'Tổng quan công ty'),
        ],
      ),
    );
  }

  // ✅ NEW: Quick Actions Tab with 2-column layout
  Widget _buildQuickActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Hành động nhanh',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thao tác thường dùng cho CEO',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // ✅ 2-Column Layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Use 2 columns on wide screens, 1 column on narrow
              final isWide = constraints.maxWidth > 800;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildActionSection(
                            title: '📋 Quản lý nhiệm vụ',
                            actions: [
                              _ActionItem(
                                icon: Icons.add_task,
                                title: 'Tạo nhiệm vụ mới',
                                subtitle:
                                    'Giao nhiệm vụ chiến lược cho Manager',
                                color: Colors.blue,
                                onTap: _showCreateTaskDialog,
                              ),
                              _ActionItem(
                                icon: Icons.assignment_turned_in,
                                title: 'Phê duyệt nhiệm vụ',
                                subtitle:
                                    'Xem và phê duyệt các nhiệm vụ đang chờ',
                                color: Colors.orange,
                                onTap: () => _tabController.animateTo(2),
                              ),
                              _ActionItem(
                                icon: Icons.analytics,
                                title: 'Xem báo cáo tổng quan',
                                subtitle: 'Thống kê hiệu suất theo công ty',
                                color: Colors.purple,
                                onTap: () => _tabController.animateTo(3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildActionSection(
                            title: '🏢 Quản lý công ty',
                            actions: [
                              _ActionItem(
                                icon: Icons.business,
                                title: 'Quản lý công ty',
                                subtitle: 'Xem và cập nhật thông tin công ty',
                                color: Colors.teal,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Chuyển sang tab Công ty...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              _ActionItem(
                                icon: Icons.people,
                                title: 'Quản lý nhân sự',
                                subtitle: 'Thêm, sửa, xóa Manager và nhân viên',
                                color: Colors.green,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Tính năng đang phát triển...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column
                    Expanded(
                      child: _buildActionSection(
                        title: '📊 Báo cáo & Phân tích',
                        actions: [
                          _ActionItem(
                            icon: Icons.bar_chart,
                            title: 'Báo cáo doanh thu',
                            subtitle: 'Xem doanh thu theo công ty và chi nhánh',
                            color: Colors.indigo,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng đang phát triển...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          _ActionItem(
                            icon: Icons.trending_up,
                            title: 'Phân tích hiệu suất',
                            subtitle: 'Dashboard phân tích KPI và hiệu suất',
                            color: Colors.pink,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng đang phát triển...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          _ActionItem(
                            icon: Icons.settings,
                            title: 'Cài đặt hệ thống',
                            subtitle: 'Quản lý cấu hình và phân quyền',
                            color: Colors.blueGrey,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng đang phát triển...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Single column for narrow screens
                return Column(
                  children: [
                    _buildActionSection(
                      title: '📋 Quản lý nhiệm vụ',
                      actions: [
                        _ActionItem(
                          icon: Icons.add_task,
                          title: 'Tạo nhiệm vụ mới',
                          subtitle: 'Giao nhiệm vụ chiến lược cho Manager',
                          color: Colors.blue,
                          onTap: _showCreateTaskDialog,
                        ),
                        _ActionItem(
                          icon: Icons.assignment_turned_in,
                          title: 'Phê duyệt nhiệm vụ',
                          subtitle: 'Xem và phê duyệt các nhiệm vụ đang chờ',
                          color: Colors.orange,
                          onTap: () => _tabController.animateTo(2),
                        ),
                        _ActionItem(
                          icon: Icons.analytics,
                          title: 'Xem báo cáo tổng quan',
                          subtitle: 'Thống kê hiệu suất theo công ty',
                          color: Colors.purple,
                          onTap: () => _tabController.animateTo(3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildActionSection(
                      title: '🏢 Quản lý công ty',
                      actions: [
                        _ActionItem(
                          icon: Icons.business,
                          title: 'Quản lý công ty',
                          subtitle: 'Xem và cập nhật thông tin công ty',
                          color: Colors.teal,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chuyển sang tab Công ty...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        _ActionItem(
                          icon: Icons.people,
                          title: 'Quản lý nhân sự',
                          subtitle: 'Thêm, sửa, xóa Manager và nhân viên',
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildActionSection(
                      title: '📊 Báo cáo & Phân tích',
                      actions: [
                        _ActionItem(
                          icon: Icons.bar_chart,
                          title: 'Báo cáo doanh thu',
                          subtitle: 'Xem doanh thu theo công ty và chi nhánh',
                          color: Colors.indigo,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        _ActionItem(
                          icon: Icons.trending_up,
                          title: 'Phân tích hiệu suất',
                          subtitle: 'Dashboard phân tích KPI và hiệu suất',
                          color: Colors.pink,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        _ActionItem(
                          icon: Icons.settings,
                          title: 'Cài đặt hệ thống',
                          subtitle: 'Quản lý cấu hình và phân quyền',
                          color: Colors.blueGrey,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection({
    required String title,
    required List<_ActionItem> actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => _buildActionCard(action)),
      ],
    );
  }

  Widget _buildActionCard(_ActionItem action) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
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
        final tasks = cachedTasks;
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
                    'Chuyển sang tab "Hành động nhanh" để tạo nhiệm vụ mới',
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
        final approvals = cachedApprovals;
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
                    color: _getApprovalTypeColor(type).withValues(alpha: 0.1),
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
                    color: Colors.orange.withValues(alpha: 0.1),
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
        final companies = cachedCompanies;
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
            // TODO: Implement proper company list when data is available
            Center(
              child: Text('Không có dữ liệu công ty',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
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
        color: color.withValues(alpha: 0.1),
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
        color: color.withValues(alpha: 0.1),
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
    // Navigate to modern smart task creation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SmartTaskCreationPage(),
      ),
    ).then((_) {
      // Refresh data when returning from task creation
      refreshAllManagementTasks(ref);
    });
  }

  // Color _getPriorityColor(TaskPriority priority) {
  //   switch (priority) {
  //     case TaskPriority.critical:
  //       return Colors.red;
  //     case TaskPriority.high:
  //       return Colors.orange;
  //     case TaskPriority.medium:
  //       return Colors.blue;
  //     case TaskPriority.low:
  //       return Colors.green;
  //   }
  // }

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

// ✅ Helper class for Quick Actions
class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
