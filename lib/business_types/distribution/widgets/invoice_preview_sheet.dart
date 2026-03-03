import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Invoice Preview Sheet - Hiển thị mẫu hóa đơn trực tiếp trong app
/// Không cần mở PDF, xem dễ dàng trên mobile
class InvoicePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final String companyName;
  final VoidCallback? onPrint;

  const InvoicePreviewSheet({
    super.key,
    required this.order,
    required this.companyName,
    this.onPrint,
  });

  /// Show the invoice preview as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> order,
    required String companyName,
    VoidCallback? onPrint,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InvoicePreviewSheet(
            order: order,
            companyName: companyName,
            onPrint: onPrint,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = (order['sales_order_items'] as List?) ?? [];
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final orderDate = DateTime.tryParse(order['created_at'] ?? '');

    // Calculate totals
    double subtotal = 0;
    for (final item in items) {
      final qty = (item['quantity'] ?? 0).toDouble();
      final price = (item['unit_price'] ?? 0).toDouble();
      subtotal += qty * price;
    }
    final discountAmount = (order['discount_amount'] ?? 0).toDouble();
    final taxAmount = (order['tax_amount'] ?? 0).toDouble();
    final shippingAmount = (order['shipping_fee'] ?? 0).toDouble();
    final total = (order['total'] ?? (subtotal - discountAmount + taxAmount + shippingAmount)).toDouble();
    final paymentStatus = order['payment_status']?.toString() ?? 'pending';

    return Column(
      children: [
        // Drag handle & Header
        _buildHeader(context),

        // Scrollable invoice content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company header
                _buildCompanyHeader(),

                const SizedBox(height: 20),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // Invoice info
                _buildInvoiceInfo(orderDate),

                const SizedBox(height: 20),

                // Customer info
                _buildCustomerInfo(customer),

                const SizedBox(height: 24),

                // Items table
                _buildItemsTable(items, currencyFormat),

                const SizedBox(height: 20),

                // Totals
                _buildTotals(currencyFormat, subtotal, discountAmount, taxAmount, shippingAmount, total),

                const SizedBox(height: 24),

                // Payment status
                _buildPaymentStatus(paymentStatus),

                const SizedBox(height: 32),

                // Signatures
                _buildSignatures(),

                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Text(
                    'Cảm ơn quý khách đã mua hàng!',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Print button
        if (onPrint != null) _buildPrintButton(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          const Text(
            'XEM MẪU HÓA ĐƠN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business, color: Colors.purple.shade700, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Địa chỉ: ${order['delivery_address'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'MST: 0123456789',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceInfo(DateTime? orderDate) {
    final orderNumber = order['order_number'] ?? 
        order['id'].toString().substring(0, 8).toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HÓA ĐƠN BÁN HÀNG',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Số HĐ: $orderNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                orderDate != null 
                    ? DateFormat('dd/MM/yyyy').format(orderDate)
                    : 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                orderDate != null 
                    ? DateFormat('HH:mm').format(orderDate)
                    : '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic>? customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'THÔNG TIN KHÁCH HÀNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Tên', customer?['name'] ?? 'N/A'),
          _buildInfoRow('Địa chỉ', order['delivery_address'] ?? customer?['address'] ?? 'N/A'),
          _buildInfoRow('Điện thoại', customer?['phone'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List items, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            const Text(
              'CHI TIẾT ĐƠN HÀNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 30, child: Text('STT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 4, child: Text('Sản phẩm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('SL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Đơn giá', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('T.Tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        ),

        // Table rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final qty = (item['quantity'] ?? 0).toDouble();
              final price = (item['unit_price'] ?? 0).toDouble();
              final lineTotal = (item['line_total'] ?? qty * price).toDouble();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: index < items.length - 1 
                      ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'] ?? 'N/A',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          if (item['unit'] != null)
                            Text(
                              item['unit'],
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        qty.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatPrice(price),
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatPrice(lineTotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }

  Widget _buildTotals(NumberFormat currencyFormat, double subtotal, double discountAmount, double taxAmount, double shippingAmount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildTotalRow('Tạm tính', subtotal, currencyFormat),
          if (discountAmount > 0)
            _buildTotalRow('Giảm giá', -discountAmount, currencyFormat, isDiscount: true),
          if (taxAmount > 0)
            _buildTotalRow('Thuế', taxAmount, currencyFormat),
          if (shippingAmount > 0)
            _buildTotalRow('Phí vận chuyển', shippingAmount, currencyFormat),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG CỘNG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, NumberFormat currencyFormat, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            '${isDiscount ? "-" : ""}${currencyFormat.format(amount.abs())}',
            style: TextStyle(
              color: isDiscount ? Colors.red.shade600 : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(String paymentStatus) {
    final isPaid = paymentStatus == 'paid';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const Text(
              'Người mua hàng',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            Text(
              '(Ký, ghi rõ họ tên)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        Column(
          children: [
            const Text(
              'Người bán hàng',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            Text(
              '(Ký, ghi rõ họ tên)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrintButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Đóng'),
                style: OutlinedButton.styleFrom(
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
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onPrint?.call();
                },
                icon: const Icon(Icons.print),
                label: const Text('In hóa đơn'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
