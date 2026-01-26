import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

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
          _MyDeliveriesPage(),
          _DriverJourneyMapPage(),
          _DeliveryHistoryPage(),
          _DriverProfilePage(),
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
              icon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: Colors.blue.shade700),
              ),
              label: 'Giao hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map, color: Colors.orange.shade700),
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
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: Colors.purple.shade700),
              ),
              label: 'Tài khoản',
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
      final userId = authState.user?.id;

      if (companyId == null || userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get pending deliveries (ready for driver to pick up)
      final pendingResp = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('delivery_status', 'pending')
          .count();

      // Get in-progress deliveries (driver is delivering)
      final inProgressResp = await supabase
          .from('sales_orders')
          .select('id')
          .eq('company_id', companyId)
          .eq('delivery_status', 'delivering')
          .count();

      // Get today's completed deliveries
      final completedResp = await supabase
          .from('sales_orders')
          .select('id, total')
          .eq('company_id', companyId)
          .eq('delivery_status', 'delivered')
          .gte('updated_at', startOfDay.toIso8601String());

      double todayRevenue = 0;
      for (var order in completedResp) {
        todayRevenue += (order['total'] as num?)?.toDouble() ?? 0;
      }

      // Get today's delivery list (pending + delivering)
      final deliveries = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .inFilter('delivery_status', ['pending', 'delivering'])
          .order('created_at', ascending: true)
          .limit(20);

      setState(() {
        _stats = {
          'pending': pendingResp.count,
          'inProgress': inProgressResp.count,
          'completedToday': completedResp.length,
          'todayRevenue': todayRevenue,
        };
        _todayDeliveries = List<Map<String, dynamic>>.from(deliveries);
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
    final customer = delivery['customers'] as Map<String, dynamic>?;
    final status = delivery['status'] as String;
    final orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
    final customerPhone = delivery['customer_phone'] ?? customer?['phone'];

    Color statusColor;
    String statusText;
    IconData statusIcon;
    bool isPending;

    switch (status) {
      case 'ready_for_delivery':
      case 'processing':
        statusColor = Colors.orange;
        statusText = 'Chờ nhận';
        statusIcon = Icons.pending_actions;
        isPending = true;
        break;
      case 'shipping':
        statusColor = Colors.blue;
        statusText = 'Đang giao';
        statusIcon = Icons.local_shipping;
        isPending = false;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help_outline;
        isPending = true;
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
                    onPressed: () => isPending
                        ? _pickupDelivery(delivery['id'])
                        : _completeDelivery(delivery['id']),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryDetailSheet(
        delivery: delivery,
        currencyFormat: currencyFormat,
        onPickup: () => _pickupDelivery(delivery['id']),
        onComplete: () => _completeDelivery(delivery['id']),
        onCall: _callCustomer,
        onNavigate: _openMaps,
      ),
    );
  }

  Future<void> _pickupDelivery(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      // Set to awaiting_pickup - warehouse needs to confirm handover
      await supabase.from('sales_orders').update({
        'delivery_status': 'awaiting_pickup',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã gửi yêu cầu! Chờ kho xác nhận giao hàng.'),
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

  Future<void> _completeDelivery(String orderId) async {
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
            const Text('Xác nhận giao hàng'),
          ],
        ),
        content: const Text('Bạn đã giao hàng thành công cho khách?'),
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

      await supabase.from('sales_orders').update({
        'delivery_status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Text('🎉 Giao hàng thành công!'),
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

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
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

  const _DeliveryDetailSheet({
    required this.delivery,
    required this.currencyFormat,
    required this.onPickup,
    required this.onComplete,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final customer = delivery['customers'] as Map<String, dynamic>?;
    final status = delivery['status'] as String;
    final orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
    final customerPhone = delivery['customer_phone'] ?? customer?['phone'];
    final notes = delivery['notes'] ?? delivery['delivery_notes'];
    final isPending = status == 'ready_for_delivery' || status == 'processing';

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
            child: Row(
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
                    label: Text(isPending ? 'Nhận đơn giao' : 'Xác nhận đã giao'),
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
    
    final isPaid = paymentStatus == 'paid';
    final isCOD = paymentMethod.toString().toLowerCase() == 'cod' || paymentMethod.toString().toLowerCase() == 'cash';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCOD && !isPaid ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCOD && !isPaid ? Colors.orange.shade200 : Colors.green.shade200,
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
                  color: isCOD ? Colors.orange.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCOD ? '💵 COD (Thu hộ)' : '💳 Đã thanh toán',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCOD ? Colors.orange.shade800 : Colors.blue.shade800,
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
                isCOD && !isPaid ? '💰 CẦN THU:' : 'Tổng tiền:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCOD && !isPaid ? Colors.orange.shade800 : Colors.black87,
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isCOD && !isPaid ? Colors.orange.shade800 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;

      final deliveries = await supabase
          .from('sales_orders')
          .select('*, customers(id, name, phone, address, latitude, longitude)')
          .eq('company_id', companyId)
          .inFilter('delivery_status', ['delivering', 'pending', 'awaiting_pickup'])
          .order('created_at', ascending: true)
          .limit(20);

      setState(() {
        _deliveryStops = List<Map<String, dynamic>>.from(deliveries);
        _isLoading = false;
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
      final customer = stop['customers'] as Map<String, dynamic>?;
      final lat = customer?['latitude'] as double?;
      final lng = customer?['longitude'] as double?;
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
    final customer = stop['customers'] as Map<String, dynamic>?;
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

      // Update customer location
      await supabase.from('customers').update({
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
        if (_pickedAddress != null && _pickedAddress != 'Không tìm thấy địa chỉ')
          'address': _pickedAddress,
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

  // Mở Google Maps để điều hướng
  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      final customer = stop['customers'] as Map<String, dynamic>?;
      final lat = customer?['latitude'] as double?;
      final lng = customer?['longitude'] as double?;
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
      final customer = stop['customers'] as Map<String, dynamic>?;
      final lat = customer?['latitude'] as double?;
      final lng = customer?['longitude'] as double?;

      if (lat != null && lng != null) {
        final deliveryStatus = stop['delivery_status'] as String? ?? 'pending';
        final isSelected = _selectedStopIndex == i;
        
        Color markerColor;
        switch (deliveryStatus) {
          case 'delivering':
            markerColor = Colors.blue;
            break;
          case 'awaiting_pickup':
            markerColor = Colors.purple;
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
      height: 100,
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
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _deliveryStops.length,
                  itemBuilder: (context, index) {
                    final stop = _deliveryStops[index];
                    final isSelected = _selectedStopIndex == index;
                    return _buildStopChip(stop, index, isSelected);
                  },
                ),
    );
  }

  Widget _buildStopChip(Map<String, dynamic> stop, int index, bool isSelected) {
    final customer = stop['customers'] as Map<String, dynamic>?;
    final customerName = stop['customer_name'] ?? customer?['name'] ?? 'KH ${index + 1}';
    final deliveryStatus = stop['delivery_status'] as String? ?? 'pending';
    final hasLocation = customer?['latitude'] != null && customer?['longitude'] != null;
    
    Color statusColor;
    switch (deliveryStatus) {
      case 'delivering':
        statusColor = Colors.blue;
        break;
      case 'awaiting_pickup':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStopIndex = index);
        
        final lat = customer?['latitude'] as double?;
        final lng = customer?['longitude'] as double?;
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
        return 'Đang giao';
      case 'awaiting_pickup':
        return 'Chờ lấy hàng';
      case 'pending':
        return 'Chờ giao';
      default:
        return status;
    }
  }

  Widget _buildSelectedStopCard(Map<String, dynamic> stop) {
    final customer = stop['customers'] as Map<String, dynamic>?;
    final customerName = stop['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = stop['delivery_address'] ?? customer?['address'] ?? 'Chưa có địa chỉ';
    final customerPhone = stop['customer_phone'] ?? customer?['phone'];
    final total = (stop['total'] as num?)?.toDouble() ?? 0;
    final orderNumber = stop['order_number']?.toString() ?? stop['id'].toString().substring(0, 8).toUpperCase();
    final hasLocation = customer?['latitude'] != null && customer?['longitude'] != null;
    final lat = customer?['latitude'] as double?;
    final lng = customer?['longitude'] as double?;

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
  List<Map<String, dynamic>> _pendingDeliveries = [];
  List<Map<String, dynamic>> _awaitingDeliveries = [];
  List<Map<String, dynamic>> _inProgressDeliveries = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Get pending (ready for pickup) - orders with delivery_status = 'pending'
      var pendingQuery = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'pending');

      if (_searchQuery.isNotEmpty) {
        pendingQuery = pendingQuery.or('order_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%');
      }

      final pending = await pendingQuery.order('updated_at', ascending: false).limit(100);

      // Get awaiting pickup (driver requested, waiting for warehouse confirmation)
      var awaitingQuery = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup');

      if (_searchQuery.isNotEmpty) {
        awaitingQuery = awaitingQuery.or('order_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%');
      }

      final awaiting = await awaitingQuery.order('updated_at', ascending: false).limit(100);

      // Get in-progress (currently being delivered) - delivery_status = 'delivering'
      var inProgressQuery = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit, unit_price, line_total)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'delivering');

      if (_searchQuery.isNotEmpty) {
        inProgressQuery = inProgressQuery.or('order_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%');
      }

      final inProgress = await inProgressQuery.order('updated_at', ascending: false).limit(100);

      setState(() {
        _pendingDeliveries = List<Map<String, dynamic>>.from(pending);
        _awaitingDeliveries = List<Map<String, dynamic>>.from(awaiting);
        _inProgressDeliveries = List<Map<String, dynamic>>.from(inProgress);
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
                      ],
                    ),
            ),
          ],
        ),
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
          final customer = delivery['customers'] as Map<String, dynamic>?;
          final orderNumber = delivery['order_number'] ?? 'N/A';
          final total = (delivery['total_amount'] ?? 0).toDouble();

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

                  // Customer info
                  if (customer != null) ...[
                    Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customer['name'] ?? delivery['customer_name'] ?? 'N/A',
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
                            customer['address'] ?? 'Chưa có địa chỉ',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],

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
    final customer = delivery['customers'] as Map<String, dynamic>?;
    final orderNumber = delivery['order_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final customerName = delivery['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = delivery['delivery_address'] ?? delivery['customer_address'] ?? customer?['address'];
    final customerPhone = delivery['customer_phone'] ?? customer?['phone'];

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
                    onPressed: () => isPending
                        ? _pickupDelivery(delivery['id'])
                        : _completeDelivery(delivery['id']),
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

  Future<void> _pickupDelivery(String orderId) async {
    try {
      final supabase = Supabase.instance.client;

      // Set to awaiting_pickup - warehouse needs to confirm handover
      await supabase.from('sales_orders').update({
        'delivery_status': 'awaiting_pickup',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã gửi yêu cầu! Chờ kho xác nhận giao hàng.'),
              ],
            ),
            backgroundColor: Colors.orange,
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

  Future<void> _completeDelivery(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận giao hàng'),
        content: const Text('Bạn đã giao hàng thành công cho khách?'),
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

      await supabase.from('sales_orders').update({
        'delivery_status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Text('🎉 Giao hàng thành công!'),
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

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
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
}
