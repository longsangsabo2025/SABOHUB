import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../providers/auth_provider.dart';
import '../../../../../services/image_upload_service.dart';
import '../../../../../widgets/customer_avatar.dart';

void showReceivablePaymentDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> customer,
  required Future<void> Function() onSuccess,
}) {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final referenceController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final debt = (customer['total_debt'] ?? 0).toDouble();
  String selectedMethod = 'cash';
  XFile? proofImage;
  Uint8List? proofImageBytes;
  bool isUploading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setDialogState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ghi nhận thanh toán',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CustomerAvatar(
                      seed: customer['name'] ?? 'K',
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Công nợ: ${currencyFormat.format(debt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Hình thức thanh toán',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodChip(
                    'Tiền mặt',
                    'cash',
                    selectedMethod,
                    Icons.money,
                    Colors.green,
                    (v) => setDialogState(() => selectedMethod = v),
                  ),
                  const SizedBox(width: 8),
                  _buildMethodChip(
                    'Chuyển khoản',
                    'transfer',
                    selectedMethod,
                    Icons.account_balance,
                    Colors.blue,
                    (v) => setDialogState(() => selectedMethod = v),
                  ),
                  const SizedBox(width: 8),
                  _buildMethodChip(
                    'Khác',
                    'other',
                    selectedMethod,
                    Icons.more_horiz,
                    Colors.grey,
                    (v) => setDialogState(() => selectedMethod = v),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền thanh toán *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: '₫',
                  helperText: 'Công nợ hiện tại: ${currencyFormat.format(debt)}',
                ),
              ),

              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (debt > 0)
                    _buildQuickAmountChip(
                      'Trả hết',
                      debt,
                      amountController,
                      () => setDialogState(() {}),
                    ),
                  if (debt >= 1000000)
                    _buildQuickAmountChip(
                      '1 triệu',
                      1000000,
                      amountController,
                      () => setDialogState(() {}),
                    ),
                  if (debt >= 500000)
                    _buildQuickAmountChip(
                      '500K',
                      500000,
                      amountController,
                      () => setDialogState(() {}),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              if (selectedMethod == 'transfer') ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'Mã giao dịch / Số tham chiếu',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Nhập mã GD ngân hàng để đối soát',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ảnh chứng minh chuyển khoản',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (proofImageBytes != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                proofImageBytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setDialogState(() {
                                  proofImage = null;
                                  proofImageBytes = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImageUploadService();
                                  final file = await picker.pickFromGallery();
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() {
                                      proofImage = file;
                                      proofImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text(
                                  'Thư viện',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImageUploadService();
                                  final file = await picker.pickFromCamera();
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() {
                                      proofImage = file;
                                      proofImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text(
                                  'Chụp ảnh',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],

              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final digitsOnly = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    final amount = digitsOnly.isEmpty ? 0 : (double.tryParse(digitsOnly) ?? 0);
                    if (amount <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập số tiền hợp lệ'),
                        ),
                      );
                      return;
                    }

                    try {
                      setDialogState(() => isUploading = true);
                      final authState = ref.read(authProvider);
                      final companyId = authState.user?.companyId;
                      final userId = authState.user?.id;
                      if (companyId == null) return;

                      String? proofImageUrl;
                      if (proofImage != null && selectedMethod == 'transfer') {
                        final uploadService = ImageUploadService();
                        proofImageUrl = await uploadService.uploadPaymentProof(
                          imageFile: proofImage!,
                          companyId: companyId,
                        );
                      }

                      final supabase = Supabase.instance.client;
                      await supabase.from('customer_payments').insert({
                        'company_id': companyId,
                        'customer_id': customer['id'],
                        'amount': amount,
                        'payment_date': DateTime.now().toIso8601String(),
                        'payment_method': selectedMethod,
                        'reference': referenceController.text.isNotEmpty
                            ? referenceController.text
                            : null,
                        'notes': noteController.text,
                        'created_by': userId,
                        if (proofImageUrl != null)
                          'proof_image_url': proofImageUrl,
                      });

                      final newDebt = (debt - amount).clamp(0, double.infinity);
                      await supabase.from('customers').update({
                        'total_debt': newDebt,
                      }).eq('id', customer['id']);

                      var remaining = amount;
                      final unpaidOrders = await supabase
                          .from('sales_orders')
                          .select('id, total, paid_amount, payment_status')
                          .eq('customer_id', customer['id'])
                          .eq('company_id', companyId)
                          .neq('payment_status', 'paid')
                          .order('created_at', ascending: true);

                      for (final order in unpaidOrders) {
                        if (remaining <= 0) break;
                        final orderTotal = (order['total'] ?? 0).toDouble();
                        final orderPaid = (order['paid_amount'] ?? 0).toDouble();
                        final orderRemaining = orderTotal - orderPaid;

                        if (orderRemaining <= 0) continue;

                        final applyAmount =
                            remaining >= orderRemaining ? orderRemaining : remaining;
                        final newPaid = orderPaid + applyAmount;
                        final newStatus = newPaid >= orderTotal ? 'paid' : 'partial';

                        await supabase.from('sales_orders').update({
                          'paid_amount': newPaid,
                          'payment_status': newStatus,
                        }).eq('id', order['id']);

                        remaining -= applyAmount;
                      }

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        await onSuccess();
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                Text('Đã ghi nhận ${currencyFormat.format(amount)}'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(isUploading ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN THANH TOÁN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildMethodChip(
  String label,
  String value,
  String selected,
  IconData icon,
  Color color,
  Function(String) onTap,
) {
  final isSelected = value == selected;
  return Expanded(
    child: GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuickAmountChip(
  String label,
  double amount,
  TextEditingController controller,
  VoidCallback onTap,
) {
  return ActionChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    onPressed: () {
      controller.text = amount.toStringAsFixed(0);
      onTap();
    },
    backgroundColor: Colors.blue.shade50,
    side: BorderSide(color: Colors.blue.shade200),
  );
}
