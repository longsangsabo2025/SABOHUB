import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../../../widgets/common/loading_indicator.dart';
import 'menu_form_page.dart';

class MenuListPage extends ConsumerStatefulWidget {
  const MenuListPage({super.key});

  @override
  ConsumerState<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends ConsumerState<MenuListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn'),
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToMenuForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Thêm món mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade700,
          tabs: MenuCategory.values.map((category) => Tab(
            text: category.label,
            icon: Icon(category.icon, size: 18),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: MenuCategory.values.map((category) => 
          _buildCategoryTab(category)
        ).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToMenuForm(),
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryTab(MenuCategory category) {
    final menuItemsAsync = ref.watch(menuItemsByCategoryProvider(category));

    return menuItemsAsync.when(
      data: (menuItems) => menuItems.isEmpty
          ? _buildEmptyState(category)
          : _buildMenuItemsList(menuItems),
      loading: () => const LoadingIndicator(message: 'Đang tải thực đơn...'),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildMenuItemsList(List<MenuItem> menuItems) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(menuItemsProvider);
        ref.invalidate(menuItemsByCategoryProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = menuItems[index];
          return _buildMenuItemCard(menuItem);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem menuItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: menuItem.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: menuItem.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    menuItem.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      menuItem.category.icon,
                      color: menuItem.category.color,
                      size: 30,
                    ),
                  ),
                )
              : Icon(
                  menuItem.category.icon,
                  color: menuItem.category.color,
                  size: 30,
                ),
        ),
        title: Text(
          menuItem.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: menuItem.isAvailable ? Colors.grey.shade800 : Colors.grey.shade500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (menuItem.description != null) ...[
              const SizedBox(height: 4),
              Text(
                menuItem.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: menuItem.category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    menuItem.category.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: menuItem.category.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: menuItem.isAvailable 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    menuItem.isAvailable ? 'Có sẵn' : 'Hết hàng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: menuItem.isAvailable 
                          ? Colors.green.shade700 
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${menuItem.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _toggleAvailability(menuItem),
                  icon: Icon(
                    menuItem.isAvailable ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  tooltip: menuItem.isAvailable ? 'Ẩn món' : 'Hiển thị món',
                  style: IconButton.styleFrom(
                    backgroundColor: menuItem.isAvailable 
                        ? Colors.orange.shade50 
                        : Colors.green.shade50,
                    foregroundColor: menuItem.isAvailable 
                        ? Colors.orange.shade600 
                        : Colors.green.shade600,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _navigateToMenuForm(menuItem),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Chỉnh sửa',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade600,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(menuItem),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Xóa món',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _navigateToMenuForm(menuItem),
      ),
    );
  }

  Widget _buildEmptyState(MenuCategory category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category.icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có món ${category.label.toLowerCase()}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm món ${category.label.toLowerCase()} đầu tiên vào thực đơn',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToMenuForm(null, category),
            icon: Icon(category.icon),
            label: Text('Thêm ${category.label}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: category.color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(menuItemsProvider);
              ref.invalidate(menuItemsByCategoryProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _navigateToMenuForm([MenuItem? menuItem, MenuCategory? defaultCategory]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuFormPage(
          menuItem: menuItem,
          defaultCategory: defaultCategory,
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItem menuItem) async {
    try {
      final actions = ref.read(menuActionsProvider);
      await actions.toggleAvailability(menuItem.id, !menuItem.isAvailable);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              menuItem.isAvailable 
                  ? 'Đã ẩn "${menuItem.name}" khỏi thực đơn' 
                  : 'Đã hiển thị "${menuItem.name}" trong thực đơn'
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
    }
  }

  void _showDeleteConfirmation(MenuItem menuItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa món'),
        content: Text('Bạn có chắc muốn xóa "${menuItem.name}" khỏi thực đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMenuItem(menuItem.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(String menuItemId) async {
    try {
      final actions = ref.read(menuActionsProvider);
      await actions.deleteMenuItem(menuItemId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa món khỏi thực đơn'),
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
    }
  }
}
