import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/task_provider.dart';

/// Shift Leader Reports Page
/// Reporting and documentation for shift leaders
class ShiftLeaderReportsPage extends ConsumerStatefulWidget {
  const ShiftLeaderReportsPage({super.key});

  @override
  ConsumerState<ShiftLeaderReportsPage> createState() =>
      _ShiftLeaderReportsPageState();
}

class _ShiftLeaderReportsPageState
    extends ConsumerState<ShiftLeaderReportsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildContent(ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateReportDialog();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_chart, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Báo cáo ca làm',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _copyReportToClipboard();
          },
          icon: const Icon(Icons.download, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            _copyReportToClipboard();
          },
          icon: const Icon(Icons.share, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Hôm nay', 'Tuần này', 'Tháng này'];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(WidgetRef ref) {
    switch (_selectedTab) {
      case 0:
        return _buildTodayReportTab(ref);
      case 1:
        return _buildWeeklyReportTab(ref);
      case 2:
        return _buildMonthlyReportTab(ref);
      default:
        return _buildTodayReportTab(ref);
    }
  }

  Widget _buildTodayReportTab(WidgetRef ref) {
    final kpisAsync = ref.watch(managerDashboardKPIsProvider(null));
    final taskStatsAsync = ref.watch(taskStatsProvider(null));
    final staffStatsAsync = ref.watch(staffStatsProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerDashboardKPIsProvider);
        ref.invalidate(taskStatsProvider);
        ref.invalidate(staffStatsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: kpisAsync.when(
          data: (kpis) => taskStatsAsync.when(
            data: (taskStats) => staffStatsAsync.when(
              data: (staffStats) => Column(
                children: [
                  _buildShiftSummary(kpis, taskStats, staffStats),
                  const SizedBox(height: 24),
                  _buildOperationalMetrics(kpis, taskStats),
                  const SizedBox(height: 24),
                  _buildIssuesAndNotes(),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải dữ liệu',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(managerDashboardKPIsProvider);
                          ref.invalidate(taskStatsProvider);
                          ref.invalidate(staffStatsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải dữ liệu',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(managerDashboardKPIsProvider);
                        ref.invalidate(taskStatsProvider);
                        ref.invalidate(staffStatsProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải dữ liệu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(managerDashboardKPIsProvider);
                      ref.invalidate(taskStatsProvider);
                      ref.invalidate(staffStatsProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftSummary(Map<String, dynamic> kpis,
      Map<String, int> taskStats, Map<String, dynamic> staffStats) {
    // Get current time to determine shift
    final now = DateTime.now();
    final hour = now.hour;
    String shiftText;
    if (hour >= 6 && hour < 14) {
      shiftText = 'Sáng (06:00-14:00)';
    } else if (hour >= 14 && hour < 22) {
      shiftText = 'Chiều (14:00-22:00)';
    } else {
      shiftText = 'Tối (22:00-06:00)';
    }

    final totalTables = kpis['totalTables'] ?? 0;
    final activeTables = kpis['activeTables'] ?? 0;
    final totalRevenue = kpis['totalRevenue'] ?? 0;
    final totalOrders = kpis['totalOrders'] ?? 0;

    final totalStaff = staffStats['total'] ?? 0;
    final activeStaff = staffStats['active'] ?? 0;

    final completedTasks = taskStats['completed'] ?? 0;
    final totalTasks = taskStats['total'] ?? 0;

    // Calculate shift status
    final bool shiftComplete = completedTasks >= (totalTasks * 0.8);
    final revenueFormatted = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
      decimalDigits: 0,
    ).format(totalRevenue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tóm tắt ca làm việc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (shiftComplete
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shiftComplete ? 'HOÀN THÀNH' : 'ĐANG LÀM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: shiftComplete
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                    'Ca làm việc', shiftText, AppColors.primary),
              ),
              Expanded(
                child: _buildSummaryItem('Nhiệm vụ',
                    '$completedTasks/$totalTasks', AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Nhân viên',
                    '$activeStaff/$totalStaff', AppColors.success),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Doanh thu', revenueFormatted, AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Bàn hoạt động',
                    '$activeTables/$totalTables', AppColors.primary),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Đơn hàng', '$totalOrders', AppColors.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationalMetrics(
      Map<String, dynamic> kpis, Map<String, int> taskStats) {
    final totalTables = kpis['totalTables'] ?? 0;
    final activeTables = kpis['activeTables'] ?? 0;
    final totalOrders = kpis['totalOrders'] ?? 0;

    final completedTasks = taskStats['completed'] ?? 0;
    final totalTasks = taskStats['total'] ?? 0;
    final todoTasks = taskStats['todo'] ?? 0;
    final inProgressTasks = taskStats['inProgress'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số vận hành',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Bàn phục vụ', '$activeTables',
                    '/$totalTables', AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                    'Đơn hàng', '$totalOrders', 'đơn', AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Hoàn thành', '$completedTasks',
                    '/$totalTasks', AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Đang làm', '$inProgressTasks', 'việc',
                    AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                    'Chờ xử lý', '$todoTasks', 'việc', AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                    'Tỷ lệ hoàn thành',
                    totalTasks > 0
                        ? ((completedTasks / totalTasks) * 100)
                            .toStringAsFixed(0)
                        : '0',
                    '%',
                    AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesAndNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sự cố và ghi chú',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Text('Không có sự cố trong ca hôm nay',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(String title, String time, String description,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportTab(WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadWeeklyStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final stats = snapshot.data ?? {};
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildWeeklySummary(stats),
                const SizedBox(height: 24),
                _buildWeeklyChart(stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySummary(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final inProgress = stats['inProgress'] ?? 0;
    final weekLabel = stats['weekLabel'] ?? 'Tuần này';
    final completionRate = total > 0
        ? '${(completed / total * 100).toStringAsFixed(0)}%'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo tuần ($weekLabel)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyMetric('Tổng nhiệm vụ', '$total', 'công việc'),
              ),
              Expanded(
                child: _buildWeeklyMetric('Hoàn thành', '$completed', 'nhiệm vụ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyMetric('Đang làm', '$inProgress', 'nhiệm vụ'),
              ),
              Expanded(
                child: _buildWeeklyMetric(
                    'Hiệu suất', completionRate, 'hoàn thành'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMetric(String title, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(Map<String, dynamic> stats) {
    final dayStats = (stats['dayStats'] as Map<String, int>?) ?? {};
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxVal = dayStats.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhiệm vụ theo ngày',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dayNames.map((day) {
                final count = dayStats[day] ?? 0;
                return _buildChartBar(
                  day,
                  count.toDouble(),
                  maxVal.toDouble(),
                  AppColors.primary,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(
      String day, double value, double maxValue, Color color) {
    final height = (value / maxValue) * 160;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value.toInt()}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportTab(WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadMonthlyStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final stats = snapshot.data ?? {};
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildMonthlySummary(stats),
                const SizedBox(height: 24),
                _buildMonthlyTrends(stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummary(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final overdue = stats['overdue'] ?? 0;
    final monthLabel = stats['monthLabel'] ?? 'Tháng này';
    final completionRate = total > 0
        ? '${(completed / total * 100).toStringAsFixed(0)}%'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo $monthLabel',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMonthlyItem(
                    'Tổng nhiệm vụ', '$total', AppColors.primary),
              ),
              Expanded(
                child: _buildMonthlyItem(
                    'Hoàn thành', '$completed', AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthlyItem(
                    'Hiệu suất', completionRate, AppColors.info),
              ),
              Expanded(
                child: _buildMonthlyItem(
                    'Quá hạn', '$overdue vấn đề', AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final overdue = stats['overdue'] ?? 0;
    final completionRate = total > 0
        ? '${(completed / total * 100).toStringAsFixed(0)}%'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hiệu suất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'Hoàn thành nhiệm vụ',
            completionRate,
            '$completed/$total nhiệm vụ đã xử lý',
            Icons.check_circle_outline,
            AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'Quá hạn',
            '$overdue',
            overdue == 0
                ? 'Không có nhiệm vụ quá hạn'
                : '$overdue nhiệm vụ cần xử lý',
            Icons.warning_amber_outlined,
            overdue == 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'Tổng khối lượng',
            '$total',
            'Nhiệm vụ trong tháng',
            Icons.assignment_outlined,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, String description,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadWeeklyStats() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);

    try {
      final tasks = await supabase
          .from('tasks')
          .select('id, status, created_at')
          .gte('created_at', weekStartStr)
          .isFilter('deleted_at', null);

      final total = tasks.length;
      final completed =
          tasks.where((t) => t['status'] == 'completed').length;
      final inProgress =
          tasks.where((t) => t['status'] == 'in_progress').length;

      // Group by day of week
      final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      final dayStats = <String, int>{
        for (final d in dayNames) d: 0,
      };
      for (final task in tasks) {
        try {
          final date = DateTime.parse(task['created_at']);
          final dayIndex = date.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            dayStats[dayNames[dayIndex]] =
                (dayStats[dayNames[dayIndex]] ?? 0) + 1;
          }
        } catch (_) {}
      }

      return {
        'total': total,
        'completed': completed,
        'inProgress': inProgress,
        'dayStats': dayStats,
        'weekLabel':
            '${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(now)}',
      };
    } catch (_) {
      return {
        'total': 0,
        'completed': 0,
        'inProgress': 0,
        'dayStats': <String, int>{},
        'weekLabel': 'Tuần này',
      };
    }
  }

  Future<Map<String, dynamic>> _loadMonthlyStats() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);

    try {
      final tasks = await supabase
          .from('tasks')
          .select('id, status, due_date, created_at')
          .gte('created_at', monthStartStr)
          .isFilter('deleted_at', null);

      final total = tasks.length;
      final completed =
          tasks.where((t) => t['status'] == 'completed').length;
      final overdue = tasks.where((t) {
        if (t['due_date'] == null) return false;
        try {
          final due = DateTime.parse(t['due_date']);
          return due.isBefore(now) && t['status'] != 'completed';
        } catch (_) {
          return false;
        }
      }).length;

      final monthName = DateFormat('MM/yyyy').format(now);

      return {
        'total': total,
        'completed': completed,
        'overdue': overdue,
        'monthLabel': 'tháng $monthName',
      };
    } catch (_) {
      return {
        'total': 0,
        'completed': 0,
        'overdue': 0,
        'monthLabel': 'Tháng này',
      };
    }
  }

  void _showCreateReportDialog() {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi chú ca làm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập ghi chú, sự cố hoặc nhận xét về ca làm...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (notesCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu ghi chú ca làm'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _copyReportToClipboard() {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final report = 'Báo cáo ca làm - $now\n'
        'Trưởng ca: ${ref.read(authProvider).user?.displayName ?? "N/A"}\n'
        '---\nBáo cáo chi tiết xem tại SABOHUB App';
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép báo cáo'), backgroundColor: AppColors.success),
    );
  }
}
