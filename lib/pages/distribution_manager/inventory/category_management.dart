// Category Management Sheet and Form Dialog

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import 'inventory_constants.dart';

// ==================== CATEGORY MANAGEMENT SHEET ====================
class CategoryManagementSheet extends ConsumerStatefulWidget {
  final List<String> categories;
  final VoidCallback onCategoryUpdated;

  const CategoryManagementSheet({
    super.key,
    required this.categories,
    required this.onCategoryUpdated,
  });

  @override
  ConsumerState<CategoryManagementSheet> createState() => _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends ConsumerState<CategoryManagementSheet> {
  List<Map<String, dynamic>> _categoryData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final response = await supabase
          .from('product_categories')
          .select('id, name, description, created_at')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        setState(() {
          _categoryData = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );

    if (result != null && result['name']?.isNotEmpty == true) {
      try {
        final companyId = ref.read(authProvider).user?.companyId ?? '';
        
        await supabase.from('product_categories').insert({
          'company_id': companyId,
          'name': result['name'],
          'description': result['description'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm danh mục thành công'), backgroundColor: Colors.green),
          );
          _loadCategoryData();
          widget.onCategoryUpdated();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CategoryFormDialog(
        initialName: category['name'],
        initialDescription: category['description'],
      ),
    );

    if (result != null && result['name']?.isNotEmpty == true) {
      try {
        await supabase
            .from('product_categories')
            .update({
              'name': result['name'],
              'description': result['description'],
            })
            .eq('id', category['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật danh mục'), backgroundColor: Colors.green),
          );
          _loadCategoryData();
          widget.onCategoryUpdated();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final productsCount = await supabase
        .from('products')
        .select('id')
        .eq('category_id', category['id'])
        .count(CountOption.exact);

    final count = productsCount.count;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text(
          count > 0
              ? 'Danh mục "${category['name']}" đang có $count sản phẩm sử dụng. Bạn có chắc muốn xóa?'
              : 'Bạn có chắc muốn xóa danh mục "${category['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (count > 0) {
          await supabase
              .from('products')
              .update({'category_id': null})
              .eq('category_id', category['id']);
        }

        await supabase
            .from('product_categories')
            .delete()
            .eq('id', category['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa danh mục'), backgroundColor: Colors.green),
          );
          _loadCategoryData();
          widget.onCategoryUpdated();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý danh mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addCategory,
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : _categoryData.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có danh mục nào',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _addCategory,
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm danh mục đầu tiên'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categoryData.length,
                        itemBuilder: (context, index) {
                          final category = _categoryData[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.category, color: Colors.teal, size: 20),
                              ),
                              title: Text(
                                category['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: category['description'] != null && category['description'].isNotEmpty
                                  ? Text(
                                      category['description'],
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, color: Colors.blue.shade400, size: 20),
                                    onPressed: () => _editCategory(category),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                    onPressed: () => _deleteCategory(category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ==================== CATEGORY FORM DIALOG ====================
class CategoryFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;

  const CategoryFormDialog({
    super.key,
    this.initialName,
    this.initialDescription,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descController = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên danh mục *',
              hintText: 'VD: Thực phẩm, Đồ uống...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Mô tả (tùy chọn)',
              hintText: 'Mô tả ngắn về danh mục',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập tên danh mục'), backgroundColor: Colors.orange),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }
}
