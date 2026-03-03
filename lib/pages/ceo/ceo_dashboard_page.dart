import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ceo_business_provider.dart';
import '../../providers/ceo_tab_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/gamification/ceo_game_summary_card.dart';
import '../../widgets/multi_account_switcher.dart';
import 'ceo_main_layout.dart';
import 'ceo_notifications_page.dart';
import 'ceo_profile_page.dart';

/// CEO Dashboard Page — The CEO's Morning View
/// Real data from sales_orders, customers, deliveries, payments
class CEODashboardPage extends ConsumerStatefulWidget {
  const CEODashboardPage({super.key});

  @override
  ConsumerState<CEODashboardPage> createState() => _CEODashboardPageState();
}

class _CEODashboardPageState extends ConsumerState<CEODashboardPage> {
  final _cf = NumberFormat('#,###', 'vi_VN');
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    final pulseAsync = ref.watch(todayBusinessPulseProvider);
    final kpisAsync = ref.watch(realCEOKPIsProvider);
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayBusinessPulseProvider);
          ref.invalidate(realCEOKPIsProvider);
          ref.invalidate(pendingApprovalsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. CEO GAME PROFILE — RPG Summary
              CeoGameSummaryCard(
                onTap: () => context.push(AppRoutes.questHub),
              ),
              const SizedBox(height: 16),

              // 1. TODAY'S PULSE — First thing CEO sees
              _buildTodayPulse(pulseAsync),
              const SizedBox(height: 20),

              // 2. REAL KPIs — Monthly business health
              _buildRealKPIs(kpisAsync),
              const SizedBox(height: 20),

              // 3. APPROVAL CENTER — CEO decisions needed
              _buildApprovalCenter(approvalsAsync),
              const SizedBox(height: 20),

              // 4. CÔNG NỢ OVERVIEW — Receivables aging
              _buildCongNoOverviewSection(),
              const SizedBox(height: 20),

              // 5. QUICK ACTIONS
              _buildQuickActionsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // APP BAR — With REAL notification count
  // =========================================================================
  PreferredSizeWidget _buildAppBar() {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'CEO Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEONotificationsPage(),
              ),
            );
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black54),
              // REAL notification badge
              unreadCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEOProfilePage(),
              ),
            );
          },
          icon: const Icon(Icons.person_outline, color: Colors.black54),
        ),
      ],
    );
  }

  // =========================================================================
  // 1. TODAY'S BUSINESS PULSE — Real-time morning view
  // =========================================================================
  Widget _buildTodayPulse(AsyncValue<TodayPulse> pulseAsync) {
    return pulseAsync.when(
      data: (pulse) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, const Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Hôm nay',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Revenue highlight
            Text(
              _currencyFormat.format(pulse.todayRevenue),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Doanh thu hôm nay',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Quick stats row
            Row(
              children: [
                _pulseChip(Icons.receipt_long, '${pulse.ordersCreated}',
                    'Đơn hàng'),
                const SizedBox(width: 8),
                _pulseChip(Icons.local_shipping, '${pulse.deliveringCount}',
                    'Đang giao'),
                const SizedBox(width: 8),
                _pulseChip(Icons.payments,
                    _cf.format(pulse.paymentsCollected), 'Thu tiền'),
                const SizedBox(width: 8),
                _pulseChip(
                    Icons.person_add, '${pulse.newCustomers}', 'KH mới'),
              ],
            ),

            // Approval alert
            if (pulse.pendingOrders > 0) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _navigateToTab(CEOTabs.tasks),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${pulse.pendingOrders} đơn hàng chờ duyệt',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Lỗi tải dữ liệu: $e'),
      ),
    );
  }

  Widget _pulseChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. REAL KPIs — from actual sales_orders data
  // =========================================================================
  Widget _buildRealKPIs(AsyncValue<CEOKPIs> kpisAsync) {
    return kpisAsync.when(
      data: (kpis) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số kinh doanh tháng này',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Doanh thu',
                  _currencyFormat.format(kpis.monthlyRevenue),
                  Icons.trending_up,
                  const Color(0xFF4CAF50),
                  kpis.revenueGrowth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  'Lợi nhuận gộp',
                  _currencyFormat.format(kpis.grossProfit),
                  Icons.account_balance_wallet,
                  const Color(0xFF2196F3),
                  kpis.grossMargin,
                  suffix: '% margin',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Nhân viên',
                  '${kpis.totalEmployees}',
                  Icons.group,
                  const Color(0xFF9C27B0),
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  'Khách hàng',
                  '${kpis.totalCustomers}',
                  Icons.store,
                  const Color(0xFFFF9800),
                  null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Đơn hoàn thành',
                  '${kpis.completedOrdersThisMonth}',
                  Icons.check_circle,
                  const Color(0xFF00BCD4),
                  null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  'Công nợ',
                  '${_cf.format(kpis.totalOutstanding)}₫',
                  Icons.account_balance,
                  kpis.totalOutstanding > 0
                      ? const Color(0xFFE53935)
                      : const Color(0xFF4CAF50),
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Lỗi: $e'),
    );
  }

  Widget _kpiCard(
      String title, String value, IconData icon, Color color, double? change,
      {String suffix = '%'}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (change >= 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}$suffix',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: change >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. APPROVAL CENTER — Quick CEO decisions
  // =========================================================================
  Widget _buildApprovalCenter(AsyncValue<PendingApprovals> approvalsAsync) {
    return approvalsAsync.when(
      data: (approvals) {
        if (approvals.totalPending == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Text(
                  'Không có mục nào chờ duyệt',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions,
                    color: Colors.orange.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Chờ duyệt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${approvals.totalPending}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pending orders
            if (approvals.pendingOrders.isNotEmpty)
              _approvalCategory(
                'Đơn hàng chờ duyệt',
                Icons.receipt_long,
                Colors.blue,
                approvals.pendingOrders.take(3).map((o) {
                  final orderNumber = o['order_number'] ?? '';
                  final total = ((o['total'] ?? 0) as num).toDouble();
                  final customerName =
                      (o['customers'] as Map?)?['name'] ?? 'N/A';
                  return _approvalItem(
                    '#$orderNumber',
                    '$customerName • ${_cf.format(total)}₫',
                    Icons.receipt_long,
                    Colors.blue,
                  );
                }).toList(),
                approvals.pendingOrders.length,
              ),

            // Pending task approvals
            if (approvals.pendingTaskApprovals.isNotEmpty)
              _approvalCategory(
                'Công việc chờ duyệt',
                Icons.assignment,
                Colors.orange,
                approvals.pendingTaskApprovals.take(3).map((t) {
                  final taskTitle =
                      (t['tasks'] as Map?)?['title'] ?? 'Chưa có tiêu đề';
                  final type = t['type'] ?? '';
                  return _approvalItem(
                    taskTitle,
                    'Loại: $type',
                    Icons.assignment,
                    Colors.orange,
                  );
                }).toList(),
                approvals.pendingTaskApprovals.length,
              ),

            // Pending other approvals
            if (approvals.pendingApprovalRequests.isNotEmpty)
              _approvalCategory(
                'Yêu cầu phê duyệt khác',
                Icons.approval,
                Colors.purple,
                approvals.pendingApprovalRequests.take(3).map((a) {
                  final desc = a['description'] ?? '';
                  final type = a['type'] ?? '';
                  return _approvalItem(
                      desc, 'Loại: $type', Icons.approval, Colors.purple);
                }).toList(),
                approvals.pendingApprovalRequests.length,
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _approvalCategory(String title, IconData icon, Color color,
      List<Widget> items, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _approvalItem(
      String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // CÔNG NỢ OVERVIEW SECTION
  // =============================================
  Widget _buildCongNoOverviewSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCongNoData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, 
                    color: Colors.orange.shade700, size: 22),
                const SizedBox(width: 8),
                Text('Công nợ phải thu',
                    style: TextStyle(
                      fontSize: 18,
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
            // Main stats row
            Row(
              children: [
                Expanded(
                  child: _buildCongNoStatCard(
                    'Tổng công nợ',
                    '${cf.format(totalOutstanding)} ₫',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCongNoStatCard(
                    'Quá hạn',
                    '${cf.format(totalOverdue)} ₫',
                    Icons.warning_amber_rounded,
                    Colors.red,
                    subtitle: '${overduePercent.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCongNoStatCard(
                    'Quá hạn >60 ngày',
                    '${cf.format((agingBuckets['61-90'] ?? 0) + (agingBuckets['90+'] ?? 0))} ₫',
                    Icons.schedule,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
            // Aging bar
            if (totalOutstanding > 0) ...[
              const SizedBox(height: 16),
              _buildAgingBarCEO(agingBuckets, totalOutstanding),
            ],
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadCongNoData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get receivables summary
      final receivables = await supabase
          .from('v_receivables_aging')
          .select('customer_id, balance, aging_bucket, days_overdue');
      
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color.shade700)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 10, color: color.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBarCEO(Map<String, double> aging, double total) {
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
        // Aging bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
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
        // Legend
        Wrap(
          spacing: 12,
          children: buckets.where((b) => b.$2 > 0).map((b) {
            final cf = NumberFormat.compact(locale: 'vi');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: b.$3, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${b.$1}: ${cf.format(b.$2)}₫',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard('Phân tích\nKPI', Icons.analytics,
                const Color(0xFF388E3C), () => _navigateToTab(CEOTabs.analytics)),
            const SizedBox(width: 12),
            _actionCard('Quản lý\nNhân sự', Icons.people,
                const Color(0xFFD32F2F), () => _navigateToTab(CEOTabs.companies)),
            const SizedBox(width: 12),
            _actionCard('Công việc', Icons.assignment,
                const Color(0xFFFF9800), () => _navigateToTab(CEOTabs.tasks)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard('Báo cáo\ntài chính', Icons.assessment,
                AppColors.primary, () => _navigateToTab(CEOTabs.reports)),
            const SizedBox(width: 12),
            _actionCard('AI Center', Icons.auto_awesome,
                const Color(0xFF7B1FA2), () => _navigateToTab(CEOTabs.ai)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Placeholder
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to a specific tab in CEO Main Layout
  void _navigateToTab(int tabIndex) {
    ceoMainLayoutKey.currentState?.navigateToTab(tabIndex);
  }
}
