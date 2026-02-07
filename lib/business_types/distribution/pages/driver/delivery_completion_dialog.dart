import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog chọn hình thức thanh toán khi hoàn thành giao hàng
class DeliveryCompletionDialog extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;

  const DeliveryCompletionDialog({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
  });

  @override
  State<DeliveryCompletionDialog> createState() => _DeliveryCompletionDialogState();
}

class _DeliveryCompletionDialogState extends State<DeliveryCompletionDialog> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  String selectedPaymentOption = 'cash_collected';

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod': return 'Tiền mặt (COD)';
      case 'cash': return 'Tiền mặt';
      case 'transfer': return 'Chuyển khoản';
      case 'card': return 'Thẻ tín dụng';
      default: return method;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return 'Đã thanh toán';
      case 'unpaid': return 'Chưa thanh toán';
      case 'partial': return 'Thanh toán một phần';
      case 'debt': return 'Ghi nợ';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.local_shipping, color: Colors.green.shade600, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Hoàn thành giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Mã đơn: ${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('👤 Khách hàng: ${widget.customerName}'),
                Text('💰 Tổng tiền: ${currencyFormat.format(widget.totalAmount)}'),
                Text('💳 Hình thức: ${_getPaymentMethodLabel(widget.paymentMethod)}'),
                Text('📊 Trạng thái: ${_getPaymentStatusLabel(widget.paymentStatus)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Xử lý thanh toán:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          
          if (widget.paymentMethod == 'cod' && widget.paymentStatus != 'paid')
            RadioListTile<String>(
              value: 'cash_collected',
              groupValue: selectedPaymentOption,
              onChanged: (value) => setState(() => selectedPaymentOption = value!),
              title: const Text('💵 Thu tiền mặt'),
              subtitle: Text('Xác nhận đã thu ${currencyFormat.format(widget.totalAmount)}'),
              dense: true,
            ),
          
          if (widget.paymentMethod == 'transfer' && widget.paymentStatus != 'paid')
            RadioListTile<String>(
              value: 'transfer_confirmed',
              groupValue: selectedPaymentOption,
              onChanged: (value) => setState(() => selectedPaymentOption = value!),
              title: const Text('🏦 Xác nhận chuyển khoản'),
              subtitle: const Text('Khách hàng đã chuyển khoản'),
              dense: true,
            ),
          
          if (widget.paymentStatus != 'paid')
            RadioListTile<String>(
              value: 'debt_added',
              groupValue: selectedPaymentOption,
              onChanged: (value) => setState(() => selectedPaymentOption = value!),
              title: const Text('📝 Ghi nợ'),
              subtitle: const Text('Khách hàng sẽ thanh toán sau'),
              dense: true,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Map<String, dynamic> result = {'updatePayment': false};
            
            switch (selectedPaymentOption) {

              case 'cash_collected':
                result = {'updatePayment': true, 'paymentStatus': 'paid', 'paymentMethod': 'cash'};
                break;
              case 'transfer_confirmed':
                result = {'updatePayment': true, 'paymentStatus': 'paid', 'paymentMethod': 'transfer'};
                break;
              case 'debt_added':
                result = {'updatePayment': true, 'paymentStatus': 'debt', 'paymentMethod': widget.paymentMethod};
                break;
            }
            
            Navigator.pop(context, result);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
