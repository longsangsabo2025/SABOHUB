import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import '../../../../widgets/customer_avatar.dart';
import 'sheets/sales_create_order_form.dart';

/// Sales Orders Page - với tabs theo trạng thái
class SalesOrdersPage extends ConsumerStatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  ConsumerState<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends ConsumerState<SalesOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateFilter;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.receipt_long, color: Colors.teal.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date filter
                  GestureDetector(
                    onTap: () async {
                      final picked = await showQuickDateRangePicker(context, current: _dateFilter);
                      if (picked != null) {
                        setState(() {
                          _dateFilter = picked.start.year == 1970 ? null : picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _dateFilter != null ? Colors.teal.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: _dateFilter != null ? Border.all(color: Colors.teal.shade300) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16,
                              color: _dateFilter != null ? Colors.teal.shade700 : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _dateFilter != null ? getDateRangeLabel(_dateFilter!) : 'Lọc theo ngày',
                            style: TextStyle(
                              fontSize: 13,
                              color: _dateFilter != null ? Colors.teal.shade700 : Colors.grey.shade600,
                              fontWeight: _dateFilter != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (_dateFilter != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _dateFilter = null),
                              child: Icon(Icons.close, size: 16, color: Colors.teal.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.teal.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.teal,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Tất cả'),
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Đã duyệt'),
                      Tab(text: 'Đang giao'),
                      Tab(text: 'Hoàn thành'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SalesOrderList(statusFilter: null, dateFilter: _dateFilter),
                  SalesOrderList(statusFilter: 'pending_approval', dateFilter: _dateFilter),
                  SalesOrderList(statusFilter: 'confirmed', dateFilter: _dateFilter),
                  SalesOrderList(statusFilter: 'processing', dateFilter: _dateFilter),
                  SalesOrderList(statusFilter: 'completed', dateFilter: _dateFilter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable order list widget with status filter
class SalesOrderList extends ConsumerStatefulWidget {
  final String? statusFilter;
  final DateTimeRange? dateFilter;
  const SalesOrderList({super.key, this.statusFilter, this.dateFilter});

  @override
  ConsumerState<SalesOrderList> createState() => _SalesOrderListState();
}

class _SalesOrderListState extends ConsumerState<SalesOrderList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant SalesOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateFilter != widget.dateFilter) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var queryBuilder = supabase
          .from('sales_orders')
          .select('*, customers(name, phone, address)')
          .eq('company_id', companyId)
          .eq('sale_id', userId ?? '');

      if (widget.statusFilter != null) {
        queryBuilder = queryBuilder.eq('status', widget.statusFilter!);
      }

      if (widget.dateFilter != null) {
        queryBuilder = queryBuilder
            .gte('created_at', widget.dateFilter!.start.toIso8601String())
            .lte('created_at', widget.dateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      }

      final data = await queryBuilder.order('created_at', ascending: false).limit(50);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load orders', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              widget.statusFilter == null ? 'Tạo đơn hàng đầu tiên!' : 'Không có đơn ở trạng thái này',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final status = order['status'] ?? 'draft';
    final deliveryStatus = order['delivery_status'] ?? 'pending';
    final total = (order['total'] ?? 0).toDouble();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

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

    // Delivery status
    String deliveryText = '';
    IconData deliveryIcon = Icons.local_shipping_outlined;
    Color deliveryColor = Colors.grey;
    switch (deliveryStatus) {
      case 'pending':
        deliveryText = 'Chưa giao';
        deliveryIcon = Icons.schedule;
        deliveryColor = Colors.grey;
        break;
      case 'awaiting_pickup':
        deliveryText = 'Chờ lấy hàng';
        deliveryIcon = Icons.inventory;
        deliveryColor = Colors.orange;
        break;
      case 'delivering':
        deliveryText = 'Đang giao';
        deliveryIcon = Icons.local_shipping;
        deliveryColor = Colors.blue;
        break;
      case 'delivered':
        deliveryText = 'Đã giao';
        deliveryIcon = Icons.check_circle;
        deliveryColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number & status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(order['order_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            
            // Date
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
            
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            
            // Customer info
            Row(
              children: [
                CustomerAvatar(
                  seed: customer?['name'] ?? 'K',
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer?['name'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (customer?['phone'] != null)
                        Text(customer!['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Delivery status & Total
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deliveryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deliveryIcon, size: 14, color: deliveryColor),
                      const SizedBox(width: 4),
                      Text(deliveryText, style: TextStyle(fontSize: 11, color: deliveryColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(currencyFormat.format(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
            
            // Edit button for draft/pending orders
            if (status == 'draft' || status == 'pending' || status == 'pending_approval') ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editOrder(order),
                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade700),
                    label: Text('Sửa đơn', style: TextStyle(color: Colors.blue.shade700)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _editOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesCreateOrderFormPage(
          existingOrder: order,
          preselectedCustomer: order['customers'],
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadOrders();
      }
    });
  }
}
