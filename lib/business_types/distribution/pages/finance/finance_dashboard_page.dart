import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/bug_report_dialog.dart';
import '../../../../widgets/realtime_notification_widgets.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import '../../../../pages/staff/staff_profile_page.dart';

// ============================================================================
// FINANCE DASHBOARD PAGE - Modern 2026 UI
// ============================================================================
class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({super.key, this.onNavigate});
  
  final void Function(int index)? onNavigate;

  @override
  ConsumerState<FinanceDashboardPage> createState() =>
      _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentPayments = [];
  List<Map<String, dynamic>> _pendingTransfers = [];
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

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final DateTimeRange effectiveRange = _dateFilter ?? DateTimeRange(
        start: DateTime(today.year, today.month, 1),
        end: today,
      );
      final rangeStart = effectiveRange.start;
      final rangeEnd = effectiveRange.end.add(const Duration(days: 1));

      // Get total receivables from customers
      final customersData = await supabase
          .from('customers')
          .select('id, name, total_debt, credit_limit')
          .eq('company_id', companyId)
          .gt('total_debt', 0);

      double totalReceivable = 0;
      double overdueAmount = 0;
      int overdueCustomers = 0;

      for (var customer in customersData) {
        final debt = (customer['total_debt'] ?? 0).toDouble();
        totalReceivable += debt;
        // Giả định nợ quá hạn nếu vượt credit limit
        final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
        if (debt > creditLimit && creditLimit > 0) {
          overdueAmount += (debt - creditLimit);
          overdueCustomers++;
        }
      }

      // Get payments in date range
      final paymentsData = await supabase
          .from('customer_payments')
          .select('id, amount, payment_date, customers(name)')
          .eq('company_id', companyId)
          .gte('payment_date', rangeStart.toIso8601String())
          .lte('payment_date', rangeEnd.toIso8601String())
          .order('payment_date', ascending: false);

      double paidThisMonth = 0;
      for (var payment in paymentsData) {
        paidThisMonth += (payment['amount'] ?? 0).toDouble();
      }

      // Recent payments
      final recentPayments = await supabase
          .from('customer_payments')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .order('payment_date', ascending: false)
          .limit(5);

      // Pending transfer orders (awaiting finance confirmation)
      final pendingTransfers = await supabase
          .from('sales_orders')
          .select('id, order_number, total, customer_name, customer_phone, created_at, customers(name, phone)')
          .eq('company_id', companyId)
          .eq('payment_status', 'pending_transfer')
          .order('created_at', ascending: false)
          .limit(20);

      // Get revenue in date range (completed orders)
      final ordersData = await supabase
          .from('sales_orders')
          .select('id, total')
          .eq('company_id', companyId)
          .eq('status', 'completed')
          .gte('created_at', rangeStart.toIso8601String())
          .lte('created_at', rangeEnd.toIso8601String());
      
      double totalRevenue = 0;
      for (var order in ordersData) {
        totalRevenue += (order['total'] ?? 0).toDouble();
      }

      setState(() {
        _stats = {
          'totalReceivable': totalReceivable,
          'overdueAmount': overdueAmount,
          'overdueCustomers': overdueCustomers,
          'paidThisMonth': paidThisMonth,
          'paymentsCount': paymentsData.length,
          'customersWithDebt': customersData.length,
          'pendingTransfersCount': pendingTransfers.length,
          'totalRevenue': totalRevenue,
          'orderCount': ordersData.length,
        };
        _recentPayments = List<Map<String, dynamic>>.from(recentPayments);
        _pendingTransfers = List<Map<String, dynamic>>.from(pendingTransfers);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load finance dashboard', e);
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
                            colors: [
                              Colors.teal.shade700,
                              Colors.teal.shade500
                            ],
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
                                        (user?.name ?? 'F')[0].toUpperCase(),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào, ${user?.name ?? 'Kế toán'}! 💰',
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
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const RealtimeNotificationBell(
                                      iconColor: Colors.white),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 15, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        _dateFilter != null ? getDateRangeLabel(_dateFilter!) : 'Tháng này',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Total receivable card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tổng công nợ phải thu',
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${_stats['customersWithDebt'] ?? 0} KH',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currencyFormat.format(
                                          _stats['totalReceivable'] ?? 0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
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

                    // Stats Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Quá hạn',
                                currencyFormat
                                    .format(_stats['overdueAmount'] ?? 0),
                                '${_stats['overdueCustomers'] ?? 0} KH',
                                Icons.warning_amber,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Đã thu tháng này',
                                currencyFormat
                                    .format(_stats['paidThisMonth'] ?? 0),
                                '${_stats['paymentsCount'] ?? 0} giao dịch',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Overdue Alert Banner
                    if ((_stats['overdueAmount'] ?? 0) > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.money_off, color: Colors.red.shade700, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚠️ ${_stats['overdueCustomers'] ?? 0} khách hàng có công nợ quá hạn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tổng: ${currencyFormat.format(_stats['overdueAmount'] ?? 0)}',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => widget.onNavigate?.call(3), // Công nợ tab
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('Xem', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Quick Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flash_on,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text('Thao tác nhanh',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAction(
                                    'Ghi nhận\nthanh toán',
                                    Icons.add_card,
                                    Colors.green,
                                    () {
                                      // Navigate to Payments tab (index 4)
                                      widget.onNavigate?.call(4);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Xem\ncông nợ',
                                    Icons.list_alt,
                                    Colors.orange,
                                    () {
                                      // Navigate to Accounts Receivable tab (index 3)
                                      widget.onNavigate?.call(3);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    'Báo cáo\ntài chính',
                                    Icons.analytics,
                                    Colors.purple,
                                    () => _showFinancialReportDialog(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pending Transfers Section
                    if (_pendingTransfers.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.pending_actions, size: 20, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Chờ xác nhận chuyển khoản',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingTransfers.length}',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = _pendingTransfers[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _buildPendingTransferCard(order, currencyFormat),
                            );
                          },
                          childCount: _pendingTransfers.length,
                        ),
                      ),
                    ],

                    // Recent Payments
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                const Text('Thanh toán gần đây',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text('Xem tất cả')),
                          ],
                        ),
                      ),
                    ),

                    if (_recentPayments.isEmpty)
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
                                  child: Icon(Icons.inbox,
                                      size: 40, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                Text('Chưa có thanh toán nào',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final payment = _recentPayments[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16,
                                  index == _recentPayments.length - 1 ? 100 : 8),
                              child: _buildPaymentCard(payment),
                            );
                          },
                          childCount: _recentPayments.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTransferCard(Map<String, dynamic> order, NumberFormat currencyFormat) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final total = (order['total'] ?? 0).toDouble();
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();
    final customerName = order['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.pending, color: Colors.blue.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          '#$orderNumber',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (createdAt != null) ...[
                          Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                          Text(
                            DateFormat('dd/MM HH:mm').format(createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
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
                      color: Colors.blue.shade700,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⏳ Chờ xác nhận',
                      style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectTransfer(order['id'], orderNumber),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmTransfer(order['id'], orderNumber, total),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Đã nhận tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTransfer(String orderId, String orderNumber, double amount) async {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Xác nhận đã nhận tiền'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác nhận đã nhận tiền chuyển khoản cho đơn hàng #$orderNumber?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số tiền:'),
                  Text(
                    currencyFormat.format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      // 1. Update order: mark as paid with paid_amount = total
      await supabase.from('sales_orders').update({
        'payment_status': 'paid',
        'paid_amount': amount,
        'payment_confirmed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // 2. Create payment record in customer_payments
      // Get customer_id from the order
      final orderData = await supabase
          .from('sales_orders')
          .select('customer_id')
          .eq('id', orderId)
          .single();
      final customerId = orderData['customer_id'];

      if (customerId != null && companyId != null) {
        await supabase.from('customer_payments').insert({
          'company_id': companyId,
          'customer_id': customerId,
          'amount': amount,
          'payment_date': DateTime.now().toIso8601String(),
          'payment_method': 'transfer',
          'reference': 'Xác nhận CK đơn #$orderNumber',
          'notes': 'Xác nhận chuyển khoản bởi kế toán',
          'created_by': userId,
        });

        // 3. Update customer total_debt
        final customerData = await supabase
            .from('customers')
            .select('total_debt')
            .eq('id', customerId)
            .single();
        final currentDebt = (customerData['total_debt'] ?? 0).toDouble();
        final newDebt = (currentDebt - amount).clamp(0, double.infinity);
        await supabase.from('customers').update({
          'total_debt': newDebt,
        }).eq('id', customerId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ Đã xác nhận chuyển khoản đơn #$orderNumber'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectTransfer(String orderId, String orderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cancel, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Từ chối xác nhận'),
          ],
        ),
        content: Text('Từ chối xác nhận chuyển khoản đơn hàng #$orderNumber?\n\nĐơn hàng sẽ quay lại trạng thái chưa thanh toán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('sales_orders').update({
        'payment_status': 'unpaid',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Text('Đã từ chối xác nhận đơn #$orderNumber'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFinancialReportDialog() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Báo cáo tài chính',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Tổng quan tháng này',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats Summary
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Revenue Card
                      _buildReportCard(
                        'Doanh thu',
                        currencyFormat.format(_stats['totalRevenue'] ?? 0),
                        Icons.trending_up,
                        Colors.green,
                        '${(_stats['orderCount'] ?? 0)} đơn hàng',
                      ),
                      const SizedBox(height: 12),
                      
                      // Receivables Card
                      _buildReportCard(
                        'Công nợ phải thu',
                        currencyFormat.format(_stats['totalReceivable'] ?? 0),
                        Icons.account_balance_wallet,
                        Colors.orange,
                        '${(_stats['customersWithDebt'] ?? 0)} khách hàng',
                      ),
                      const SizedBox(height: 12),
                      
                      // Collected Card
                      _buildReportCard(
                        'Đã thu trong tháng',
                        currencyFormat.format(_stats['paidThisMonth'] ?? 0),
                        Icons.payments,
                        Colors.blue,
                        '${(_stats['paymentsCount'] ?? 0)} lần thanh toán',
                      ),
                      const SizedBox(height: 12),
                      
                      // Pending Transfers
                      _buildReportCard(
                        'Chờ xác nhận CK',
                        '${_pendingTransfers.length} đơn',
                        Icons.pending_actions,
                        Colors.purple,
                        currencyFormat.format(_pendingTransfers.fold<double>(
                          0, (sum, o) => sum + (o['total'] ?? 0).toDouble())),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onNavigate?.call(3); // Go to Công nợ tab
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Xem công nợ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onNavigate?.call(4); // Go to Thu tiền tab
                      },
                      icon: const Icon(Icons.payments),
                      label: const Text('Thu tiền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                )),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final customer = payment['customers'] as Map<String, dynamic>?;
    final amount = (payment['amount'] ?? 0).toDouble();
    final paymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments, color: Colors.green.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer?['name'] ?? 'Khách hàng',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (paymentDate != null)
                  Text(DateFormat('dd/MM/yyyy').format(paymentDate),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('+${currencyFormat.format(amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
