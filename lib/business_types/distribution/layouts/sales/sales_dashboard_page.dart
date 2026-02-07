import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import '../../../../widgets/bug_report_dialog.dart';
import '../../../../widgets/realtime_notification_widgets.dart';
import '../../widgets/sales_features_widgets.dart';
import '../../../../pages/staff/staff_profile_page.dart';

/// Sales Dashboard Page - Modern 2026 UI
class SalesDashboardPage extends ConsumerStatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  ConsumerState<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends ConsumerState<SalesDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      final today = DateTime.now();
      final DateTimeRange effectiveRange = _dateFilter ?? DateTimeRange(
        start: DateTime(today.year, today.month, today.day),
        end: DateTime(today.year, today.month, today.day),
      );
      final rangeStart = effectiveRange.start;
      final rangeEnd = effectiveRange.end.add(const Duration(days: 1));
      final startOfMonth = DateTime(today.year, today.month, 1);

      final todayOrders = await supabase
          .from('sales_orders')
          .select('id, total')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .gte('created_at', rangeStart.toIso8601String())
          .lte('created_at', rangeEnd.toIso8601String());

      final monthOrders = await supabase
          .from('sales_orders')
          .select('id, total, status')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .gte('created_at', startOfMonth.toIso8601String());

      final recent = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '')
          .order('created_at', ascending: false)
          .limit(5);

      double todayRevenue = 0;
      for (var order in todayOrders) {
        todayRevenue += (order['total'] ?? 0).toDouble();
      }

      double monthRevenue = 0;
      int pendingCount = 0;
      int completedCount = 0;
      for (var order in monthOrders) {
        monthRevenue += (order['total'] ?? 0).toDouble();
        if (order['status'] == 'pending_approval' || order['status'] == 'draft') {
          pendingCount++;
        }
        if (order['status'] == 'completed') {
          completedCount++;
        }
      }

      setState(() {
        _stats = {
          'todayOrders': todayOrders.length,
          'todayRevenue': todayRevenue,
          'monthOrders': monthOrders.length,
          'monthRevenue': monthRevenue,
          'pendingOrders': pendingCount,
          'completedOrders': completedCount,
        };
        _recentOrders = List<Map<String, dynamic>>.from(recent);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load sales dashboard', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    // Modern Header
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.orange.shade700, Colors.orange.shade500],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (user?.name ?? 'S')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào, ${user?.name ?? 'Sales'}! 🎯',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user?.companyName ?? 'Công ty',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const RealtimeNotificationBell(iconColor: Colors.white),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onSelected: (value) async {
                                      if (value == 'profile') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const Scaffold(body: StaffProfilePage()),
                                          ),
                                        );
                                      } else if (value == 'bug_report') {
                                        BugReportDialog.show(context);
                                      } else if (value == 'logout') {
                                        await ref.read(authProvider.notifier).logout();
                                        if (context.mounted) context.go('/login');
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'profile',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 20),
                                            SizedBox(width: 8),
                                            Text('Tài khoản'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'bug_report',
                                        child: Row(
                                          children: [
                                            Icon(Icons.bug_report_outlined, size: 20, color: Colors.red.shade400),
                                            const SizedBox(width: 8),
                                            const Text('Báo cáo lỗi'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'logout',
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Today revenue card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date filter button
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showQuickDateRangePicker(context, current: _dateFilter);
                                        if (picked != null) {
                                          setState(() {
                                            _dateFilter = picked.start.year == 1970 ? null : picked;
                                            _isLoading = true;
                                          });
                                          _loadDashboardData();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              _dateFilter != null ? getDateRangeLabel(_dateFilter!) : 'Hôm nay',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _dateFilter != null ? 'Doanh thu ${getDateRangeLabel(_dateFilter!).toLowerCase()}' : 'Doanh thu hôm nay',
                                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                currencyFormat.format(_stats['todayRevenue'] ?? 0),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.shopping_cart, color: Colors.orange.shade700, size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${_stats['todayOrders'] ?? 0} đơn',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Monthly Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Tháng này',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Tổng đơn',
                                '${_stats['monthOrders'] ?? 0}',
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Chờ duyệt',
                                '${_stats['pendingOrders'] ?? 0}',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Hoàn thành',
                                '${_stats['completedOrders'] ?? 0}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Month revenue
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Doanh số tháng',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(_stats['monthRevenue'] ?? 0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // KPI Targets Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: KpiTargetsCard(),
                      ),
                    ),

                    // Recent Orders
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Đơn hàng gần đây',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_recentOrders.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có đơn hàng nào',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tạo đơn đầu tiên ngay!',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = _recentOrders[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, index == _recentOrders.length - 1 ? 100 : 8),
                              child: _buildOrderCard(order),
                            );
                          },
                          childCount: _recentOrders.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final status = order['status'] ?? 'draft';
    final total = (order['total'] ?? 0).toDouble();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    Color statusColor;
    String statusText;
    switch (status) {
      case 'draft':
        statusColor = Colors.grey;
        statusText = 'Nháp';
        break;
      case 'pending':
      case 'pending_approval':
        statusColor = Colors.amber;
        statusText = 'Chờ duyệt';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Đã duyệt';
        break;
      case 'processing':
        statusColor = Colors.purple;
        statusText = 'Đang xử lý';
        break;
      case 'ready':
        statusColor = Colors.indigo;
        statusText = 'Sẵn sàng';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?['name'] ?? 'Khách hàng',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${order['order_number'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
