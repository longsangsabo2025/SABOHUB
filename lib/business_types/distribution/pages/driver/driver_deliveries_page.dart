import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import 'driver_providers.dart';

/// Driver Deliveries Page - Quản lý đơn hàng theo 4 tab
/// - Chờ nhận (pending from sales_orders)
/// - Chờ kho (loading status in deliveries)
/// - Đang giao (in_progress)
/// - Đã giao (completed)
class DriverDeliveriesPage extends ConsumerStatefulWidget {
  const DriverDeliveriesPage({super.key});

  @override
  ConsumerState<DriverDeliveriesPage> createState() => _DriverDeliveriesPageState();
}

class _DriverDeliveriesPageState extends ConsumerState<DriverDeliveriesPage>
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
  DateTimeRange? _deliveredDateFilter;

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

  @override
  Widget build(BuildContext context) {
    // Watch for route optimization changes and refresh data
    ref.listen<int>(routeOptimizedProvider, (previous, next) {
      if (previous != next) {
        AppLogger.info('Route optimized, refreshing deliveries list...');
        _loadDeliveries();
      }
    });

    return _buildContent();
  }

  Future<void> _loadDeliveries() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final driverId = authState.user?.id;

      if (companyId == null || driverId == null) return;

      final supabase = Supabase.instance.client;

      // ===== TAB 1: CHỜ NHẬN - Query từ sales_orders (awaiting_pickup) =====
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
      // Sort by route_order first (if optimized), then by updated_at
      var awaitingQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              delivery_address, customer_address,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'loading');

      final awaiting = await awaitingQuery.order('route_order', ascending: true, nullsFirst: false).order('updated_at', ascending: false).limit(100);

      // ===== TAB 3: ĐANG GIAO - Query từ deliveries (in_progress) =====
      // Sort by route_order first (if optimized), then by updated_at
      var inProgressQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              delivery_address, customer_address,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'in_progress');

      final inProgress = await inProgressQuery.order('route_order', ascending: true, nullsFirst: false).order('updated_at', ascending: false).limit(100);

      // ===== TAB 4: ĐÃ GIAO - Query từ deliveries (completed) =====
      var deliveredQuery = supabase
          .from('deliveries')
          .select('''
            *,
            sales_orders:order_id(
              id, order_number, total, customer_name, payment_status, payment_method,
              delivery_address, customer_address,
              customers(name, phone, address, lat, lng),
              sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
            )
          ''')
          .eq('company_id', companyId)
          .eq('driver_id', driverId)
          .eq('status', 'completed');

      if (_deliveredDateFilter != null) {
        deliveredQuery = deliveredQuery
            .gte('updated_at', _deliveredDateFilter!.start.toIso8601String())
            .lte('updated_at', _deliveredDateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      }

      final delivered = await deliveredQuery.order('updated_at', ascending: false).limit(200);

      setState(() {
        _pendingDeliveries = pendingList;
        _awaitingDeliveries = List<Map<String, dynamic>>.from(awaiting);
        _inProgressDeliveries = List<Map<String, dynamic>>.from(inProgress);
        _deliveredDeliveries = List<Map<String, dynamic>>.from(delivered);
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

  Widget _buildContent() {
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
                        _buildTab(Icons.pending_actions, 'Chờ nhận', _pendingDeliveries.length, Colors.orange),
                        _buildTab(Icons.hourglass_empty, 'Chờ kho', _awaitingDeliveries.length, Colors.purple),
                        _buildTab(Icons.local_shipping, 'Đang giao', _inProgressDeliveries.length, Colors.blue),
                        _buildTab(Icons.check_circle, 'Đã giao', _deliveredDeliveries.length, Colors.green),
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

  Widget _buildTab(IconData icon, String label, int count, Color color) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // LIST BUILDERS
  // ============================================================================

  Widget _buildDeliveredDateFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final picked = await showQuickDateRangePicker(context, current: _deliveredDateFilter);
          if (picked != null) {
            if (picked.start.year == 1970) {
              setState(() => _deliveredDateFilter = null);
            } else {
              setState(() => _deliveredDateFilter = picked);
            }
            _loadDeliveries();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _deliveredDateFilter != null ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _deliveredDateFilter != null ? Colors.green.shade400 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16,
                color: _deliveredDateFilter != null ? Colors.green.shade700 : Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _deliveredDateFilter != null
                      ? getDateRangeLabel(_deliveredDateFilter!)
                      : 'Tất cả thời gian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _deliveredDateFilter != null ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_deliveredDateFilter != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _deliveredDateFilter = null);
                    _loadDeliveries();
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

  Widget _buildDeliveredList(List<Map<String, dynamic>> deliveries) {
    return Column(
      children: [
        _buildDeliveredDateFilter(),
        Expanded(
          child: deliveries.isEmpty
              ? _buildEmptyState(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: _deliveredDateFilter != null
                      ? 'Không có đơn đã giao trong khoảng thời gian này'
                      : 'Chưa có đơn đã giao',
                  subtitle: _deliveredDateFilter != null
                      ? 'Thử chọn khoảng thời gian khác'
                      : 'Các đơn bạn đã giao thành công\nsẽ hiển thị ở đây',
                )
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = deliveries[index];
                      return _buildDeliveredCard(delivery);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAwaitingList(List<Map<String, dynamic>> deliveries) {
    if (deliveries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        color: Colors.purple,
        title: 'Không có đơn chờ xác nhận',
        subtitle: 'Các đơn bạn đã nhận sẽ hiển thị ở đây\nkhi chờ kho xác nhận giao hàng',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildAwaitingCard(delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryList(List<Map<String, dynamic>> deliveries, {required bool isPending}) {
    if (deliveries.isEmpty) {
      return _buildEmptyState(
        icon: isPending ? Icons.inbox_outlined : Icons.local_shipping_outlined,
        color: Colors.grey,
        title: isPending ? 'Không có đơn chờ nhận' : 'Không có đơn đang giao',
        subtitle: 'Kéo xuống để làm mới',
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

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CARD BUILDERS
  // ============================================================================

  Widget _buildDeliveredCard(Map<String, dynamic> delivery) {
    final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    
    final orderNumber = salesOrder?['order_number'] ?? delivery['order_number'] ?? 'N/A';
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Không có tên';
    final customerAddress = salesOrder?['delivery_address'] ?? salesOrder?['customer_address'] ?? delivery['delivery_address'] ?? customer?['address'] ?? '';
    final totalAmount = (salesOrder?['total'] ?? delivery['total_amount'] ?? 0).toDouble();
    final updatedAt = delivery['updated_at'] != null 
        ? DateTime.parse(delivery['updated_at']).toLocal() 
        : DateTime.now();
    final paymentStatus = salesOrder?['payment_status'] ?? delivery['payment_status'] ?? 'pending';
    final paymentMethod = salesOrder?['payment_method'] ?? delivery['payment_method'] ?? '';

    String getPaymentMethodText() {
      if (paymentStatus != 'paid') return 'Chưa thu';
      switch (paymentMethod) {
        case 'cash': return 'Thu tiền mặt';
        case 'transfer': return 'Chuyển khoản';
        case 'debt': return 'Ghi công nợ';
        default: return 'Đã thu tiền';
      }
    }

    IconData getPaymentIcon() {
      if (paymentStatus != 'paid') return Icons.pending;
      switch (paymentMethod) {
        case 'cash': return Icons.payments;
        case 'transfer': return Icons.qr_code;
        case 'debt': return Icons.receipt_long;
        default: return Icons.check_circle;
      }
    }

    return GestureDetector(
      onTap: () => _showOrderDetailSheet(delivery),
      child: Container(
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
    ),
    );
  }

  Widget _buildAwaitingCard(Map<String, dynamic> delivery) {
    final salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
    final customer = salesOrder?['customers'] as Map<String, dynamic>?;
    final orderNumber = salesOrder?['order_number'] ?? delivery['delivery_number'] ?? 'N/A';
    final total = (salesOrder?['total'] ?? delivery['total_amount'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _showOrderDetailSheet(delivery),
      child: Card(
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Customer info
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
                    salesOrder?['delivery_address'] ?? salesOrder?['customer_address'] ?? delivery['delivery_address'] ?? customer?['address'] ?? 'Chưa có địa chỉ',
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
    ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, {required bool isPending}) {
    final isFromSalesOrders = delivery['_source'] == 'sales_orders';
    
    final Map<String, dynamic>? salesOrder;
    final Map<String, dynamic>? customer;
    
    if (isFromSalesOrders) {
      salesOrder = delivery;
      customer = delivery['customers'] as Map<String, dynamic>?;
    } else {
      salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
      customer = salesOrder?['customers'] as Map<String, dynamic>?;
    }
    
    final orderNumber = salesOrder?['order_number']?.toString() ?? 
                        delivery['delivery_number']?.toString() ?? 
                        delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (salesOrder?['total'] as num?)?.toDouble() ?? 
                  (salesOrder?['total_amount'] as num?)?.toDouble() ?? 0;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = salesOrder?['delivery_address'] ?? salesOrder?['customer_address'] ?? delivery['delivery_address'] ?? customer?['address'];
    final customerPhone = customer?['phone'];

    return GestureDetector(
      onTap: () => _showOrderDetailSheet(delivery, isFromSalesOrders: isFromSalesOrders),
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
                        if (isFromSalesOrders) {
                          final orderId = delivery['id'] as String;
                          _acceptOrder(orderId, delivery);
                        } else {
                          final deliveryId = delivery['id'] as String;
                          final orderId = delivery['order_id'] as String? ?? 
                                         (delivery['sales_orders'] as Map<String, dynamic>?)?['id'] as String?;
                          if (orderId == null || orderId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lỗi: Đơn hàng không tồn tại hoặc đã bị xóa'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _pickupDelivery(deliveryId, orderId);
                        }
                      } else {
                        final deliveryId = delivery['id'] as String;
                        final orderId = delivery['order_id'] as String? ?? 
                                       (delivery['sales_orders'] as Map<String, dynamic>?)?['id'] as String?;
                        if (orderId == null || orderId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lỗi: Đơn hàng không tồn tại hoặc đã bị xóa'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
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
    ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> orderData) async {
    // Validate orderId
    if (orderId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Mã đơn hàng không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final driverId = authState.user?.id;
      final companyId = authState.user?.companyId;
      
      if (driverId == null || companyId == null) {
        throw Exception('Chưa đăng nhập hoặc thiếu thông tin công ty');
      }

      final now = DateTime.now().toIso8601String();
      await supabase.from('deliveries').insert({
        'company_id': companyId,
        'order_id': orderId,
        'driver_id': driverId,
        'delivery_number': 'DL-${DateTime.now().millisecondsSinceEpoch}',
        'delivery_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'loading',
        'updated_at': now,
      }).select().single();

      // Update sales_orders delivery_status so warehouse can track
      await supabase.from('sales_orders').update({
        'delivery_status': 'awaiting_pickup',
        'updated_at': now,
      }).eq('id', orderId);

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

      // Use RPC for transaction-safe update
      final result = await supabase.rpc('start_delivery', params: {
        'p_delivery_id': deliveryId,
        'p_order_id': orderId,
      });
      
      if (result != null && result['success'] == false) {
        throw Exception(result['error'] ?? 'Unknown error');
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
    AppLogger.info('🚛 _completeDelivery called with deliveryId: "$deliveryId", orderId: "$orderId"');
    
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
      
      final orderResponse = await supabase
          .from('sales_orders')
          .select('payment_method, payment_status, total, customer_id, customers(name, total_debt)')
          .eq('id', orderId)
          .single();

      final paymentMethod = orderResponse['payment_method']?.toString().toLowerCase() ?? 'cod';
      final paymentStatus = orderResponse['payment_status']?.toString().toLowerCase() ?? 'unpaid';
      final total = (orderResponse['total'] ?? 0).toDouble();
      final customerId = orderResponse['customer_id']?.toString();
      final customerData = orderResponse['customers'] as Map<String, dynamic>?;
      final customerName = customerData?['name'] ?? 'Khách hàng';
      final currentDebt = (customerData?['total_debt'] ?? 0).toDouble();

      final result = await _showPaymentMethodDialog(
        deliveryId: deliveryId,
        orderId: orderId,
        customerName: customerName,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        totalAmount: total,
      );

      if (result == null) return;

      AppLogger.info('🔄 Completing delivery with RPC: $result');

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

      // Handle debt update separately (customer balance)
      if (result['updatePayment'] == true && result['paymentMethod'] == 'debt' && customerId != null) {
        final newDebt = currentDebt + total;
        await supabase.from('customers').update({
          'total_debt': newDebt,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', customerId);
        AppLogger.info('📝 Updated customer debt: $currentDebt -> $newDebt');
      }
      
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

  Future<Map<String, dynamic>?> _showPaymentMethodDialog({
    required String deliveryId,
    required String orderId,
    required String customerName,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
  }) async {
    String? selectedOption;
    
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
                  
                  RadioListTile<String?>(  
                    value: 'cash',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v),
                    title: const Text('💵 Thu tiền mặt'),
                    subtitle: Text(currencyFormat.format(totalAmount), style: const TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  RadioListTile<String?>(  
                    value: 'transfer',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v),
                    title: const Text('🏦 Chuyển khoản'),
                    subtitle: const Text('Hiện QR cho khách quét', style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  if (selectedOption == 'transfer')
                    Container(
                      margin: const EdgeInsets.only(left: 16, bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showQRTransferDialog(totalAmount, orderId, deliveryId);
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
                  
                  RadioListTile<String?>(  
                    value: 'debt',
                    groupValue: selectedOption,
                    onChanged: (v) => setState(() => selectedOption = v),
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
              onPressed: selectedOption == null ? null : () {
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
                    // Chuyển khoản: cần kế toán xác nhận
                    result = {
                      'updatePayment': true,
                      'paymentStatus': 'pending_transfer',
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

  Future<void> _showQRTransferDialog(double amount, String orderId, String deliveryId) async {
    debugPrint('🔷 _showQRTransferDialog called with amount: $amount, orderId: $orderId, deliveryId: $deliveryId');
    try {
      // Lấy companyId từ authProvider (không dùng supabase.auth.currentUser)
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      debugPrint('🔷 AuthState user: ${authState.user?.name} - companyId: $companyId');
      
      if (companyId == null) {
        debugPrint('❌ CompanyId is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin công ty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final supabase = Supabase.instance.client;
      final companyData = await supabase
          .from('companies')
          .select('bank_name, bank_account_number, bank_account_name, bank_bin')
          .eq('id', companyId)
          .maybeSingle();
      
      debugPrint('🔷 Company data: $companyData');
      
      if (companyData == null || 
          companyData['bank_bin'] == null || 
          companyData['bank_account_number'] == null) {
        debugPrint('❌ Company bank info incomplete');
        if (mounted) {
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
      
      final amountInt = amount.toInt();
      final content = 'TT $orderId';
      final qrUrl = 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png?amount=$amountInt&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}';
      
      debugPrint('✅ QR URL: $qrUrl');
      debugPrint('🔷 mounted: $mounted');
      
      if (mounted) {
        debugPrint('🔷 Showing QR dialog...');
        final confirmed = await showDialog<bool>(
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
                onPressed: () => Navigator.pop(ctx, false),
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
        );

        // Nếu user xác nhận đã chuyển khoản, update database
        if (confirmed == true) {
          debugPrint('✅ User confirmed transfer, updating database...');
          
          // Use RPC for transaction-safe update
          final result = await supabase.rpc('complete_delivery_transfer', params: {
            'p_delivery_id': deliveryId,
            'p_order_id': orderId,
          });
          if (result != null && result['success'] == false) {
            throw Exception(result['error'] ?? 'Unknown error');
          }

          debugPrint('✅ Database updated successfully!');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('🎉 Giao hàng và thanh toán thành công!')),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            _loadDeliveries();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in QR dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) return;

    String cleanAddress = address;
    if (address.contains('--')) {
      cleanAddress = address.split('--').first.trim();
    }

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

  // ============================================================================
  // ORDER DETAIL BOTTOM SHEET
  // ============================================================================

  void _showOrderDetailSheet(Map<String, dynamic> delivery, {bool isFromSalesOrders = false}) {
    final Map<String, dynamic>? salesOrder;
    final Map<String, dynamic>? customer;

    if (isFromSalesOrders) {
      salesOrder = delivery;
      customer = delivery['customers'] as Map<String, dynamic>?;
    } else {
      salesOrder = delivery['sales_orders'] as Map<String, dynamic>?;
      customer = salesOrder?['customers'] as Map<String, dynamic>?;
    }

    final orderNumber = salesOrder?['order_number']?.toString() ?? 'N/A';
    final total = (salesOrder?['total'] as num?)?.toDouble() ?? 0;
    final customerName = salesOrder?['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerPhone = customer?['phone'] as String?;
    final customerAddress = salesOrder?['delivery_address'] ?? salesOrder?['customer_address'] ?? delivery['delivery_address'] ?? customer?['address'] ?? '';
    final paymentStatus = salesOrder?['payment_status'] ?? 'pending';
    final paymentMethod = salesOrder?['payment_method'] ?? '';
    final items = (isFromSalesOrders
        ? delivery['sales_order_items']
        : salesOrder?['sales_order_items']) as List<dynamic>? ?? [];

    String paymentLabel;
    Color paymentColor;
    IconData paymentIcon;
    switch (paymentStatus) {
      case 'paid':
        paymentLabel = 'Đã thanh toán';
        paymentColor = Colors.green;
        paymentIcon = Icons.check_circle;
        break;
      case 'partial':
        paymentLabel = 'Thanh toán một phần';
        paymentColor = Colors.orange;
        paymentIcon = Icons.timelapse;
        break;
      case 'debt':
        paymentLabel = 'Công nợ';
        paymentColor = Colors.red;
        paymentIcon = Icons.receipt_long;
        break;
      default:
        paymentLabel = 'Chưa thanh toán';
        paymentColor = Colors.grey;
        paymentIcon = Icons.pending;
    }

    String methodLabel = '';
    if (paymentMethod == 'cash') methodLabel = 'Tiền mặt';
    if (paymentMethod == 'transfer') methodLabel = 'Chuyển khoản';
    if (paymentMethod == 'debt') methodLabel = 'Công nợ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '#$orderNumber',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currencyFormat.format(total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Customer section
                    _buildDetailSection('Khách hàng', [
                      _buildDetailRow(Icons.person, customerName),
                      if (customerPhone != null && customerPhone.isNotEmpty)
                        _buildDetailRowTappable(
                          Icons.phone,
                          customerPhone,
                          Colors.green,
                          () => _callCustomer(customerPhone),
                        ),
                      if (customerAddress.isNotEmpty)
                        _buildDetailRowTappable(
                          Icons.location_on,
                          customerAddress,
                          Colors.blue,
                          () => _openMaps(customerAddress),
                        ),
                    ]),

                    const SizedBox(height: 16),

                    // Payment section
                    _buildDetailSection('Thanh toán', [
                      Row(
                        children: [
                          Icon(paymentIcon, size: 18, color: paymentColor),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: paymentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              paymentLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: paymentColor,
                              ),
                            ),
                          ),
                          if (methodLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '($methodLabel)',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Items section
                    _buildDetailSection(
                      'Sản phẩm (${items.length})',
                      items.isEmpty
                          ? [
                              Text(
                                'Không có thông tin sản phẩm',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ]
                          : items.map<Widget>((item) {
                              final itemMap = item as Map<String, dynamic>;
                              final name = itemMap['product_name'] ?? 'Sản phẩm';
                              final qty = itemMap['quantity'] ?? 0;
                              final unit = itemMap['unit'] ?? '';
                              final unitPrice = (itemMap['unit_price'] as num?)?.toDouble() ?? 0;
                              final lineTotal = (itemMap['line_total'] as num?)?.toDouble() ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$qty $unit  ×  ${currencyFormat.format(unitPrice)}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          currencyFormat.format(lineTotal),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Total row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currencyFormat.format(total),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
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
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowTappable(IconData icon, String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, color: color, decoration: TextDecoration.underline),
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
