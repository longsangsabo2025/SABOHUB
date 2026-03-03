import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../business_types/service/services/bill_service.dart';
import '../../../providers/auth_provider.dart';
import 'dart:typed_data';

/// Manager Upload Bill Page - Manager upload bill và tính commission
class ManagerUploadBillPage extends ConsumerStatefulWidget {
  const ManagerUploadBillPage({super.key});

  @override
  ConsumerState<ManagerUploadBillPage> createState() =>
      _ManagerUploadBillPageState();
}

class _ManagerUploadBillPageState extends ConsumerState<ManagerUploadBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _billService = BillService();

  final _billNumberController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _billDate = DateTime.now();
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _billNumberController.dispose();
    _totalAmountController.dispose();
    _storeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<void> _uploadBill() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider);
    final companyId = user.user?.companyId;
    final userId = user.user?.id ?? '';

    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy company ID')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image nếu có
      String? imageUrl;
      if (_imageBytes != null && _imageFileName != null) {
        final extension = _imageFileName!.split('.').last;
        imageUrl = await _billService.uploadBillImage(
          companyId,
          _billNumberController.text,
          _imageBytes!,
          extension,
        );
      }

      // Create bill
      await _billService.uploadBill(
        companyId: companyId,
        userId: userId,
        billNumber: _billNumberController.text,
        billDate: _billDate,
        totalAmount: double.parse(_totalAmountController.text),
        storeName: _storeNameController.text.isEmpty
            ? null
            : _storeNameController.text,
        billImageUrl: imageUrl,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Upload bill thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Upload Bill'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bill Image
            if (_imageBytes != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload Image Button
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                _imageBytes == null ? 'Chọn Ảnh Bill' : 'Đổi Ảnh',
              ),
            ),

            const SizedBox(height: 24),

            // Bill Number
            TextFormField(
              controller: _billNumberController,
              decoration: const InputDecoration(
                labelText: 'Số Bill *',
                hintText: 'VD: BILL001',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số bill';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Bill Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày Bill'),
              subtitle: Text(
                '${_billDate.day}/${_billDate.month}/${_billDate.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _billDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _billDate = date;
                  });
                }
              },
            ),

            const Divider(),
            const SizedBox(height: 16),

            // Total Amount
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Tổng Tiền *',
                hintText: '1000000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '₫',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tổng tiền';
                }
                if (double.tryParse(value) == null) {
                  return 'Số tiền không hợp lệ';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Store Name (Optional)
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Tên Cửa Hàng',
                hintText: 'Chi nhánh 1',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Notes (Optional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi Chú',
                hintText: 'Thêm ghi chú...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadBill,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '✅ Upload Bill',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
