import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../providers/auth_provider.dart';

/// Sheet điều chỉnh tồn kho
class StockAdjustSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSuccess;

  const StockAdjustSheet({
    super.key,
    required this.item,
    required this.onSuccess,
  });

  @override
  ConsumerState<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<StockAdjustSheet> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _adjustType = 'in';
  String _reason = '';
  bool _isLoading = false;

  final Map<String, List<String>> _reasonsByType = {
    'in': ['Nhập hàng từ nhà cung cấp', 'Trả hàng từ khách', 'Điều chỉnh sau kiểm kê', 'Khác'],
    'out': ['Xuất hàng bán', 'Hàng bị hỏng/hết hạn', 'Trả nhà cung cấp', 'Chuyển kho', 'Khác'],
    'adjustment': ['Kiểm kê điều chỉnh', 'Sai lệch hệ thống', 'Khác'],
  };

  @override
  void initState() {
    super.initState();
    _reason = _reasonsByType['in']!.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _currentStock => widget.item['quantity'] as int? ?? 0;
  Map<String, dynamic>? get _product => widget.item['products'] as Map<String, dynamic>?;

  Future<void> _submit() async {
    final qtyStr = _quantityController.text.trim();
    if (qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final qty = int.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng phải lớn hơn 0'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_adjustType == 'out' && qty > _currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đủ hàng trong kho (tồn: $_currentStock)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;

      if (companyId == null) throw Exception('Vui lòng đăng nhập lại');

      final supabase = Supabase.instance.client;
      final productId = _product?['id'];
      final warehouseId = widget.item['warehouse_id'];

      int newQty;
      if (_adjustType == 'in') {
        newQty = _currentStock + qty;
      } else if (_adjustType == 'out') {
        newQty = _currentStock - qty;
      } else {
        newQty = qty;
      }

      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'warehouse_id': warehouseId,
        'product_id': productId,
        'type': _adjustType == 'adjustment' ? 'adjustment' : _adjustType,
        'reason': _reason,
        'quantity': _adjustType == 'adjustment' ? (qty - _currentStock).abs() : qty,
        'before_quantity': _currentStock,
        'after_quantity': newQty,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_by': userId,
      });

      await supabase
          .from('inventory')
          .update({'quantity': newQty})
          .eq('id', widget.item['id']);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();

        String message;
        if (_adjustType == 'in') {
          message = 'Đã nhập thêm $qty ${_product?['unit'] ?? 'đơn vị'}';
        } else if (_adjustType == 'out') {
          message = 'Đã xuất $qty ${_product?['unit'] ?? 'đơn vị'}';
        } else {
          message = 'Đã điều chỉnh tồn kho thành $newQty';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '$_currentStock',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product?['name'] ?? 'Sản phẩm',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tồn kho hiện tại: $_currentStock ${_product?['unit'] ?? 'đơn vị'}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Loại điều chỉnh',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTypeChip('in', 'Nhập kho', Icons.add_circle_outline, Colors.green),
                    const SizedBox(width: 8),
                    _buildTypeChip('out', 'Xuất kho', Icons.remove_circle_outline, Colors.red),
                    const SizedBox(width: 8),
                    _buildTypeChip('adjustment', 'Đặt SL', Icons.edit_outlined, Colors.blue),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  _adjustType == 'adjustment' ? 'Số lượng mới *' : 'Số lượng *',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _adjustType == 'adjustment' ? 'Nhập số lượng tồn kho mới' : 'Nhập số lượng',
                    prefixIcon: Icon(
                      _adjustType == 'in' ? Icons.add : _adjustType == 'out' ? Icons.remove : Icons.edit,
                      color: _adjustType == 'in' ? Colors.green : _adjustType == 'out' ? Colors.red : Colors.blue,
                    ),
                    suffixText: _product?['unit'] ?? 'đơn vị',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Lý do',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_reasonsByType[_adjustType] ?? []).map((reason) {
                    final isSelected = _reason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _reason = reason);
                        }
                      },
                      selectedColor: _adjustType == 'in'
                          ? Colors.green.shade100
                          : _adjustType == 'out'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (_adjustType == 'in'
                                ? Colors.green.shade800
                                : _adjustType == 'out'
                                    ? Colors.red.shade800
                                    : Colors.blue.shade800)
                            : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Ghi chú (tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Đang xử lý...' : 'Xác nhận',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adjustType == 'in'
                        ? Colors.green
                        : _adjustType == 'out'
                            ? Colors.red
                            : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _adjustType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _adjustType = type;
            _reason = _reasonsByType[type]?.first ?? '';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
