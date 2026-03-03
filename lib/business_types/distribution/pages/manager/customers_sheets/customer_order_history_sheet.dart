import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/odori_customer.dart';
import 'customer_order_detail_dialog.dart';

final _supabase = Supabase.instance.client;

// ==================== CUSTOMER ORDER HISTORY SHEET (ENHANCED) ====================
class CustomerOrderHistorySheet extends StatefulWidget {
  final OdoriCustomer customer;
  final ScrollController scrollController;

  const CustomerOrderHistorySheet({
    super.key,
    required this.customer,
    required this.scrollController,
  });

  @override
  State<CustomerOrderHistorySheet> createState() => _CustomerOrderHistorySheetState();
}

class _CustomerOrderHistorySheetState extends State<CustomerOrderHistorySheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  // Statistics
  double _totalRevenue = 0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await _supabase
          .from('sales_orders')
          .select('''
            id, order_number, order_date, total, paid_amount, 
            status, payment_status, delivery_status,
            created_at, notes
          ''')
          .eq('customer_id', widget.customer.id)
          .order('created_at', ascending: false)
          .limit(100);

      final orders = List<Map<String, dynamic>>.from(response);
      
      // Calculate stats (exclude cancelled)
      double totalRevenue = 0;
      int completed = 0;
      for (final order in orders) {
        final status = order['status'] as String?;
        if (status != 'cancelled') {
          totalRevenue += (order['total'] as num?)?.toDouble() ?? 0;
          if (status == 'completed') completed++;
        }
      }

      if (mounted) {
        setState(() {
          _orders = orders;
          _totalRevenue = totalRevenue;
          _completedOrders = completed;
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

  void _showOrderDetail(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailDialog(order: order, currencyFormat: currencyFormat),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      case 'approved': return Colors.teal;
      case 'delivering': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'pending': return 'Chờ duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'processing': return 'Đang xử lý';
      case 'approved': return 'Đã duyệt';
      case 'delivering': return 'Đang giao';
      default: return status ?? 'N/A';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'unpaid': return Colors.red;
      case 'debt': return Colors.deepOrange;
      case 'pending_transfer': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid': return 'Đã TT';
      case 'partial': return 'TT 1 phần';
      case 'unpaid': return 'Chưa TT';
      case 'debt': return 'Công nợ';
      case 'pending_transfer': return 'Chờ CK';
      default: return status ?? '';
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lịch sử mua hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.customer.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          // Stats
          if (!_isLoading && _orders.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Tổng đơn', '${_orders.where((o) => o['status'] != 'cancelled').length}', Colors.orange),
                  Container(width: 1, height: 30, color: Colors.orange.shade200),
                  _buildStat('Hoàn thành', '$_completedOrders', Colors.green),
                  Container(width: 1, height: 30, color: Colors.orange.shade200),
                  _buildStat('Doanh thu', currencyFormat.format(_totalRevenue), Colors.teal),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // List
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
                    : ListView.separated(
                        controller: widget.scrollController,
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderDate = DateTime.tryParse(order['order_date']?.toString() ?? order['created_at']?.toString() ?? '');
    final status = order['status'] as String?;
    final paymentStatus = order['payment_status'] as String?;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0;
    final isCancelled = status == 'cancelled';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isCancelled ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt, color: _getStatusColor(status), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order['order_number'] ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(fontSize: 10, color: _getStatusColor(status), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderDate != null ? DateFormat('dd/MM/yyyy - HH:mm').format(orderDate) : 'N/A',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isCancelled ? Colors.grey : Colors.teal,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (!isCancelled && paymentStatus != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(paymentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPaymentStatusText(paymentStatus),
                            style: TextStyle(fontSize: 10, color: _getPaymentStatusColor(paymentStatus)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                ],
              ),
              // Payment progress bar for partial payments
              if (!isCancelled && paymentStatus == 'partial' && total > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: paidAmount / total,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(paidAmount / total * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
