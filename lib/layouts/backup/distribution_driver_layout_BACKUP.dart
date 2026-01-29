import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import '../pages/staff/staff_profile_page.dart';
import '../pages/driver/google_maps_route_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:math';

import '../widgets/bug_report_dialog.dart';
import '../widgets/realtime_notification_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

/// Distribution Driver Layout - Modern 2026 UI
/// Layout cho Tài xế giao hàng của công ty phân phối
/// Handles: Delivery pickup, Route navigation, Delivery confirmation
class DistributionDriverLayout extends ConsumerStatefulWidget {
  const DistributionDriverLayout({super.key});

  @override
  ConsumerState<DistributionDriverLayout> createState() =>
      _DistributionDriverLayoutState();
}

class _DistributionDriverLayoutState
    extends ConsumerState<DistributionDriverLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DriverRoutePage(),
          _MyDeliveriesPage(),
          _DriverJourneyMapPage(),
          _DeliveryHistoryPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.space_dashboard, color: Colors.blue.shade700),
              ),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: Colors.orange.shade700),
              ),
              label: 'Giao hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map, color: Colors.teal.shade700),
              ),
              label: 'Hành trình',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: Colors.green.shade700),
              ),
              label: 'Lịch sử',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DRIVER ROUTE PAGE - Lộ trình giao hàng - Modern 2026 UI
// ============================================================================
class _DriverRoutePage extends ConsumerStatefulWidget {
  const _DriverRoutePage();

  @override
  ConsumerState<_DriverRoutePage> createState() => _DriverRoutePageState();
}

class _DriverRoutePageState extends ConsumerState<_DriverRoutePage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayDeliveries = [];
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
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
                      child: Container(
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
                              // Top row with avatar and notification
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
                                          'Xin chào, ${user?.name ?? 'Tài xế'}! 👋',
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

                              // Date display
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
                                    Text(
                                      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Chờ nhận',
                                '${_stats['pending'] ?? 0}',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Đang giao',
                                '${_stats['inProgress'] ?? 0}',
                                Icons.local_shipping,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'Hoàn thành',
                                '${_stats['completedToday'] ?? 0}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today's Revenue Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                child: const Icon(Icons.payments, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thu hộ hôm nay',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(_stats['todayRevenue'] ?? 0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Section title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Đơn cần giao',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_todayDeliveries.isNotEmpty)
                              TextButton(
                                onPressed: () {},
                                child: Text('Xem tất cả (${_todayDeliveries.length})'),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Delivery list
                    if (_todayDeliveries.isEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có đơn cần giao',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hãy nghỉ ngơi hoặc kiểm tra lại sau',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
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
              fontSize: 24,
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

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    // Check data source: from sales_orders or deliveries table
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    final isPendingMarker = delivery['_isPending'] == true;
    
    // Extract data based on source
    Map<String, dynamic>? customer;
    String orderNumber;
    double total;
    String customerName;
    String? customerAddress;
    String? customerPhone;
    String deliveryStatus;
    
    if (isFromSalesOrders) {
      // Data from sales_orders table directly
      customer = delivery['customers'] as Map<String, dynamic>?;
      orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
      total = (delivery['total'] as num?)?.toDouble() ?? (delivery['total_amount'] as num?)?.toDouble() ?? 0;
      customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
      customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
      customerPhone = delivery['customer_phone'] ?? customer?['phone'];
      deliveryStatus = delivery['delivery_status'] as String? ?? 'awaiting_pickup';
    } else {
      // Data from deliveries table with joined sales_orders
      final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
      customer = salesOrder?['customers'] as Map<String, dynamic>?;
      orderNumber = salesOrder?['order_number']?.toString() ?? 
                    delivery['delivery_number']?.toString() ?? 
                    delivery['id'].toString().substring(0, 8).toUpperCase();
      // sales_orders uses 'total' not 'total_amount', also check delivery's total_amount
      total = (salesOrder?['total'] as num?)?.toDouble() ?? 
              (delivery['total_amount'] as num?)?.toDouble() ?? 0;
      customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
      customerAddress = delivery['delivery_address'] ?? customer?['address'];
      customerPhone = customer?['phone'];
      deliveryStatus = delivery['status'] as String? ?? 'planned';
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool isPending = isPendingMarker;

    // Determine status display based on delivery_status or status
    if (isFromSalesOrders) {
      // From sales_orders - check delivery_status
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
      // From deliveries table - check status
      // Valid statuses: planned, loading, in_progress, completed, cancelled
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$orderNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            currencyFormat.format(total),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (customerPhone != null)
                      GestureDetector(
                        onTap: () => _callCustomer(customerPhone),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customerAddress,
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.directions, color: Colors.blue.shade600, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final isFromSalesOrders = delivery['_source'] == 'sales_orders';
                      final deliveryId = isFromSalesOrders ? null : (delivery['id'] as String?);
                      final orderId = (delivery['id'] as String?) ?? 
                                     (delivery['order_id'] as String?) ?? 
                                     (delivery['sales_orders'] as Map<String, dynamic>?)?['id'] as String? ?? 
                                     '';
                      if (isPending) {
                        _pickupDelivery(deliveryId, orderId, isFromSalesOrders);
                      } else {
                        _completeDelivery(deliveryId ?? '', orderId);
                      }
                    },
                    icon: Icon(isPending ? Icons.play_arrow : Icons.check_circle, size: 20),
                    label: Text(isPending ? 'Nhận đơn giao' : 'Xác nhận đã giao'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetail(Map<String, dynamic> delivery) {
    // Determine if this is a sales_orders record (no deliveryId yet)
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    final orderId = (delivery['id'] as String?) ?? (delivery['order_id'] as String?) ?? '';
    final deliveryId = isFromSalesOrders ? null : (delivery['id'] as String?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryDetailSheet(
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
    final reasons = [
      'Khách không có nhà',
      'Khách từ chối nhận hàng',
      'Địa chỉ không chính xác',
      'Không liên lạc được',
      'Khách hẹn giao lại',
      'Lý do khác',
    ];
    
    String? selectedReason;
    String? otherReason;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
              const Text('Không giao được'),
            ],
          ),
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
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onChanged: (value) => otherReason = value,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
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

      // Update delivery record
      await supabase.from('deliveries').update({
        'status': 'failed',
        'notes': reason,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      // Update sales_order record
      await supabase.from('sales_orders').update({
        'delivery_status': 'failed',
        'delivery_failed_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã báo cáo không giao được'),
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
      AppLogger.error('Failed to mark delivery as failed', e);
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

  Future<void> _collectPayment(String orderId) async {
    // Lấy thông tin đơn hàng
    final supabase = Supabase.instance.client;
    final orderData = await supabase
        .from('sales_orders')
        .select('total, customer_id, payment_method, customers(name, total_debt)')
        .eq('id', orderId)
        .maybeSingle();
    
    if (orderData == null) return;
    
    final total = (orderData['total'] as num?)?.toDouble() ?? 0;
    final customerId = orderData['customer_id'];
    final customerName = orderData['customers']?['name'] ?? 'Khách hàng';
    final currentDebt = (orderData['customers']?['total_debt'] as num?)?.toDouble() ?? 0;
    final paymentMethod = orderData['payment_method']?.toString().toLowerCase() ?? 'cod';
    
    String? selectedOption;
    
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payments, color: Colors.green.shade600),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Xác nhận thanh toán')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin đơn hàng
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số tiền:'),
                          Text(
                            currencyFormat.format(total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Khách hàng:'),
                          Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text('Chọn phương thức:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Option 1: Thu tiền mặt
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('💵', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Thu tiền mặt (COD)'),
                    ],
                  ),
                  subtitle: const Text('Khách trả tiền mặt ngay'),
                  value: 'cash',
                  groupValue: selectedOption,
                  onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                
                // Option 2: Chuyển khoản
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('🏦', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Chuyển khoản'),
                    ],
                  ),
                  subtitle: const Text('Chờ Finance xác nhận'),
                  value: 'transfer',
                  groupValue: selectedOption,
                  onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                
                // Option 3: Ghi nợ
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Text('📝', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Ghi nợ'),
                    ],
                  ),
                  subtitle: Text('Công nợ hiện tại: ${currencyFormat.format(currentDebt)}'),
                  value: 'debt',
                  groupValue: selectedOption,
                  onChanged: (v) => setState(() => selectedOption = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                
                if (selectedOption == 'debt')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Công nợ sau giao dịch: ${currencyFormat.format(currentDebt + total)}',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedOption == null ? null : () => Navigator.pop(context, selectedOption),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedOption == 'debt' 
                    ? Colors.orange 
                    : selectedOption == 'transfer' 
                        ? Colors.blue 
                        : Colors.green,
              ),
              child: Text(
                selectedOption == 'debt' 
                    ? 'Ghi nợ' 
                    : selectedOption == 'transfer' 
                        ? 'Chờ xác nhận' 
                        : 'Xác nhận',
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null) return;

    try {
      if (confirmed == 'cash') {
        // Thu tiền mặt - đánh dấu đã thanh toán
        await supabase.from('sales_orders').update({
          'payment_status': 'paid',
          'payment_method': 'cash',
          'payment_collected_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('💰 Đã xác nhận thu tiền mặt!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (confirmed == 'transfer') {
        // Chuyển khoản - chờ Finance xác nhận
        await supabase.from('sales_orders').update({
          'payment_status': 'pending_transfer',
          'payment_method': 'transfer',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('🏦 Đã ghi nhận chuyển khoản. Chờ Finance xác nhận.')),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (confirmed == 'debt') {
        // Ghi nợ - cập nhật công nợ khách hàng
        await supabase.from('sales_orders').update({
          'payment_status': 'debt',
          'payment_method': 'debt',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);

        // Cập nhật công nợ khách hàng
        if (customerId != null) {
          await supabase.from('customers').update({
            'total_debt': currentDebt + total,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', customerId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('📝 Đã ghi nợ ${currencyFormat.format(total)}')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      if (mounted) _loadDashboardData();
    } catch (e) {
      AppLogger.error('Failed to process payment', e);
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

  Future<void> _pickupDelivery(String? deliveryId, String orderId, bool isFromSalesOrders) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (isFromSalesOrders) {
        // Create new delivery record and assign to driver
        final now = DateTime.now().toIso8601String();
        final insertResult = await supabase.from('deliveries').insert({
          'company_id': companyId,
          'order_id': orderId,
          'driver_id': driverId,
          'delivery_number': 'DL-${DateTime.now().millisecondsSinceEpoch}',
          'delivery_date': DateTime.now().toIso8601String().split('T')[0],
          'status': 'in_progress',
          'started_at': now,
          'updated_at': now,
        }).select().single();

        // Update sales_orders delivery_status
        if (orderId.isNotEmpty) {
          await supabase.from('sales_orders').update({
            'delivery_status': 'delivering',
            'updated_at': now,
          }).eq('id', orderId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã nhận đơn! Bắt đầu giao hàng.'),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadDashboardData();
        }
      } else if (deliveryId != null) {
        // Update delivery status to in_progress
        await supabase.from('deliveries').update({
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', deliveryId);

        // Also update sales_orders delivery_status for consistency
        if (orderId.isNotEmpty) {
          await supabase.from('sales_orders').update({
            'delivery_status': 'delivering',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', orderId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đã nhận đơn! Bắt đầu giao hàng.'),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadDashboardData();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pickup delivery', e);
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

  Future<void> _completeDelivery(String deliveryId, String orderId) async {
    // Debug log
    AppLogger.info('🚛 [Dashboard] _completeDelivery called with deliveryId: "$deliveryId", orderId: "$orderId"');
    
    // Validate orderId is a valid UUID (not empty, not null string)
    if (orderId.isEmpty || orderId == 'null') {
      AppLogger.error('Invalid orderId: $orderId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Không tìm thấy mã đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Get order info to check payment status
      final orderResponse = await supabase
          .from('sales_orders')
          .select('payment_method, payment_status, total, customers(name)')
          .eq('id', orderId)
          .single();

      final paymentMethod = orderResponse['payment_method']?.toString().toLowerCase() ?? 'cod';
      final paymentStatus = orderResponse['payment_status']?.toString().toLowerCase() ?? 'unpaid';
      final total = (orderResponse['total'] ?? 0).toDouble();
      final customerData = orderResponse['customers'] as Map<String, dynamic>?;
      final customerName = customerData?['name'] ?? 'Khách hàng';

      // Show delivery completion with payment options
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _buildDeliveryCompletionDialog(
          orderId: orderId,
          customerName: customerName,
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
          totalAmount: total,
        ),
      );

      if (result == null) return;

      // Update delivery record - use 'completed' status (valid: planned, loading, in_progress, completed, cancelled)
      await supabase.from('deliveries').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      // Update sales_orders delivery status and payment if needed
      Map<String, dynamic> updateData = {
        'delivery_status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (result['updatePayment'] == true) {
        updateData['payment_status'] = result['paymentStatus'];
        updateData['payment_method'] = result['paymentMethod'];
        if (result['paymentStatus'] == 'paid') {
          updateData['payment_collected_at'] = DateTime.now().toIso8601String();
        }
      }

      AppLogger.info('🔄 [Dashboard] Updating sales_orders: $updateData where id=$orderId');

      await supabase.from('sales_orders').update(updateData).eq('id', orderId);
      
      AppLogger.info('✅ [Dashboard] Update completed for orderId: $orderId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['updatePayment'] == true 
                        ? '🎉 Giao hàng và thanh toán thành công!'
                        : '🎉 Giao hàng thành công!',
                  ),
                ),
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
      AppLogger.error('Failed to complete delivery', e);
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

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có địa chỉ')),
      );
      return;
    }

    // Clean address: remove notes after '--' (e.g., "123 ABC -- Chị Trúc" -> "123 ABC")
    String cleanAddress = address;
    if (address.contains('--')) {
      cleanAddress = address.split('--').first.trim();
    }

    // Use Google Maps Directions API with current location as origin
    // travelmode=driving for car navigation
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=${Uri.encodeComponent(cleanAddress)}&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có số điện thoại')),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildDeliveryCompletionDialog({
    required String orderId,
    required String customerName,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    String selectedPaymentOption = 'delivered_only'; // delivered_only, cash_collected, transfer_confirmed, debt_added

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.local_shipping, color: Colors.green.shade600, size: 32),
              ),
              const SizedBox(height: 12),
              Text('Hoàn thành giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Mã đơn: $orderId', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('👤 Khách hàng: $customerName'),
                    Text('💰 Tổng tiền: ${currencyFormat.format(totalAmount)}'),
                    Text('💳 Hình thức: ${_getPaymentMethodLabel(paymentMethod)}'),
                    Text('📊 Trạng thái: ${_getPaymentStatusLabel(paymentStatus)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment options
              const Text('Xử lý thanh toán:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              
              // Option 1: Chỉ giao hàng
              RadioListTile<String>(
                value: 'delivered_only',
                groupValue: selectedPaymentOption,
                onChanged: (value) => setState(() => selectedPaymentOption = value!),
                title: const Text('Chỉ xác nhận giao hàng'),
                subtitle: Text('Giữ nguyên trạng thái thanh toán: ${_getPaymentStatusLabel(paymentStatus)}'),
                dense: true,
              ),
              
              // Option 2: Thu tiền mặt (nếu COD)
              if (paymentMethod == 'cod' && paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'cash_collected',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('💵 Thu tiền mặt'),
                  subtitle: Text('Xác nhận đã thu ${currencyFormat.format(totalAmount)}'),
                  dense: true,
                ),
              
              // Option 3: Xác nhận chuyển khoản
              if (paymentMethod == 'transfer' && paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'transfer_confirmed',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('🏦 Xác nhận chuyển khoản'),
                  subtitle: const Text('Khách hàng đã chuyển khoản'),
                  dense: true,
                ),
              
              // Option 4: Ghi nợ
              if (paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'debt_added',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('📝 Ghi nợ'),
                  subtitle: const Text('Khách hàng sẽ thanh toán sau'),
                  dense: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> result = {'updatePayment': false};
                
                switch (selectedPaymentOption) {
                  case 'delivered_only':
                    // Chỉ cập nhật delivery status
                    break;
                    
                  case 'cash_collected':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid',
                      'paymentMethod': 'cash',
                    };
                    break;
                    
                  case 'transfer_confirmed':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid', 
                      'paymentMethod': 'transfer',
                    };
                    break;
                    
                  case 'debt_added':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'debt',
                      'paymentMethod': paymentMethod, // Giữ nguyên payment method
                    };
                    break;
                }
                
                Navigator.pop(context, result);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Tiền mặt (COD)';
      case 'cash':
        return 'Tiền mặt';
      case 'transfer':
        return 'Chuyển khoản';
      case 'card':
        return 'Thẻ tín dụng';
      default:
        return method;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'partial':
        return 'Thanh toán một phần';
      case 'debt':
        return 'Ghi nợ';
      default:
        return status;
    }
  }
}

// ============================================================================
// DELIVERY DETAIL SHEET
// ============================================================================
class _DeliveryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final NumberFormat currencyFormat;
  final VoidCallback onPickup;
  final VoidCallback onComplete;
  final Function(String?) onCall;
  final Function(String?) onNavigate;
  final VoidCallback onFailDelivery;
  final VoidCallback onCollectPayment;

  const _DeliveryDetailSheet({
    required this.delivery,
    required this.currencyFormat,
    required this.onPickup,
    required this.onComplete,
    required this.onCall,
    required this.onNavigate,
    required this.onFailDelivery,
    required this.onCollectPayment,
  });

  @override
  Widget build(BuildContext context) {
    final customer = delivery['customers'] as Map<String, dynamic>?;
    final status = delivery['status'] as String;
    final deliveryStatus = delivery['delivery_status'] as String?;
    final orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
    final customerPhone = delivery['customer_phone'] ?? customer?['phone'];
    final notes = delivery['notes'] ?? delivery['delivery_notes'];
    final isPending = status == 'ready_for_delivery' || status == 'processing';
    final isDelivering = deliveryStatus == 'delivering';
    
    // Payment info
    final paymentMethod = delivery['payment_method']?.toString().toLowerCase() ?? 'cod';
    final paymentStatus = delivery['payment_status'] ?? 'pending';
    // Show payment button for all unpaid orders when delivering
    final needsPaymentCollection = paymentStatus != 'paid' && isDelivering;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #$orderNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        currencyFormat.format(total),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer section
                  _buildSectionTitle('Thông tin khách hàng', Icons.person),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (customerPhone != null)
                                    Text(customerPhone, style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            if (customerPhone != null)
                              ElevatedButton.icon(
                                onPressed: () => onCall(customerPhone),
                                icon: const Icon(Icons.phone, size: 18),
                                label: const Text('Gọi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (customerAddress != null && customerAddress.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => onNavigate(customerAddress),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.blue.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      customerAddress,
                                      style: TextStyle(color: Colors.blue.shade700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.directions, color: Colors.blue.shade700, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Notes section
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Ghi chú', Icons.notes),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(notes),
                    ),
                  ],

                  // Products section
                  const SizedBox(height: 20),
                  _buildSectionTitle('Sản phẩm đặt hàng', Icons.inventory_2),
                  const SizedBox(height: 12),
                  _buildProductsList(),

                  // Payment info section
                  const SizedBox(height: 20),
                  _buildSectionTitle('Thanh toán', Icons.payments),
                  const SizedBox(height: 12),
                  _buildPaymentInfo(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Navigation + Main action
                Row(
                  children: [
                    if (customerAddress != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigate(customerAddress),
                          icon: const Icon(Icons.directions),
                          label: const Text('Chỉ đường'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    if (customerAddress != null) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          isPending ? onPickup() : onComplete();
                        },
                        icon: Icon(isPending ? Icons.play_arrow : Icons.check_circle),
                        label: Text(isPending ? 'Nhận đơn giao' : 'Đã giao'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Row 2: Collect payment + Failed delivery (only when delivering)
                if (isDelivering) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Collect payment button (for all unpaid orders)
                      if (needsPaymentCollection)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onCollectPayment();
                            },
                            icon: const Icon(Icons.payments),
                            label: const Text('Xác nhận thanh toán'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      if (needsPaymentCollection) const SizedBox(width: 12),
                      // Failed delivery button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onFailDelivery();
                          },
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          label: const Text('Không giao được', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    final items = delivery['sales_order_items'] as List<dynamic>? ?? [];
    
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Không có thông tin sản phẩm', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final productName = item['product_name'] ?? 'Sản phẩm';
          final quantity = item['quantity'] ?? 0;
          final unit = item['unit'] ?? '';
          final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final lineTotal = (item['line_total'] as num?)?.toDouble() ?? (quantity * unitPrice);
          
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: index < items.length - 1
                  ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity $unit x ${currencyFormat.format(unitPrice)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Line total
                Text(
                  currencyFormat.format(lineTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final paymentMethod = delivery['payment_method'] ?? 'COD';
    final paymentStatus = delivery['payment_status'] ?? 'pending';
    final orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    
    final isPaid = paymentStatus == 'paid';
    final isCOD = paymentMethod.toString().toLowerCase() == 'cod' || paymentMethod.toString().toLowerCase() == 'cash';
    final isTransfer = paymentMethod.toString().toLowerCase() == 'transfer' || paymentMethod.toString().toLowerCase() == 'bank';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : (isTransfer ? Colors.blue.shade50 : Colors.orange.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? Colors.green.shade200 : (isTransfer ? Colors.blue.shade200 : Colors.orange.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phương thức:', style: TextStyle(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTransfer ? Colors.blue.shade100 : (isCOD ? Colors.orange.shade100 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTransfer ? '🏦 Chuyển khoản' : (isCOD ? '💵 COD (Thu hộ)' : '💳 Đã thanh toán'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTransfer ? Colors.blue.shade800 : (isCOD ? Colors.orange.shade800 : Colors.green.shade800),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trạng thái:', style: TextStyle(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                !isPaid ? '💰 CẦN THU:' : 'Tổng tiền:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: !isPaid ? Colors.orange.shade800 : Colors.black87,
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: !isPaid ? Colors.orange.shade800 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          
          // QR Button for transfer payments
          if (!isPaid) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (btnContext) => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showQRTransferDialog(
                    btnContext,
                    total,
                    orderNumber,
                  ),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Hiện QR chuyển khoản'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showQRTransferDialog(BuildContext context, double amount, String orderNumber) async {
    // Fetch company bank info
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // Get employee's company
      final empData = await supabase
          .from('employees')
          .select('company_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      
      if (empData == null || empData['company_id'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thông tin công ty')),
          );
        }
        return;
      }
      
      // Get company bank info
      final companyData = await supabase
          .from('companies')
          .select('bank_name, bank_account_number, bank_account_name, bank_bin')
          .eq('id', empData['company_id'])
          .maybeSingle();
      
      if (companyData == null || 
          companyData['bank_bin'] == null || 
          companyData['bank_account_number'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Công ty chưa cấu hình tài khoản ngân hàng. Liên hệ Manager/CEO để cấu hình.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final bankBin = companyData['bank_bin'];
      final accountNumber = companyData['bank_account_number'];
      final accountName = companyData['bank_account_name'] ?? '';
      final bankName = companyData['bank_name'] ?? 'Ngân hàng';
      
      // Build VietQR URL
      final amountInt = amount.toInt();
      final content = 'TT $orderNumber';
      final qrUrl = 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png?amount=$amountInt&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}';
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.qr_code, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('QR Chuyển khoản'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Image.network(
                          qrUrl,
                          width: 250,
                          height: 250,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Text('Không thể tải QR'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          bankName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountName,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Số tiền:', style: TextStyle(fontSize: 12)),
                        Text(
                          currencyFormat.format(amount),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Nội dung:', style: TextStyle(fontSize: 12)),
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Sau khi khách chuyển khoản, Manager sẽ xác nhận',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================================
// DRIVER JOURNEY MAP PAGE - Map định tuyến giao hàng với GPS & Google Maps
// ============================================================================
class _DriverJourneyMapPage extends ConsumerStatefulWidget {
  const _DriverJourneyMapPage();

  @override
  ConsumerState<_DriverJourneyMapPage> createState() => _DriverJourneyMapPageState();
}

class _DriverJourneyMapPageState extends ConsumerState<_DriverJourneyMapPage> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _isLocating = false;
  bool _isEditingLocation = false;
  bool _isUpdatingLocation = false;
  bool _mapReady = false; // Track when map is ready
  bool _isRouteOptimized = false; // Track if route has been optimized
  LatLng? _currentLocation;
  LatLng? _pickedLocation; // Vị trí được chọn để cập nhật
  String? _pickedAddress; // Địa chỉ từ reverse geocoding
  List<Map<String, dynamic>> _deliveryStops = [];
  int _selectedStopIndex = -1;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  // GPS Tracking
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  
  // Default location (Ho Chi Minh City center)
  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadDeliveryStops();
    _startGPSTracking();
  }

  // Bắt đầu theo dõi GPS real-time
  Future<void> _startGPSTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ vị trí (GPS)'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cần quyền truy cập vị trí để theo dõi GPS'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isTracking = true);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Cập nhật khi di chuyển 10m
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          }
        },
        onError: (error) {
          AppLogger.error('GPS stream error', error);
          setState(() => _isTracking = false);
        },
      );
    } catch (e) {
      AppLogger.error('Failed to start GPS tracking', e);
      setState(() => _isTracking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bật GPS: ${e.toString()}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _stopGPSTracking() {
    _positionStream?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = _defaultLocation;
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dịch vụ vị trí (GPS) chưa được bật'),
              action: SnackBarAction(
                label: 'Bật GPS',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Move to default location
        if (_mapReady && mounted) {
          _mapController.move(_defaultLocation, 12);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = _defaultLocation;
            _isLocating = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = _defaultLocation;
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật quyền truy cập vị trí trong cài đặt'),
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });

      // Only move if map is ready
      if (_mapReady && mounted) {
        _mapController.move(_currentLocation!, 14);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Đã xác định vị trí: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to get location', e);
      setState(() {
        _currentLocation = _defaultLocation;
        _isLocating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xác định vị trí: ${e.toString().length > 50 ? e.toString().substring(0, 50) : e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDeliveryStops() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (companyId == null || driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      // Query from deliveries table filtered by driver_id
      // Valid statuses: planned, loading, in_progress, completed, cancelled
      final deliveries = await supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, delivery_address,
              delivery_status, payment_method, payment_status,
              customers(id, name, phone, address, lat, lng)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .inFilter('status', ['planned', 'loading', 'in_progress'])
          .order('created_at', ascending: true)
          .limit(20);

      setState(() {
        _deliveryStops = List<Map<String, dynamic>>.from(deliveries);
        _isLoading = false;
        _isRouteOptimized = false; // Reset khi load lại dữ liệu
      });

      if (_deliveryStops.isNotEmpty) {
        _fitMapToMarkers();
      }
    } catch (e) {
      AppLogger.error('Failed to load delivery stops', e);
      setState(() => _isLoading = false);
    }
  }

  void _fitMapToMarkers() {
    if (!_mapReady) return; // Check map is ready
    if (_deliveryStops.isEmpty && _currentLocation == null) return;

    final points = <LatLng>[];
    
    if (_currentLocation != null) {
      points.add(_currentLocation!);
    }

    for (final stop in _deliveryStops) {
      // New structure: delivery -> sales_orders -> customers
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
    } else {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  // Reverse Geocoding - lấy địa chỉ từ tọa độ
  Future<String?> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street?.isNotEmpty == true) parts.add(place.street!);
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
        return parts.join(', ');
      }
    } catch (e) {
      AppLogger.error('Reverse geocoding failed', e);
    }
    return null;
  }

  // Forward Geocoding - lấy tọa độ từ địa chỉ
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      AppLogger.error('Forward geocoding failed', e);
    }
    return null;
  }

  // Chọn vị trí trên map
  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (!_isEditingLocation) {
      setState(() => _selectedStopIndex = -1);
      return;
    }

    setState(() {
      _pickedLocation = point;
      _pickedAddress = 'Đang tìm địa chỉ...';
    });

    // Reverse geocoding
    final address = await _getAddressFromCoordinates(point.latitude, point.longitude);
    setState(() {
      _pickedAddress = address ?? 'Không tìm thấy địa chỉ';
    });
  }

  // Cập nhật vị trí khách hàng vào database
  Future<void> _updateCustomerLocation() async {
    if (_selectedStopIndex < 0 || _pickedLocation == null) return;

    final stop = _deliveryStops[_selectedStopIndex];
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerId = customer?['id'];

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpdatingLocation = true);

    try {
      final supabase = Supabase.instance.client;

      // Update customer location - CHỈ cập nhật tọa độ, không cập nhật địa chỉ
      // (theo yêu cầu: cập nhật vị trí chỉ thay đổi tọa độ, địa chỉ giữ nguyên)
      await supabase.from('customers').update({
        'lat': _pickedLocation!.latitude,
        'lng': _pickedLocation!.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', customerId);

      // Reload data
      await _loadDeliveryStops();

      setState(() {
        _isEditingLocation = false;
        _pickedLocation = null;
        _pickedAddress = null;
        _isUpdatingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã cập nhật vị trí khách hàng!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update customer location', e);
      setState(() => _isUpdatingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mở Google Maps để tìm địa chỉ chính xác
  Future<void> _openGoogleMapsSearch(String? currentAddress) async {
    String query = currentAddress ?? '';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Tối ưu và sắp xếp lại danh sách điểm giao hàng
  void _optimizeAndReorderStops() {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng để tối ưu')),
      );
      return;
    }

    // Kiểm tra xem có bao nhiêu điểm có tọa độ
    int stopsWithCoords = 0;
    for (final stop in _deliveryStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      if (lat != null && lng != null) {
        stopsWithCoords++;
      }
    }

    if (stopsWithCoords < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 2 điểm có tọa độ để tối ưu')),
      );
      return;
    }

    // Optimize route using Nearest Neighbor algorithm
    final optimizedStops = _optimizeRouteNearestNeighbor(
      _deliveryStops,
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );

    setState(() {
      _deliveryStops = optimizedStops;
      _isRouteOptimized = true;
      _selectedStopIndex = -1; // Reset selection
    });

    // Tính tổng khoảng cách sau khi tối ưu
    double totalDistance = 0;
    double? prevLat = _currentLocation?.latitude;
    double? prevLng = _currentLocation?.longitude;
    
    for (final stop in optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = (customer?['lat'] as num?)?.toDouble();
      final lng = (customer?['lng'] as num?)?.toDouble();
      
      if (lat != null && lng != null && prevLat != null && prevLng != null) {
        totalDistance += _calculateDistance(prevLat, prevLng, lat, lng);
        prevLat = lat;
        prevLng = lng;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tối ưu tuyến đường! Tổng: ${totalDistance.toStringAsFixed(1)} km'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Fit map to show all optimized stops
    _fitMapToMarkers();
  }

  // Mở Google Maps để điều hướng
  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Tính khoảng cách giữa 2 điểm (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Thuật toán Nearest Neighbor để optimize tuyến đường
  List<Map<String, dynamic>> _optimizeRouteNearestNeighbor(
    List<Map<String, dynamic>> stops,
    double? startLat,
    double? startLng,
  ) {
    if (stops.length <= 2) return stops;

    final List<Map<String, dynamic>> optimized = [];
    final List<Map<String, dynamic>> remaining = List.from(stops);

    // Điểm bắt đầu: vị trí hiện tại hoặc điểm đầu tiên
    double currentLat = startLat ?? 10.8;
    double currentLng = startLng ?? 106.7;

    while (remaining.isNotEmpty) {
      int nearestIndex = 0;
      double nearestDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final stop = remaining[i];
        final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
        final customer = salesOrder?['customers'] as Map<String, dynamic>?;
        final lat = (customer?['lat'] as num?)?.toDouble();
        final lng = (customer?['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final distance = _calculateDistance(currentLat, currentLng, lat, lng);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestIndex = i;
          }
        }
      }

      final nearest = remaining.removeAt(nearestIndex);
      optimized.add(nearest);

      // Cập nhật vị trí hiện tại
      final salesOrder = nearest['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      currentLat = (customer?['lat'] as num?)?.toDouble() ?? currentLat;
      currentLng = (customer?['lng'] as num?)?.toDouble() ?? currentLng;
    }

    return optimized;
  }

  // Mở Google Maps với toàn bộ tuyến đường giao hàng (ĐÃ OPTIMIZE)
  Future<void> _openFullRouteInGoogleMaps() async {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng')),
      );
      return;
    }

    // Optimize route using Nearest Neighbor algorithm
    final optimizedStops = _optimizeRouteNearestNeighbor(
      _deliveryStops,
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );

    // Collect all waypoints (prefer address text over coordinates for Google Maps display)
    final List<String> waypoints = [];
    for (final stop in optimizedStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      
      // Use delivery_address or customer address first, fallback to coordinates
      final deliveryAddress = salesOrder?['delivery_address'] as String?;
      final customerAddress = customer?['address'] as String?;
      final lat = customer?['lat'] as num?;
      final lng = customer?['lng'] as num?;
      
      // Prefer text address for better Google Maps display
      if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
        waypoints.add(deliveryAddress);
      } else if (customerAddress != null && customerAddress.isNotEmpty) {
        waypoints.add(customerAddress);
      } else if (lat != null && lng != null) {
        waypoints.add('$lat,$lng');
      }
    }

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Các điểm giao hàng chưa có tọa độ')),
      );
      return;
    }

    // Build Google Maps URL with optimized waypoints
    String url;
    if (waypoints.length == 1) {
      // Single destination - use simple navigation
      url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=${waypoints.first}'
          '&travelmode=driving';
    } else {
      // Multiple waypoints: origin (current location or first stop), waypoints (middle), destination (last)
      final origin = _currentLocation != null
          ? '${_currentLocation!.latitude},${_currentLocation!.longitude}'
          : waypoints.first;
      
      final destination = waypoints.last;
      
      // Middle waypoints (exclude first if using current location, exclude last always)
      final middleWaypoints = _currentLocation != null
          ? waypoints.sublist(0, waypoints.length - 1) // All except last
          : waypoints.sublist(1, waypoints.length - 1); // Exclude first and last
      
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(origin)}'
          '&destination=${Uri.encodeComponent(destination)}'
          '&travelmode=driving';
      
      if (middleWaypoints.isNotEmpty) {
        // Google Maps supports up to 9 waypoints in URL
        final waypointsStr = middleWaypoints.take(9).join('|');
        url += '&waypoints=${Uri.encodeComponent(waypointsStr)}';
      }
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Mở trang Google Maps Route với bản đồ tích hợp
  void _openGoogleMapsRoutePage() {
    if (_deliveryStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có điểm giao hàng')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoogleMapsRoutePage(
          deliveryStops: _deliveryStops,
          currentLat: _currentLocation?.latitude,
          currentLng: _currentLocation?.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultLocation,
              initialZoom: 13,
              onTap: _onMapTap,
              onMapReady: () {
                setState(() => _mapReady = true);
                // Now safe to fit markers if data already loaded
                if (_deliveryStops.isNotEmpty || _currentLocation != null) {
                  _fitMapToMarkers();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sabohub.app',
              ),

              // Route polyline
              if (_deliveryStops.isNotEmpty && _currentLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _buildRoutePoints(),
                      color: Colors.blue.shade600,
                      strokeWidth: 4,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Header
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isEditingLocation ? Colors.orange.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: _isEditingLocation 
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditingLocation 
                          ? Colors.orange.shade100 
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditingLocation ? Icons.edit_location : Icons.map,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isEditingLocation 
                              ? 'Chạm vào map để chọn vị trí' 
                              : 'Hành trình giao hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isEditingLocation ? Colors.orange.shade800 : Colors.black87,
                          ),
                        ),
                        Text(
                          _isEditingLocation 
                              ? 'Sau đó nhấn "Lưu vị trí"'
                              : '${_deliveryStops.length} điểm giao • GPS ${_isTracking ? "ON" : "OFF"}',
                          style: TextStyle(
                            color: _isEditingLocation 
                                ? Colors.orange.shade600 
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditingLocation)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingLocation = false;
                          _pickedLocation = null;
                          _pickedAddress = null;
                        });
                      },
                      child: const Text('Hủy'),
                    )
                  else
                    IconButton(
                      onPressed: _initializeMap,
                      icon: _isLoading || _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),

          // Picked location info card
          if (_isEditingLocation && _pickedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              top: 100,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Vị trí đã chọn:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pickedAddress ?? 'Đang tìm địa chỉ...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      '${_pickedLocation!.latitude.toStringAsFixed(6)}, ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdatingLocation ? null : _updateCustomerLocation,
                        icon: _isUpdatingLocation 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isUpdatingLocation ? 'Đang lưu...' : 'Lưu vị trí này'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Positioned(
            right: 16,
            bottom: _selectedStopIndex >= 0 ? 280 : 120,
            child: Column(
              children: [
                // Optimize route button
                FloatingActionButton.small(
                  heroTag: 'optimize_route',
                  onPressed: _optimizeAndReorderStops,
                  backgroundColor: _isRouteOptimized ? Colors.green : Colors.white,
                  tooltip: 'Tối ưu tuyến đường',
                  child: Icon(
                    Icons.route,
                    color: _isRouteOptimized ? Colors.white : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                // Open full route in Google Maps (embedded view)
                FloatingActionButton.small(
                  heroTag: 'google_maps_route',
                  onPressed: () => _openGoogleMapsRoutePage(),
                  backgroundColor: Colors.white,
                  tooltip: 'Xem tuyến đường Google Maps',
                  child: Icon(Icons.map_outlined, color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                // Open in external Google Maps app
                FloatingActionButton.small(
                  heroTag: 'google_maps_external',
                  onPressed: _openFullRouteInGoogleMaps,
                  backgroundColor: Colors.white,
                  tooltip: 'Mở Google Maps App',
                  child: Icon(Icons.navigation_outlined, color: Colors.blue.shade700),
                ),
                const SizedBox(height: 8),
                // GPS tracking toggle
                FloatingActionButton.small(
                  heroTag: 'gps_toggle',
                  onPressed: _isTracking ? _stopGPSTracking : _startGPSTracking,
                  backgroundColor: _isTracking ? Colors.green : Colors.white,
                  child: Icon(
                    _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _isTracking ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                // Fit all markers
                FloatingActionButton.small(
                  heroTag: 'fit_bounds',
                  onPressed: _fitMapToMarkers,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.zoom_out_map, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                // My location
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLocating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),

          // Bottom delivery stops list
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStopsList(),
          ),

          // Selected stop detail card
          if (_selectedStopIndex >= 0 && _selectedStopIndex < _deliveryStops.length && !_isEditingLocation)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: _buildSelectedStopCard(_deliveryStops[_selectedStopIndex]),
            ),
        ],
      ),
    );
  }

  List<LatLng> _buildRoutePoints() {
    final points = <LatLng>[];
    
    if (_currentLocation != null) {
      points.add(_currentLocation!);
    }

    for (final stop in _deliveryStops) {
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    return points;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Picked location marker (when editing)
    if (_isEditingLocation && _pickedLocation != null) {
      markers.add(
        Marker(
          point: _pickedLocation!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 60,
          ),
        ),
      );
    }

    // Current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Delivery stop markers
    for (int i = 0; i < _deliveryStops.length; i++) {
      final stop = _deliveryStops[i];
      final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
      final customer = salesOrder?['customers'] as Map<String, dynamic>?;
      final lat = customer?['lat'] as double?;
      final lng = customer?['lng'] as double?;

      if (lat != null && lng != null) {
        // Use delivery status from deliveries table
        // Valid statuses: planned, loading, in_progress, completed, cancelled
        final deliveryStatus = stop['status'] as String? ?? 'planned';
        final isSelected = _selectedStopIndex == i;
        
        Color markerColor;
        switch (deliveryStatus) {
          case 'in_progress':
            markerColor = Colors.blue;
            break;
          case 'loading':
            markerColor = Colors.purple;
            break;
          case 'planned':
            markerColor = Colors.orange;
            break;
          case 'completed':
            markerColor = Colors.green;
            break;
          default:
            markerColor = Colors.orange;
        }

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: isSelected ? 60 : 45,
            height: isSelected ? 60 : 45,
            child: GestureDetector(
              onTap: () => setState(() => _selectedStopIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 4 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.4),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 18 : 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildStopsList() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveryStops.isEmpty
              ? Center(
                  child: Text(
                    'Không có điểm giao hàng',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : Column(
                  children: [
                    // Counter indicator
                    Container(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_deliveryStops.length} điểm giao',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _deliveryStops.length,
                        itemBuilder: (context, index) {
                          final stop = _deliveryStops[index];
                          final isSelected = _selectedStopIndex == index;
                          return _buildStopChip(stop, index, isSelected);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStopChip(Map<String, dynamic> stop, int index, bool isSelected) {
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'KH ${index + 1}';
    final deliveryStatus = stop['status'] as String? ?? 'planned';
    final hasLocation = customer?['lat'] != null && customer?['lng'] != null;
    
    // Valid statuses: planned, loading, in_progress, completed, cancelled
    Color statusColor;
    switch (deliveryStatus) {
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'loading':
        statusColor = Colors.purple;
        break;
      case 'planned':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStopIndex = index);
        
        final lat = customer?['lat'] as double?;
        final lng = customer?['lng'] as double?;
        if (lat != null && lng != null) {
          _mapController.move(LatLng(lat, lng), 16);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? statusColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? statusColor : (hasLocation ? Colors.grey.shade300 : Colors.red.shade300),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : statusColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasLocation
                    ? Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : const Icon(Icons.location_off, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customerName.length > 15 ? '${customerName.substring(0, 15)}...' : customerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  hasLocation ? _getStatusText(deliveryStatus) : '⚠️ Chưa có tọa độ',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.8) 
                        : (hasLocation ? Colors.grey.shade600 : Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivering':
      case 'in_progress':
        return 'Đang giao';
      case 'awaiting_pickup':
      case 'planned':
        return 'Chờ giao';
      case 'loading':
        return 'Đang lấy hàng';
      case 'completed':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _buildSelectedStopCard(Map<String, dynamic> stop) {
    final salesOrder = stop['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = salesOrder?['delivery_address'] ?? customer?['address'] ?? 'Chưa có địa chỉ';
    final customerPhone = customer?['phone'];
    // sales_orders uses 'total' not 'total_amount'
    final total = (salesOrder?['total'] as num?)?.toDouble() ?? 
                  (stop['total_amount'] as num?)?.toDouble() ?? 0;
    final orderNumber = salesOrder?['order_number']?.toString() ?? 
                        stop['delivery_number']?.toString() ?? 
                        stop['id'].toString().substring(0, 8).toUpperCase();
    final hasLocation = customer?['lat'] != null && customer?['lng'] != null;
    final lat = customer?['lat'] as double?;
    final lng = customer?['lng'] as double?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$orderNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!hasLocation)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Thiếu tọa độ',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedStopIndex = -1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Customer info
          Text(
            customerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openGoogleMapsSearch(customerAddress),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerAddress,
                    style: TextStyle(
                      color: Colors.blue.shade600, 
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.open_in_new, size: 12, color: Colors.blue.shade400),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons - 2 rows
          Row(
            children: [
              if (customerPhone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(customerPhone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Gọi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (customerPhone != null) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasLocation 
                      ? () => _openGoogleMapsNavigation(lat!, lng!)
                      : () => _openGoogleMapsSearch(customerAddress),
                  icon: Icon(hasLocation ? Icons.directions : Icons.search, size: 16),
                  label: Text(hasLocation ? 'Chỉ đường' : 'Tìm trên Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Edit location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingLocation = true;
                  _pickedLocation = null;
                  _pickedAddress = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Chạm vào bản đồ để chọn vị trí mới'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.edit_location_alt, size: 16),
              label: Text(hasLocation ? 'Sửa vị trí trên map' : 'Thêm vị trí trên map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.orange.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openNavigation(String? address) async {
    if (address == null || address.isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ============================================================================
// MY DELIVERIES PAGE - Modern UI
// ============================================================================
class _MyDeliveriesPage extends ConsumerStatefulWidget {
  const _MyDeliveriesPage();

  @override
  ConsumerState<_MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends ConsumerState<_MyDeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingDeliveries = [];  // Chờ nhận (pending)
  List<Map<String, dynamic>> _awaitingDeliveries = [];  // Chờ kho (awaiting_pickup)
  List<Map<String, dynamic>> _inProgressDeliveries = [];  // Đang giao (delivering)
  List<Map<String, dynamic>> _deliveredDeliveries = [];  // Đã giao (delivered)
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDeliveries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (companyId == null || driverId == null) return;

      final supabase = Supabase.instance.client;

      // ===== TAB 1: CHỜ NHẬN - Query từ sales_orders (awaiting_pickup) =====
      // Chỉ lấy những đơn chưa có delivery record nào
      final pendingOrders = await supabase
          .from('sales_orders')
          .select('''
            *, 
            customers(name, phone, address, lat, lng), 
            sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
          ''')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .order('created_at', ascending: true)
          .limit(100);

      // Lấy danh sách order_id đã có delivery
      final existingDeliveries = await supabase
          .from('deliveries')
          .select('order_id')
          .eq('company_id', companyId);
      
      final deliveredOrderIds = (existingDeliveries as List)
          .map((d) => d['order_id'] as String?)
          .where((id) => id != null)
          .toSet();

      // Filter ra những đơn chưa có delivery
      final pendingList = <Map<String, dynamic>>[];
      for (var order in pendingOrders) {
        final orderId = order['id'] as String?;
        if (orderId != null && !deliveredOrderIds.contains(orderId)) {
          pendingList.add({
            ...order,
            '_source': 'sales_orders',
            '_isPending': true,
          });
        }
      }

      // ===== TAB 2: CHỜ KHO - Query từ deliveries (loading) =====
      // Đơn đã nhận, đang chờ kho xác nhận giao hàng
      var awaitingQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'loading');

      final awaiting = await awaitingQuery.order('updated_at', ascending: false).limit(100);

      // ===== TAB 3: ĐANG GIAO - Query từ deliveries (in_progress) =====
      var inProgressQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'in_progress');

      final inProgress = await inProgressQuery.order('updated_at', ascending: false).limit(100);

      // ===== TAB 4: ĐÃ GIAO - Query từ deliveries (completed) =====
      var deliveredQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'completed');

      final delivered = await deliveredQuery.order('updated_at', ascending: false).limit(100);

      setState(() {
        _pendingDeliveries = pendingList;  // Từ sales_orders (awaiting_pickup)
        _awaitingDeliveries = List<Map<String, dynamic>>.from(awaiting);  // Chờ kho (loading)
        _inProgressDeliveries = List<Map<String, dynamic>>.from(inProgress);  // Đang giao
        _deliveredDeliveries = List<Map<String, dynamic>>.from(delivered);  // Đã giao
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load deliveries', e);
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Giao hàng',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadDeliveries();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm đơn hàng, khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.orange.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontSize: 12),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pending_actions, size: 16),
                              const SizedBox(width: 4),
                              const Text('Chờ nhận'),
                              if (_pendingDeliveries.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pendingDeliveries.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hourglass_empty, size: 16),
                              const SizedBox(width: 4),
                              const Text('Chờ kho'),
                              if (_awaitingDeliveries.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_awaitingDeliveries.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping, size: 16),
                              const SizedBox(width: 4),
                              const Text('Đang giao'),
                              if (_inProgressDeliveries.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_inProgressDeliveries.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 16),
                              const SizedBox(width: 4),
                              const Text('Đã giao'),
                              if (_deliveredDeliveries.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_deliveredDeliveries.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDeliveryList(_pendingDeliveries, isPending: true),
                        _buildAwaitingList(_awaitingDeliveries),
                        _buildDeliveryList(_inProgressDeliveries, isPending: false),
                        _buildDeliveredList(_deliveredDeliveries),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveredList(List<Map<String, dynamic>> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn đã giao',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các đơn bạn đã giao thành công\nsẽ hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          // Get sales_orders data from nested query
          final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
          final customer = salesOrder?['customers'] as Map<String, dynamic>?;
          
          final orderNumber = salesOrder?['order_number'] ?? delivery['order_number'] ?? 'N/A';
          final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Không có tên';
          final customerAddress = customer?['address'] ?? '';
          // Get total from sales_orders, fallback to delivery total_amount
          final totalAmount = (salesOrder?['total'] ?? delivery['total_amount'] ?? 0).toDouble();
          final updatedAt = delivery['updated_at'] != null 
              ? DateTime.parse(delivery['updated_at']).toLocal() 
              : DateTime.now();
          // Payment status from sales_orders, not deliveries
          final paymentStatus = salesOrder?['payment_status'] ?? delivery['payment_status'] ?? 'pending';
          final paymentMethod = salesOrder?['payment_method'] ?? delivery['payment_method'] ?? '';

          // Helper to get payment method display text
          String getPaymentMethodText() {
            if (paymentStatus != 'paid') return 'Chưa thu';
            switch (paymentMethod) {
              case 'cash': return 'Thu tiền mặt';
              case 'transfer': return 'Chuyển khoản';
              case 'debt': return 'Ghi công nợ';
              default: return 'Đã thu tiền';
            }
          }

          // Helper to get payment icon
          IconData getPaymentIcon() {
            if (paymentStatus != 'paid') return Icons.pending;
            switch (paymentMethod) {
              case 'cash': return Icons.payments;
              case 'transfer': return Icons.qr_code;
              case 'debt': return Icons.receipt_long;
              default: return Icons.check_circle;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '#$orderNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (customerAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customerAddress,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Đã giao',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentStatus == 'paid' ? Colors.blue.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getPaymentIcon(),
                              size: 14,
                              color: paymentStatus == 'paid' ? Colors.blue.shade700 : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              getPaymentMethodText(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: paymentStatus == 'paid' ? Colors.blue.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')} - ${updatedAt.day}/${updatedAt.month}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAwaitingList(List<Map<String, dynamic>> deliveries) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 48,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn chờ xác nhận',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các đơn bạn đã nhận sẽ hiển thị ở đây\nkhi chờ kho xác nhận giao hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          // Data từ deliveries table có nested sales_orders
          final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
          final customer = salesOrder?['customers'] as Map<String, dynamic>?;
          final orderNumber = salesOrder?['order_number'] ?? delivery['delivery_number'] ?? 'N/A';
          // Use 'total' first, then fallback to 'total_amount'
          final total = (salesOrder?['total'] ?? delivery['total_amount'] ?? 0).toDouble();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.purple.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_empty, size: 14, color: Colors.purple.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Chờ kho xác nhận',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Customer info - luôn hiển thị dù có customer hay không
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer?['name'] ?? salesOrder?['customer_name'] ?? 'Khách hàng',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer?['address'] ?? delivery['delivery_address'] ?? 'Chưa có địa chỉ',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Total amount
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          currencyFormat.format(total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vui lòng đến kho để nhận hàng. Kho sẽ xác nhận khi bàn giao.',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryList(List<Map<String, dynamic>> deliveries, {required bool isPending}) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.inbox_outlined : Icons.local_shipping_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Không có đơn chờ nhận' : 'Không có đơn đang giao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Kéo xuống để làm mới',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildDeliveryCard(delivery, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, {required bool isPending}) {
    // Check if data comes from sales_orders directly or from deliveries table
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    
    // Data structure depends on source:
    // - From sales_orders: data is flat with nested 'customers'
    // - From deliveries: data has nested 'sales_orders' with 'customers'
    final Map<String, dynamic>? salesOrder;
    final Map<String, dynamic>? customer;
    
    if (isFromSalesOrders) {
      // Data is the sales order itself
      salesOrder = delivery;
      customer = delivery['customers'] as Map<String, dynamic>?;
    } else {
      // Data is from deliveries table with nested sales_orders
      salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
      customer = salesOrder?['customers'] as Map<String, dynamic>?;
    }
    
    final orderNumber = salesOrder?['order_number']?.toString() ?? 
                        delivery['delivery_number']?.toString() ?? 
                        delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (salesOrder?['total'] as num?)?.toDouble() ?? 
                  (salesOrder?['total_amount'] as num?)?.toDouble() ?? 0;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = delivery['delivery_address'] ?? customer?['address'];
    final customerPhone = customer?['phone'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPending ? Colors.orange.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  currencyFormat.format(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer info
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ),
                if (customerPhone != null)
                  IconButton(
                    icon: Icon(Icons.phone, color: Colors.green.shade600, size: 20),
                    onPressed: () => _callCustomer(customerPhone),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
              ],
            ),

            if (customerAddress != null && customerAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openMaps(customerAddress),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerAddress,
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade400),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                if (!isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps(customerAddress),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: isPending ? 1 : 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isPending) {
                        // For pending orders from sales_orders, we need to create delivery record
                        if (isFromSalesOrders) {
                          final orderId = delivery['id'] as String;
                          _acceptOrder(orderId, delivery);
                        } else {
                          final deliveryId = delivery['id'] as String;
                          final orderId = delivery['order_id'] as String? ?? 
                                         (delivery['sales_orders'] as Map<String, dynamic>?)?['id'] as String? ?? 
                                         deliveryId;
                          _pickupDelivery(deliveryId, orderId);
                        }
                      } else {
                        final deliveryId = delivery['id'] as String;
                        final orderId = delivery['order_id'] as String? ?? 
                                       (delivery['sales_orders'] as Map<String, dynamic>?)?['id'] as String? ?? 
                                       deliveryId;
                        _completeDelivery(deliveryId, orderId);
                      }
                    },
                    icon: Icon(isPending ? Icons.play_arrow : Icons.check_circle, size: 18),
                    label: Text(isPending ? 'Nhận đơn' : 'Đã giao'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get driver ID and company ID from auth provider (same as dashboard)
      final authState = ref.read(authProvider);
      final driverId = authState.user?.id;
      final companyId = authState.user?.companyId;
      
      if (driverId == null || companyId == null) {
        throw Exception('Chưa đăng nhập hoặc thiếu thông tin công ty');
      }

      // Create new delivery record with status = 'loading' (chờ kho xác nhận)
      final now = DateTime.now().toIso8601String();
      await supabase.from('deliveries').insert({
        'company_id': companyId,
        'order_id': orderId,
        'driver_id': driverId,
        'delivery_number': 'DL-${DateTime.now().millisecondsSinceEpoch}',
        'delivery_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'loading',  // Chờ kho xác nhận
        'updated_at': now,
      }).select().single();

      // Update sales_orders - giữ nguyên awaiting_pickup vì chưa thực sự giao
      // Chỉ cập nhật khi kho xác nhận xong mới chuyển sang 'delivering'
      // Không cần update sales_orders ở đây vì delivery đã track status riêng

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã nhận đơn! Chờ kho xác nhận giao hàng.'),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDeliveries();
      }
    } catch (e) {
      AppLogger.error('Failed to accept order', e);
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

  Future<void> _pickupDelivery(String deliveryId, String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      // Update delivery status to in_progress (valid: planned, loading, in_progress, completed, cancelled)
      await supabase.from('deliveries').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      // Also update sales_orders delivery_status for consistency
      await supabase.from('sales_orders').update({
        'delivery_status': 'delivering',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã nhận đơn! Bắt đầu giao hàng.'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDeliveries();
      }
    } catch (e) {
      AppLogger.error('Failed to pickup delivery', e);
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

  Future<void> _completeDelivery(String deliveryId, String orderId) async {
    // Debug log
    AppLogger.info('🚛 _completeDelivery called with deliveryId: "$deliveryId", orderId: "$orderId"');
    
    // Validate orderId is a valid UUID (not empty, not null string)
    if (orderId.isEmpty || orderId == 'null') {
      AppLogger.error('Invalid orderId: $orderId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Không tìm thấy mã đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Get order info to check payment status
      final orderResponse = await supabase
          .from('sales_orders')
          .select('payment_method, payment_status, total, customers(name)')
          .eq('id', orderId)
          .single();

      final paymentMethod = orderResponse['payment_method']?.toString().toLowerCase() ?? 'cod';
      final paymentStatus = orderResponse['payment_status']?.toString().toLowerCase() ?? 'unpaid';
      final total = (orderResponse['total'] ?? 0).toDouble();
      final customerData = orderResponse['customers'] as Map<String, dynamic>?;
      final customerName = customerData?['name'] ?? 'Khách hàng';

      // Show payment method selection dialog
      final result = await _showPaymentMethodDialog(
        orderId: orderId,
        customerName: customerName,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        totalAmount: total,
      );

      if (result == null) return;

      AppLogger.info('🔄 Updating deliveries and sales_orders with payment: $result');

      // Update delivery record - use 'completed' (valid: planned, loading, in_progress, completed, cancelled)
      await supabase.from('deliveries').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', deliveryId);

      // Update sales_orders delivery status and payment if needed
      Map<String, dynamic> updateData = {
        'delivery_status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (result['updatePayment'] == true) {
        updateData['payment_status'] = result['paymentStatus'];
        updateData['payment_method'] = result['paymentMethod'];
        if (result['paymentStatus'] == 'paid') {
          updateData['payment_collected_at'] = DateTime.now().toIso8601String();
        }
      }

      await supabase.from('sales_orders').update(updateData).eq('id', orderId);
      
      AppLogger.info('✅ Update completed for deliveryId: $deliveryId, orderId: $orderId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['updatePayment'] == true 
                        ? '🎉 Giao hàng và thanh toán thành công!'
                        : '🎉 Giao hàng thành công!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadDeliveries();
      }
    } catch (e) {
      AppLogger.error('Failed to complete delivery', e);
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

  /// Dialog chọn phương thức thanh toán khi hoàn thành giao hàng
  Future<Map<String, dynamic>?> _showPaymentMethodDialog({
    required String orderId,
    required String customerName,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
  }) async {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    String selectedOption = 'delivered_only';
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Xác nhận giao hàng', style: TextStyle(fontSize: 18)),
                    Text(customerName, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment status info
                if (paymentStatus == 'paid')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Đơn hàng đã thanh toán', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                else ...[
                  const Text('Chọn phương thức:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Option 1: Just deliver
                  RadioListTile<String>(
                    value: 'delivered_only',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v!),
                    title: const Text('Chỉ xác nhận giao hàng'),
                    subtitle: const Text('Chưa thu tiền', style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Option 2: Cash
                  RadioListTile<String>(
                    value: 'cash',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v!),
                    title: const Text('💵 Thu tiền mặt'),
                    subtitle: Text(currencyFormat.format(totalAmount), style: const TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Option 3: Transfer
                  RadioListTile<String>(
                    value: 'transfer',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v!),
                    title: const Text('🏦 Chuyển khoản'),
                    subtitle: const Text('Hiện QR cho khách quét', style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Show QR button when transfer is selected
                  if (selectedOption == 'transfer')
                    Container(
                      margin: const EdgeInsets.only(left: 16, bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close current dialog
                          _showQRTransferDialog(this.context, totalAmount, orderId);
                        },
                        icon: const Icon(Icons.qr_code, size: 20),
                        label: const Text('Hiện QR cho khách quét'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  
                  // Option 4: Debt
                  RadioListTile<String>(
                    value: 'debt',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v!),
                    title: const Text('📝 Ghi nợ'),
                    subtitle: const Text('Thêm vào công nợ khách hàng', style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Map<String, dynamic> result = {'updatePayment': false};
                
                switch (selectedOption) {
                  case 'cash':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid',
                      'paymentMethod': 'cash',
                    };
                    break;
                  case 'transfer':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid',
                      'paymentMethod': 'transfer',
                    };
                    break;
                  case 'debt':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'unpaid',
                      'paymentMethod': 'debt',
                    };
                    break;
                  default:
                    result = {'updatePayment': false};
                }
                
                Navigator.pop(context, result);
              },
              icon: const Icon(Icons.check),
              label: const Text('Xác nhận'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) return;

    // Clean address: remove notes after '--' (e.g., "123 ABC -- Chị Trúc" -> "123 ABC")
    String cleanAddress = address;
    if (address.contains('--')) {
      cleanAddress = address.split('--').first.trim();
    }

    // Use Google Maps Directions API with current location as origin
    // travelmode=driving for car navigation
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=${Uri.encodeComponent(cleanAddress)}&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Hiển thị QR VietQR để khách quét chuyển khoản
  void _showQRTransferDialog(BuildContext context, double amount, String orderId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // Get employee's company
      final empData = await supabase
          .from('employees')
          .select('company_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      
      if (empData == null || empData['company_id'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thông tin công ty')),
          );
        }
        return;
      }
      
      // Get company bank info
      final companyData = await supabase
          .from('companies')
          .select('bank_name, bank_account_number, bank_account_name, bank_bin')
          .eq('id', empData['company_id'])
          .maybeSingle();
      
      if (companyData == null || 
          companyData['bank_bin'] == null || 
          companyData['bank_account_number'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Công ty chưa cấu hình tài khoản ngân hàng. Liên hệ Manager/CEO để cấu hình.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final bankBin = companyData['bank_bin'];
      final accountNumber = companyData['bank_account_number'];
      final accountName = companyData['bank_account_name'] ?? '';
      final bankName = companyData['bank_name'] ?? 'Ngân hàng';
      
      // Build VietQR URL
      final amountInt = amount.toInt();
      final content = 'TT $orderId';
      final qrUrl = 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png?amount=$amountInt&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}';
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.qr_code, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('QR Chuyển khoản', style: TextStyle(fontSize: 18))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.network(
                      qrUrl,
                      width: 220,
                      height: 220,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 220,
                        height: 220,
                        color: Colors.grey.shade100,
                        child: const Center(child: Text('Không thể tải QR')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          bankName,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountNumber,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(accountName, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Số tiền:', style: TextStyle(fontSize: 12)),
                        Text(
                          currencyFormat.format(amount),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                        const SizedBox(height: 8),
                        const Text('Nội dung:', style: TextStyle(fontSize: 12)),
                        Text(content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Sau khi khách chuyển, nhấn Xác nhận để hoàn thành',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận đã chuyển'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ).then((confirmed) async {
          if (confirmed == true && context.mounted) {
            // TODO: Handle confirmation - update payment status
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}

// ============================================================================
// DELIVERY HISTORY PAGE - Modern UI
// ============================================================================
class _DeliveryHistoryPage extends ConsumerStatefulWidget {
  const _DeliveryHistoryPage();

  @override
  ConsumerState<_DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends ConsumerState<_DeliveryHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  String _dateFilter = 'today';
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null || userId == null) return;

      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      DateTime startDate;
      switch (_dateFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'delivered')
          .gte('updated_at', startDate.toIso8601String())
          .order('updated_at', ascending: false)
          .limit(100);

      setState(() {
        _history = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load delivery history', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _history.fold<num>(
      0,
      (sum, order) => sum + ((order['total'] as num?) ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lịch sử giao hàng',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadHistory();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date filter chips
                  Row(
                    children: [
                      _buildFilterChip('Hôm nay', 'today'),
                      const SizedBox(width: 8),
                      _buildFilterChip('7 ngày', 'week'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tháng này', 'month'),
                    ],
                  ),
                ],
              ),
            ),

            // Summary card
            if (!_isLoading && _history.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_history.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Đơn đã giao',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payments, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tổng thu hộ',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // History list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có lịch sử giao hàng',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final order = _history[index];
                              return _buildHistoryCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _dateFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateFilter = value;
          _isLoading = true;
        });
        _loadHistory();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final deliveredAt = order['delivery_date'] != null
        ? DateTime.tryParse(order['delivery_date'])
        : null;
    final customerName = order['customer_name'] ?? customer?['name'] ?? 'Khách hàng';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$orderNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  customerName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (deliveredAt != null)
                  Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(deliveredAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(total),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRIVER PROFILE PAGE - Modern UI
// ============================================================================
class _DriverProfilePage extends ConsumerWidget {
  const _DriverProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'T')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Tài xế',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Tài xế giao hàng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.companyName ?? 'Công ty',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        iconColor: Colors.blue,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Xem và chỉnh sửa thông tin',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.directions_car_outlined,
                        iconColor: Colors.orange,
                        title: 'Phương tiện',
                        subtitle: 'Quản lý xe giao hàng',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bar_chart_outlined,
                        iconColor: Colors.green,
                        title: 'Thống kê',
                        subtitle: 'Xem hiệu suất làm việc',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.purple,
                        title: 'Thông báo',
                        subtitle: 'Quản lý thông báo',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        iconColor: Colors.grey,
                        title: 'Cài đặt',
                        subtitle: 'Tùy chỉnh ứng dụng',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bug report & Support
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        iconColor: Colors.teal,
                        title: 'Trợ giúp',
                        subtitle: 'Hướng dẫn sử dụng',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        iconColor: Colors.red,
                        title: 'Báo cáo lỗi',
                        subtitle: 'Gửi phản hồi về vấn đề gặp phải',
                        onTap: () => BugReportDialog.show(context),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(authProvider.notifier).logout();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildDeliveryCompletionDialog({
    required String orderId,
    required String customerName,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    String selectedPaymentOption = 'delivered_only'; // delivered_only, cash_collected, transfer_confirmed, debt_added

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.local_shipping, color: Colors.green.shade600, size: 32),
              ),
              const SizedBox(height: 12),
              Text('Hoàn thành giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Mã đơn: $orderId', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('👤 Khách hàng: $customerName'),
                    Text('💰 Tổng tiền: ${currencyFormat.format(totalAmount)}'),
                    Text('💳 Hình thức: ${_getPaymentMethodLabel(paymentMethod)}'),
                    Text('📊 Trạng thái: ${_getPaymentStatusLabel(paymentStatus)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment options
              const Text('Xử lý thanh toán:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              
              // Option 1: Chỉ giao hàng
              RadioListTile<String>(
                value: 'delivered_only',
                groupValue: selectedPaymentOption,
                onChanged: (value) => setState(() => selectedPaymentOption = value!),
                title: const Text('Chỉ xác nhận giao hàng'),
                subtitle: Text('Giữ nguyên trạng thái thanh toán: ${_getPaymentStatusLabel(paymentStatus)}'),
                dense: true,
              ),
              
              // Option 2: Thu tiền mặt (nếu COD)
              if (paymentMethod == 'cod' && paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'cash_collected',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('💵 Thu tiền mặt'),
                  subtitle: Text('Xác nhận đã thu ${currencyFormat.format(totalAmount)}'),
                  dense: true,
                ),
              
              // Option 3: Xác nhận chuyển khoản
              if (paymentMethod == 'transfer' && paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'transfer_confirmed',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('🏦 Xác nhận chuyển khoản'),
                  subtitle: const Text('Khách hàng đã chuyển khoản'),
                  dense: true,
                ),
              
              // Option 4: Ghi nợ
              if (paymentStatus != 'paid')
                RadioListTile<String>(
                  value: 'debt_added',
                  groupValue: selectedPaymentOption,
                  onChanged: (value) => setState(() => selectedPaymentOption = value!),
                  title: const Text('📝 Ghi nợ'),
                  subtitle: const Text('Khách hàng sẽ thanh toán sau'),
                  dense: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> result = {'updatePayment': false};
                
                switch (selectedPaymentOption) {
                  case 'delivered_only':
                    // Chỉ cập nhật delivery status
                    break;
                    
                  case 'cash_collected':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid',
                      'paymentMethod': 'cash',
                    };
                    break;
                    
                  case 'transfer_confirmed':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'paid', 
                      'paymentMethod': 'transfer',
                    };
                    break;
                    
                  case 'debt_added':
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'debt',
                      'paymentMethod': paymentMethod, // Giữ nguyên payment method
                    };
                    break;
                }
                
                Navigator.pop(context, result);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Tiền mặt (COD)';
      case 'cash':
        return 'Tiền mặt';
      case 'transfer':
        return 'Chuyển khoản';
      case 'card':
        return 'Thẻ tín dụng';
      default:
        return method;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'partial':
        return 'Thanh toán một phần';
      case 'debt':
        return 'Ghi nợ';
      default:
        return status;
    }
  }
}
