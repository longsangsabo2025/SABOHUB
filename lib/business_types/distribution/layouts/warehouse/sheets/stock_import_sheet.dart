import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../providers/auth_provider.dart';
import '../../../../../utils/app_logger.dart';

/// Sheet nhập kho mới
class StockImportSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> inventory;
  final VoidCallback onSuccess;

  const StockImportSheet({
    super.key,
    required this.inventory,
    required this.onSuccess,
  });

  @override
  ConsumerState<StockImportSheet> createState() => _StockImportSheetState();
}

class _StockImportSheetState extends ConsumerState<StockImportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProduct;
  String? _selectedWarehouseId;
  String _reason = 'Nhập hàng từ nhà cung cấp';
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _warehouses = [];
  String _searchQuery = '';

  final List<String> _commonReasons = [
    'Nhập hàng từ nhà cung cấp',
    'Trả hàng từ khách',
    'Chuyển kho nội bộ',
    'Điều chỉnh sau kiểm kê',
    'Sản xuất hoàn thành',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _warehouses = List<Map<String, dynamic>>.from(data);
          final mainWarehouse = _warehouses.firstWhere(
            (w) => w['type'] == 'main',
            orElse: () => _warehouses.isNotEmpty ? _warehouses.first : {},
          );
          if (mainWarehouse.isNotEmpty) {
            _selectedWarehouseId = mainWarehouse['id'];
          }
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load warehouses', e);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('products')
          .select('id, name, sku, unit')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name');

      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load products', e);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             sku.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn kho nhập'),
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
      final quantity = int.parse(_quantityController.text);

      final warehouseId = _selectedWarehouseId!;

      final selectedWarehouse = _warehouses.firstWhere(
        (w) => w['id'] == warehouseId, 
        orElse: () => {'name': 'Kho'}
      );

      // Get current inventory quantity
      final existingInventory = await supabase
          .from('inventory')
          .select('id, quantity')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .eq('product_id', _selectedProductId!)
          .maybeSingle();

      final beforeQuantity = (existingInventory?['quantity'] as int?) ?? 0;
      final afterQuantity = beforeQuantity + quantity;

      // Insert movement record
      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'warehouse_id': warehouseId,
        'product_id': _selectedProductId,
        'type': 'in',
        'reason': _reason,
        'quantity': quantity,
        'before_quantity': beforeQuantity,
        'after_quantity': afterQuantity,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'created_by': userId,
      });

      // Update inventory quantity
      if (existingInventory != null) {
        await supabase
            .from('inventory')
            .update({'quantity': afterQuantity, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existingInventory['id']);
      } else {
        await supabase.from('inventory').insert({
          'company_id': companyId,
          'warehouse_id': warehouseId,
          'product_id': _selectedProductId,
          'quantity': afterQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Đã nhập $quantity ${_selectedProduct?['unit'] ?? 'đơn vị'} vào ${selectedWarehouse['name']}'),
                ),
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
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_circle, color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhập kho',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Thêm hàng vào kho',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product selection
                  const Text(
                    'Chọn sản phẩm *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm sản phẩm...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product list
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy sản phẩm',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isSelected = _selectedProductId == product['id'];
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.green.shade50,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'SKU: ${product['sku'] ?? 'N/A'} • ${product['unit'] ?? 'đơn vị'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: Colors.green.shade700)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = product['id'];
                                    _selectedProduct = product;
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã chọn: ${_selectedProduct!['name']}',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${_selectedProduct!['unit'] ?? 'đơn vị'}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Warehouse selection
                  const Text(
                    'Chọn kho nhập *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWarehouseId,
                        isExpanded: true,
                        hint: const Text('Chọn kho'),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _warehouses.map((wh) {
                          final isMain = wh['type'] == 'main';
                          return DropdownMenuItem<String>(
                            value: wh['id'],
                            child: Row(
                              children: [
                                Icon(
                                  isMain ? Icons.home_work : Icons.warehouse,
                                  size: 20,
                                  color: isMain ? Colors.blue : Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Text(wh['name'] ?? 'Kho'),
                                if (isMain) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Kho chính',
                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedWarehouseId = value),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quantity
                  const Text(
                    'Số lượng nhập *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Nhập số lượng',
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                      suffixText: _selectedProduct?['unit'] ?? 'đơn vị',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) return 'Số lượng phải lớn hơn 0';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Reason
                  const Text(
                    'Lý do nhập kho',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonReasons.map((reason) {
                      final isSelected = _reason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _reason = reason);
                          }
                        },
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Notes
                  const Text(
                    'Ghi chú (tùy chọn)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Thêm ghi chú...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Submit button
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
                    _isLoading ? 'Đang xử lý...' : 'Xác nhận nhập kho',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
}
