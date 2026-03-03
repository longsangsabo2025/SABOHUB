import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

// ==================== ORDER DETAIL DIALOG ====================
class OrderDetailDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final NumberFormat currencyFormat;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.currencyFormat,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final response = await _supabase
          .from('sales_order_items')
          .select('id, product_name, product_sku, quantity, unit, unit_price, line_total, notes')
          .eq('order_id', widget.order['id'])
          .order('created_at');

      setState(() {
        _items = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.tryParse(widget.order['order_date']?.toString() ?? widget.order['created_at']?.toString() ?? '');
    final total = (widget.order['total'] as num?)?.toDouble() ?? 0;
    final paidAmount = (widget.order['paid_amount'] as num?)?.toDouble() ?? 0;
    final status = widget.order['status'] as String?;
    final paymentStatus = widget.order['payment_status'] as String?;
    final deliveryStatus = widget.order['delivery_status'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.teal.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order['order_number'] ?? 'Chi tiết đơn hàng',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (orderDate != null)
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(orderDate),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),

            // Order info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip('Trạng thái', _getStatusText(status), _getStatusColor(status)),
                  _buildInfoChip('Thanh toán', _getPaymentStatusText(paymentStatus), _getPaymentStatusColor(paymentStatus)),
                  if (deliveryStatus != null)
                    _buildInfoChip('Giao hàng', _getDeliveryText(deliveryStatus), _getDeliveryColor(deliveryStatus)),
                ],
              ),
            ),

            // Items list
            Flexible(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('Không có sản phẩm', style: TextStyle(color: Colors.grey.shade500)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final qty = item['quantity'] ?? 0;
                            final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
                            final lineTotal = (item['line_total'] as num?)?.toDouble() ?? 0;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ?? 'N/A',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$qty ${item['unit'] ?? 'sp'} × ${widget.currencyFormat.format(unitPrice)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  widget.currencyFormat.format(lineTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
            ),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền:', style: TextStyle(fontSize: 16)),
                      Text(
                        widget.currencyFormat.format(total),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                      ),
                    ],
                  ),
                  if (paidAmount > 0 && paidAmount < total) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đã thanh toán:', style: TextStyle(color: Colors.green.shade600)),
                        Text(widget.currencyFormat.format(paidAmount), style: TextStyle(color: Colors.green.shade600)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Còn nợ:', style: TextStyle(color: Colors.red.shade600)),
                        Text(
                          widget.currencyFormat.format(total - paidAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
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

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid': return 'Đã TT';
      case 'partial': return 'TT 1 phần';
      case 'unpaid': return 'Chưa TT';
      case 'debt': return 'Công nợ';
      case 'pending_transfer': return 'Chờ CK';
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

  String _getDeliveryText(String? status) {
    switch (status) {
      case 'delivered': return 'Đã giao';
      case 'delivering': return 'Đang giao';
      case 'pending': return 'Chờ giao';
      case 'failed': return 'Giao thất bại';
      default: return status ?? 'N/A';
    }
  }

  Color _getDeliveryColor(String? status) {
    switch (status) {
      case 'delivered': return Colors.green;
      case 'delivering': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
}
