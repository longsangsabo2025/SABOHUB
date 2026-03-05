import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ceo_business_provider.dart';
import '../../providers/ceo_tab_provider.dart';
import '../../widgets/gamification/ceo_game_summary_card.dart';
import '../../widgets/company_quick_access_cards.dart';
import '../../widgets/multi_account_switcher.dart';
import '../../core/keys/ceo_keys.dart';
import 'ceo_main_layout.dart';
import 'ceo_profile_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

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

  // Track expanded states for collapsible sections
  bool _kpisExpanded = false;
  bool _congNoExpanded = false;

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
              // 0. CEO GAME PROFILE — Compact RPG Summary
              CeoGameSummaryCard(
                onTap: () => context.push(AppRoutes.questHub),
              ),
              const SizedBox(height: 12),

              // 1. HERO CARD — Today's Pulse + Key Numbers
              _buildHeroCard(pulseAsync, kpisAsync),
              const SizedBox(height: 12),

              // 2. APPROVAL CENTER — Only if items pending
              _buildApprovalCenter(approvalsAsync),
              
              // 3. CÔNG TY CON — Quick Access
              const CompanyQuickAccessCards(),
              const SizedBox(height: 12),

              // 4. COLLAPSIBLE: Chi tiết KPIs
              _buildCollapsibleKPIs(kpisAsync),
              const SizedBox(height: 8),

              // 5. COLLAPSIBLE: Công nợ
              _buildCollapsibleCongNo(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // HERO CARD — Combined Today's Pulse + Key KPIs (Compact)
  // =========================================================================  
  Widget _buildHeroCard(AsyncValue<TodayPulse> pulseAsync, AsyncValue<CEOKPIs> kpisAsync) {
    return pulseAsync.when(
      data: (pulse) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
                SizedBox(width: 6),
                Text(
                  'Hôm nay • ${DateFormat('dd/MM').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const Spacer(),
                // Pending orders badge
                if (pulse.pendingOrders > 0)
                  GestureDetector(
                    onTap: () => _navigateToTab(CEOTabs.tasks),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${pulse.pendingOrders} chờ duyệt',
                            style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Revenue highlight
            Text(
              _currencyFormat.format(pulse.todayRevenue),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            Text(
              'Doanh thu hôm nay',
              style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Quick stats - 4 columns compact
            Row(
              children: [
                _heroStat(Icons.receipt_long, '${pulse.ordersCreated}', 'Đơn'),
                _heroStat(Icons.local_shipping, '${pulse.deliveringCount}', 'Giao'),
                _heroStat(Icons.payments, _cf.format(pulse.paymentsCollected), 'Thu'),
                _heroStat(Icons.person_add, '${pulse.newCustomers}', 'KH mới'),
              ],
            ),
            
            // Monthly KPIs row (from kpisAsync)
            kpisAsync.when(
              data: (kpis) => Column(
                children: [
                  Divider(color: Theme.of(context).colorScheme.surface24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _monthKpi('Doanh thu tháng', _currencyFormat.format(kpis.monthlyRevenue)),
                      _monthKpi('Lợi nhuận', '${kpis.grossMargin.toStringAsFixed(1)}%'),
                      _monthKpi('Công nợ', '${_cf.format(kpis.totalOutstanding)}₫'),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      loading: () => Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
            ),
            const SizedBox(height: 6),
            Text('$e', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(todayBusinessPulseProvider);
                ref.invalidate(realCEOKPIsProvider);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.surface70, size: 16),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.surface60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _monthKpi(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.surface60, fontSize: 10)),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  // =========================================================================
  // COLLAPSIBLE KPIs Section
  // =========================================================================
  Widget _buildCollapsibleKPIs(AsyncValue<CEOKPIs> kpisAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Chi tiết KPIs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          initiallyExpanded: _kpisExpanded,
          onExpansionChanged: (expanded) => setState(() => _kpisExpanded = expanded),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildKPIContent(kpisAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIContent(AsyncValue<CEOKPIs> kpisAsync) {
    return kpisAsync.when(
      data: (kpis) => Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniKpiCard('Doanh thu', _currencyFormat.format(kpis.monthlyRevenue), Icons.trending_up, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _miniKpiCard('Lợi nhuận', _currencyFormat.format(kpis.grossProfit), Icons.account_balance_wallet, Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniKpiCard('Nhân viên', '${kpis.totalEmployees}', Icons.group, Colors.purple)),
              const SizedBox(width: 8),
              Expanded(child: _miniKpiCard('Khách hàng', '${kpis.totalCustomers}', Icons.store, Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniKpiCard('Đơn xong', '${kpis.completedOrdersThisMonth}', Icons.check_circle, Colors.teal)),
              const SizedBox(width: 8),
              Expanded(child: _miniKpiCard('Công nợ', '${_cf.format(kpis.totalOutstanding)}₫', Icons.account_balance, Colors.red)),
            ],
          ),
        ],
      ),
      loading: () => SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Lỗi: $e'),
    );
  }

  Widget _miniKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // COLLAPSIBLE Công Nợ Section
  // =========================================================================
  Widget _buildCollapsibleCongNo() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Công nợ phải thu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          initiallyExpanded: _congNoExpanded,
          onExpansionChanged: (expanded) => setState(() => _congNoExpanded = expanded),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCongNoContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCongNoContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCongNoData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Không có dữ liệu công nợ'),
          );
        }
        final data = snapshot.data!;
        final cf = NumberFormat('#,###', 'vi_VN');
        final totalOutstanding = (data['total_outstanding'] ?? 0).toDouble();
        final totalOverdue = (data['total_overdue'] ?? 0).toDouble();
        final customerCount = data['customer_count'] ?? 0;
        final agingBuckets = data['aging'] as Map<String, double>? ?? {};

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _miniKpiCard('Tổng nợ', '${cf.format(totalOutstanding)}₫', Icons.monetization_on, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _miniKpiCard('Quá hạn', '${cf.format(totalOverdue)}₫', Icons.warning, Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _miniKpiCard('KH nợ', '$customerCount', Icons.people, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _miniKpiCard('>60 ngày', '${cf.format((agingBuckets['61-90'] ?? 0) + (agingBuckets['90+'] ?? 0))}₫', Icons.schedule, Colors.deepOrange)),
              ],
            ),
            if (totalOutstanding > 0) ...[
              const SizedBox(height: 12),
              _buildAgingBarCEO(agingBuckets, totalOutstanding),
            ],
          ],
        );
      },
    );
  }

  // =========================================================================
  // APP BAR — Simplified header
  // =========================================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface87),
        onPressed: () => ceoScaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        'CEO Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface87,
        ),
      ),
      actions: [
        MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEOProfilePage(),
              ),
            );
          },
          icon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurface54),
        ),
      ],
    );
  }

  // =========================================================================
  // APPROVAL CENTER — Quick CEO decisions
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
                SizedBox(width: 8),
                Text(
                  'Chờ duyệt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${approvals.totalPending}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
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
  // CÔNG NỢ DATA LOADING (used by collapsible section)
  // =============================================
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

  /// Navigate to a specific tab in CEO Main Layout
  void _navigateToTab(int tabIndex) {
    ceoMainLayoutKey.currentState?.navigateToTab(tabIndex);
  }
}
