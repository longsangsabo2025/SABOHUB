import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_sabohub/core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/cached_data_providers.dart'; // PHASE 3B: Manager cache
import '../../providers/auth_provider.dart';
import '../../widgets/company_quick_access_cards.dart';
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
    final currentUser = ref.watch(currentUserProvider);
    final branchId = currentUser?.branchId;

    // PHASE 3B: Use CACHED providers for instant loads (5min TTL)
    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider(branchId));
    final activitiesAsync = ref.watch(
        cachedManagerRecentActivitiesProvider((branchId: branchId, limit: 10)));

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate cache to force fresh data
          ref.invalidateManagerDashboard(branchId);
        },
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kpisAsync.when(
                data: (cachedKpis) => _buildWelcomeSection(cachedKpis),
                loading: () => _buildLoadingWelcome(),
                error: (e, _) => _buildErrorCard(
                  'Lỗi tải dữ liệu tổng quan',
                  '$e',
                  () => ref.invalidateManagerDashboard(branchId),
                ),
              ),
              AppSpacing.gapXXL,
              kpisAsync.when(
                data: (cachedKpis) => _buildQuickStats(cachedKpis),
                loading: () => _buildLoadingStats(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              AppSpacing.gapXXL,
              // Quick Access Cards for corporation managers
              const CompanyQuickAccessCards(),
              AppSpacing.gapXXL,
              _buildCongNoSection(),
              AppSpacing.gapXXL,
              _buildOperationsSection(),
              AppSpacing.gapXXL,
              activitiesAsync.when(
                data: (cachedActivities) => _buildRecentActivities(
                    List<Map<String, dynamic>>.from(cachedActivities)),
                loading: () => _buildLoadingActivities(),
                error: (e, _) => _buildErrorCard(
                  'Lỗi tải hoạt động gần đây',
                  '$e',
                  () => ref.invalidateManagerDashboard(branchId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Quản lý',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // View Reports button
        IconButton(
          icon: const Icon(Icons.assignment, color: AppColors.textPrimary),
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
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
        ),
        IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
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
      padding: AppSpacing.paddingXL,
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
          AppSpacing.gapSM,
          const Text(
            'Tổng quan hoạt động hôm nay',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          AppSpacing.gapLG,
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
              AppSpacing.hGapMD,
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
      padding: AppSpacing.paddingXL,
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
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: textColor),
          AppSpacing.gapSM,
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
        AppSpacing.gapLG,
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
            AppSpacing.hGapMD,
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
        AppSpacing.gapMD,
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
            AppSpacing.hGapMD,
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
        AppSpacing.gapLG,
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
      padding: AppSpacing.paddingLG,
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
          AppSpacing.gapMD,
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
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
        AppSpacing.gapLG,
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Đơn hàng',
                'Xử lý đơn',
                Icons.receipt_long,
                AppColors.success,
              ),
            ),
            AppSpacing.hGapMD,
            Expanded(
              child: _buildActionCard(
                'Kho hàng',
                'Kiểm tra tồn',
                Icons.inventory,
                AppColors.warning,
              ),
            ),
          ],
        ),
        AppSpacing.gapMD,
        Row(
          children: [
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
        padding: AppSpacing.paddingLG,
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
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.gapMD,
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
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
        AppSpacing.gapLG,
        Container(
          padding: AppSpacing.paddingLG,
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
                    padding: AppSpacing.paddingXL,
                    child: Text(
                      'Chưa có nhân viên',
                      style: TextStyle(color: AppColors.grey500),
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
        return AppColors.success;
      case 'orange':
        return AppColors.warning;
      case 'grey':
        return AppColors.grey500;
      default:
        return AppColors.grey500;
    }
  }

  Widget _buildTeamMember(
      String name, String shift, String status, Color statusColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.grey200,
          child: Text(
            name[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        AppSpacing.hGapMD,
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
                  color: AppColors.grey600,
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
        AppSpacing.gapLG,
        Container(
          padding: AppSpacing.paddingLG,
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
                    padding: AppSpacing.paddingXL,
                    child: Text(
                      'Chưa có hoạt động',
                      style: TextStyle(color: AppColors.grey500),
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
        AppSpacing.gapLG,
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
          padding: AppSpacing.paddingSM,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.info, size: 16),
        ),
        AppSpacing.hGapMD,
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
                  color: AppColors.grey600,
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
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;
    if (companyId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCongNoData(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: AppSpacing.paddingXXL,
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
          padding: AppSpacing.paddingLG,
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
                      color: AppColors.warningDark, size: 22),
                  AppSpacing.hGapSM,
                  Text('Công nợ phải thu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey800,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: overdueCount > 0 ? AppColors.errorLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      overdueCount > 0 ? '$overdueCount quá hạn' : 'Tốt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: overdueCount > 0 ? AppColors.errorDark : AppColors.successDark,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMD,
              // Overdue alert banner
              if (overdueCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorLight),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.money_off, color: AppColors.errorDark, size: 18),
                      AppSpacing.hGapSM,
                      Expanded(
                        child: Text(
                          '⚠️ $overdueCount khoản quá hạn · ${cf.format(totalOverdue)}₫',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorDark,
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
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCongNoStatCard(
                      'Quá hạn',
                      '${cf.format(totalOverdue)}₫',
                      Icons.warning_amber_rounded,
                      AppColors.error,
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
                      AppColors.info,
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
      Color color, {String? subtitle}) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          AppSpacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: AppColors.grey600)),
                const SizedBox(height: 1),
                Text(value, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBar(Map<String, double> aging, double total) {
    final buckets = [
      ('Chưa hạn', aging['current'] ?? 0, AppColors.success),
      ('1-30d', aging['1-30'] ?? 0, Colors.yellow.shade700),
      ('31-60d', aging['31-60'] ?? 0, AppColors.warning),
      ('61-90d', aging['61-90'] ?? 0, Colors.deepOrange),
      ('>90d', aging['90+'] ?? 0, AppColors.error),
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
                    style: TextStyle(fontSize: 9, color: AppColors.grey600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String title, String detail, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingXXL,
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          AppSpacing.gapLG,
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          AppSpacing.gapSM,
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLG,
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
