import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../../../widgets/common/loading_indicator.dart';

class MenuFormPage extends ConsumerStatefulWidget {
  final MenuItem? menuItem;
  final MenuCategory? defaultCategory;

  const MenuFormPage({
    super.key,
    this.menuItem,
    this.defaultCategory,
  });

  @override
  ConsumerState<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends ConsumerState<MenuFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  MenuCategory _selectedCategory = MenuCategory.food;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _initializeFromMenuItem(widget.menuItem!);
    } else if (widget.defaultCategory != null) {
      _selectedCategory = widget.defaultCategory!;
    }
  }

  void _initializeFromMenuItem(MenuItem menuItem) {
    _nameController.text = menuItem.name;
    _priceController.text = menuItem.price.toString();
    _descriptionController.text = menuItem.description ?? '';
    _imageUrlController.text = menuItem.imageUrl ?? '';
    _selectedCategory = menuItem.category;
    _isAvailable = menuItem.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuItem != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa món' : 'Thêm món mới'),
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade900,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveMenuItem,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Lưu'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade700,
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
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildPricingSection(),
                    const SizedBox(height: 24),
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    _buildAvailabilitySection(),
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món *',
                hintText: 'Ví dụ: Cà phê đen, Bánh mì thịt nướng',
                prefixIcon: Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên món';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả món ăn',
                hintText: 'Mô tả ngắn gọn về món ăn, nguyên liệu...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh mục',
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
              children: MenuCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 18,
                        color: isSelected ? Colors.white : category.color,
                      ),
                      const SizedBox(width: 8),
                      Text(category.label),
                    ],
                  ),
                  selectedColor: category.color,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : category.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }).toList(),
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
              'Giá bán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá bán *',
                hintText: '25000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VND',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Giá bán phải là số dương';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hình ảnh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL hình ảnh',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_imageUrlController.text.isNotEmpty) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Không thể tải hình ảnh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Để trống nếu không có hình ảnh. Hỗ trợ định dạng JPG, PNG.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
              title: const Text('Có sẵn trong thực đơn'),
              subtitle: Text(
                _isAvailable 
                    ? 'Khách hàng có thể đặt món này' 
                    : 'Món này sẽ bị ẩn khỏi thực đơn'
              ),
              activeColor: Colors.green.shade600,
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
        onPressed: _isLoading ? null : _saveMenuItem,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(widget.menuItem != null ? 'Cập nhật món' : 'Thêm món mới'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final actions = ref.read(menuActionsProvider);
      final price = double.parse(_priceController.text);
      
      if (widget.menuItem != null) {
        // Update existing menu item
        await actions.updateMenuItem(
          id: widget.menuItem!.id,
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: price,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
          imageUrl: _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
          isAvailable: _isAvailable,
        );
      } else {
        // Create new menu item
        await actions.createMenuItem(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: price,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
          imageUrl: _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.menuItem != null 
                  ? 'Đã cập nhật món "${_nameController.text}"' 
                  : 'Đã thêm món "${_nameController.text}" vào thực đơn'
            ),
            backgroundColor: Colors.green,
          ),
        );
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