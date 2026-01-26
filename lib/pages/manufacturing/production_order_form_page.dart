import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';

class ProductionOrderFormPage extends ConsumerStatefulWidget {
  const ProductionOrderFormPage({super.key});

  @override
  ConsumerState<ProductionOrderFormPage> createState() => _ProductionOrderFormPageState();
}

class _ProductionOrderFormPageState extends ConsumerState<ProductionOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedBomId; 
  DateTime _startDate = DateTime.now();

  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitFormat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      if (companyId == null) throw Exception('User context not found');

      final quantity = int.parse(_quantityController.text);
      final db = Supabase.instance.client;

      // Create Production Order (Standard table: 'manufacturing_production_orders')
      // Note: Assuming table names based on `manufacturing_models.dart` or standard naming.
      // We will check the model context if needed, but let's stick to standard names.
      
      final orderData = {
        'company_id': companyId,
        'product_id': _selectedProductId,
        'quantity': quantity,
        'status': 'planned', // Default status
        'start_date': _startDate.toIso8601String(),
        'bom_id': _selectedBomId, // Can be null if manual
        'notes': _notesController.text,
        'created_by': userId,
        'order_number': 'PO-${DateTime.now().millisecondsSinceEpoch}', // Simple auto-gen
      };

      await db.from('manufacturing_production_orders').insert(orderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo lệnh sản xuất')),
        );
        Navigator.pop(context);
        // We might want to invalidate a provider if one existed for production orders
        // ex: ref.invalidate(productionOrdersProvider);
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
    // We need products. Reuse existing productsProvider.
    final productsAsync = ref.watch(productsProvider(const ProductFilters()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Lệnh Sản Xuất'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product Selection
              productsAsync.when(
                data: (products) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sản phẩm cần sản xuất *'),
                  value: _selectedProductId,
                  items: products.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = val;
                      final prod = products.firstWhere((p) => p.id == val);
                      _selectedProductName = prod.name;
                      // Logic to fetch BOM for this product could go here
                      // _loadBomForProduct(val);
                    });
                  },
                  validator: (val) => val == null ? 'Bắt buộc' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Lỗi tải sản phẩm: $e'),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng sản xuất *'),
                keyboardType: TextInputType.number,
                 validator: (val) {
                  if (val == null || val.isEmpty) return 'Bắt buộc';
                  if (int.tryParse(val) == null) return 'Phải là số nguyên';
                  if (int.parse(val) <= 0) return 'Phải lớn hơn 0';
                  return null;
                },
              ),
               const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày bắt đầu dự kiến'),
                subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // BOM Selection (Optional / Advanced)
              // For V1, we can skip or just show a placeholder if no BOM API ready.
              // Assuming manual for now.

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Ghi chú kỹ thuật'),
                maxLines: 3,
              ),
               const SizedBox(height: 24),

               ElevatedButton(
                onPressed: _isLoading ? null : _submitFormat,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Tạo Lệnh Sản Xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
