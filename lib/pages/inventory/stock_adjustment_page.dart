import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/odori_providers.dart';

class StockAdjustmentPage extends ConsumerStatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  ConsumerState<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends ConsumerState<StockAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String _movementType = 'in';
  String? _selectedProductId;
  bool _isLoading = false;

  final List<Map<String, String>> _movementTypes = [
    {'value': 'in', 'label': 'Nhập kho'},
    {'value': 'out', 'label': 'Xuất kho'},
    {'value': 'adjustment', 'label': 'Điều chỉnh'},
  ];

  final List<String> _commonReasons = [
    'Nhập hàng từ nhà cung cấp',
    'Xuất hàng bán',
    'Kiểm kê điều chỉnh',
    'Hàng bị hỏng/hết hạn',
    'Trả hàng từ khách',
    'Chuyển kho',
    'Khác',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      // Get user's company_id
      final employee = await supabase
          .from('employees')
          .select('company_id')
          .eq('user_id', user.id)
          .single();

      final companyId = employee['company_id'];
      final quantity = int.parse(_quantityController.text);

      // Insert inventory movement
      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'product_id': _selectedProductId,
        'type': _movementType,
        'reason': _reasonController.text.isNotEmpty ? _reasonController.text : null,
        'quantity': quantity,
        'before_quantity': 0, // Could fetch current stock if needed
        'after_quantity': _movementType == 'out' ? -quantity : quantity, // Simplified
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_by': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_movementType == 'in' 
                ? 'Đã nhập kho thành công' 
                : _movementType == 'out' 
                    ? 'Đã xuất kho thành công'
                    : 'Đã điều chỉnh kho thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(const ProductFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập/Xuất Kho'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Movement Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loại giao dịch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: _movementTypes.map((type) {
                        IconData icon;
                        switch (type['value']) {
                          case 'in':
                            icon = Icons.arrow_downward;
                            break;
                          case 'out':
                            icon = Icons.arrow_upward;
                            break;
                          default:
                            icon = Icons.sync;
                        }
                        return ButtonSegment(
                          value: type['value']!,
                          label: Text(type['label']!),
                          icon: Icon(icon),
                        );
                      }).toList(),
                      selected: {_movementType},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _movementType = selected.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2),
                        const SizedBox(width: 8),
                        const Text(
                          'Sản phẩm *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    productsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Text('Lỗi: $error'),
                      data: (products) {
                        if (products.isEmpty) {
                          return const Text(
                            'Chưa có sản phẩm nào. Vui lòng thêm sản phẩm trước.',
                            style: TextStyle(color: Colors.orange),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedProductId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Chọn sản phẩm',
                          ),
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product.id,
                              child: Text(product.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProductId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn sản phẩm';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.numbers),
                        const SizedBox(width: 8),
                        const Text(
                          'Số lượng *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập số lượng',
                        suffixText: 'đơn vị',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số lượng';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Số lượng phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        const Text(
                          'Lý do',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonReasons.map((reason) {
                        final isSelected = _reasonController.text == reason;
                        return ChoiceChip(
                          label: Text(reason),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _reasonController.text = reason;
                              } else {
                                _reasonController.clear();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Hoặc nhập lý do khác',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes),
                        const SizedBox(width: 8),
                        const Text(
                          'Ghi chú',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Thêm ghi chú (nếu có)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _movementType == 'in'
                      ? Colors.green
                      : _movementType == 'out'
                          ? Colors.red
                          : Colors.orange,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_movementType == 'in'
                              ? Icons.arrow_downward
                              : _movementType == 'out'
                                  ? Icons.arrow_upward
                                  : Icons.sync),
                          const SizedBox(width: 8),
                          Text(
                            _movementType == 'in'
                                ? 'XÁC NHẬN NHẬP KHO'
                                : _movementType == 'out'
                                    ? 'XÁC NHẬN XUẤT KHO'
                                    : 'XÁC NHẬN ĐIỀU CHỈNH',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
