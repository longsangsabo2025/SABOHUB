import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

class WarehousePackingPage extends ConsumerStatefulWidget {
  const WarehousePackingPage({super.key});

  @override
  ConsumerState<WarehousePackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends ConsumerState<WarehousePackingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _packedOrders = [];
  List<Map<String, dynamic>> _readyForDriverOrders = [];
  List<Map<String, dynamic>> _awaitingPickupOrders = [];
  List<Map<String, dynamic>> _handedOverOrders = [];
  DateTimeRange? _handedOverDateFilter;
  
  // Track which orders are being processed to prevent double-click
  final Set<String> _processingOrders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    await Future.wait([
      _loadPackedOrders(),
      _loadReadyForDriverOrders(),
      _loadAwaitingPickupOrders(),
      _loadHandedOverOrders(),
    ]);
  }

  Future<void> _loadReadyForDriverOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Orders packed and ready for driver to pickup (delivery_status = 'awaiting_pickup')
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(*), warehouses(id, name)')
          .eq('company_id', companyId)
          .eq('delivery_status', 'awaiting_pickup')
          .order('updated_at', ascending: false)
          .limit(50);

      setState(() {
        _readyForDriverOrders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load ready for driver orders', e);
    }
  }

  Future<void> _loadAwaitingPickupOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Tab 3: Orders accepted by driver (deliveries.status = 'loading'), waiting for warehouse handover
      final data = await supabase
          .from('deliveries')
          .select('*, sales_orders:order_id(id, order_number, total, customer_name, delivery_address, created_at, updated_at, payment_method, payment_status, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit)), employees:driver_id(id, full_name)')
          .eq('company_id', companyId)
          .eq('status', 'loading')
          .order('updated_at', ascending: false)
          .limit(50);

      setState(() {
        _awaitingPickupOrders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load awaiting pickup orders', e);
    }
  }

  Future<void> _loadHandedOverOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Tab 4: Orders handed over to driver (in_progress or completed)
      var handedQuery = supabase
          .from('deliveries')
          .select('*, sales_orders:order_id(id, order_number, total, customer_name, delivery_address, payment_method, payment_status, delivery_status, customers(name, phone, address), sales_order_items(id, product_name, quantity, unit)), employees:driver_id(id, full_name)')
          .eq('company_id', companyId)
          .inFilter('status', ['in_progress', 'completed']);

      if (_handedOverDateFilter != null) {
        handedQuery = handedQuery
            .gte('updated_at', _handedOverDateFilter!.start.toIso8601String())
            .lte('updated_at', _handedOverDateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      } else {
        // Default: today
        final today = DateTime.now().toIso8601String().split('T')[0];
        handedQuery = handedQuery.gte('updated_at', '${today}T00:00:00');
      }

      final data = await handedQuery
          .order('updated_at', ascending: false)
          .limit(200);

      setState(() {
        _handedOverOrders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load handed over orders', e);
    }
  }

  Future<void> _loadPackedOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      // Show orders that are ready (picked) and waiting for packing
      // status = 'ready' means picked and ready for packing
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address), sales_order_items(*), warehouses(id, name)')
          .eq('company_id', companyId)
          .eq('status', 'ready')
          .eq('delivery_status', 'pending')
          .order('updated_at', ascending: true)
          .limit(50);

      setState(() {
        _packedOrders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load packed orders', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markReadyForDelivery(String orderId) async {
    // Prevent double-click
    if (_processingOrders.contains(orderId)) return;
    
    setState(() => _processingOrders.add(orderId));
    
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('sales_orders').update({
        'status': 'completed',
        'delivery_status': 'awaiting_pickup',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white),
                SizedBox(width: 12),
                Text('Đơn hàng sẵn sàng để giao!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadAllOrders();
      }
    } catch (e) {
      AppLogger.error('Failed to mark ready', e);
    } finally {
      if (mounted) {
        setState(() => _processingOrders.remove(orderId));
      }
    }
  }

  Future<void> _confirmHandoverToDriver(String deliveryId, String orderId) async {
    // Prevent double-click
    if (_processingOrders.contains(deliveryId)) return;
    
    setState(() => _processingOrders.add(deliveryId));
    
    try {
      final supabase = Supabase.instance.client;

      // Use RPC for transaction-safe update
      final result = await supabase.rpc('start_delivery', params: {
        'p_delivery_id': deliveryId,
        'p_order_id': orderId,
      });
      
      if (result != null && result['success'] == false) {
        throw Exception(result['error'] ?? 'Unknown error');
      }

      // Ensure sales_orders delivery_status is updated
      await supabase.from('sales_orders').update({
        'delivery_status': 'delivering',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xác nhận giao hàng cho tài xế!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadAllOrders();
      }
    } catch (e) {
      AppLogger.error('Failed to confirm handover', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingOrders.remove(deliveryId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with TabBar
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Đóng gói & Giao hàng',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadAllOrders();
                          },
                        ),
                      ],
                    ),
                  ),
                  // TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      labelColor: Colors.green.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontSize: 11),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 14),
                              const SizedBox(width: 4),
                              const Text('Đóng gói'),
                              if (_packedOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_packedOrders.length}',
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
                              const Icon(Icons.local_shipping, size: 14),
                              const SizedBox(width: 4),
                              const Text('Sẵn sàng'),
                              if (_readyForDriverOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_readyForDriverOrders.length}',
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
                              const Icon(Icons.delivery_dining, size: 14),
                              const SizedBox(width: 4),
                              const Text('Chờ giao'),
                              if (_awaitingPickupOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_awaitingPickupOrders.length}',
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
                              const Icon(Icons.fact_check, size: 14),
                              const SizedBox(width: 4),
                              const Text('Đã giao'),
                              if (_handedOverOrders.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_handedOverOrders.length}',
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
                  const SizedBox(height: 12),
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
                        _buildPackedOrdersList(),
                        _buildReadyForDriverList(),
                        _buildAwaitingPickupList(),
                        _buildHandedOverList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyForDriverList() {
    if (_readyForDriverOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping_outlined, size: 48, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn sẵn sàng giao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Sẵn sàng giao" ở tab Đóng gói\nđể đơn hiển thị ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _readyForDriverOrders.length,
        itemBuilder: (context, index) {
          final order = _readyForDriverOrders[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();

          return GestureDetector(
            onTap: () => _showOrderDetailSheet(order),
            child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_shipping, color: Colors.blue.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderNumber',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              customer?['name'] ?? order['customer_name'] ?? 'Khách hàng',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Chờ tài xế',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if ((order['delivery_address'] ?? customer?['address']) != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['delivery_address'] ?? customer!['address'],
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Order info (total, items, time)
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_outlined, size: 15, color: Colors.green.shade600),
                                const SizedBox(width: 5),
                                Text('Tổng tiền:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format((order['total'] as num?)?.toDouble() ?? 0),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 15, color: Colors.blue.shade600),
                                const SizedBox(width: 5),
                                Text('Sản phẩm:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            Text(
                              '${(order['sales_order_items'] as List?)?.length ?? 0} SP',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (order['updated_at'] != null) ...[                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 15, color: Colors.orange.shade600),
                                  const SizedBox(width: 5),
                                  Text('Cập nhật:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                              Text(
                                DateFormat('HH:mm dd/MM').format(DateTime.parse(order['updated_at']).toLocal()),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
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
                            'Đang chờ tài xế đến nhận hàng',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackedOrdersList() {
    if (_packedOrders.isEmpty) {
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
              child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn đã đóng gói',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _packedOrders.length,
        itemBuilder: (context, index) {
          final order = _packedOrders[index];
          return _buildPackedOrderCard(order);
        },
      ),
    );
  }

  Widget _buildPackedOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final orderNumber = order['order_number']?.toString() ?? order['id'].toString().substring(0, 8).toUpperCase();
    final warehouse = order['warehouses'] as Map<String, dynamic>?;
    final warehouseName = warehouse?['name'] ?? 'Kho chính';

    return GestureDetector(
      onTap: () => _showOrderDetailSheet(order),
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2, color: Colors.green.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$orderNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warehouse, size: 10, color: Colors.grey.shade600),
                                const SizedBox(width: 3),
                                Text(
                                  warehouseName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        customer?['name'] ?? 'Khách hàng',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã đóng gói',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if ((order['delivery_address'] ?? customer?['address']) != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['delivery_address'] ?? customer!['address'],
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Product items
            if (order['sales_order_items'] != null && (order['sales_order_items'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Sản phẩm (${(order['sales_order_items'] as List).length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(order['sales_order_items'] as List).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item['product_name']} x${item['quantity']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processingOrders.contains(order['id'])
                    ? null
                    : () => _markReadyForDelivery(order['id']),
                icon: _processingOrders.contains(order['id'])
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.local_shipping, size: 20),
                label: Text(_processingOrders.contains(order['id'])
                    ? 'Đang xử lý...'
                    : 'Sẵn sàng giao cho tài xế'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _processingOrders.contains(order['id'])
                      ? Colors.grey
                      : Colors.blue,
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
    );
  }

  Widget _buildAwaitingPickupList() {
    if (_awaitingPickupOrders.isEmpty) {
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
              child: Icon(Icons.delivery_dining_outlined, size: 48, color: Colors.purple.shade300),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đơn chờ giao',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi tài xế nhận đơn, đơn sẽ hiển thị ở đây\nđể kho xác nhận bàn giao',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final timeFmt = DateFormat('HH:mm dd/MM');

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _awaitingPickupOrders.length,
        itemBuilder: (context, index) {
          // Data now comes from deliveries table
          final delivery = _awaitingPickupOrders[index];
          final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
          final customer = salesOrder?['customers'] as Map<String, dynamic>?;
          final driver = delivery['employees'] as Map<String, dynamic>?;
          final orderNumber = salesOrder?['order_number']?.toString() ?? 'N/A';
          final deliveryId = delivery['id'] as String;
          final orderId = salesOrder?['id'] as String? ?? '';
          final total = (salesOrder?['total'] as num?)?.toDouble() ?? 0;
          final items = salesOrder?['sales_order_items'] as List? ?? [];
          final driverName = driver?['full_name'] ?? 'Tài xế';
          final updatedAt = delivery['updated_at'] != null
              ? DateTime.parse(delivery['updated_at']).toLocal()
              : null;
          final address = salesOrder?['delivery_address'] ?? customer?['address'];

          return GestureDetector(
            onTap: () => _showOrderDetailSheet(delivery, isFromDeliveries: true),
            child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
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
                  // Header row: icon, order number, customer, badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delivery_dining, color: Colors.purple.shade600, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$orderNumber',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              customer?['name'] ?? salesOrder?['customer_name'] ?? 'Khách hàng',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_empty, size: 14, color: Colors.purple.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Tài xế đã nhận',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Address
                  if (address != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Order info: total, items, driver, time
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_outlined, size: 15, color: Colors.green.shade600),
                                const SizedBox(width: 5),
                                Text('Tổng tiền:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            Text(
                              currencyFmt.format(total),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 15, color: Colors.blue.shade600),
                                const SizedBox(width: 5),
                                Text('Sản phẩm:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            Text(
                              '${items.length} SP',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: 15, color: Colors.purple.shade600),
                                const SizedBox(width: 5),
                                Text('Tài xế:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            Text(
                              driverName,
                              style: TextStyle(color: Colors.purple.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (updatedAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 15, color: Colors.orange.shade600),
                                  const SizedBox(width: 5),
                                  Text('Nhận lúc:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                              Text(
                                timeFmt.format(updatedAt),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm handover button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _processingOrders.contains(deliveryId)
                          ? null
                          : () => _confirmHandoverToDriver(deliveryId, orderId),
                      icon: _processingOrders.contains(deliveryId)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 20),
                      label: Text(_processingOrders.contains(deliveryId)
                          ? 'Đang xử lý...'
                          : 'Xác nhận đã giao cho tài xế'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _processingOrders.contains(deliveryId)
                            ? Colors.grey
                            : Colors.green,
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
          );
        },
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final picked = await showQuickDateRangePicker(context, current: _handedOverDateFilter);
          if (picked != null) {
            if (picked.start.year == 1970) {
              setState(() => _handedOverDateFilter = null);
            } else {
              setState(() => _handedOverDateFilter = picked);
            }
            _loadHandedOverOrders();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _handedOverDateFilter != null ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _handedOverDateFilter != null ? Colors.green.shade400 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16,
                color: _handedOverDateFilter != null ? Colors.green.shade700 : Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _handedOverDateFilter != null
                      ? getDateRangeLabel(_handedOverDateFilter!)
                      : 'Hôm nay (mặc định)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _handedOverDateFilter != null ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_handedOverDateFilter != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _handedOverDateFilter = null);
                    _loadHandedOverOrders();
                  },
                  child: Icon(Icons.close, size: 16, color: Colors.green.shade700),
                )
              else
                Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandedOverList() {
    return Column(
      children: [
        _buildDateFilterBar(),
        Expanded(
          child: _handedOverOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fact_check_outlined, size: 48, color: Colors.green.shade300),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _handedOverDateFilter != null
                            ? 'Không có đơn bàn giao trong khoảng thời gian này'
                            : 'Chưa có đơn bàn giao hôm nay',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sử dụng bộ lọc ngày để xem\nlịch sử bàn giao tài xế',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : _buildHandedOverContent(),
        ),
      ],
    );
  }

  Widget _buildHandedOverContent() {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final timeFmt = DateFormat('HH:mm dd/MM');

    // Calculate summary
    double totalAmount = 0;
    int totalOrders = _handedOverOrders.length;
    int completedCount = 0;
    int inProgressCount = 0;
    for (var d in _handedOverOrders) {
      final so = d['sales_orders'] as Map<String, dynamic>?;
      totalAmount += (so?['total'] as num?)?.toDouble() ?? 0;
      if (d['status'] == 'completed') completedCount++;
      if (d['status'] == 'in_progress') inProgressCount++;
    }

    return RefreshIndicator(
      onRefresh: _loadAllOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fact_check, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Đối soát hôm nay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem('Tổng đơn', '$totalOrders', Icons.receipt_long),
                    ),
                    Expanded(
                      child: _buildSummaryItem('Đang giao', '$inProgressCount', Icons.local_shipping),
                    ),
                    Expanded(
                      child: _buildSummaryItem('Đã giao', '$completedCount', Icons.check_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng giá trị:', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text(
                        currencyFmt.format(totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Order list
          ...List.generate(_handedOverOrders.length, (index) {
            final delivery = _handedOverOrders[index];
            final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
            final customer = salesOrder?['customers'] as Map<String, dynamic>?;
            final driver = delivery['employees'] as Map<String, dynamic>?;
            final orderNumber = salesOrder?['order_number']?.toString() ?? 'N/A';
            final total = (salesOrder?['total'] as num?)?.toDouble() ?? 0;
            final items = salesOrder?['sales_order_items'] as List? ?? [];
            final driverName = driver?['full_name'] ?? 'Tài xế';
            final status = delivery['status'] as String? ?? '';
            final updatedAt = delivery['updated_at'] != null
                ? DateTime.parse(delivery['updated_at']).toLocal()
                : null;
            final address = salesOrder?['delivery_address'] ?? customer?['address'];
            final paymentStatus = salesOrder?['payment_status'] ?? '';
            final deliveryStatus = salesOrder?['delivery_status'] ?? '';

            final isCompleted = status == 'completed';
            final isDelivered = deliveryStatus == 'delivered';

            Color statusColor = isCompleted ? Colors.green : Colors.blue;
            String statusText = isCompleted 
                ? (isDelivered ? 'Đã giao xong' : 'Đang giao') 
                : 'Đang giao';
            IconData statusIcon = isCompleted 
                ? (isDelivered ? Icons.check_circle : Icons.local_shipping) 
                : Icons.local_shipping;

            return GestureDetector(
              onTap: () => _showOrderDetailSheet(delivery, isFromDeliveries: true),
              child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                  width: 1,
                ),
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
                        Text(
                          '#$orderNumber',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (paymentStatus == 'paid') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments, size: 12, color: Colors.green.shade600),
                                const SizedBox(width: 3),
                                Text(
                                  'Đã thu',
                                  style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          currencyFmt.format(total),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Customer & driver info
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer?['name'] ?? salesOrder?['customer_name'] ?? 'Khách hàng',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.delivery_dining, size: 14, color: Colors.purple.shade400),
                        const SizedBox(width: 4),
                        Text(
                          driverName,
                          style: TextStyle(color: Colors.purple.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    if (address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Items & time
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${items.length} SP',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const Spacer(),
                        if (updatedAt != null) ...[
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            timeFmt.format(updatedAt),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showOrderDetailSheet(Map<String, dynamic> data, {bool isFromDeliveries = false}) {
    final salesOrder = isFromDeliveries
        ? (data['sales_orders'] as Map<String, dynamic>? ?? {})
        : data;
    final customer = salesOrder['customers'] as Map<String, dynamic>? ?? {};
    final items = salesOrder['sales_order_items'] as List? ?? [];
    final orderNumber = salesOrder['order_number']?.toString() ?? 'N/A';
    final total = (salesOrder['total'] as num?)?.toDouble() ?? 0;
    final paymentStatus = salesOrder['payment_status'] ?? '';
    final paymentMethod = salesOrder['payment_method'] ?? '';
    final address = salesOrder['delivery_address'] ?? customer['address'] ?? '';
    final phone = customer['phone']?.toString() ?? '';
    final customerName = customer['name'] ?? salesOrder['customer_name'] ?? 'Khách hàng';
    final driver = isFromDeliveries ? (data['employees'] as Map<String, dynamic>?) : null;
    final driverName = driver?['full_name'] ?? '';

    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: order number + total
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long, color: Colors.blue.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đơn hàng #$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(currencyFmt.format(total), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Customer info
              _buildDetailSection('Khách hàng', Icons.person, Colors.blue, [
                _buildDetailRow('Tên', customerName),
                if (phone.isNotEmpty)
                  _buildDetailRowTappable('Điện thoại', phone, Icons.phone, () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  }),
                if (address.isNotEmpty)
                  _buildDetailRowTappable('Địa chỉ', address, Icons.map, () async {
                    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  }),
              ]),

              // Driver info (only for delivery tabs)
              if (isFromDeliveries && driverName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailSection('Tài xế', Icons.delivery_dining, Colors.purple, [
                  _buildDetailRow('Tên', driverName),
                  if (driver?['phone'] != null)
                    _buildDetailRowTappable('Điện thoại', driver!['phone'].toString(), Icons.phone, () async {
                      final uri = Uri.parse('tel:${driver['phone']}');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    }),
                ]),
              ],

              // Payment
              const SizedBox(height: 12),
              _buildDetailSection('Thanh toán', Icons.payments, Colors.green, [
                _buildDetailRow('Trạng thái', paymentStatus == 'paid' ? 'Đã thanh toán' : (paymentStatus == 'pending' ? 'Chưa thanh toán' : paymentStatus)),
                if (paymentMethod.isNotEmpty)
                  _buildDetailRow('Phương thức', paymentMethod == 'cash' ? 'Tiền mặt' : (paymentMethod == 'transfer' ? 'Chuyển khoản' : paymentMethod)),
              ]),

              // Items
              const SizedBox(height: 12),
              _buildDetailSection('Sản phẩm (${items.length})', Icons.shopping_bag, Colors.orange, [
                ...items.map((item) {
                  final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                  final price = (item['unit_price'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0;
                  final lineTotal = qty * price;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['product_name'] ?? 'Sản phẩm',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '$qty x ${currencyFmt.format(price)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyFmt.format(lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
              ]),

              // Total summary
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(currencyFmt.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade700)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDetailRowTappable(String label, String value, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blue.shade600))),
                  const SizedBox(width: 4),
                  Icon(icon, size: 14, color: Colors.blue.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
