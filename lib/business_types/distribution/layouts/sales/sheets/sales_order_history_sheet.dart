import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Lịch sử đơn hàng của khách hàng - Bottom sheet
class SalesOrderHistorySheet extends StatefulWidget {
  final Map<String, dynamic> customer;
  final ScrollController scrollController;

  const SalesOrderHistorySheet({
    super.key,
    required this.customer,
    required this.scrollController,
  });

  @override
  State<SalesOrderHistorySheet> createState() => _SalesOrderHistorySheetState();
}

class _SalesOrderHistorySheetState extends State<SalesOrderHistorySheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final customerId = widget.customer['id'];
      
      final response = await supabase
          .from('sales_orders')
          .select('id, order_number, total, status, created_at')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'draft': return Colors.grey;
      case 'pending_approval': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      case 'confirmed': return Colors.teal;
      case 'ready': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'draft': return 'Nháp';
      case 'pending_approval': return 'Chờ duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'processing': return 'Đang xử lý';
      case 'confirmed': return 'Đã duyệt';
      case 'ready': return 'Sẵn sàng';
      default: return status ?? 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.customer['name'] ?? 'Khách hàng', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final createdAt = DateTime.tryParse(order['created_at'] ?? '');
                          final status = order['status'] as String?;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt, color: _getStatusColor(status)),
                              ),
                              title: Text(
                                order['order_number'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                createdAt != null 
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                                    : 'N/A',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(order['total'] ?? 0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(fontSize: 11, color: _getStatusColor(status)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Summary footer
          if (_orders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${_orders.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const Text('Tổng đơn', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        currencyFormat.format(_orders.fold<double>(0, (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble())),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const Text('Tổng giá trị', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
