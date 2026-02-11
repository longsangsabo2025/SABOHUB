import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/auth_provider.dart';
import '../../models/odori_sales_order.dart';
import '../../../../pages/orders/order_form_page.dart';

/// Orders Management Page
/// Trang quản lý đơn hàng với các tab theo trạng thái
class OrdersManagementPage extends ConsumerStatefulWidget {
  const OrdersManagementPage({super.key});

  @override
  ConsumerState<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends ConsumerState<OrdersManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.blue.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.blue.shade700,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Chờ duyệt'),
                    Tab(text: 'Đã duyệt'),
                    Tab(text: 'Đang giao'),
                    Tab(text: 'Hoàn thành'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Đã làm mới danh sách đơn hàng'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              OrderListByStatus(status: 'pending_approval'),
              OrderListByStatus(statusList: ['confirmed', 'processing', 'ready']),
              OrderListByStatus(
                status: 'completed',
                deliveryStatusNotIn: ['delivered'],
              ),
              OrderListByStatus(
                status: 'completed',
                deliveryStatus: 'delivered',
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// Order List By Status
/// Danh sách đơn hàng theo trạng thái cụ thể
class OrderListByStatus extends ConsumerStatefulWidget {
  final String? status;
  final List<String>? statusList;
  final String? deliveryStatus;
  final List<String>? deliveryStatusNotIn;
  const OrderListByStatus({
    super.key,
    this.status,
    this.statusList,
    this.deliveryStatus,
    this.deliveryStatusNotIn,
  });

  @override
  ConsumerState<OrderListByStatus> createState() => _OrderListByStatusState();
}

class _OrderListByStatusState extends ConsumerState<OrderListByStatus> {
  final List<OdoriSalesOrder> _allOrders = [];
  int _currentOffset = 0;
  static const int _pageSize = 30;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  // Stats
  int _totalOrders = 0;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStats();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.companyId == null) return;

      final supabase = Supabase.instance.client;
      var query = supabase
          .from('sales_orders')
          .select('id, total')
          .eq('company_id', user.companyId!);
      
      // Apply status filters
      if (widget.statusList != null) {
        query = query.inFilter('status', widget.statusList!);
      } else if (widget.status != null) {
        query = query.eq('status', widget.status!);
      }
      if (widget.deliveryStatus != null) {
        query = query.eq('delivery_status', widget.deliveryStatus!);
      }
      if (widget.deliveryStatusNotIn != null) {
        for (final ds in widget.deliveryStatusNotIn!) {
          query = query.neq('delivery_status', ds);
        }
      }
      
      final resp = await query;
      
      final orders = resp as List;
      _totalOrders = orders.length;
      _totalAmount = orders.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
      
      if (mounted) setState(() {});
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _allOrders.clear();
      _currentOffset = 0;
      _hasMore = true;
    });

    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.companyId == null) {
        setState(() {
          _errorMessage = 'Vui lòng đăng nhập lại';
          _isInitialLoading = false;
        });
        return;
      }

      final supabase = Supabase.instance.client;
      var query = supabase
          .from('sales_orders')
          .select('*, customers!inner(name, address, phone), sales_order_items(*, products(name, sku, image_url))')
          .eq('company_id', user.companyId!);
      
      // Apply status filters
      if (widget.statusList != null) {
        query = query.inFilter('status', widget.statusList!);
      } else if (widget.status != null) {
        query = query.eq('status', widget.status!);
      }
      if (widget.deliveryStatus != null) {
        query = query.eq('delivery_status', widget.deliveryStatus!);
      }
      if (widget.deliveryStatusNotIn != null) {
        for (final ds in widget.deliveryStatusNotIn!) {
          query = query.neq('delivery_status', ds);
        }
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('order_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(_currentOffset, _currentOffset + _pageSize - 1);

      final orders = (response as List).map((json) => OdoriSalesOrder.fromJson(json)).toList();

      setState(() {
        _allOrders.addAll(orders);
        _currentOffset += orders.length;
        _hasMore = orders.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.companyId == null) return;

      final supabase = Supabase.instance.client;
      var query = supabase
          .from('sales_orders')
          .select('*, customers!inner(name, address, phone), sales_order_items(*, products(name, sku, image_url))')
          .eq('company_id', user.companyId!);
      
      // Apply status filters
      if (widget.statusList != null) {
        query = query.inFilter('status', widget.statusList!);
      } else if (widget.status != null) {
        query = query.eq('status', widget.status!);
      }
      if (widget.deliveryStatus != null) {
        query = query.eq('delivery_status', widget.deliveryStatus!);
      }
      if (widget.deliveryStatusNotIn != null) {
        for (final ds in widget.deliveryStatusNotIn!) {
          query = query.neq('delivery_status', ds);
        }
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('order_number.ilike.%$_searchQuery%,customer_name.ilike.%$_searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(_currentOffset, _currentOffset + _pageSize - 1);

      final orders = (response as List).map((json) => OdoriSalesOrder.fromJson(json)).toList();

      setState(() {
        _allOrders.addAll(orders);
        _currentOffset += orders.length;
        _hasMore = orders.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadInitial();
  }

  Future<void> _approveOrder(OdoriSalesOrder order) async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final supabase = Supabase.instance.client;
      await supabase.from('sales_orders').update({
        'status': 'confirmed',
        'approved_by': user.id,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã duyệt đơn hàng ${order.orderNumber}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadStats();
        _loadInitial();
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

  Future<void> _rejectOrder(OdoriSalesOrder order, String reason) async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final supabase = Supabase.instance.client;
      await supabase.from('sales_orders').update({
        'status': 'cancelled',
        'rejected_by': user.id,
        'rejected_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối đơn hàng ${order.orderNumber}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadStats();
        _loadInitial();
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

  Future<void> _updateOrderStatus(OdoriSalesOrder order, String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'delivered') {
        updateData['delivery_date'] = DateTime.now().toIso8601String();
      }

      // When order is completed, also mark delivery_status as delivered
      if (newStatus == 'completed') {
        updateData['delivery_status'] = 'delivered';
      }

      await supabase.from('sales_orders').update(updateData).eq('id', order.id);
      
      // Create commission for referrer when order is completed
      if (newStatus == 'completed') {
        await _createCommissionIfApplicable(order);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadStats();
        _loadInitial();
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
  
  /// Create commission for referrer when order is completed
  Future<void> _createCommissionIfApplicable(OdoriSalesOrder order) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      // Get customer to check if they have a referrer
      final customerData = await supabase
          .from('customers')
          .select('id, referrer_id')
          .eq('id', order.customerId)
          .maybeSingle();
      
      if (customerData == null || customerData['referrer_id'] == null) {
        debugPrint('No referrer for this customer, skipping commission');
        return;
      }
      
      final referrerId = customerData['referrer_id'] as String;
      
      // Get referrer to check commission settings
      final referrerData = await supabase
          .from('referrers')
          .select('id, commission_rate, commission_type, status')
          .eq('id', referrerId)
          .maybeSingle();
      
      if (referrerData == null || referrerData['status'] != 'active') {
        debugPrint('Referrer not found or inactive');
        return;
      }
      
      final commissionRate = (referrerData['commission_rate'] ?? 0).toDouble();
      final commissionType = referrerData['commission_type'] as String? ?? 'all_orders';
      
      // Check if commission_type is 'first_order' - only apply to first completed order
      if (commissionType == 'first_order') {
        final existingCommissions = await supabase
            .from('commissions')
            .select('id')
            .eq('referrer_id', referrerId)
            .eq('customer_id', order.customerId)
            .limit(1);
        
        if ((existingCommissions as List).isNotEmpty) {
          debugPrint('Commission already exists for first_order type, skipping');
          return;
        }
      }
      
      // Check if commission already exists for this order
      final existingForOrder = await supabase
          .from('commissions')
          .select('id')
          .eq('order_id', order.id)
          .maybeSingle();
      
      if (existingForOrder != null) {
        debugPrint('Commission already exists for this order');
        return;
      }
      
      // Calculate commission amount
      final commissionAmount = order.total * (commissionRate / 100);
      
      // Create commission record
      await supabase.from('commissions').insert({
        'company_id': companyId,
        'referrer_id': referrerId,
        'customer_id': order.customerId,
        'order_id': order.id,
        'order_code': order.orderNumber,
        'order_amount': order.total,
        'commission_rate': commissionRate,
        'commission_amount': commissionAmount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Commission created: ${commissionAmount.toStringAsFixed(0)}đ for referrer $referrerId');
    } catch (e) {
      debugPrint('Error creating commission: $e');
      // Don't throw - commission creation failure shouldn't block order completion
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'pending_approval': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'processing': return Colors.blue;
      case 'ready': return Colors.purple;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Nháp';
      case 'pending_approval': return 'Chờ duyệt';
      case 'confirmed': return 'Đã duyệt';
      case 'processing': return 'Đang xử lý';
      case 'ready': return 'Sẵn sàng';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  IconData _getPaymentIcon(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid': return Icons.check_circle;
      case 'partial': return Icons.pie_chart;
      default: return Icons.access_time;
    }
  }

  Color _getPaymentColor(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getPaymentLabel(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid': return 'Đã TT';
      case 'partial': return 'TT một phần';
      default: return 'Chưa TT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Stats Cards
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Số đơn',
                      '$_totalOrders',
                      _getStatusColor(widget.status ?? widget.statusList?.first ?? 'pending'),
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildStatCard(
                      'Tổng giá trị',
                      currencyFormat.format(_totalAmount),
                      Colors.blue,
                      Icons.payments,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
            ),

            // Order count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Đang hiển thị ${_allOrders.length} đơn hàng',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (_hasMore) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey.shade600),
                  ],
                ],
              ),
            ),

            // Order list
            if (_isInitialLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadInitial,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_allOrders.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text('Không có đơn hàng', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(_getStatusLabel(widget.status ?? widget.statusList?.first ?? ''), style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadStats();
                    await _loadInitial();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _allOrders.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (BuildContext ctx, int index) {
                      if (index >= _allOrders.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final order = _allOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
              ),
          ],
        ),

        // FAB for creating new order
        if (widget.status == 'pending_approval')
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showCreateOrderSheet(context),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn'),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OdoriSalesOrder order) {
    final statusColor = _getStatusColor(order.status);
    final paymentColor = _getPaymentColor(order.paymentStatus);
    final timeAgo = _getTimeAgo(order.createdAt);

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetail(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order number + Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber.isNotEmpty ? order.orderNumber : '#${order.id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Customer info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.customerName ?? 'Khách lẻ',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if ((order.deliveryAddress ?? order.customerAddress) != null && (order.deliveryAddress ?? order.customerAddress)!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (order.deliveryAddress ?? order.customerAddress)!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                const SizedBox(height: 12),

                // Footer: Total + Payment + Actions
                Row(
                  children: [
                    // Total
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng tiền',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          Text(
                            currencyFormat.format(order.total),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: paymentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getPaymentIcon(order.paymentStatus), size: 14, color: paymentColor),
                          const SizedBox(width: 4),
                          Text(
                            _getPaymentLabel(order.paymentStatus),
                            style: TextStyle(
                              fontSize: 11,
                              color: paymentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Action buttons based on status
                    ..._buildActionButtons(order),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(OdoriSalesOrder order) {
    switch (widget.status) {
      case 'pending_approval':
        return [
          IconButton(
            onPressed: () => _showRejectDialog(order),
            icon: Icon(Icons.close, color: Colors.red.shade400),
            tooltip: 'Từ chối',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _approveOrder(order),
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Duyệt',
            style: IconButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ];
      case 'confirmed':
        return [
          ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, 'processing'),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('Giao hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ];
      case 'processing':
        return [
          ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, 'completed'),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showOrderDetail(OdoriSalesOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailSheet(
        order: order,
        currencyFormat: currencyFormat,
        onApprove: widget.status == 'pending_approval' ? () => _approveOrder(order) : null,
        onReject: widget.status == 'pending_approval' ? () => _showRejectDialog(order) : null,
        onUpdateStatus: (newStatus) => _updateOrderStatus(order, newStatus),
        onEdit: _canEdit(order.status) ? () => _editOrder(order) : null,
        onCancel: _canCancel(order.status) ? () => _showCancelDialog(order) : null,
        onDelete: _canDelete(order.status) ? () => _showDeleteConfirmation(order) : null,
      ),
    );
  }
  
  /// Check if order can be edited
  bool _canEdit(String status) {
    return status == 'draft' || status == 'pending_approval';
  }
  
  /// Check if order can be cancelled
  bool _canCancel(String status) {
    return status == 'confirmed' || status == 'processing';
  }
  
  /// Check if order can be deleted — manager can delete any order
  bool _canDelete(String status) {
    return true;
  }
  
  /// Navigate to edit order form
  void _editOrder(OdoriSalesOrder order) {
    Navigator.pop(context); // Close the detail sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormPage(orderToEdit: order),
      ),
    );
  }
  
  /// Show cancel order dialog
  void _showCancelDialog(OdoriSalesOrder order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Hủy đơn hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn hủy đơn hàng ${order.orderNumber}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do hủy',
                hintText: 'Nhập lý do hủy đơn...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder(order, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Cancel order
  Future<void> _cancelOrder(OdoriSalesOrder order, String reason) async {
    try {
      final authState = ref.read(authProvider);
      await Supabase.instance.client
          .from('sales_orders')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancelled_by': authState.user?.id,
            'cancellation_reason': reason.isNotEmpty ? reason : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order.id);
      
      if (mounted) {
        Navigator.pop(context); // Close detail sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã hủy đơn hàng ${order.orderNumber}'),
          backgroundColor: Colors.orange,
        ));
        _loadStats();
        _loadInitial(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi hủy đơn: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
  
  /// Show delete confirmation dialog
  void _showDeleteConfirmation(OdoriSalesOrder order) {
    final isCompleted = ['completed', 'confirmed', 'delivered'].contains(order.status);
    final isPaid = order.paymentStatus == 'paid';
    
    String warningText = 'Bạn có chắc muốn xóa đơn hàng ${order.orderNumber}?';
    if (isCompleted || isPaid) {
      warningText += '\n\n⚠️ Đơn hàng này';
      if (isCompleted) warningText += ' đã hoàn thành';
      if (isPaid) warningText += '${isCompleted ? ' và' : ''} đã thanh toán';
      warningText += '. Xóa sẽ ảnh hưởng dữ liệu báo cáo.';
    }
    warningText += '\n\nHành động này không thể hoàn tác!';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Xóa đơn hàng'),
          ],
        ),
        content: Text(warningText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Delete order permanently (including all related records)
  Future<void> _deleteOrder(OdoriSalesOrder order) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Delete all related records first (foreign key dependencies)
      await supabase.from('delivery_items').delete().eq('order_id', order.id);
      await supabase.from('deliveries').delete().eq('order_id', order.id);
      await supabase.from('sell_in_transactions').delete().eq('sales_order_id', order.id);
      await supabase.from('product_samples').delete().eq('order_id', order.id);
      await supabase.from('sales_order_history').delete().eq('order_id', order.id);
      await supabase.from('sales_order_items').delete().eq('order_id', order.id);
      
      // Delete the order itself
      await supabase.from('sales_orders').delete().eq('id', order.id);
      
      if (mounted) {
        Navigator.pop(context); // Close detail sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xóa đơn hàng ${order.orderNumber}'),
          backgroundColor: Colors.teal,
        ));
        _loadStats();
        _loadInitial(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi xóa đơn: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showRejectDialog(OdoriSalesOrder order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn từ chối đơn hàng ${order.orderNumber}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do từ chối',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectOrder(order, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showCreateOrderSheet(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderFormPage()),
    );
    
    // Refresh orders list if order was created
    if (result == true && mounted) {
      setState(() {});
    }
  }
}


/// Order Detail Sheet
/// Sheet hiển thị chi tiết đơn hàng
class OrderDetailSheet extends StatelessWidget {
  final OdoriSalesOrder order;
  final NumberFormat currencyFormat;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final Function(String)? onUpdateStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const OrderDetailSheet({
    super.key,
    required this.order,
    required this.currencyFormat,
    this.onApprove,
    this.onReject,
    this.onUpdateStatus,
    this.onEdit,
    this.onCancel,
    this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'pending_approval': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'processing': return Colors.blue;
      case 'ready': return Colors.purple;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Nháp';
      case 'pending_approval': return 'Chờ duyệt';
      case 'confirmed': return 'Đã duyệt';
      case 'processing': return 'Đang xử lý';
      case 'ready': return 'Sẵn sàng';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  Color _getPaymentColor(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getPaymentLabel(String? paymentStatus, double paidAmount, double total) {
    switch (paymentStatus) {
      case 'paid': return 'Đã thanh toán đủ';
      case 'partial': return 'Đã TT ${currencyFormat.format(paidAmount)} / ${currencyFormat.format(total)}';
      default: return 'Chưa thanh toán';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final paymentColor = _getPaymentColor(order.paymentStatus);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.receipt_long, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber.isNotEmpty ? order.orderNumber : '#${order.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Section
                  _buildSectionTitle('Thông tin khách hàng', Icons.person),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow('Tên khách hàng', order.customerName ?? 'Khách lẻ'),
                    if (order.customerPhone != null)
                      _buildInfoRow('Số điện thoại', order.customerPhone!),
                    if ((order.deliveryAddress ?? order.customerAddress) != null)
                      _buildInfoRow('Địa chỉ giao', (order.deliveryAddress ?? order.customerAddress)!),
                    if (order.deliveryContactName != null)
                      _buildInfoRow('Người nhận', order.deliveryContactName!),
                    if (order.deliveryContactPhone != null)
                      _buildInfoRow('SĐT nhận hàng', order.deliveryContactPhone!),
                  ]),

                  const SizedBox(height: 20),

                  // Order Info Section
                  _buildSectionTitle('Thông tin đơn hàng', Icons.info_outline),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow('Ngày tạo', _formatDate(order.createdAt)),
                    _buildInfoRow('Ngày đặt', _formatDate(order.orderDate)),
                    if (order.source != null && order.source!.isNotEmpty)
                      _buildInfoRow('Nguồn', order.source!),
                    if (order.priority != null)
                      _buildInfoRow('Ưu tiên', _getPriorityLabel(order.priority!)),
                  ]),

                  const SizedBox(height: 20),

                  // Payment Section
                  _buildSectionTitle('Thanh toán', Icons.payments),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng tiền hàng'),
                            Text(
                              currencyFormat.format(order.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        // Show discount if exists
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.discount, size: 16, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chiết khấu${order.discountPercent != null && order.discountPercent! > 0 ? ' (${order.discountPercent!.toStringAsFixed(0)}%)' : ''}',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ],
                              ),
                              Text(
                                '-${currencyFormat.format(order.discountAmount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Khách phải trả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              currencyFormat.format(order.total),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trạng thái'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: paymentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getPaymentLabel(order.paymentStatus, order.paidAmount, order.total),
                                style: TextStyle(
                                  color: paymentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (order.paymentStatus == 'partial' || order.paymentStatus == 'unpaid') ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Còn nợ', style: TextStyle(color: Colors.red.shade700)),
                              Text(
                                currencyFormat.format(order.total - order.paidAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Items Section
                  if (order.items != null && order.items!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Sản phẩm (${order.items!.length})', Icons.inventory_2),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: order.items!.asMap().entries.map((entry) {
                          final item = entry.value;
                          final isLast = entry.key == order.items!.length - 1;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item.productImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              item.productImageUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  '${entry.key + 1}',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              '${entry.key + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade600,
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
                                          item.productName ?? 'Sản phẩm',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(item.lineTotal),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (!isLast)
                                Divider(height: 16, color: Colors.grey.shade200),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Notes Section
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
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
                      child: Text(order.notes!),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action Buttons
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
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Pending approval: Approve/Reject + Edit
    if (onApprove != null && onReject != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('Duyệt đơn hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa đơn hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Confirmed: Start delivery + Cancel
    if (order.status == 'confirmed' && onUpdateStatus != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => onUpdateStatus!('processing'),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Bắt đầu giao hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy đơn hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.shade300),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Processing: Complete delivery + Cancel
    if (order.status == 'processing' && onUpdateStatus != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => onUpdateStatus!('completed'),
            icon: const Icon(Icons.check_circle),
            label: const Text('Xác nhận đã giao'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy đơn hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.shade300),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Cancelled: Delete only
    if (order.status == 'cancelled' && onDelete != null) {
      return OutlinedButton.icon(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_forever),
        label: const Text('Xóa đơn hàng'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Draft: Edit + Delete
    if (order.status == 'draft') {
      return Row(
        children: [
          if (onDelete != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Xóa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (onEdit != null && onDelete != null) const SizedBox(width: 12),
          if (onEdit != null)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // For delivered/completed orders - delete only
    if (onDelete != null) {
      return OutlinedButton.icon(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_forever),
        label: const Text('Xóa đơn hàng'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.shade300),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.teal.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'cao': return 'Cao';
      case 'medium':
      case 'trung bình': return 'Trung bình';
      case 'low':
      case 'thấp': return 'Thấp';
      default: return priority;
    }
  }
}
