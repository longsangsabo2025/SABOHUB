import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final TableSession session;

  const PaymentPage({super.key, required this.session});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerNameController.text = widget.session.customerName ?? '';
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _notesController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.session.calculateTotalAmount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        leading: _isProcessing 
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            _buildSessionInfoCard(totalAmount),
            const SizedBox(height: 24),

            // Payment Method Selection
            Text(
              'Chọn phương thức thanh toán',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodCards(),
            const SizedBox(height: 24),

            // Cash payment details
            if (_selectedMethod == PaymentMethod.cash) ...[
              Text(
                'Chi tiết thanh toán tiền mặt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền nhận (nghìn đồng)',
                  hintText: 'Ví dụ: ${(totalAmount / 1000).ceil()}',
                  prefixText: '₫ ',
                  suffixText: 'K',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_paidAmountController.text.isNotEmpty) ...[
                _buildChangeCalculation(totalAmount),
              ],
              const SizedBox(height: 16),
            ],

            // Customer name
            Text(
              'Tên khách hàng (tuỳ chọn)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'Ghi chú (tuỳ chọn)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú về thanh toán',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 32),

            // Process Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedMethod == null || _isProcessing 
                    ? null 
                    : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing 
                      ? 'Đang xử lý thanh toán...' 
                      : 'Xác nhận thanh toán',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(double totalAmount) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_bar, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  widget.session.tableName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.session.customerName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Khách: ${widget.session.customerName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Amount breakdown
            _buildAmountRow(
              'Tiền bàn',
              widget.session.calculateTableAmount(),
              Colors.blue.shade600,
            ),
            _buildAmountRow(
              'Đồ ăn/uống',
              widget.session.ordersAmount,
              Colors.orange.shade600,
            ),
            const Divider(),
            _buildAmountRow(
              'Tổng cộng',
              totalAmount,
              Colors.green.shade600,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            '${amount.toInt()}K',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCards() {
    return Column(
      children: PaymentMethod.values.map((method) {
        final isSelected = _selectedMethod == method;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _isProcessing ? null : () {
              setState(() {
                _selectedMethod = method;
                // Pre-fill paid amount for cash
                if (method == PaymentMethod.cash) {
                  final totalAmount = widget.session.calculateTotalAmount();
                  _paidAmountController.text = (totalAmount / 1000).ceil().toString();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? method.color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? method.color.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: method.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMethodIcon(method),
                      color: method.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? method.color : Colors.black87,
                          ),
                        ),
                        Text(
                          _getMethodDescription(method),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: method.color,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChangeCalculation(double totalAmount) {
    final paidAmount = (double.tryParse(_paidAmountController.text) ?? 0) * 1000;
    final change = paidAmount - totalAmount;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: change >= 0 ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            change >= 0 ? 'Tiền thối:' : 'Thiếu:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          Text(
            '${change.abs().toInt()}K',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.qr:
        return Icons.qr_code;
      case PaymentMethod.transfer:
        return Icons.account_balance;
    }
  }

  String _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Thanh toán trực tiếp tại quầy';
      case PaymentMethod.card:
        return 'Quẹt thẻ ATM hoặc thẻ tín dụng';
      case PaymentMethod.qr:
        return 'Quét mã QR VNPay/MoMo/ZaloPay';
      case PaymentMethod.transfer:
        return 'Chuyển khoản ngân hàng';
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get paid amount for cash payments
      double? paidAmount;
      if (_selectedMethod == PaymentMethod.cash && _paidAmountController.text.isNotEmpty) {
        paidAmount = (double.tryParse(_paidAmountController.text) ?? 0) * 1000;
        final totalAmount = widget.session.calculateTotalAmount();
        if (paidAmount < totalAmount) {
          throw Exception('Số tiền nhận không đủ để thanh toán');
        }
      }

      final paymentActions = ref.read(paymentActionsProvider);
      await paymentActions.processPaymentAndCompleteSession(
        sessionId: widget.session.id,
        method: _selectedMethod!,
        paidAmount: paidAmount,
        customerName: _customerNameController.text.trim().isEmpty 
            ? null 
            : _customerNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Thanh toán thành công! Phiên chơi đã kết thúc.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to sessions or home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
