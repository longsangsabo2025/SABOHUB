import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/bug_report_dialog.dart';
import '../../../../widgets/realtime_notification_widgets.dart';
import '../../../../pages/staff/staff_profile_page.dart';
import 'delivery_detail_sheet.dart';
import 'delivery_completion_dialog.dart';

/// DRIVER ROUTE PAGE - Lộ trình giao hàng - Modern 2026 UI
class DriverRoutePage extends ConsumerStatefulWidget {
  const DriverRoutePage({super.key});

  @override
  ConsumerState<DriverRoutePage> createState() => DriverRoutePageState();
}

class DriverRoutePageState extends ConsumerState<DriverRoutePage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayDeliveries = [];
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void refresh() {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (companyId == null || driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get pending deliveries from sales_orders (awaiting_pickup - ready for any driver)
      final pendingResp = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .count();

      // Get in-progress deliveries (this driver is delivering) from deliveries table
      final inProgressResp = await supabase
          .from('deliveries')
          .select('id')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'in_progress')
          .count();

      // Get today's completed deliveries from deliveries table
      final completedResp = await supabase
          .from('deliveries')
          .select('id, sales_orders:order_id(total)')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String());

      double todayRevenue = 0;
      for (var delivery in completedResp) {
        final order = delivery['sales_orders'] as Map<String, dynamic>?;
        todayRevenue += (order?['total'] as num?)?.toDouble() ?? 0;
      }

      // Get pending orders from sales_orders (awaiting_pickup)
      final pendingOrders = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .order('created_at', ascending: true)
          .limit(20);

      // Get in-progress deliveries from deliveries table (assigned to this driver)
      final inProgressDeliveries = await supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name,
              customers(name, phone, address),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'in_progress')
          .order('created_at', ascending: true)
          .limit(20);

      // Combine both lists - pending orders first, then in-progress
      final allDeliveries = <Map<String, dynamic>>[];
      
      // Add pending orders with a marker
      for (var order in pendingOrders) {
        allDeliveries.add({
          ...order,
          '_source': 'sales_orders',
          '_isPending': true,
        });
      }
      
      // Add in-progress deliveries with a marker
      for (var delivery in inProgressDeliveries) {
        allDeliveries.add({
          ...delivery,
          '_source': 'deliveries',
          '_isPending': false,
        });
      }

      setState(() {
        _stats = {
          'pending': pendingResp.count,
          'inProgress': inProgressResp.count,
          'completedToday': completedResp.length,
          'todayRevenue': todayRevenue,
        };
        _todayDeliveries = allDeliveries;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load driver dashboard', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
                      child: _buildHeader(user),
                    ),

                    // Stats Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard('Chờ nhận', '${_stats['pending'] ?? 0}', Icons.pending_actions, Colors.orange)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Đang giao', '${_stats['inProgress'] ?? 0}', Icons.local_shipping, Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Hoàn thành', '${_stats['completedToday'] ?? 0}', Icons.check_circle, Colors.green)),
                          ],
                        ),
                      ),
                    ),

                    // Today's Revenue Card
                    SliverToBoxAdapter(child: _buildRevenueCard()),

                    // Section title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Đơn cần giao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (_todayDeliveries.isNotEmpty)
                              TextButton(onPressed: () {}, child: Text('Xem tất cả (${_todayDeliveries.length})')),
                          ],
                        ),
                      ),
                    ),

                    // Delivery list
                    if (_todayDeliveries.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final delivery = _todayDeliveries[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, index == _todayDeliveries.length - 1 ? 100 : 12),
                              child: _buildDeliveryCard(delivery),
                            );
                          },
                          childCount: _todayDeliveries.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
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
                      (user?.name ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, ${user?.name ?? 'Tài xế'}! 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(user?.companyName ?? 'Công ty',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
                const RealtimeNotificationBell(iconColor: Colors.white),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Scaffold(body: StaffProfilePage())));
                    } else if (value == 'bug_report') {
                      BugReportDialog.show(context);
                    } else if (value == 'logout') {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 8), Text('Tài khoản')])),
                    PopupMenuItem(value: 'bug_report', child: Row(children: [Icon(Icons.bug_report_outlined, size: 20, color: Colors.red.shade400), const SizedBox(width: 8), const Text('Báo cáo lỗi')])),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Đăng xuất', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _showTodayRevenueDetails,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.payments, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thu hộ hôm nay', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(currencyFormat.format(_stats['todayRevenue'] ?? 0),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTodayRevenueDetails() async {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    final driverId = authState.user?.id;

    if (companyId == null || driverId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get today's completed deliveries with payment info
      final completedData = await supabase
          .from('deliveries')
          .select('id, completed_at, sales_orders:order_id(id, order_number, total, customer_name, payment_status, payment_method, customers(name))')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      Navigator.pop(context); // Close loading

      // Calculate stats by payment method
      double cashTotal = 0;
      double transferTotal = 0;
      double debtTotal = 0;
      int cashCount = 0;
      int transferCount = 0;
      int debtCount = 0;

      final deliveries = List<Map<String, dynamic>>.from(completedData);

      for (var delivery in deliveries) {
        final order = delivery['sales_orders'] as Map<String, dynamic>?;
        if (order == null) continue;

        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final paymentStatus = order['payment_status']?.toString().toLowerCase() ?? '';
        final paymentMethod = order['payment_method']?.toString().toLowerCase() ?? '';

        if (paymentStatus == 'paid') {
          if (paymentMethod == 'transfer') {
            transferTotal += total;
            transferCount++;
          } else {
            cashTotal += total;
            cashCount++;
          }
        } else {
          debtTotal += total;
          debtCount++;
        }
      }

      // Show bottom sheet
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _buildRevenueDetailSheet(
          deliveries: deliveries,
          cashTotal: cashTotal,
          cashCount: cashCount,
          transferTotal: transferTotal,
          transferCount: transferCount,
          debtTotal: debtTotal,
          debtCount: debtCount,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      AppLogger.error('Failed to load revenue details', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Widget _buildRevenueDetailSheet({
    required List<Map<String, dynamic>> deliveries,
    required double cashTotal,
    required int cashCount,
    required double transferTotal,
    required int transferCount,
    required double debtTotal,
    required int debtCount,
  }) {
    final totalRevenue = cashTotal + transferTotal;
    final totalOrders = deliveries.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.payments, color: Colors.green.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thu hộ hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$totalOrders đơn • ${currencyFormat.format(totalRevenue + debtTotal)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRevenueStatCard(
                      icon: Icons.money,
                      label: 'Tiền mặt',
                      count: cashCount,
                      amount: cashTotal,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRevenueStatCard(
                      icon: Icons.account_balance,
                      label: 'Chuyển khoản',
                      count: transferCount,
                      amount: transferTotal,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRevenueStatCard(
                      icon: Icons.pending_actions,
                      label: 'Công nợ',
                      count: debtCount,
                      amount: debtTotal,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // List
            Expanded(
              child: deliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Chưa có đơn hoàn thành', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: deliveries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final delivery = deliveries[index];
                        return _buildDeliveryDetailCard(delivery);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStatCard({
    required IconData icon,
    required String label,
    required int count,
    required double amount,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 20),
          const SizedBox(height: 6),
          Text('$count đơn', style: TextStyle(fontSize: 11, color: color.shade700)),
          const SizedBox(height: 2),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color.shade600)),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailCard(Map<String, dynamic> delivery) {
    final order = delivery['sales_orders'] as Map<String, dynamic>?;
    if (order == null) return const SizedBox.shrink();

    final orderNumber = order['order_number']?.toString() ?? '';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final customer = order['customers'] as Map<String, dynamic>?;
    final customerName = order['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final paymentStatus = order['payment_status']?.toString().toLowerCase() ?? '';
    final paymentMethod = order['payment_method']?.toString().toLowerCase() ?? '';
    final completedAt = delivery['completed_at'] != null
        ? DateTime.tryParse(delivery['completed_at'])
        : null;

    final isPaid = paymentStatus == 'paid';
    final isTransfer = paymentMethod == 'transfer';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isPaid) {
      if (isTransfer) {
        statusColor = Colors.blue;
        statusLabel = 'Chuyển khoản';
        statusIcon = Icons.account_balance;
      } else {
        statusColor = Colors.green;
        statusLabel = 'Tiền mặt';
        statusIcon = Icons.money;
      }
    } else {
      statusColor = Colors.orange;
      statusLabel = 'Công nợ';
      statusIcon = Icons.pending_actions;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(customerName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (completedAt != null)
                  Text(
                    DateFormat('HH:mm').format(completedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(total),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text('Không có đơn cần giao', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Hãy nghỉ ngơi hoặc kiểm tra lại sau', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    final isPendingMarker = delivery['_isPending'] == true;
    
    Map<String, dynamic>? customer;
    String orderNumber;
    double total;
    String customerName;
    String? customerAddress;
    String? customerPhone;
    String deliveryStatus;
    
    if (isFromSalesOrders) {
      customer = delivery['customers'] as Map<String, dynamic>?;
      orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
      total = (delivery['total'] as num?)?.toDouble() ?? (delivery['total_amount'] as num?)?.toDouble() ?? 0;
      customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
      customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
      customerPhone = delivery['customer_phone'] ?? customer?['phone'];
      deliveryStatus = delivery['delivery_status'] as String? ?? 'awaiting_pickup';
    } else {
      final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
      customer = salesOrder?['customers'] as Map<String, dynamic>?;
      orderNumber = salesOrder?['order_number']?.toString() ?? delivery['delivery_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
      total = (salesOrder?['total'] as num?)?.toDouble() ?? (delivery['total_amount'] as num?)?.toDouble() ?? 0;
      customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
      customerAddress = delivery['delivery_address'] ?? customer?['address'];
      customerPhone = customer?['phone'];
      deliveryStatus = delivery['status'] as String? ?? 'planned';
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool isPending = isPendingMarker;

    if (isFromSalesOrders) {
      switch (deliveryStatus) {
        case 'awaiting_pickup':
          statusColor = Colors.orange;
          statusText = 'Chờ nhận';
          statusIcon = Icons.pending_actions;
          isPending = true;
          break;
        case 'delivering':
          statusColor = Colors.blue;
          statusText = 'Đang giao';
          statusIcon = Icons.local_shipping;
          isPending = false;
          break;
        default:
          statusColor = Colors.grey;
          statusText = deliveryStatus;
          statusIcon = Icons.help_outline;
          isPending = true;
      }
    } else {
      switch (deliveryStatus) {
        case 'planned':
        case 'loading':
          statusColor = Colors.orange;
          statusText = 'Chờ nhận';
          statusIcon = Icons.pending_actions;
          isPending = true;
          break;
        case 'in_progress':
          statusColor = Colors.blue;
          statusText = 'Đang giao';
          statusIcon = Icons.local_shipping;
          isPending = false;
          break;
        case 'completed':
          statusColor = Colors.green;
          statusText = 'Đã giao';
          statusIcon = Icons.check_circle;
          isPending = false;
          break;
        case 'cancelled':
          statusColor = Colors.red;
          statusText = 'Đã hủy';
          statusIcon = Icons.cancel;
          isPending = false;
          break;
        default:
          statusColor = Colors.grey;
          statusText = deliveryStatus;
          statusIcon = Icons.help_outline;
          isPending = true;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDeliveryDetail(delivery),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(currencyFormat.format(total), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(child: Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    if (customerPhone != null)
                      GestureDetector(
                        onTap: () => _callCustomer(customerPhone),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.phone, color: Colors.green.shade600, size: 18),
                        ),
                      ),
                  ],
                ),
                if (customerAddress != null && customerAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openMaps(customerAddress),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customerAddress, style: TextStyle(color: Colors.blue.shade700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          Icon(Icons.directions, color: Colors.blue.shade600, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetail(Map<String, dynamic> delivery) {
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    final orderId = (delivery['id'] as String?) ?? (delivery['order_id'] as String?) ?? '';
    final deliveryId = isFromSalesOrders ? null : (delivery['id'] as String?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryDetailSheet(
        delivery: delivery,
        currencyFormat: currencyFormat,
        onPickup: () => _pickupDelivery(deliveryId, orderId, isFromSalesOrders),
        onComplete: () => _completeDelivery(deliveryId ?? '', orderId),
        onCall: _callCustomer,
        onNavigate: _openMaps,
        onFailDelivery: () => _failDelivery(deliveryId ?? '', orderId),
        onCollectPayment: () => _collectPayment(orderId),
      ),
    );
  }

  Future<void> _failDelivery(String deliveryId, String orderId) async {
    final reasons = ['Khách không có nhà', 'Khách từ chối nhận hàng', 'Địa chỉ không chính xác', 'Không liên lạc được', 'Khách hẹn giao lại', 'Lý do khác'];
    String? selectedReason;
    String? otherReason;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.cancel, color: Colors.red.shade600)),
            const SizedBox(width: 12),
            const Text('Không giao được'),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn lý do không giao được:'),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                if (selectedReason == 'Lý do khác') ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(hintText: 'Nhập lý do...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                    onChanged: (value) => otherReason = value,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    try {
      final supabase = Supabase.instance.client;
      final reason = selectedReason == 'Lý do khác' ? otherReason : selectedReason;

      // Use RPC for transaction-safe update
      final result = await supabase.rpc('fail_delivery', params: {
        'p_delivery_id': deliveryId,
        'p_order_id': orderId,
        'p_reason': reason,
      });
      if (result != null && result['success'] == false) {
        throw Exception(result['error'] ?? 'Unknown error');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.info, color: Colors.white), SizedBox(width: 12), Text('Đã báo cáo không giao được')]),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _loadDashboardData();
      }
    } catch (e) {
      AppLogger.error('Failed to mark delivery as failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _collectPayment(String orderId) async {
    final supabase = Supabase.instance.client;
    final orderData = await supabase.from('sales_orders').select('total, customer_id, payment_method, customers(name, total_debt)').eq('id', orderId).maybeSingle();
    if (orderData == null) return;
    
    final total = (orderData['total'] as num?)?.toDouble() ?? 0;
    final customerId = orderData['customer_id'];
    final customerName = orderData['customers']?['name'] ?? 'Khách hàng';
    final currentDebt = (orderData['customers']?['total_debt'] as num?)?.toDouble() ?? 0;
    
    String? selectedOption;
    
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.payments, color: Colors.green.shade600)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Xác nhận thanh toán')),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Số tiền:'),
                      Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade800)),
                    ]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Khách hàng:'), Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500))]),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Chọn phương thức:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Row(children: [Text('💵', style: TextStyle(fontSize: 20)), SizedBox(width: 8), Text('Thu tiền mặt (COD)')]),
                  subtitle: const Text('Khách trả tiền mặt ngay'),
                  value: 'cash', groupValue: selectedOption, onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero, dense: true,
                ),
                RadioListTile<String>(
                  title: const Row(children: [Text('🏦', style: TextStyle(fontSize: 20)), SizedBox(width: 8), Text('Chuyển khoản')]),
                  subtitle: const Text('Chờ Finance xác nhận'),
                  value: 'transfer', groupValue: selectedOption, onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero, dense: true,
                ),
                RadioListTile<String>(
                  title: const Row(children: [Text('📝', style: TextStyle(fontSize: 20)), SizedBox(width: 8), Text('Ghi nợ')]),
                  subtitle: Text('Công nợ hiện tại: ${currencyFormat.format(currentDebt)}'),
                  value: 'debt', groupValue: selectedOption, onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero, dense: true,
                ),
                if (selectedOption == 'debt')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Công nợ sau giao dịch: ${currencyFormat.format(currentDebt + total)}', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500))),
                    ]),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: selectedOption == null ? null : () => Navigator.pop(context, selectedOption),
              style: ElevatedButton.styleFrom(backgroundColor: selectedOption == 'debt' ? Colors.orange : selectedOption == 'transfer' ? Colors.blue : Colors.green),
              child: Text(selectedOption == 'debt' ? 'Ghi nợ' : selectedOption == 'transfer' ? 'Chờ xác nhận' : 'Xác nhận'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null) return;

    try {
      if (confirmed == 'cash') {
        await supabase.from('sales_orders').update({
          'payment_status': 'paid', 'payment_method': 'cash',
          'payment_collected_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('💰 Đã xác nhận thu tiền mặt!')]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      } else if (confirmed == 'transfer') {
        await supabase.from('sales_orders').update({'payment_status': 'pending_transfer', 'payment_method': 'transfer', 'updated_at': DateTime.now().toIso8601String()}).eq('id', orderId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.schedule, color: Colors.white), SizedBox(width: 12), Expanded(child: Text('🏦 Đã ghi nhận chuyển khoản. Chờ Finance xác nhận.'))]), backgroundColor: Colors.blue, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      } else if (confirmed == 'debt') {
        await supabase.from('sales_orders').update({'payment_status': 'debt', 'payment_method': 'debt', 'updated_at': DateTime.now().toIso8601String()}).eq('id', orderId);
        if (customerId != null) await supabase.from('customers').update({'total_debt': currentDebt + total, 'updated_at': DateTime.now().toIso8601String()}).eq('id', customerId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.receipt_long, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('📝 Đã ghi nợ ${currencyFormat.format(total)}'))]), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
      if (mounted) _loadDashboardData();
    } catch (e) {
      AppLogger.error('Failed to process payment', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _pickupDelivery(String? deliveryId, String orderId, bool isFromSalesOrders) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (isFromSalesOrders) {
        final now = DateTime.now().toIso8601String();
        final newDelivery = await supabase.from('deliveries').insert({
          'company_id': companyId, 'order_id': orderId, 'driver_id': driverId,
          'delivery_number': 'DL-${DateTime.now().millisecondsSinceEpoch}',
          'delivery_date': DateTime.now().toIso8601String().split('T')[0],
          'status': 'in_progress', 'started_at': now, 'updated_at': now,
        }).select().single();

        if (orderId.isNotEmpty) await supabase.from('sales_orders').update({'delivery_status': 'delivering', 'updated_at': now}).eq('id', orderId);
      } else if (deliveryId != null && orderId.isNotEmpty) {
        // Use RPC for transaction-safe update
        final result = await supabase.rpc('start_delivery', params: {
          'p_delivery_id': deliveryId,
          'p_order_id': orderId,
        });
        if (result != null && result['success'] == false) {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.local_shipping, color: Colors.white), SizedBox(width: 12), Text('Đã nhận đơn! Bắt đầu giao hàng.')]), backgroundColor: Colors.blue, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        _loadDashboardData();
      }
    } catch (e) {
      AppLogger.error('Failed to pickup delivery', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _completeDelivery(String deliveryId, String orderId) async {
    AppLogger.info('🚛 [Dashboard] _completeDelivery called with deliveryId: "$deliveryId", orderId: "$orderId"');
    
    if (orderId.isEmpty || orderId == 'null') {
      AppLogger.error('Invalid orderId: $orderId');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không tìm thấy mã đơn hàng'), backgroundColor: Colors.red));
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final orderResponse = await supabase.from('sales_orders').select('payment_method, payment_status, total, customers(name)').eq('id', orderId).single();

      final paymentMethod = orderResponse['payment_method']?.toString().toLowerCase() ?? 'cod';
      final paymentStatus = orderResponse['payment_status']?.toString().toLowerCase() ?? 'unpaid';
      final total = (orderResponse['total'] ?? 0).toDouble();
      final customerData = orderResponse['customers'] as Map<String, dynamic>?;
      final customerName = customerData?['name'] ?? 'Khách hàng';

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => DeliveryCompletionDialog(
          orderId: orderId, customerName: customerName, paymentMethod: paymentMethod, paymentStatus: paymentStatus, totalAmount: total,
        ),
      );

      if (result == null) return;

      // Use RPC for transaction-safe update
      final rpcResult = await supabase.rpc('complete_delivery', params: {
        'p_delivery_id': deliveryId,
        'p_order_id': orderId,
        'p_payment_status': result['updatePayment'] == true ? result['paymentStatus'] : null,
        'p_payment_method': result['updatePayment'] == true ? result['paymentMethod'] : null,
      });
      
      if (rpcResult != null && rpcResult['success'] == false) {
        throw Exception(rpcResult['error'] ?? 'Unknown error');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.celebration, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(result['updatePayment'] == true ? '🎉 Giao hàng và thanh toán thành công!' : '🎉 Giao hàng thành công!'))]),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _loadDashboardData();
      }
    } catch (e) {
      AppLogger.error('Failed to complete delivery', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có địa chỉ')));
      return;
    }
    String cleanAddress = address.contains('--') ? address.split('--').first.trim() : address;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=${Uri.encodeComponent(cleanAddress)}&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có số điện thoại')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
