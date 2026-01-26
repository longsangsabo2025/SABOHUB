import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/odori_product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final OdoriProduct? product;

  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController(); // e.g., kg, lit, hop
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _skuController.text = widget.product!.sku;
      _unitController.text = widget.product!.unit;
      _sellingPriceController.text = widget.product!.sellingPrice.toString();
      _costPriceController.text = widget.product!.costPrice.toString();
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _isActive = widget.product!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitFormat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhóm hàng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) throw Exception('User context not found');

      final productData = {
        'company_id': companyId,
        'category_id': _selectedCategoryId,
        'sku': _skuController.text,
        'name': _nameController.text,
        'unit': _unitController.text,
        'selling_price': double.tryParse(_sellingPriceController.text) ?? 0,
        'cost_price': double.tryParse(_costPriceController.text) ?? 0,
        'image_url': _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        'status': _isActive ? 'active' : 'inactive',
      };

      final db = Supabase.instance.client;

      if (widget.product != null) {
        // Update
        await db.from('products').update(productData).eq('id', widget.product!.id);
      } else {
        // Create
        await db.from('products').insert(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu sản phẩm thành công')),
        );
        ref.invalidate(productsProvider); // Refresh list
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
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Basic Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                        validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(labelText: 'Mã SKU *'),
                        validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Nhóm hàng *'),
                          value: _selectedCategoryId,
                          items: categories.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                          validator: (val) => val == null ? 'Bắt buộc' : null,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => Text('Lỗi tải danh mục: $e'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pricing Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Giá & Đơn vị', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Đơn vị tính (ví dụ: chai, hộp) *'),
                        validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              decoration: const InputDecoration(labelText: 'Giá bán *'),
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              decoration: const InputDecoration(labelText: 'Giá vốn'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 16),

              // Extra Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Thông tin thêm', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(labelText: 'Link Ảnh (URL)'),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Đang kinh doanh (Active)'),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitFormat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Lưu Sản Phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
