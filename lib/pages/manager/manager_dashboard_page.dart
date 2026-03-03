import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              _buildCongNoSection(),
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
        // View Reports button
        IconButton(
          icon: const Icon(Icons.assignment, color: Colors.black87),
          onPressed: () {
            context.push('/manager-reports');
          },
          tooltip: 'Báo cáo nhân viên',
        ),
        // Multi-Account Switcher
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📬 Thông báo đang được phát triển'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.success,
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
          colors: [Color(0xFF34D399), AppColors.success],
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
          colors: [Color(0xFF34D399), AppColors.success],
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
                AppColors.info,
                '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Khách hàng',
                '$customers',
                Icons.person,
                AppColors.primary,
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
                AppColors.success,
                '${orderChange >= 0 ? '+' : ''}${orderChange.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hiệu suất',
                '${performance.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.warning,
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
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
                AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Đơn hàng',
                'Xử lý đơn',
                Icons.receipt_long,
                AppColors.success,
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
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Báo cáo',
                'Tạo báo cáo',
                Icons.assessment,
                AppColors.primary,
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

  // =============================================
  // CÔNG NỢ OVERVIEW SECTION
  // =============================================
  Widget _buildCongNoSection() {
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCongNoData(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!;
        final cf = NumberFormat('#,###', 'vi_VN');
        final totalOutstanding = (data['total_outstanding'] ?? 0).toDouble();
        final totalOverdue = (data['total_overdue'] ?? 0).toDouble();
        final customerCount = data['customer_count'] ?? 0;
        final overdueCount = data['overdue_count'] ?? 0;
        final agingBuckets = data['aging'] as Map<String, double>? ?? {};
        final overduePercent = totalOutstanding > 0
            ? (totalOverdue / totalOutstanding * 100) : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 8),
                  Text('Công nợ phải thu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: overdueCount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      overdueCount > 0 ? '$overdueCount quá hạn' : 'Tốt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: overdueCount > 0 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Overdue alert banner
              if (overdueCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.money_off, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ $overdueCount khoản quá hạn · ${cf.format(totalOverdue)}₫',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildCongNoStatCard(
                      'Tổng công nợ',
                      '${cf.format(totalOutstanding)}₫',
                      Icons.monetization_on,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCongNoStatCard(
                      'Quá hạn',
                      '${cf.format(totalOverdue)}₫',
                      Icons.warning_amber_rounded,
                      Colors.red,
                      subtitle: '${overduePercent.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildCongNoStatCard(
                      'Khách hàng nợ',
                      '$customerCount',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCongNoStatCard(
                      '>60 ngày',
                      '${cf.format((agingBuckets['61-90'] ?? 0) + (agingBuckets['90+'] ?? 0))}₫',
                      Icons.schedule,
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              // Aging bar
              if (totalOutstanding > 0) ...[
                const SizedBox(height: 14),
                _buildAgingBar(agingBuckets, totalOutstanding),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadCongNoData(String companyId) async {
    try {
      final supabase = Supabase.instance.client;
      final receivables = await supabase
          .from('v_receivables_aging')
          .select('customer_id, balance, aging_bucket, days_overdue')
          .eq('company_id', companyId);

      double totalOutstanding = 0;
      double totalOverdue = 0;
      int overdueCount = 0;
      final customers = <String>{};
      final aging = <String, double>{
        'current': 0, '1-30': 0, '31-60': 0, '61-90': 0, '90+': 0
      };

      for (final r in (receivables as List)) {
        final bal = ((r['balance'] ?? 0) as num).toDouble();
        final bucket = r['aging_bucket']?.toString() ?? 'current';
        final daysOverdue = (r['days_overdue'] ?? 0) as num;

        totalOutstanding += bal;
        aging[bucket] = (aging[bucket] ?? 0) + bal;
        customers.add(r['customer_id'].toString());

        if (daysOverdue > 0) {
          totalOverdue += bal;
          overdueCount++;
        }
      }

      return {
        'total_outstanding': totalOutstanding,
        'total_overdue': totalOverdue,
        'customer_count': customers.length,
        'overdue_count': overdueCount,
        'aging': aging,
      };
    } catch (e) {
      return {};
    }
  }

  Widget _buildCongNoStatCard(String title, String value, IconData icon,
      MaterialColor color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color.shade700, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                const SizedBox(height: 1),
                Text(value, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color.shade700)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 9, color: color.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBar(Map<String, double> aging, double total) {
    final buckets = [
      ('Chưa hạn', aging['current'] ?? 0, Colors.green),
      ('1-30d', aging['1-30'] ?? 0, Colors.yellow.shade700),
      ('31-60d', aging['31-60'] ?? 0, Colors.orange),
      ('61-90d', aging['61-90'] ?? 0, Colors.deepOrange),
      ('>90d', aging['90+'] ?? 0, Colors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 8,
            child: Row(
              children: buckets.map((b) {
                final pct = total > 0 ? b.$2 / total : 0.0;
                if (pct <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (pct * 1000).round().clamp(1, 1000),
                  child: Container(color: b.$3),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: buckets.where((b) => b.$2 > 0).map((b) {
            final cf = NumberFormat.compact(locale: 'vi');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: b.$3, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('${b.$1}: ${cf.format(b.$2)}₫',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
