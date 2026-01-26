import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';

/// Page to record a payment against customer receivables
class ReceivablePaymentPage extends ConsumerStatefulWidget {
  final String? preselectedCustomerId;
  
  const ReceivablePaymentPage({super.key, this.preselectedCustomerId});

  @override
  ConsumerState<ReceivablePaymentPage> createState() => _ReceivablePaymentPageState();
}

class _ReceivablePaymentPageState extends ConsumerState<ReceivablePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedReceivableId;
  String _paymentMethod = 'cash';
  DateTime _paymentDate = DateTime.now();
  
  List<Map<String, dynamic>> _openReceivables = [];
  bool _loadingReceivables = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCustomerId != null) {
      _selectedCustomerId = widget.preselectedCustomerId;
      _loadOpenReceivables(widget.preselectedCustomerId!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadOpenReceivables(String customerId) async {
    setState(() => _loadingReceivables = true);
    try {
      final db = Supabase.instance.client;
      final res = await db
          .from('receivables')
          .select('id, invoice_number, total_amount, paid_amount, due_date')
          .eq('customer_id', customerId)
          .inFilter('status', ['open', 'partial'])
          .order('due_date');
      
      setState(() {
        _openReceivables = List<Map<String, dynamic>>.from(res);
        _loadingReceivables = false;
      });
    } catch (e) {
      setState(() => _loadingReceivables = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải công nợ: $e')),
        );
      }
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      if (companyId == null) throw Exception('User context not found');

      final amount = double.tryParse(_amountController.text) ?? 0;
      final db = Supabase.instance.client;

      // 1. Create Payment Record
      await db.from('payments').insert({
        'company_id': companyId,
        'customer_id': _selectedCustomerId,
        'receivable_id': _selectedReceivableId, // Can be null for general payment
        'amount': amount,
        'payment_date': _paymentDate.toIso8601String(),
        'payment_method': _paymentMethod,
        'reference_number': _referenceController.text,
        'notes': _notesController.text,
        'created_by': userId,
        'status': 'completed',
      });

      // 2. Update Receivable if specific one was selected
      if (_selectedReceivableId != null) {
        // Find the receivable and update paid_amount
        final receivable = _openReceivables.firstWhere(
          (r) => r['id'] == _selectedReceivableId,
          orElse: () => {},
        );
        
        if (receivable.isNotEmpty) {
          final currentPaid = (receivable['paid_amount'] as num?)?.toDouble() ?? 0;
          final totalAmount = (receivable['total_amount'] as num?)?.toDouble() ?? 0;
          final newPaidAmount = currentPaid + amount;
          
          String newStatus = 'partial';
          if (newPaidAmount >= totalAmount) {
            newStatus = 'paid';
          }

          await db.from('receivables').update({
            'paid_amount': newPaidAmount,
            'status': newStatus,
          }).eq('id', _selectedReceivableId!);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận thanh toán thành công')),
        );
        ref.invalidate(receivablesProvider);
        ref.invalidate(overdueReceivablesProvider);
        ref.invalidate(paymentsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider(const CustomerFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi nhận thanh toán'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Khách hàng *'),
                  value: _selectedCustomerId,
                  items: customers.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCustomerId = val;
                      _selectedReceivableId = null;
                      _openReceivables = [];
                    });
                    if (val != null) _loadOpenReceivables(val);
                  },
                  validator: (val) => val == null ? 'Bắt buộc' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Lỗi: $e'),
              ),
              const SizedBox(height: 16),

              // Receivable Selection (if customer selected)
              if (_selectedCustomerId != null) ...[
                const Text('Chọn công nợ cần thanh toán (Tùy chọn)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_loadingReceivables)
                  const Center(child: CircularProgressIndicator())
                else if (_openReceivables.isEmpty)
                  const Text('Không có công nợ mở', style: TextStyle(color: Colors.grey))
                else
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _openReceivables.length,
                      itemBuilder: (context, index) {
                        final rec = _openReceivables[index];
                        final remaining = (rec['total_amount'] as num).toDouble() -
                            ((rec['paid_amount'] as num?)?.toDouble() ?? 0);
                        return RadioListTile<String>(
                          title: Text(rec['invoice_number'] ?? 'Công nợ #${rec['id'].substring(0, 8)}'),
                          subtitle: Text('Còn nợ: ${remaining.toStringAsFixed(0)}đ'),
                          value: rec['id'],
                          groupValue: _selectedReceivableId,
                          onChanged: (val) => setState(() => _selectedReceivableId = val),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày thanh toán'),
                subtitle: Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _paymentDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // Method
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Phương thức'),
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Số tiền thu (VND) *'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Bắt buộc';
                  if (double.tryParse(val) == null) return 'Số không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: 'Mã giao dịch / Tham chiếu'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Xác nhận thanh toán'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
