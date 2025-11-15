import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/cached_data_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/multi_account_switcher.dart';

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
    final authState = ref.watch(authProvider);
    final branchId = authState.user?.branchId;

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
      backgroundColor: Colors.white,
      title: const Text(
        'Phân tích dữ liệu',
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔄 Làm mới dữ liệu $_selectedPeriod'),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📤 Chia sẻ báo cáo $_selectedPeriod'),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFF3B82F6),
              ),
            );
          },
          icon: const Icon(Icons.share, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Doanh thu', 'Khách hàng', 'Sản phẩm'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
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

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRevenueTab();
      case 1:
        return _buildCustomerTab();
      case 2:
        return _buildProductTab();
      default:
        return _buildRevenueTab();
    }
  }

  Widget _buildRevenueTab() {
    final authState = ref.watch(authProvider);
    final branchId = authState.user?.branchId;
    final companyId = authState.user?.companyId;

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
        color: Colors.white,
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
                  const Color(0xFF10B981),
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Đơn hàng',
                  '$orders',
                  '${orderChange >= 0 ? '+' : ''}${orderChange.toStringAsFixed(1)}%',
                  const Color(0xFF3B82F6),
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
                  const Color(0xFF8B5CF6),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'TB/Đơn',
                  orders > 0 ? _currencyFormat.format(revenue / orders) : '0₫',
                  '',
                  const Color(0xFFF59E0B),
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
                  const Color(0xFF6B7280),
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
                  const Color(0xFF10B981),
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
                  const Color(0xFFF59E0B),
                  Icons.event_busy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Ngừng làm',
                  '$inactiveStaff',
                  '',
                  const Color(0xFFEF4444),
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
                  const Color(0xFF10B981),
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
                  const Color(0xFF3B82F6),
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
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;
    final employeesAsync = ref.watch(cachedCompanyEmployeesProvider(companyId ?? ''));

    return employeesAsync.when(
      data: (employees) {
        final activeStaff = employees.where((e) => e.isActive).length;
        final totalStaff = employees.length;
        final onLeave = employees.where((e) => !e.isActive).length;

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
        Icon(icon, size: 32, color: const Color(0xFF8B5CF6)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;
    final employeesAsync = ref.watch(cachedCompanyEmployeesProvider(companyId ?? ''));

    return employeesAsync.when(
      data: (employees) {
        final total = employees.length;
        if (total == 0) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Chưa có nhân viên')),
          );
        }

        final roleStats = <String, int>{};
        for (var e in employees) {
          final role = e.role.toString().split('.').last;
          roleStats[role] = (roleStats[role] ?? 0) + 1;
        }

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
                    color = const Color(0xFFF59E0B);
                    displayName = 'Quản lý';
                    break;
                  case 'shift_leader':
                    color = const Color(0xFF10B981);
                    displayName = 'Trưởng ca';
                    break;
                  case 'staff':
                    color = const Color(0xFF3B82F6);
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
    final authState = ref.watch(authProvider);
    final branchId = authState.user?.branchId;
    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider(branchId));

    return kpisAsync.when(
      data: (cachedKpis) {
        final kpis = cachedKpis;
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
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategories() {
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;
    final statsAsync = ref.watch(cachedStaffStatsProvider(companyId));

    return statsAsync.when(
      data: (cachedStats) {
        final stats = cachedStats;
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
