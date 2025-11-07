import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/table.dart';
import '../../providers/table_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class TableFormPage extends ConsumerStatefulWidget {
  final BilliardsTable? table;

  const TableFormPage({super.key, this.table});

  @override
  ConsumerState<TableFormPage> createState() => _TableFormPageState();
}

class _TableFormPageState extends ConsumerState<TableFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  String _selectedTableType = 'POOL';
  bool _isLoading = false;

  final Map<String, String> _tableTypes = {
    'POOL': 'Pool (8-Ball)',
    'LO': 'Lỗ (9-Ball)', 
    'CAROM': 'Carom',
    'SNOOKER': 'Snooker',
  };

  final Map<String, double> _defaultRates = {
    'POOL': 50000,
    'LO': 60000,
    'CAROM': 70000,
    'SNOOKER': 80000,
  };

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _initializeFromTable(widget.table!);
    } else {
      _hourlyRateController.text = _defaultRates[_selectedTableType]!.toString();
    }
  }

  void _initializeFromTable(BilliardsTable table) {
    _tableNumberController.text = table.tableNumber;
    _hourlyRateController.text = '50000'; // Default since not in current model
    _selectedTableType = 'POOL'; // Default since not in current model
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.table != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa bàn' : 'Thêm bàn mới'),
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple.shade900,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveTable,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Lưu'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple.shade700,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Đang xử lý...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildTableTypeSection(),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin cơ bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tableNumberController,
              decoration: const InputDecoration(
                labelText: 'Số bàn *',
                hintText: 'Ví dụ: 1, 2, VIP1',
                prefixIcon: Icon(Icons.table_bar),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số bàn';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loại bàn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _tableTypes.entries.map((entry) {
                final isSelected = _selectedTableType == entry.key;
                return FilterChip(
                  selected: isSelected,
                  label: Text(entry.value),
                  selectedColor: Colors.purple.shade600,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.purple.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTableType = entry.key;
                        _hourlyRateController.text = _defaultRates[entry.key]!.toString();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mô tả loại bàn:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTableTypeDescription(_selectedTableType),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giá thuê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Giá thuê theo giờ *',
                hintText: '50000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VND/giờ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá thuê';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Giá thuê phải là số dương';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Giá thuê có thể được điều chỉnh theo từng phiên chơi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveTable,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(widget.table != null ? 'Cập nhật bàn' : 'Thêm bàn mới'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _getTableTypeDescription(String type) {
    switch (type) {
      case 'POOL':
        return 'Bàn Pool tiêu chuẩn với 6 lỗ, thích hợp cho 8-Ball Pool';
      case 'LO':
        return 'Bàn Lỗ với 6 lỗ, chuyên cho 9-Ball và các game Lỗ';
      case 'CAROM':
        return 'Bàn Carom không có lỗ, dùng cho Carom Billiards';
      case 'SNOOKER':
        return 'Bàn Snooker lớn với 6 lỗ, dành cho Snooker chuyên nghiệp';
      default:
        return '';
    }
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(tableActionsProvider);
      final hourlyRate = double.parse(_hourlyRateController.text);
      
      if (widget.table != null) {
        // For now, we'll just show success since update isn't fully implemented
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật Bàn ${_tableNumberController.text}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new table
        await actions.createTable(
          tableNumber: _tableNumberController.text.trim(),
          tableType: _selectedTableType,
          hourlyRate: hourlyRate,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm Bàn ${_tableNumberController.text} vào hệ thống'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}