import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cached_providers.dart';

final supabase = Supabase.instance.client;

// Helper extension for AsyncValue
extension AsyncValueX<T> on AsyncValue<T> {
  T? get valueOrNull => whenOrNull(data: (value) => value);
}

// Legacy provider (redirects to cached provider)
final warehouseOrdersProvider = FutureProvider.autoDispose<List<WarehouseOrder>>((ref) async {
  final cached = await ref.watch(cachedWarehouseOrdersProvider.future);
  return cached.map((c) => WarehouseOrder.fromCache(c)).toList();
});

// Provider for drivers (unchanged)
final driversProvider = FutureProvider.autoDispose<List<Driver>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('employees')
      .select('id, full_name')
      .eq('company_id', companyId)
      .eq('role', 'driver')
      .eq('is_active', true);

  return (response as List).map((json) => Driver.fromJson(json)).toList();
});

class WarehouseOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String? customerName;
  final DateTime orderDate;
  final List<OrderItem> items;

  WarehouseOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName,
    required this.orderDate,
    required this.items,
  });

  factory WarehouseOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['sales_order_items'] as List?)
        ?.map((i) => OrderItem.fromJson(i))
        .toList() ?? [];
    return WarehouseOrder(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      customerName: json['customers']?['name'],
      orderDate: DateTime.parse(json['order_date']),
      items: items,
    );
  }
  
  // Convert from cache model
  factory WarehouseOrder.fromCache(WarehouseOrderCache cache) {
    return WarehouseOrder(
      id: cache.id,
      orderNumber: cache.orderNumber,
      status: cache.status,
      customerName: cache.customerName,
      orderDate: cache.orderDate,
      items: cache.items.map((i) => OrderItem.fromCache(i)).toList(),
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int quantity;
  bool isPicked;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    required this.quantity,
    this.isPicked = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['products']?['name'] ?? json['product_name'] ?? 'Unknown',
      sku: json['products']?['sku'] ?? json['product_sku'],
      unit: json['products']?['unit'] ?? 'pcs',
      quantity: json['quantity'] ?? 0,
    );
  }
  
  // Convert from cache model
  factory OrderItem.fromCache(WarehouseOrderItemCache cache) {
    return OrderItem(
      id: cache.id,
      productId: cache.productId,
      productName: cache.productName,
      sku: cache.sku,
      unit: cache.unit,
      quantity: cache.quantity,
    );
  }
}

class Driver {
  final String id;
  final String fullName;

  Driver({required this.id, required this.fullName});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      fullName: json['full_name'],
    );
  }
}

class WarehousePickingPage extends ConsumerStatefulWidget {
  const WarehousePickingPage({super.key});

  @override
  ConsumerState<WarehousePickingPage> createState() => _WarehousePickingPageState();
}

class _WarehousePickingPageState extends ConsumerState<WarehousePickingPage> {
  final dateFormat = DateFormat('dd/MM/yyyy');
  
  @override
  Widget build(BuildContext context) {
    // 🔥 PHASE 4: Use CACHED provider with realtime listener
    ref.watch(warehouseOrderListenerProvider); // Enable realtime updates
    final ordersAsync = ref.watch(warehouseOrdersProvider);
    final driversAsync = ref.watch(driversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soạn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshWarehouseOrders(ref),
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
                onPressed: () => refreshWarehouseOrders(ref),
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
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có đơn hàng cần soạn',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(warehouseOrdersProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderPickingCard(
                  order: order,
                  drivers: driversAsync.valueOrNull ?? [],
                  onPick: () => _showPickingDialog(context, order, driversAsync.valueOrNull ?? []),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showPickingDialog(BuildContext context, WarehouseOrder order, List<Driver> drivers) {
    // Copy items with pick status
    final pickItems = order.items.map((item) => OrderItem(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      sku: item.sku,
      unit: item.unit,
      quantity: item.quantity,
      isPicked: false,
    )).toList();

    String? selectedDriverId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final allPicked = pickItems.every((item) => item.isPicked);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soạn đơn ${order.orderNumber}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.customerName ?? 'Khách hàng',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
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
                
                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pickItems.length,
                    itemBuilder: (context, index) {
                      final item = pickItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: item.isPicked,
                          onChanged: (value) {
                            setModalState(() {
                              item.isPicked = value ?? false;
                            });
                          },
                          title: Text(
                            item.productName,
                            style: TextStyle(
                              decoration: item.isPicked ? TextDecoration.lineThrough : null,
                              color: item.isPicked ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(
                            '${item.sku ?? ''} • ${item.quantity} ${item.unit}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: item.isPicked ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Driver selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(
                      labelText: 'Phân tài xế',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    items: drivers.map((driver) => DropdownMenuItem(
                      value: driver.id,
                      child: Text(driver.fullName),
                    )).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedDriverId = value;
                      });
                    },
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: allPicked
                              ? () => _completePicking(order, selectedDriverId)
                              : null,
                          icon: const Icon(Icons.check),
                          label: Text('Hoàn tất soạn hàng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _completePicking(WarehouseOrder order, String? driverId) async {
    try {
      // Update order status
      await supabase.from('sales_orders').update({
        'status': 'ready',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', order.id);

      // Create delivery if driver is assigned and order is not a sample
      if (driverId != null) {
        // Check if this is a sample order (no delivery needed)
        final orderCheck = await supabase
            .from('sales_orders')
            .select('order_type')
            .eq('id', order.id)
            .single();
        final orderType = orderCheck['order_type'] as String? ?? 'regular';

        if (orderType != 'sample') {
          final user = ref.read(currentUserProvider);
          final companyId = user?.companyId;
          
          // Generate delivery number using database function
          final deliveryNumberResult = await supabase.rpc(
            'generate_delivery_number',
            params: {'p_company_id': companyId},
          );
          final deliveryNumber = deliveryNumberResult as String? ?? 'DLV${DateTime.now().millisecondsSinceEpoch}';
          
          await supabase.from('deliveries').insert({
            'company_id': companyId,
            'order_id': order.id,
            'driver_id': driverId,
            'delivery_number': deliveryNumber,
            'status': 'planned',
            'delivery_date': DateTime.now().toIso8601String().split('T')[0],
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hoàn tất soạn đơn ${order.orderNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(warehouseOrdersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _OrderPickingCard extends StatelessWidget {
  final WarehouseOrder order;
  final List<Driver> drivers;
  final VoidCallback onPick;

  const _OrderPickingCard({
    required this.order,
    required this.drivers,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = order.status == 'picking' ? Colors.orange : Colors.blue;
    final statusLabel = order.status == 'picking' ? 'Đang soạn' : 'Chờ soạn';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPick,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} sản phẩm',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Items preview
              ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${order.items.length - 3} sản phẩm khác',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.inventory),
                  label: Text('Bắt đầu soạn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
