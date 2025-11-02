import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/manager_provider.dart';
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
          // Create new report
        },
        backgroundColor: const Color(0xFF8B5CF6),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📥 Tải xuống báo cáo'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.download, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📤 Chia sẻ báo cáo'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
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
                      isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
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
                    color: Color(0xFF8B5CF6),
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
                          backgroundColor: const Color(0xFF8B5CF6),
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
                  color: Color(0xFF8B5CF6),
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
                        backgroundColor: const Color(0xFF8B5CF6),
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
                color: Color(0xFF8B5CF6),
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
                      backgroundColor: const Color(0xFF8B5CF6),
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
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shiftComplete ? 'HOÀN THÀNH' : 'ĐANG LÀM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: shiftComplete
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
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
                    'Ca làm việc', shiftText, const Color(0xFF8B5CF6)),
              ),
              Expanded(
                child: _buildSummaryItem('Nhiệm vụ',
                    '$completedTasks/$totalTasks', const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Nhân viên',
                    '$activeStaff/$totalStaff', const Color(0xFF10B981)),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Doanh thu', revenueFormatted, const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Bàn hoạt động',
                    '$activeTables/$totalTables', const Color(0xFF8B5CF6)),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Đơn hàng', '$totalOrders', const Color(0xFF3B82F6)),
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
                    '/$totalTables', const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                    'Đơn hàng', '$totalOrders', 'đơn', const Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Hoàn thành', '$completedTasks',
                    '/$totalTasks', const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Đang làm', '$inProgressTasks', 'việc',
                    const Color(0xFF8B5CF6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                    'Chờ xử lý', '$todoTasks', 'việc', const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                    'Tỷ lệ hoàn thành',
                    totalTasks > 0
                        ? '${((completedTasks / totalTasks) * 100).toStringAsFixed(0)}'
                        : '0',
                    '%',
                    const Color(0xFF10B981)),
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
          _buildIssueItem(
            'Máy pha chế bàn 5 gặp sự cố',
            '15:30',
            'Đã liên hệ kỹ thuật viên, sửa chữa trong 30 phút',
            Icons.build,
            const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _buildIssueItem(
            'Nhân viên Lan xin nghỉ sớm',
            '19:00',
            'Lý do cá nhân, đã điều chỉnh phân công',
            Icons.person,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _buildIssueItem(
            'Khách hàng khen ngợi dịch vụ',
            '20:15',
            'Bàn 8 - nhân viên Mai được khách khen',
            Icons.thumb_up,
            const Color(0xFF10B981),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklySummary(),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
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
            'Báo cáo tuần (1-7 Nov)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyMetric('Tổng ca', '21', 'ca làm việc'),
              ),
              Expanded(
                child: _buildWeeklyMetric('Trung bình', '6.5', 'nhân viên/ca'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyMetric('Doanh thu', '16.8M', 'VNĐ'),
              ),
              Expanded(
                child: _buildWeeklyMetric(
                    'Hiệu suất', '87%', 'nhiệm vụ hoàn thành'),
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
            color: Color(0xFF8B5CF6),
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

  Widget _buildWeeklyChart() {
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
            'Biểu đồ doanh thu theo ngày',
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
              children: [
                _buildChartBar('T2', 1.8, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('T3', 2.4, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('T4', 2.1, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('T5', 2.8, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('T6', 3.2, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('T7', 2.6, 3.0, const Color(0xFF8B5CF6)),
                _buildChartBar('CN', 1.9, 3.0, const Color(0xFF8B5CF6)),
              ],
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
          '${value}M',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthlySummary(),
          const SizedBox(height: 24),
          _buildMonthlyTrends(),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
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
            'Báo cáo tháng 11/2024',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMonthlyItem(
                    'Tổng ca làm', '89 ca', const Color(0xFF8B5CF6)),
              ),
              Expanded(
                child: _buildMonthlyItem(
                    'Doanh thu', '72.5M', const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthlyItem(
                    'Hiệu suất', '91%', const Color(0xFF3B82F6)),
              ),
              Expanded(
                child: _buildMonthlyItem(
                    'Sự cố', '12 vấn đề', const Color(0xFFEF4444)),
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

  Widget _buildMonthlyTrends() {
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
            'Xu hướng và thống kê',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'Doanh thu tăng trưởng',
            '+12.5%',
            'So với tháng trước',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'Hiệu suất nhóm',
            '91%',
            'Cao hơn mục tiêu 85%',
            Icons.group,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'Sự cố giảm',
            '-23%',
            'Ít hơn so với tháng trước',
            Icons.warning,
            const Color(0xFF8B5CF6),
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
}
