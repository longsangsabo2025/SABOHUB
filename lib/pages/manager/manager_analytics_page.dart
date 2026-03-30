import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../providers/cached_data_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/multi_account_switcher.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';
import '../../business_types/distribution/services/sales_features_service.dart';
import '../../business_types/distribution/widgets/sales_features_widgets_2.dart';

/// Manager Analytics Page
/// Detailed analytics for management operations
class ManagerAnalyticsPage extends ConsumerStatefulWidget {
  const ManagerAnalyticsPage({super.key});

  @override
  ConsumerState<ManagerAnalyticsPage> createState() =>
      _ManagerAnalyticsPageState();
}

class _ManagerAnalyticsPageState extends ConsumerState<ManagerAnalyticsPage> {
  String _selectedPeriod = 'Hôm nay';
  int _selectedTab = 0;
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final branchId = user?.branchId;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate cache to force fresh data
          ref.invalidateManagerDashboard(branchId);
        },
        child: Column(
          children: [
            _buildPeriodSelector(),
            _buildTabBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Phân tích dữ liệu',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface87,
        ),
      ),
      actions: [
        // Multi-Account Switcher
        MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            final user = ref.read(currentUserProvider);
            final branchId = user?.branchId;
            final companyId = user?.companyId;
            ref.invalidate(cachedManagerDashboardKPIsProvider(branchId));
            ref.invalidate(cachedStaffStatsProvider(companyId ?? ''));
            ref.invalidate(cachedCompanyEmployeesProvider(companyId ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã làm mới dữ liệu'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.success,
              ),
            );
          },
          icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface54),
        ),
        IconButton(
          onPressed: () {
            final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
            final report = 'Báo cáo phân tích - $now\n'
                'Kỳ: $_selectedPeriod\n'
                '---\nXem chi tiết tại SABOHUB App';
            Clipboard.setData(ClipboardData(text: report));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã sao chép báo cáo'),
                duration: Duration(seconds: 1),
                backgroundColor: AppColors.success,
              ),
            );
          },
          icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface54),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          'Hôm nay',
          'Tuần này',
          'Tháng này',
        ].map((period) => _buildPeriodChip(period)).toList(),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Doanh thu', 'Nhân viên', 'Vận hành', 'Khảo sát'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.info : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRevenueTab();
      case 1:
        return _buildCustomerTab();
      case 2:
        return _buildProductTab();
      case 3:
        return _buildSurveyTab();
      default:
        return _buildRevenueTab();
    }
  }

  Widget _buildRevenueTab() {
    final user = ref.watch(currentUserProvider);
    final branchId = user?.branchId;
    final companyId = user?.companyId;

    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider(branchId));
    final staffStatsAsync = ref.watch(cachedStaffStatsProvider(companyId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          kpisAsync.when(
            data: (cachedKpis) => _buildRevenueMetrics(cachedKpis),
            loading: () => _buildLoadingCard(height: 180),
            error: (_, __) => _buildRevenueMetrics({}),
          ),
          const SizedBox(height: 24),
          staffStatsAsync.when(
            data: (cachedStats) => _buildStaffMetrics(cachedStats),
            loading: () => _buildLoadingCard(height: 150),
            error: (_, __) => _buildStaffMetrics({}),
          ),
          const SizedBox(height: 24),
          kpisAsync.when(
            data: (cachedKpis) => _buildPerformanceMetrics(cachedKpis),
            loading: () => _buildLoadingCard(height: 120),
            error: (_, __) => _buildPerformanceMetrics({}),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRevenueMetrics(Map<String, dynamic> kpis) {
    final revenue = kpis['todayRevenue'] ?? 0.0;
    final revenueChange = kpis['revenueChange'] ?? 0.0;
    final orders = kpis['totalOrders'] ?? 0;
    final orderChange = kpis['orderChange'] ?? 0.0;
    final customers = kpis['totalCustomers'] ?? 0;
    final customerChange = kpis['customerChange'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu hôm nay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Doanh thu',
                  _currencyFormat.format(revenue),
                  '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%',
                  AppColors.success,
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Đơn hàng',
                  '$orders',
                  '${orderChange >= 0 ? '+' : ''}${orderChange.toStringAsFixed(1)}%',
                  AppColors.info,
                  Icons.receipt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Khách hàng',
                  '$customers',
                  '${customerChange >= 0 ? '+' : ''}${customerChange.toStringAsFixed(1)}%',
                  AppColors.primary,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'TB/Đơn',
                  orders > 0 ? _currencyFormat.format(revenue / orders) : '0₫',
                  '',
                  AppColors.warning,
                  Icons.analytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffMetrics(Map<String, dynamic> stats) {
    final totalStaff = stats['totalStaff'] ?? 0;
    final activeStaff = stats['activeStaff'] ?? 0;
    final onLeave = stats['onLeave'] ?? 0;
    final inactiveStaff = stats['inactiveStaff'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhân viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Tổng số',
                  '$totalStaff',
                  '',
                  AppColors.neutral500,
                  Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Đang làm',
                  '$activeStaff',
                  totalStaff > 0
                      ? '${(activeStaff / totalStaff * 100).toStringAsFixed(0)}%'
                      : '0%',
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Nghỉ phép',
                  '$onLeave',
                  '',
                  AppColors.warning,
                  Icons.event_busy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Ngừng làm',
                  '$inactiveStaff',
                  '',
                  AppColors.error,
                  Icons.cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> kpis) {
    final performance = kpis['performance'] ?? 0.0;
    final performanceChange = kpis['performanceChange'] ?? 0.0;
    final activeTables = kpis['activeTables'] ?? 0;
    final totalTables = kpis['totalTables'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hiệu suất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Hiệu suất',
                  '${performance.toStringAsFixed(0)}%',
                  '${performanceChange >= 0 ? '+' : ''}${performanceChange.toStringAsFixed(1)}%',
                  AppColors.success,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Bàn hoạt động',
                  '$activeTables/$totalTables',
                  totalTables > 0
                      ? '${(activeTables / totalTables * 100).toStringAsFixed(0)}%'
                      : '0%',
                  AppColors.info,
                  Icons.table_restaurant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String change, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (change.isNotEmpty)
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCustomerStats(),
          const SizedBox(height: 24),
          _buildCustomerSegments(),
        ],
      ),
    );
  }

  Widget _buildCustomerStats() {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;
    final employeesAsync = ref.watch(cachedCompanyEmployeesProvider(companyId ?? ''));

    return employeesAsync.when(
      data: (employees) {
        final activeStaff = employees.where((e) => e.isActive).length;
        final totalStaff = employees.length;
        final onLeave = employees.where((e) => !e.isActive).length;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thống kê nhân viên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomerMetric(
                        'Tổng NV', totalStaff.toString(), Icons.people),
                  ),
                  Expanded(
                    child: _buildCustomerMetric('Hoạt động',
                        activeStaff.toString(), Icons.check_circle),
                  ),
                  Expanded(
                    child: _buildCustomerMetric(
                        'Nghỉ phép', onLeave.toString(), Icons.event_busy),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(height: 150),
      error: (e, s) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Lỗi: ${e.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primary),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSegments() {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;
    final employeesAsync = ref.watch(cachedCompanyEmployeesProvider(companyId ?? ''));

    return employeesAsync.when(
      data: (employees) {
        final total = employees.length;
        if (total == 0) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('Chưa có nhân viên')),
          );
        }

        final roleStats = <String, int>{};
        for (var e in employees) {
          final role = e.role.toString().split('.').last;
          roleStats[role] = (roleStats[role] ?? 0) + 1;
        }

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân bố nhân viên theo vai trò',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...roleStats.entries.map((e) {
                final percentage = (e.value / total * 100).round();
                Color color;
                String displayName;
                switch (e.key) {
                  case 'manager':
                    color = AppColors.warning;
                    displayName = 'Quản lý';
                    break;
                  case 'shift_leader':
                    color = AppColors.success;
                    displayName = 'Trưởng ca';
                    break;
                  case 'staff':
                    color = AppColors.info;
                    displayName = 'Nhân viên';
                    break;
                  default:
                    color = Colors.grey;
                    displayName = e.key;
                }
                return _buildSegmentItem(displayName, percentage, color);
              }),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(height: 150),
      error: (e, s) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Lỗi: ${e.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem(String title, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTopProducts(),
          const SizedBox(height: 24),
          _buildProductCategories(),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final user = ref.watch(currentUserProvider);
    final branchId = user?.branchId;
    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider(branchId));

    return kpisAsync.when(
      data: (cachedKpis) {
        final kpis = cachedKpis;
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hiệu suất hoạt động',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildProductItem(
                'Bàn đang hoạt động',
                '${kpis['activeTables'] ?? 0}/${kpis['totalTables'] ?? 0}',
                '${kpis['performance'] ?? 0}%',
              ),
              _buildProductItem(
                'Đơn hàng hôm nay',
                '${kpis['totalOrders'] ?? 0}',
                '100%',
              ),
              _buildProductItem(
                'Doanh thu',
                _currencyFormat.format(kpis['revenue'] ?? 0),
                '100%',
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(height: 200),
      error: (e, s) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Lỗi: ${e.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(String product, String quantity, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              product,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              quantity,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategories() {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;
    final statsAsync = ref.watch(cachedStaffStatsProvider(companyId));

    return statsAsync.when(
      data: (cachedStats) {
        final stats = cachedStats;
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng quan trạng thái',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem('✅', '${stats['active'] ?? 0}', 'Hoạt động'),
                  _buildStatusItem(
                      '📅', '${stats['onLeave'] ?? 0}', 'Nghỉ phép'),
                  _buildStatusItem(
                      '❌', '${stats['inactive'] ?? 0}', 'Không hoạt động'),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(height: 150),
      error: (e, s) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Lỗi: ${e.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // SURVEY TAB
  // ====================================================================
  Widget _buildSurveyTab() {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;

    if (companyId == null) {
      return const Center(child: Text('Không tìm thấy công ty'));
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(surveyServiceProvider).getSurveyStats(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        final totalSurveys = stats['totalSurveys'] ?? 0;
        final activeSurveys = stats['activeSurveys'] ?? 0;
        final totalResponses = stats['totalResponses'] ?? 0;
        final todayResponses = stats['todayResponses'] ?? 0;
        final avgScore = (stats['avgScore'] ?? 0.0).toDouble();
        final avgDuration = stats['avgDurationSeconds'] ?? 0;
        final uniqueRespondents = stats['uniqueRespondents'] ?? 0;
        final breakdown = List<Map<String, dynamic>>.from(stats['surveyBreakdown'] ?? []);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview metrics
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng quan khảo sát',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Tổng khảo sát',
                            '$totalSurveys',
                            '$activeSurveys đang hoạt động',
                            Colors.purple,
                            Icons.poll,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Tổng phản hồi',
                            '$totalResponses',
                            'Hôm nay: $todayResponses',
                            AppColors.info,
                            Icons.question_answer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Điểm TB',
                            avgScore > 0 ? avgScore.toStringAsFixed(1) : '-',
                            '',
                            AppColors.warning,
                            Icons.star,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'NV đã khảo sát',
                            '$uniqueRespondents',
                            avgDuration > 0 ? 'TB ${(avgDuration / 60).toStringAsFixed(1)} phút' : '',
                            AppColors.success,
                            Icons.people,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Per-survey breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Chi tiết từng khảo sát',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateQuickSurveyForm(),
                              ),
                            ).then((created) {
                              if (created == true) setState(() {});
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tạo mới'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (breakdown.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.poll_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Chưa có khảo sát nào',
                                  style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateQuickSurveyForm(),
                                    ),
                                  ).then((created) {
                                    if (created == true) setState(() {});
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Tạo khảo sát đầu tiên'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...breakdown.map((s) => _buildSurveyBreakdownItem(s)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurveyBreakdownItem(Map<String, dynamic> survey) {
    final responseCount = survey['responseCount'] ?? 0;
    final target = survey['targetResponses'] ?? 0;
    final completion = survey['completionRate'] ?? 0;
    final isActive = survey['isActive'] == true;
    final questionCount = survey['questionCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? Colors.purple.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.purple.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.poll : Icons.poll_outlined,
                color: isActive ? Colors.purple.shade700 : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  survey['title'] ?? 'Không tên',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.purple.shade900 : Colors.grey.shade700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withValues(alpha: 0.15) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Hoạt động' : 'Tắt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSurveyChip(Icons.quiz, '$questionCount câu hỏi'),
              const SizedBox(width: 12),
              _buildSurveyChip(Icons.question_answer, '$responseCount phản hồi'),
              if (target > 0) ...[
                const SizedBox(width: 12),
                _buildSurveyChip(Icons.flag, '$completion% mục tiêu'),
              ],
            ],
          ),
          if (target > 0 && responseCount > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (responseCount / target).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade300,
                color: completion >= 100 ? AppColors.success : Colors.purple,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurveyChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildStatusItem(String emoji, String count, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
