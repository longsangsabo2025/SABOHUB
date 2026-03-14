import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../widgets/customer_avatar.dart';

Future<void> showAddManualReceivableDialog({
  required BuildContext context,
  required String companyId,
  required VoidCallback onSuccess,
}) async {
  final supabase = Supabase.instance.client;

  // Load ALL customers (not just those with debt)
  List<Map<String, dynamic>> allCustomers = [];
  try {
    final data = await supabase
        .from('customers')
        .select('id, name, code, phone, total_debt')
        .eq('company_id', companyId)
        .order('name');
    allCustomers = List<Map<String, dynamic>>.from(data);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách khách hàng: $e'), backgroundColor: Colors.red),
      );
    }
    return;
  }

  if (allCustomers.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có khách hàng nào trong hệ thống'), backgroundColor: Colors.orange),
      );
    }
    return;
  }

  final amountController = TextEditingController();
  final refController = TextEditingController();
  final noteController = TextEditingController(text: 'Công nợ đầu kỳ');
  final customerSearchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  Map<String, dynamic>? selectedCustomer;
  DateTime invoiceDate = DateTime.now();
  DateTime? dueDate;
  bool isSubmitting = false;

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final filtered = customerSearchController.text.isEmpty
            ? allCustomers
            : allCustomers.where((c) {
                final q = customerSearchController.text.toLowerCase();
                return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
                    (c['code'] ?? '').toString().toLowerCase().contains(q) ||
                    (c['phone'] ?? '').toString().toLowerCase().contains(q);
              }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.history_edu, color: Colors.blue.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nhập công nợ đầu kỳ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Ghi nhận công nợ từ trước khi sử dụng hệ thống',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Customer Selection ----
                      const Text('Chọn khách hàng *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),

                      if (selectedCustomer != null) ...[
                        // Selected customer card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              CustomerAvatar(
                                seed: selectedCustomer!['name'] ?? 'K',
                                radius: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(selectedCustomer!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '${selectedCustomer!['code'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if ((selectedCustomer!['total_debt'] ?? 0).toDouble() > 0)
                                      Text(
                                        'Nợ hiện tại: ${currencyFormat.format((selectedCustomer!['total_debt'] ?? 0).toDouble())}',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 20),
                                tooltip: 'Đổi khách hàng',
                                onPressed: () => setDialogState(() => selectedCustomer = null),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Customer search
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: customerSearchController,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, mã, SĐT...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Customer list
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length.clamp(0, 50),
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final c = filtered[index];
                              return ListTile(
                                dense: true,
                                leading: CustomerAvatar(
                                  seed: c['name'] ?? 'K',
                                  radius: 16,
                                ),
                                title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                subtitle: Text('${c['code'] ?? ''} • ${c['phone'] ?? ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                trailing: (c['total_debt'] ?? 0).toDouble() > 0
                                    ? Text(currencyFormat.format((c['total_debt'] ?? 0).toDouble()),
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade600))
                                    : null,
                                onTap: () {
                                  setDialogState(() {
                                    selectedCustomer = c;
                                    customerSearchController.clear();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ---- Amount ----
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số tiền công nợ *',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixText: '₫',
                          helperText: 'Tổng số tiền khách hàng còn nợ',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Dates row ----
                      Row(
                        children: [
                          // Invoice date
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: invoiceDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Localizations.override(
                                      context: context,
                                      locale: const Locale('vi'),
                                      delegates: const [
                                        GlobalMaterialLocalizations.delegate,
                                        GlobalWidgetsLocalizations.delegate,
                                        GlobalCupertinoLocalizations.delegate,
                                      ],
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() => invoiceDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Ngày phát sinh', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          Text(DateFormat('dd/MM/yyyy').format(invoiceDate),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Due date
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Localizations.override(
                                      context: context,
                                      locale: const Locale('vi'),
                                      delegates: const [
                                        GlobalMaterialLocalizations.delegate,
                                        GlobalWidgetsLocalizations.delegate,
                                        GlobalCupertinoLocalizations.delegate,
                                      ],
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() => dueDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                      ? Colors.red.shade300
                                      : Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                  color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                      ? Colors.red.shade50 : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event, size: 18,
                                        color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                            ? Colors.red.shade600 : Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Hạn thanh toán', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          Text(
                                            dueDate != null
                                                ? DateFormat('dd/MM/yyyy').format(dueDate!)
                                                : 'Chưa chọn',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: dueDate != null && dueDate!.isBefore(DateTime.now())
                                                  ? Colors.red.shade700 : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (dueDate != null && dueDate!.isBefore(DateTime.now())) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text('Hạn thanh toán đã qua → sẽ ghi nhận là "quá hạn"',
                                style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ---- Reference number ----
                      TextField(
                        controller: refController,
                        decoration: InputDecoration(
                          labelText: 'Số hóa đơn / mã tham chiếu',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'VD: HD-001, INV-2024-001... (để trống sẽ tự tạo)',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Notes ----
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Ghi chú',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ---- Info box ----
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Công nợ đầu kỳ là khoản nợ phát sinh trước khi sử dụng hệ thống. '
                                'Sau khi nhập, khoản nợ sẽ xuất hiện trong danh sách công nợ và '
                                'có thể thu tiền bình thường.',
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // space for button
                    ],
                  ),
                ),
              ),

              // ---- Submit button ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : () async {
                      // Validate
                      if (selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn khách hàng'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final digitsOnly = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final amount = digitsOnly.isEmpty ? 0 : (double.tryParse(digitsOnly) ?? 0);
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        final result = await supabase.rpc('create_manual_receivable', params: {
                          'p_company_id': companyId,
                          'p_customer_id': selectedCustomer!['id'],
                          'p_amount': amount,
                          'p_invoice_date': DateFormat('yyyy-MM-dd').format(invoiceDate),
                          'p_due_date': dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : null,
                          'p_reference_number': refController.text.isNotEmpty ? refController.text : null,
                          'p_notes': noteController.text.isNotEmpty ? noteController.text : null,
                        });

                        final res = result as Map<String, dynamic>;
                        if (res['success'] == true) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Đã ghi nhận công nợ ${currencyFormat.format(amount)} cho ${res['customer_name']}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          // Refresh the parent list
                          onSuccess();
                        } else {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${res['error']}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(isSubmitting ? 'Đang lưu...' : 'Ghi nhận công nợ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
