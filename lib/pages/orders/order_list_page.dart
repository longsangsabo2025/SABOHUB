import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import 'order_form_page.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade700,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Đang chuẩn bị'),
            Tab(text: 'Sẵn sàng'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllOrdersTab(),
          _buildOrdersByStatusTab(OrderStatus.pending),
          _buildOrdersByStatusTab(OrderStatus.preparing),
          _buildOrdersByStatusTab(OrderStatus.ready),
          _buildOrdersByStatusTab(OrderStatus.completed),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToOrderForm(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllOrdersTab() {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      data: (orders) => orders.isEmpty
          ? _buildEmptyState()
          : _buildOrderList(orders),
      loading: () => const LoadingIndicator(message: 'Đang tải đơn hàng...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildOrdersByStatusTab(OrderStatus status) {
    final ordersAsync = ref.watch(ordersByStatusProvider(status));

    return ordersAsync.when(
      data: (orders) => orders.isEmpty
          ? _buildEmptyState(status: status)
          : _buildOrderList(orders),
      loading: () => const LoadingIndicator(message: 'Đang tải đơn hàng...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersProvider);
        ref.invalidate(ordersByStatusProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: order.status.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Đơn #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer and table info
            if (order.customerName != null || order.tableName != null) ...[
              Row(
                children: [
                  if (order.customerName != null) ...[
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      order.customerName!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  if (order.customerName != null && order.tableName != null)
                    Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                  if (order.tableName != null) ...[
                    Icon(Icons.table_restaurant, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      order.tableName!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Order items
            if (order.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Món đã đặt:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text('${item.quantity}x '),
                          Expanded(child: Text(item.menuItemName)),
                          Text(
                            '${(item.totalPrice).toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                    if (order.items.length > 3)
                      Text(
                        '... và ${order.items.length - 3} món khác',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Total and actions
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildOrderActions(order),
              ],
            ),

            // Order time
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.status == OrderStatus.pending) ...[
          IconButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing),
            icon: const Icon(Icons.restaurant, size: 20),
            tooltip: 'Bắt đầu chuẩn bị',
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange.shade50,
              foregroundColor: Colors.orange.shade600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (order.status == OrderStatus.preparing) ...[
          IconButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.ready),
            icon: const Icon(Icons.check_circle, size: 20),
            tooltip: 'Sẵn sàng phục vụ',
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              foregroundColor: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (order.status == OrderStatus.ready) ...[
          IconButton(
            onPressed: () => _updateOrderStatus(order.id, OrderStatus.completed),
            icon: const Icon(Icons.done_all, size: 20),
            tooltip: 'Hoàn thành',
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
          IconButton(
            onPressed: () => _showDeleteConfirmation(order),
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Hủy đơn',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade600,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({OrderStatus? status}) {
    String message;
    String subtitle;
    
    switch (status) {
      case OrderStatus.pending:
        message = 'Không có đơn hàng chờ xử lý';
        subtitle = 'Các đơn hàng mới sẽ xuất hiện ở đây';
        break;
      case OrderStatus.preparing:
        message = 'Không có đơn đang chuẩn bị';
        subtitle = 'Đơn hàng đang được chế biến sẽ hiển thị ở đây';
        break;
      case OrderStatus.ready:
        message = 'Không có đơn sẵn sàng';
        subtitle = 'Đơn hàng sẵn sàng phục vụ sẽ hiển thị ở đây';
        break;
      case OrderStatus.completed:
        message = 'Chưa có đơn hoàn thành';
        subtitle = 'Lịch sử đơn hàng sẽ xuất hiện ở đây';
        break;
      default:
        message = 'Chưa có đơn hàng nào';
        subtitle = 'Tạo đơn hàng đầu tiên của bạn';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          if (status == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToOrderForm,
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn hàng mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(ordersProvider);
              ref.invalidate(ordersByStatusProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderForm([Order? order]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OrderFormPage(),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final actions = ref.read(orderActionsProvider);
      await actions.updateOrderStatus(orderId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng thành ${status.label}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  void _showDeleteConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: Text('Bạn có chắc muốn hủy đơn hàng #${order.id.substring(0, 8)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteOrder(order.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      final actions = ref.read(orderActionsProvider);
      await actions.deleteOrder(orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
