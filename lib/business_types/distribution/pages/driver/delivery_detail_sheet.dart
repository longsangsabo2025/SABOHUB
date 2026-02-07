import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DELIVERY DETAIL SHEET - Chi tiết đơn hàng bottom sheet
class DeliveryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final NumberFormat currencyFormat;
  final VoidCallback onPickup;
  final VoidCallback onComplete;
  final Function(String?) onCall;
  final Function(String?) onNavigate;
  final VoidCallback onFailDelivery;
  final VoidCallback onCollectPayment;

  const DeliveryDetailSheet({
    super.key,
    required this.delivery,
    required this.currencyFormat,
    required this.onPickup,
    required this.onComplete,
    required this.onCall,
    required this.onNavigate,
    required this.onFailDelivery,
    required this.onCollectPayment,
  });

  // Extract effective order data from either sales_orders or deliveries source
  Map<String, dynamic>? get _salesOrder => delivery['sales_orders'] as Map<String, dynamic>?;
  Map<String, dynamic> get _effectiveOrder => _salesOrder ?? delivery;
  Map<String, dynamic>? get _customer => (_salesOrder?['customers'] ?? delivery['customers']) as Map<String, dynamic>?;

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final salesOrder = _salesOrder;
    final effectiveOrder = _effectiveOrder;
    final status = delivery['status'] as String? ?? 'pending';
    // For deliveries rows, use delivery['status']; for sales_orders rows, use delivery_status
    final deliveryStatus = salesOrder != null ? delivery['status'] : (delivery['delivery_status'] as String?);
    final orderNumber = effectiveOrder['order_number']?.toString() ?? delivery['delivery_number']?.toString() ?? delivery['id'].toString().substring(0, 8).toUpperCase();
    final total = (effectiveOrder['total'] as num?)?.toDouble() ?? (delivery['total_amount'] as num?)?.toDouble() ?? 0;
    final customerName = effectiveOrder['customer_name'] ?? customer?['name'] ?? 'Khách hàng';
    final customerAddress = effectiveOrder['delivery_address'] ?? customer?['address'];
    final customerPhone = customer?['phone'] ?? effectiveOrder['customer_phone'];
    final notes = delivery['notes'] ?? effectiveOrder['delivery_notes'];
    final isPending = status == 'ready_for_delivery' || status == 'processing';
    final isDelivering = deliveryStatus == 'delivering' || deliveryStatus == 'in_progress';
    
    // Payment info for conditional display
    final paymentStatus = effectiveOrder['payment_status']?.toString() ?? 'pending';
    final needsPaymentCollection = paymentStatus != 'paid' && isDelivering;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đơn hàng #$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(currencyFormat.format(total), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Thông tin khách hàng', Icons.person),
                  const SizedBox(height: 12),
                  _buildCustomerInfo(context, customerName, customerPhone, customerAddress),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Ghi chú', Icons.notes),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)),
                      child: Text(notes),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildSectionTitle('Sản phẩm đặt hàng', Icons.inventory_2),
                  const SizedBox(height: 12),
                  _buildProductsList(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Thanh toán', Icons.payments),
                  const SizedBox(height: 12),
                  _buildPaymentInfo(context, orderNumber),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildActionButtons(context, isPending, isDelivering, needsPaymentCollection, customerAddress),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, String customerName, String? customerPhone, String? customerAddress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (customerPhone != null) Text(customerPhone, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (customerPhone != null)
                ElevatedButton.icon(
                  onPressed: () => onCall(customerPhone),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Gọi'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
            ],
          ),
          if (customerAddress != null && customerAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => onNavigate(customerAddress),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(child: Text(customerAddress, style: TextStyle(color: Colors.blue.shade700))),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.directions, color: Colors.blue.shade700, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade700)),
      ],
    );
  }

  Widget _buildProductsList() {
    final items = _effectiveOrder['sales_order_items'] as List<dynamic>? ?? [];
    
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('Không có thông tin sản phẩm', style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final productName = item['product_name'] ?? 'Sản phẩm';
          final quantity = item['quantity'] ?? 0;
          final unit = item['unit'] ?? '';
          final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
          final lineTotal = (item['line_total'] as num?)?.toDouble() ?? (quantity * unitPrice);
          
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: index < items.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade200)) : null),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$quantity $unit x ${currencyFormat.format(unitPrice)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Text(currencyFormat.format(lineTotal), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context, String orderNumber) {
    final effectiveOrder = _effectiveOrder;
    final total = (effectiveOrder['total'] as num?)?.toDouble() ?? (delivery['total_amount'] as num?)?.toDouble() ?? 0;
    final paymentMethod = effectiveOrder['payment_method']?.toString() ?? 'COD';
    final paymentStatus = effectiveOrder['payment_status']?.toString() ?? 'pending';
    
    final isPaid = paymentStatus == 'paid';
    final isCOD = paymentMethod.toString().toLowerCase() == 'cod' || paymentMethod.toString().toLowerCase() == 'cash';
    final isTransfer = paymentMethod.toString().toLowerCase() == 'transfer' || paymentMethod.toString().toLowerCase() == 'bank';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : (isTransfer ? Colors.blue.shade50 : Colors.orange.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? Colors.green.shade200 : (isTransfer ? Colors.blue.shade200 : Colors.orange.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phương thức:', style: TextStyle(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTransfer ? Colors.blue.shade100 : (isCOD ? Colors.orange.shade100 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTransfer ? '🏦 Chuyển khoản' : (isCOD ? '💵 COD (Thu hộ)' : '💳 Đã thanh toán'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: isTransfer ? Colors.blue.shade800 : (isCOD ? Colors.orange.shade800 : Colors.green.shade800), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trạng thái:', style: TextStyle(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isPaid ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(isPaid ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade800 : Colors.red.shade800, fontSize: 13)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(!isPaid ? '💰 CẦN THU:' : 'Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: !isPaid ? Colors.orange.shade800 : Colors.black87)),
              Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: !isPaid ? Colors.orange.shade800 : Colors.green.shade700)),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showQRTransferDialog(context, total, orderNumber),
                icon: const Icon(Icons.qr_code),
                label: const Text('Hiện QR chuyển khoản'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, side: BorderSide(color: Colors.blue.shade300), padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPending, bool isDelivering, bool needsPaymentCollection, String? customerAddress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (customerAddress != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigate(customerAddress),
                    icon: const Icon(Icons.directions),
                    label: const Text('Chỉ đường'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              if (customerAddress != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    isPending ? onPickup() : onComplete();
                  },
                  icon: Icon(isPending ? Icons.play_arrow : Icons.check_circle),
                  label: Text(isPending ? 'Nhận đơn giao' : 'Đã giao'),
                  style: ElevatedButton.styleFrom(backgroundColor: isPending ? Colors.orange : Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          ),
          if (isDelivering) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (needsPaymentCollection)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(context); onCollectPayment(); },
                      icon: const Icon(Icons.payments),
                      label: const Text('Xác nhận thanh toán'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                if (needsPaymentCollection) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(context); onFailDelivery(); },
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Không giao được', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  void _showQRTransferDialog(BuildContext context, double amount, String orderNumber) async {
    try {
      final supabase = Supabase.instance.client;
      // Get company_id from the delivery data or employees table
      final companyId = delivery['company_id'] as String?;
      if (companyId == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy thông tin công ty')));
        return;
      }
      
      final companyData = await supabase.from('companies').select('bank_name, bank_account_number, bank_account_name, bank_bin').eq('id', companyId).maybeSingle();
      if (companyData == null || companyData['bank_bin'] == null || companyData['bank_account_number'] == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Công ty chưa cấu hình tài khoản ngân hàng'), backgroundColor: Colors.orange));
        return;
      }
      
      final bankBin = companyData['bank_bin'];
      final accountNumber = companyData['bank_account_number'];
      final accountName = companyData['bank_account_name'] ?? '';
      final bankName = companyData['bank_name'] ?? 'Ngân hàng';
      
      final amountInt = amount.toInt();
      final content = 'TT $orderNumber';
      final qrUrl = 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png?amount=$amountInt&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName)}';
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(children: [Icon(Icons.qr_code, color: Colors.blue.shade700), const SizedBox(width: 8), const Text('QR Chuyển khoản')]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: Image.network(qrUrl, width: 250, height: 250,
                      loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(width: 250, height: 250, child: Center(child: CircularProgressIndicator())),
                      errorBuilder: (_, __, ___) => Container(width: 250, height: 250, color: Colors.grey.shade100, child: const Center(child: Text('Không thể tải QR'))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      Text(bankName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      const SizedBox(height: 4),
                      Text(accountNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(accountName, style: TextStyle(color: Colors.grey.shade700)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(children: [
                      const Text('Số tiền:', style: TextStyle(fontSize: 12)),
                      Text(currencyFormat.format(amount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                      const SizedBox(height: 8),
                      const Text('Nội dung:', style: TextStyle(fontSize: 12)),
                      Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('⚠️ Sau khi khách chuyển khoản, Manager sẽ xác nhận', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }
}
