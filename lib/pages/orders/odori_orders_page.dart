import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/odori_sales_order.dart';
import '../../providers/odori_providers.dart';
import 'order_form_page.dart';

final supabase = Supabase.instance.client;

class OdoriOrdersPage extends ConsumerStatefulWidget {
  const OdoriOrdersPage({super.key});

  @override
  ConsumerState<OdoriOrdersPage> createState() => _OdoriOrdersPageState();
}

class _OdoriOrdersPageState extends ConsumerState<OdoriOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _statusFilter = null;
              break;
            case 1:
              _statusFilter = 'pending_approval';
              break;
            case 2:
              _statusFilter = 'processing';
              break;
            case 3:
              _statusFilter = 'delivered';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(salesOrdersProvider(OrderFilters(
      status: _statusFilter,
    )));
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Tất cả'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chờ duyệt'),
                  const SizedBox(width: 4),
                  pendingAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => orders.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${orders.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Đang xử lý'),
            const Tab(text: 'Đã giao'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(salesOrdersProvider(const OrderFilters())),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _statusFilter == null ? 'Chưa có đơn hàng nào' : 'Không có đơn hàng ${_getStatusLabel(_statusFilter!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(salesOrdersProvider(OrderFilters(
              status: _statusFilter,
            )).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrderSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo đơn'),
      ),
    );
  }

  void _showFilterSheet() {
    // TODO: Implement date range filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bộ lọc ngày đang phát triển')),
    );
  }

  void _showCreateOrderSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OrderFormPage(),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_approval':
        return 'chờ duyệt';
      case 'processing':
        return 'đang xử lý';
      case 'delivered':
        return 'đã giao';
      default:
        return status;
    }
  }
}

class _OrderCard extends ConsumerWidget {
  final OdoriSalesOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customerName ?? 'Khách hàng',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.orderDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  if (order.saleName != null) ...[
                    Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      order.saleName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(order.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      _PaymentBadge(status: order.paymentStatus),
                    ],
                  ),
                  // Action buttons based on status
                  _buildActionButtons(context, ref),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (order.isPendingApproval) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: () => _rejectOrder(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Từ chối'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _approveOrder(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Duyệt'),
          ),
        ],
      );
    } else if (order.status == 'approved') {
      return ElevatedButton.icon(
        onPressed: () => _sendToWarehouse(context, ref),
        icon: const Icon(Icons.warehouse, size: 18),
        label: const Text('Gửi kho'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showOrderDetail(BuildContext context) {
    // TODO: Navigate to order detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết đơn ${order.orderNumber}')),
    );
  }

  void _approveOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận duyệt đơn'),
        content: Text('Bạn có chắc muốn duyệt đơn hàng ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.from('sales_orders').update({
                  'status': 'approved',
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', order.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã duyệt đơn ${order.orderNumber}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  ref.invalidate(salesOrdersProvider(const OrderFilters()));
                  ref.invalidate(pendingApprovalsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _rejectOrder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận từ chối đơn'),
        content: Text('Bạn có chắc muốn từ chối đơn hàng ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.from('sales_orders').update({
                  'status': 'rejected',
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', order.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã từ chối đơn ${order.orderNumber}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  ref.invalidate(salesOrdersProvider(const OrderFilters()));
                  ref.invalidate(pendingApprovalsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _sendToWarehouse(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gửi đơn cho kho'),
        content: Text('Gửi đơn ${order.orderNumber} cho kho soạn hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await supabase.from('sales_orders').update({
                  'status': 'sent_to_warehouse',
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', order.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi đơn ${order.orderNumber} cho kho'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  ref.invalidate(salesOrdersProvider(const OrderFilters()));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Gửi kho'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'Nháp';
        break;
      case 'pending_approval':
        color = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'approved':
        color = Colors.blue;
        label = 'Đã duyệt';
        break;
      case 'processing':
        color = Colors.purple;
        label = 'Đang xử lý';
        break;
      case 'ready':
        color = Colors.teal;
        label = 'Sẵn sàng';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Đã giao';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String status;

  const _PaymentBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Đã thanh toán';
        icon = Icons.check_circle;
        break;
      case 'partial':
        color = Colors.orange;
        label = 'Thanh toán một phần';
        icon = Icons.timelapse;
        break;
      default:
        color = Colors.red;
        label = 'Chưa thanh toán';
        icon = Icons.warning;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
