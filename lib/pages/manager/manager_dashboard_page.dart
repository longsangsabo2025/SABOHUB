import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/cached_data_providers.dart'; // PHASE 3B: Manager cache
import '../../providers/auth_provider.dart';
import '../../widgets/multi_account_switcher.dart';

/// Manager Dashboard Page
/// Management overview with team metrics and operations
class ManagerDashboardPage extends ConsumerStatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  ConsumerState<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends ConsumerState<ManagerDashboardPage> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final branchId = authState.user?.branchId;

    // PHASE 3B: Use CACHED providers for instant loads (5min TTL)
    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider(branchId));
    final activitiesAsync = ref.watch(
        cachedManagerRecentActivitiesProvider((branchId: branchId, limit: 10)));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate cache to force fresh data
          ref.invalidateManagerDashboard(branchId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kpisAsync.when(
                data: (cachedKpis) => _buildWelcomeSection(cachedKpis),
                loading: () => _buildLoadingWelcome(),
                error: (_, __) => _buildWelcomeSection({}),
              ),
              const SizedBox(height: 24),
              kpisAsync.when(
                data: (cachedKpis) => _buildQuickStats(cachedKpis),
                loading: () => _buildLoadingStats(),
                error: (_, __) => _buildQuickStats({}),
              ),
              const SizedBox(height: 24),
              _buildOperationsSection(),
              const SizedBox(height: 24),
              activitiesAsync.when(
                data: (cachedActivities) => _buildRecentActivities(
                    List<Map<String, dynamic>>.from(cachedActivities)),
                loading: () => _buildLoadingActivities(),
                error: (_, __) => _buildRecentActivities([]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Quản lý',
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
              const SnackBar(
                content: Text('📬 Thông báo đang được phát triển'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: const Icon(Icons.person_outline, color: Colors.black54),
          tooltip: 'Hồ sơ cá nhân',
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> kpis) {
    final activeStaff = kpis['activeStaff'] ?? 0;
    final totalStaff = kpis['totalStaff'] ?? 0;
    final activeTables = kpis['activeTables'] ?? 0;
    final totalTables = kpis['totalTables'] ?? 0;

    final hour = DateTime.now().hour;
    String greeting = 'Chào buổi sáng';
    if (hour >= 12 && hour < 18) {
      greeting = 'Chào buổi chiều';
    } else if (hour >= 18) {
      greeting = 'Chào buổi tối';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, Quản lý!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tổng quan hoạt động hôm nay',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Nhân viên',
                  '$activeStaff/$totalStaff',
                  Icons.people,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Bàn hoạt động',
                  '$activeTables/$totalTables',
                  Icons.table_restaurant,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWelcome() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: textColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> kpis) {
    final revenue = kpis['todayRevenue'] ?? 0.0;
    final revenueChange = kpis['revenueChange'] ?? 0.0;
    final customers = kpis['totalCustomers'] ?? 0;
    final customerChange = kpis['customerChange'] ?? 0.0;
    final orders = kpis['totalOrders'] ?? 0;
    final orderChange = kpis['orderChange'] ?? 0.0;
    final performance = kpis['performance'] ?? 0.0;
    final performanceChange = kpis['performanceChange'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Doanh thu hôm nay',
                _currencyFormat.format(revenue),
                Icons.attach_money,
                const Color(0xFF3B82F6),
                '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Khách hàng',
                '$customers',
                Icons.person,
                const Color(0xFF8B5CF6),
                '${customerChange >= 0 ? '+' : ''}${customerChange.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Đơn hàng',
                '$orders',
                Icons.receipt,
                const Color(0xFF10B981),
                '${orderChange >= 0 ? '+' : ''}${orderChange.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hiệu suất',
                '${performance.toStringAsFixed(0)}%',
                Icons.trending_up,
                const Color(0xFFF59E0B),
                '${performanceChange >= 0 ? '+' : ''}${performanceChange.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
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
      ),
    );
  }

  Widget _buildOperationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hoạt động',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔍 Xem tất cả hoạt động'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Quản lý bàn',
                'Theo dõi bàn',
                Icons.table_restaurant,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Đơn hàng',
                'Xử lý đơn',
                Icons.receipt_long,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Kho hàng',
                'Kiểm tra tồn',
                Icons.inventory,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Báo cáo',
                'Tạo báo cáo',
                Icons.assessment,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, String subtitle, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚀 $title - $subtitle'),
            duration: const Duration(seconds: 2),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTeamSection(List<Map<String, dynamic>> team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đội ngũ hôm nay',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: team.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Chưa có nhân viên',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < team.length; i++) ...[
                      if (i > 0) const Divider(),
                      _buildTeamMember(
                        team[i]['name'] as String,
                        team[i]['shift'] as String,
                        team[i]['status'] as String,
                        _getStatusColor(team[i]['statusColor'] as String),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTeamMember(
      String name, String shift, String status, Color statusColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            name[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                shift,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(List<Map<String, dynamic>> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: activities.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Chưa có hoạt động',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < activities.length; i++) ...[
                      if (i > 0) const Divider(),
                      _buildActivity(
                        activities[i]['title'] as String,
                        activities[i]['time'] as String,
                        _getActivityIcon(activities[i]['icon'] as String),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'payment':
        return Icons.payment;
      case 'login':
        return Icons.login;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildActivity(String title, String time, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
