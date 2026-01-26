import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/manufacturing_service.dart';
import '../../models/manufacturing_models.dart';
import 'production_order_form_page.dart';

class ProductionOrdersPage extends ConsumerStatefulWidget {
  const ProductionOrdersPage({super.key});

  @override
  ConsumerState<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
}

class _ProductionOrdersPageState extends ConsumerState<ProductionOrdersPage> {
  final _service = ManufacturingService();
  List<ProductionOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.getProductionOrders();
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lệnh sản xuất: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'planned': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft': return 'Nháp';
      case 'planned': return 'Đã lên kế hoạch';
      case 'in_progress': return 'Đang sản xuất';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lệnh Sản Xuất'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductionOrderFormPage()),
              ).then((_) => _loadOrders()); // Refresh after return
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.factory, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có lệnh sản xuất'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status),
                          child: const Icon(Icons.factory, color: Colors.white),
                        ),
                        title: Text('MO-${order.orderNumber}'),
                        subtitle: Text(
                          'Sản phẩm: ${order.productId}\n'
                          '${_getStatusText(order.status)} • Số lượng: ${order.plannedQuantity}',
                        ),
                        isThreeLine: true,
                        trailing: order.producedQuantity > 0
                            ? Text(
                                'SX: ${order.producedQuantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo lệnh sản xuất - Coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
