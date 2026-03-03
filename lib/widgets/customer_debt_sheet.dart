import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../business_types/distribution/models/odori_customer.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;
final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

/// Widget to display and manage customer debt
class CustomerDebtSheet extends ConsumerStatefulWidget {
  final OdoriCustomer customer;
  final VoidCallback? onChanged;

  const CustomerDebtSheet({
    super.key,
    required this.customer,
    this.onChanged,
  });

  @override
  ConsumerState<CustomerDebtSheet> createState() => _CustomerDebtSheetState();
}

class _CustomerDebtSheetState extends ConsumerState<CustomerDebtSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Debt summary
  double _totalDebt = 0;
  int _unpaidOrderCount = 0;
  double _totalOrders = 0;
  double _totalPaid = 0;

  // Unpaid orders
  List<Map<String, dynamic>> _unpaidOrders = [];

  // Payment history
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load unpaid orders
      final ordersResponse = await supabase
          .from('sales_orders')
          .select('id, order_number, order_date, total, paid_amount, payment_status, status, due_date')
          .eq('customer_id', widget.customer.id)
          .neq('status', 'cancelled')
          .order('order_date', ascending: false);

      // Load payments
      final paymentsResponse = await supabase
          .from('payments')
          .select('id, payment_number, payment_date, amount, payment_method, status, notes, reference_number')
          .eq('customer_id', widget.customer.id)
          .order('payment_date', ascending: false)
          .limit(50);

      // Also check customer_payments table
      final customerPaymentsResponse = await supabase
          .from('customer_payments')
          .select('id, amount, payment_date, payment_method, notes, reference')
          .eq('customer_id', widget.customer.id)
          .order('payment_date', ascending: false)
          .limit(50);

      final orders = List<Map<String, dynamic>>.from(ordersResponse);
      final payments = List<Map<String, dynamic>>.from(paymentsResponse);
      final customerPayments = List<Map<String, dynamic>>.from(customerPaymentsResponse);

      // Calculate totals
      double totalOrders = 0;
      double totalPaid = 0;
      List<Map<String, dynamic>> unpaid = [];

      for (final order in orders) {
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0;
        totalOrders += total;
        totalPaid += paidAmount;

        if (total > paidAmount) {
          unpaid.add(order);
        }
      }

      // Combine payments from both tables
      final allPayments = <Map<String, dynamic>>[];
      for (final p in payments) {
        allPayments.add({
          'id': p['id'],
          'payment_number': p['payment_number'],
          'payment_date': p['payment_date'],
          'amount': p['amount'],
          'payment_method': p['payment_method'],
          'status': p['status'],
          'notes': p['notes'],
          'reference': p['reference_number'],
          'source': 'payments',
        });
      }
      for (final p in customerPayments) {
        allPayments.add({
          'id': p['id'],
          'payment_date': p['payment_date'],
          'amount': p['amount'],
          'payment_method': p['payment_method'],
          'notes': p['notes'],
          'reference': p['reference'],
          'source': 'customer_payments',
        });
      }

      // Sort by date
      allPayments.sort((a, b) {
        final dateA = DateTime.tryParse(a['payment_date']?.toString() ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['payment_date']?.toString() ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _totalOrders = totalOrders;
        _totalPaid = totalPaid;
        _totalDebt = totalOrders - totalPaid;
        _unpaidOrderCount = unpaid.length;
        _unpaidOrders = unpaid;
        _payments = allPayments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showRecordPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        customer: widget.customer,
        companyId: ref.read(authProvider).user?.companyId ?? '',
        unpaidOrders: _unpaidOrders,
        currentDebt: _totalDebt,
        onSaved: () {
          _loadData();
          widget.onChanged?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance_wallet, color: Colors.red.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Công nợ khách hàng',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.customer.name,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                // Debt summary cards
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Tổng công nợ',
                          _currencyFormat.format(_totalDebt),
                          _totalDebt > 0 ? Colors.red : Colors.green,
                          Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Đơn chưa TT',
                          '$_unpaidOrderCount đơn',
                          Colors.orange,
                          Icons.receipt_long,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat('Tổng mua', _currencyFormat.format(_totalOrders)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniStat('Đã thanh toán', _currencyFormat.format(_totalPaid)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.red.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red.shade700,
            tabs: const [
              Tab(text: 'Đơn chưa thanh toán'),
              Tab(text: 'Lịch sử thu tiền'),
            ],
          ),

          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                              const SizedBox(height: 8),
                              Text('Lỗi: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUnpaidOrdersTab(),
                          _buildPaymentsTab(),
                        ],
                      ),
          ),

          // Record payment button
          if (!_isLoading && _totalDebt > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showRecordPaymentDialog,
                  icon: const Icon(Icons.payments),
                  label: const Text('Ghi nhận thanh toán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildUnpaidOrdersTab() {
    if (_unpaidOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có công nợ!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Khách hàng đã thanh toán hết',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _unpaidOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _unpaidOrders[index];
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0;
        final remaining = total - paidAmount;
        final orderDate = DateTime.tryParse(order['order_date']?.toString() ?? '');
        final dueDate = DateTime.tryParse(order['due_date']?.toString() ?? '');
        final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
              width: isOverdue ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      order['order_number'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'QUÁ HẠN',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (orderDate != null)
                      Text('Ngày đặt: ${DateFormat('dd/MM/yyyy').format(orderDate)}'),
                    if (dueDate != null)
                      Text(
                        'Hạn TT: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                        style: TextStyle(color: isOverdue ? Colors.red : null),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng đơn', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Đã TT', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_currencyFormat.format(paidAmount), 
                             style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green.shade600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Còn nợ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(_currencyFormat.format(remaining),
                             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.payment, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Chưa có lịch sử thu tiền', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final paymentDate = DateTime.tryParse(payment['payment_date']?.toString() ?? '');
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['payment_number'] ?? 'Thanh toán',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (paymentDate != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(paymentDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    if (payment['payment_method'] != null)
                      Text(
                        _getPaymentMethodText(payment['payment_method']),
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                      ),
                  ],
                ),
              ),
              Text(
                _currencyFormat.format(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPaymentMethodText(String? method) {
    switch (method) {
      case 'cash': return 'Tiền mặt';
      case 'bank_transfer': return 'Chuyển khoản';
      case 'card': return 'Thẻ';
      case 'momo': return 'MoMo';
      case 'zalo_pay': return 'ZaloPay';
      default: return method ?? 'Khác';
    }
  }
}

/// Dialog to record a payment
class RecordPaymentDialog extends StatefulWidget {
  final OdoriCustomer customer;
  final String companyId;
  final List<Map<String, dynamic>> unpaidOrders;
  final double currentDebt;
  final VoidCallback onSaved;

  const RecordPaymentDialog({
    super.key,
    required this.customer,
    required this.companyId,
    required this.unpaidOrders,
    required this.currentDebt,
    required this.onSaved,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Tiền mặt'},
    {'value': 'bank_transfer', 'label': 'Chuyển khoản'},
    {'value': 'momo', 'label': 'MoMo'},
    {'value': 'zalo_pay', 'label': 'ZaloPay'},
    {'value': 'card', 'label': 'Thẻ'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền phải lớn hơn 0'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate payment number
      final now = DateTime.now();
      final paymentNumber = 'PAY${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch % 10000}';

      // Insert payment
      await supabase.from('payments').insert({
        'company_id': widget.companyId,
        'customer_id': widget.customer.id,
        'payment_number': paymentNumber,
        'payment_date': now.toIso8601String(),
        'amount': amount,
        'payment_method': _paymentMethod,
        'reference_number': _referenceController.text.isNotEmpty ? _referenceController.text.trim() : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        'status': 'completed',
      });

      // Update paid_amount on orders (distribute payment across unpaid orders)
      double remainingPayment = amount;
      for (final order in widget.unpaidOrders) {
        if (remainingPayment <= 0) break;

        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final currentPaid = (order['paid_amount'] as num?)?.toDouble() ?? 0;
        final orderDebt = total - currentPaid;

        if (orderDebt > 0) {
          final payForThisOrder = remainingPayment >= orderDebt ? orderDebt : remainingPayment;
          final newPaidAmount = currentPaid + payForThisOrder;

          await supabase.from('sales_orders').update({
            'paid_amount': newPaidAmount,
            'payment_status': newPaidAmount >= total ? 'paid' : 'partial',
          }).eq('id', order['id']);

          remainingPayment -= payForThisOrder;
        }
      }

      // Update customer total_debt
      final newDebt = widget.currentDebt - amount;
      await supabase.from('customers').update({
        'total_debt': newDebt > 0 ? newDebt : 0,
      }).eq('id', widget.customer.id);

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã ghi nhận thanh toán ${_currencyFormat.format(amount)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  const Text('Ghi nhận thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Công nợ hiện tại:'),
                    Text(
                      _currencyFormat.format(widget.currentDebt),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền thanh toán *',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'đ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số tiền' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Phương thức',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                items: _paymentMethods.map((m) {
                  return DropdownMenuItem(value: m['value'], child: Text(m['label']!));
                }).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Mã giao dịch / Tham chiếu',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'VD: Mã chuyển khoản...',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Xác nhận thanh toán'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
