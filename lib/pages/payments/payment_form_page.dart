import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  const PaymentFormPage({super.key});

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController(); // e.g. Transaction ID

  String? _selectedCustomerId;
  // In a real app, you might want to select specific Invoices/Receivables to pay against.
  // For simplicity V1, we just record a payment from a Customer.
  
  String _paymentMethod = 'cash'; // cash, bank_transfer
  DateTime _paymentDate = DateTime.now();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submitFormat() async {
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

      final db = Supabase.instance.client;

      // Insert Payment Record
      await db.from('payments').insert({
        'company_id': companyId,
        'customer_id': _selectedCustomerId,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'payment_date': _paymentDate.toIso8601String(),
        'payment_method': _paymentMethod,
        'reference_number': _referenceController.text,
        'notes': _notesController.text,
        'created_by': userId,
        'status': 'completed', // Assuming immediate completion for manual entry
      });

      // Optional: Update Receivables logic would go here (e.g. decrease debt)
      // This usually requires a backend trigger or complex client logic to find open invoices.
      // We will skip auto-allocation for now unless requested.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu phiếu thu thành công')),
        );
        ref.invalidate(paymentsProvider); // Refresh list
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
    // Fetch customers for dropdown
    final customersAsync = ref.watch(customersProvider(const CustomerFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phiếu Thu (Thanh toán)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
                  onChanged: (val) => setState(() => _selectedCustomerId = val),
                  validator: (val) => val == null ? 'Bắt buộc' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Lỗi tải khách hàng: $e'),
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày thu tiền'),
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

              // Method Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Phương thức thanh toán'),
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Chuyển khoản ngân hàng')),
                  DropdownMenuItem(value: 'check', child: Text('Séc')),
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
                  if (double.tryParse(val) == null) return 'Phải là số';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reference
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: 'Mã tham chiếu (Số hóa đơn/Mã GD)'),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submitFormat,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Lưu Phiếu Thu (Payment)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
