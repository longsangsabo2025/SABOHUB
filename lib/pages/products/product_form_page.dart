import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/odori_product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/odori_providers.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/sabo_image_picker.dart';

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
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minWholesaleQtyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _weightController = TextEditingController();
  final _minStockController = TextEditingController();

  String? _selectedCategoryId;
  String _weightUnit = 'kg';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isDeleting = false;
  
  // Image handling
  XFile? _selectedImage;
  String? _currentImageUrl;

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _skuController.text = p.sku;
      _barcodeController.text = p.barcode ?? '';
      _unitController.text = p.unit;
      _sellingPriceController.text = p.sellingPrice.toInt().toString();
      _costPriceController.text = p.costPrice.toInt().toString();
      _wholesalePriceController.text = p.wholesalePrice?.toInt().toString() ?? '';
      _minWholesaleQtyController.text = p.minWholesaleQty?.toString() ?? '';
      _descriptionController.text = p.description ?? '';
      _imageUrlController.text = p.imageUrl ?? '';
      _weightController.text = p.weight?.toString() ?? '';
      _minStockController.text = p.minStock?.toString() ?? '';
      _selectedCategoryId = p.categoryId;
      _weightUnit = p.weightUnit ?? 'kg';
      _isActive = p.isActive;
      _currentImageUrl = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _wholesalePriceController.dispose();
    _minWholesaleQtyController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _weightController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) throw Exception('User context not found');

      // Upload image if selected
      String? imageUrl = _imageUrlController.text.trim().isNotEmpty 
          ? _imageUrlController.text.trim() 
          : null;
      
      if (_selectedImage != null) {
        final uploadService = ImageUploadService();
        final productId = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await uploadService.uploadProductImage(
          imageFile: _selectedImage!,
          companyId: companyId,
          productId: productId,
        );
      }

      final productData = {
        'company_id': companyId,
        'category_id': _selectedCategoryId,
        'sku': _skuController.text.trim(),
        'barcode': _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        'unit': _unitController.text.trim(),
        'selling_price': double.tryParse(_sellingPriceController.text.replaceAll('.', '')) ?? 0,
        'cost_price': double.tryParse(_costPriceController.text.replaceAll('.', '')) ?? 0,
        'wholesale_price': _wholesalePriceController.text.isNotEmpty 
            ? double.tryParse(_wholesalePriceController.text.replaceAll('.', '')) 
            : null,
        'min_wholesale_qty': _minWholesaleQtyController.text.isNotEmpty 
            ? int.tryParse(_minWholesaleQtyController.text) 
            : null,
        'image_url': imageUrl,
        'weight': _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        'weight_unit': _weightController.text.isNotEmpty ? _weightUnit : null,
        'min_stock': _minStockController.text.isNotEmpty ? int.tryParse(_minStockController.text) : null,
        'status': _isActive ? 'active' : 'inactive',
      };

      final db = Supabase.instance.client;

      if (widget.product != null) {
        await db.from('products').update(productData).eq('id', widget.product!.id);
      } else {
        await db.from('products').insert(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm mới'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${widget.product!.name}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final db = Supabase.instance.client;
      await db.from('products').delete().eq('id', widget.product!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sản phẩm'), backgroundColor: Colors.orange),
        );
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _isDeleting ? null : _deleteProduct,
              icon: _isDeleting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa sản phẩm',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              _buildSectionCard(
                title: 'Thông tin cơ bản',
                icon: Icons.info_outline,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc nhập tên' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'Mã SKU *',
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Nhóm hàng',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-- Không chọn --')),
                        ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Lỗi tải danh mục: $e'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả sản phẩm',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing Card
              _buildSectionCard(
                title: 'Giá & Đơn vị',
                icon: Icons.attach_money,
                children: [
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị tính *',
                      prefixIcon: Icon(Icons.straighten),
                      hintText: 'Ví dụ: chai, hộp, kg, thùng',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Giá bán *',
                            prefixIcon: Icon(Icons.sell),
                            suffixText: 'đ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Giá vốn',
                            prefixIcon: Icon(Icons.price_change_outlined),
                            suffixText: 'đ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _wholesalePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Giá sỉ',
                            prefixIcon: Icon(Icons.local_offer_outlined),
                            suffixText: 'đ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minWholesaleQtyController,
                          decoration: const InputDecoration(
                            labelText: 'SL tối thiểu sỉ',
                            prefixIcon: Icon(Icons.production_quantity_limits),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  // Margin display
                  if (_sellingPriceController.text.isNotEmpty && _costPriceController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Builder(builder: (context) {
                        final sell = double.tryParse(_sellingPriceController.text) ?? 0;
                        final cost = double.tryParse(_costPriceController.text) ?? 0;
                        final margin = sell > 0 ? ((sell - cost) / sell * 100) : 0;
                        final profit = sell - cost;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: margin > 0 ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('Lợi nhuận', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text(
                                    '${currencyFormat.format(profit)}đ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: profit >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('Biên LN', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  Text(
                                    '${margin.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: margin >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Info
              _buildSectionCard(
                title: 'Thông tin thêm',
                icon: Icons.more_horiz,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Trọng lượng',
                            prefixIcon: Icon(Icons.scale),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'ĐV'),
                          value: _weightUnit,
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'g', child: Text('g')),
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'l', child: Text('lít')),
                          ],
                          onChanged: (val) => setState(() => _weightUnit = val ?? 'kg'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Tồn kho tối thiểu',
                      prefixIcon: Icon(Icons.inventory_outlined),
                      hintText: 'Cảnh báo khi dưới mức này',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  // Image Picker Section
                  const Text(
                    'Hình ảnh sản phẩm',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ProductImagePicker(
                    currentImageUrl: _currentImageUrl,
                    onImageSelected: (image) {
                      setState(() {
                        _selectedImage = image;
                        if (image == null) {
                          _imageUrlController.clear();
                          _currentImageUrl = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Keep URL field as backup option
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Hoặc nhập link ảnh',
                      prefixIcon: const Icon(Icons.link),
                      hintText: 'https://...',
                      suffixIcon: _imageUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _imageUrlController.clear();
                                  _currentImageUrl = null;
                                });
                              },
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() {
                        _currentImageUrl = value.isNotEmpty ? value : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Đang kinh doanh'),
                    subtitle: Text(_isActive ? 'Sản phẩm đang hoạt động' : 'Sản phẩm đã ngưng'),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
