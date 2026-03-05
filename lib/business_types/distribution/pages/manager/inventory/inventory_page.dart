// Main Inventory Page - Refactored version
// This file contains only the main InventoryPage widget and imports other modules

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/odori_product.dart';
import '../../../providers/inventory_provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../widgets/sabo_refresh_button.dart';
import '../../../../../utils/app_logger.dart';
import 'inventory_constants.dart';
import 'product_sheets.dart';
import 'category_management.dart';
import 'warehouse_detail_page.dart';
import 'warehouse_dialogs.dart';
import 'sample_management_page.dart';
import 'add_sample_sheet.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

// ==================== INVENTORY PAGE ====================
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> with SingleTickerProviderStateMixin {
  // Keep controllers local (need dispose lifecycle)
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    // Provider's build() kicks off all initial loading
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  // ---- Thin wrappers delegating to InventoryNotifier ----

  Future<void> _loadInventoryData() =>
      ref.read(inventoryProvider.notifier).loadInventoryData();

  Future<void> _loadWarehouses() =>
      ref.read(inventoryProvider.notifier).loadWarehouses();

  Future<void> _loadSamples() =>
      ref.read(inventoryProvider.notifier).loadSamples();

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() =>
      ref.read(inventoryProvider.notifier).loadCategories();

  Future<void> _loadStats() =>
      ref.read(inventoryProvider.notifier).loadStats();

  Future<void> _loadInitial() =>
      ref.read(inventoryProvider.notifier).loadProducts();

  Future<void> _loadMore() =>
      ref.read(inventoryProvider.notifier).loadMore();

  // Get actual stock from inventory table (not from product.minStock)
  int _getProductTotalStock(OdoriProduct product) {
    final stockInfo = ref.read(inventoryProvider).productStockMap[product.id];
    return stockInfo?['total'] as int? ?? 0;
  }
  
  int _getProductWarehouseCount(OdoriProduct product) {
    final stockInfo = ref.read(inventoryProvider).productStockMap[product.id];
    return stockInfo?['warehouseCount'] as int? ?? 0;
  }
  
  List<Map<String, dynamic>> _getProductWarehouseBreakdown(OdoriProduct product) {
    final stockInfo = ref.read(inventoryProvider).productStockMap[product.id];
    return List<Map<String, dynamic>>.from(stockInfo?['warehouses'] ?? []);
  }

  Color _getStockColor(OdoriProduct product) {
    final stock = _getProductTotalStock(product);
    final reorderPoint = product.reorderPoint ?? 10;
    if (stock == 0) return Colors.red;
    if (stock < reorderPoint) return Colors.orange;
    return Colors.green;
  }

  String _getStockLabel(OdoriProduct product) {
    final stock = _getProductTotalStock(product);
    final reorderPoint = product.reorderPoint ?? 10;
    if (stock == 0) return 'Hết hàng';
    if (stock < reorderPoint) return 'Sắp hết';
    return 'Còn hàng';
  }

  void _onSearchChanged(String value) {
    ref.read(inventoryProvider.notifier).setSearchQuery(value);
  }

  Future<void> _refreshAll() =>
      ref.read(inventoryProvider.notifier).refreshAll();

  @override
  Widget build(BuildContext context) {
    // Watch provider to trigger rebuilds on state changes
    ref.watch(inventoryProvider);
    return Column(
      children: [
        // Tab Bar Header
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.teal.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(text: 'DS Kho', icon: Icon(Icons.warehouse_outlined, size: 18)),
              Tab(text: 'Sản phẩm', icon: Icon(Icons.inventory_2_outlined, size: 18)),
              Tab(text: 'SP Mẫu', icon: Icon(Icons.content_copy_outlined, size: 18)),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWarehouseListTab(),
              _buildProductsTab(),
              _buildSampleProductsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  // Tab 1: Warehouse List
  Widget _buildWarehouseListTab() {
    if (ref.watch(inventoryProvider).warehouses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warehouse_outlined, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có kho nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddWarehouseDialog(),
              icon: const Icon(Icons.add),
              label: Text('Thêm kho mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadWarehouses,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ref.watch(inventoryProvider).warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = ref.watch(inventoryProvider).warehouses[index];
              return _buildWarehouseCard(warehouse);
            },
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addWarehouse',
            onPressed: () => _showAddWarehouseDialog(),
            backgroundColor: Colors.teal,
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
            label: Text('Thêm kho', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWarehouseCard(Map<String, dynamic> warehouse) {
    final name = warehouse['name'] ?? 'Kho';
    final code = warehouse['code'] ?? '';
    final type = warehouse['type'] ?? 'main';
    final address = warehouse['address'] ?? '';
    final isActive = warehouse['is_active'] ?? true;
    
    final config = WarehouseTypeConfig.fromType(type);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: !isActive ? Border.all(color: Colors.red.shade200) : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showWarehouseDetail(warehouse),
          onLongPress: () => _showWarehouseActionsSheet(warehouse),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(config.icon, color: config.color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isActive ? Theme.of(context).colorScheme.onSurface87 : Colors.grey,
                                  ),
                                ),
                              ),
                              if (!isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Ngưng HĐ',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: config.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  config.label,
                                  style: TextStyle(color: config.color, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (code.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Mã: $code',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')])),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(children: [
                            Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Ngưng hoạt động' : 'Kích hoạt'),
                          ]),
                        ),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditWarehouseSheet(warehouse);
                        } else if (value == 'toggle') {
                          _toggleWarehouseStatus(warehouse);
                        } else if (value == 'delete') {
                          _confirmDeleteWarehouse(warehouse);
                        }
                      },
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _toggleWarehouseStatus(Map<String, dynamic> warehouse) async {
    try {
      final isActive = warehouse['is_active'] ?? true;
      
      await supabase
          .from('warehouses')
          .update({'is_active': !isActive})
          .eq('id', warehouse['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Đã ngưng hoạt động kho' : 'Đã kích hoạt kho'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWarehouses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _confirmDeleteWarehouse(Map<String, dynamic> warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa kho "${warehouse['name']}"?\n\nLưu ý: Không thể xóa kho đang có tồn kho hoặc đơn hàng liên quan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWarehouse(warehouse);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteWarehouse(Map<String, dynamic> warehouse) async {
    try {
      await supabase.from('warehouses').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', warehouse['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa kho'), backgroundColor: Colors.green),
        );
        _loadWarehouses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _showWarehouseDetail(Map<String, dynamic> warehouse) {
    final config = WarehouseTypeConfig.fromType(warehouse['type'] ?? 'main');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarehouseDetailPage(
          warehouse: warehouse,
          warehouseName: warehouse['name'] ?? 'Kho',
          warehouseCode: warehouse['code'] ?? '',
          warehouseAddress: warehouse['address'] ?? '',
          typeColor: config.color,
          typeLabel: config.label,
          typeIcon: config.icon,
          onStockIn: () => _showStockInDialog(warehouse),
          onStockOut: () => _showStockOutDialog(warehouse),
          onTransfer: () => _showTransferStockDialog(warehouse),
          onEdit: () => _showEditWarehouseSheet(warehouse),
          allWarehouses: ref.read(inventoryProvider).warehouses,
          onRefresh: () {
            _loadWarehouses();
            _loadInventoryData();
          },
        ),
      ),
    ).then((_) {
      _loadWarehouses();
      _loadInventoryData();
    });
  }
  
  void _showWarehouseActionsSheet(Map<String, dynamic> warehouse) {
    final name = warehouse['name'] ?? 'Kho';
    final type = warehouse['type'] ?? 'main';
    final isMain = type == 'main';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isMain ? Colors.blue : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMain ? Icons.home_work : Icons.warehouse,
                    color: isMain ? Colors.blue : Colors.orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        isMain ? 'Kho chính' : 'Kho phụ',
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
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildWarehouseActionButton(
                    icon: Icons.inventory_2,
                    label: 'Tồn kho',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      _showWarehouseDetail(warehouse);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWarehouseActionButton(
                    icon: Icons.add_box,
                    label: 'Nhập hàng',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showStockInDialog(warehouse);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWarehouseActionButton(
                    icon: Icons.outbox,
                    label: 'Xuất hàng',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showStockOutDialog(warehouse);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWarehouseActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển kho',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _showTransferStockDialog(warehouse);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditWarehouseSheet(warehouse);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa thông tin'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWarehouseActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getWarehouseStock(String warehouseId) async {
    try {
      final companyId = ref.read(currentUserProvider)?.companyId ?? '';
      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .gt('quantity', 0)
          .order('products(name)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      AppLogger.error('Error loading warehouse stock: $e');
      return [];
    }
  }
  
  void _showAddWarehouseDialog() {
    WarehouseFormSheet.show(
      context: context,
      ref: ref,
      onSuccess: _loadWarehouses,
    );
  }
  
  void _showEditWarehouseSheet(Map<String, dynamic> warehouse) {
    WarehouseFormSheet.show(
      context: context,
      ref: ref,
      warehouse: warehouse,
      onSuccess: _loadWarehouses,
    );
  }
  
  void _showStockInDialog(Map<String, dynamic> warehouse) {
    StockInSheet.show(
      context: context,
      ref: ref,
      warehouse: warehouse,
      products: ref.read(inventoryProvider).allProducts,
      onSuccess: () {
        _loadInventoryData();
      },
    );
  }
  
  void _showStockOutDialog(Map<String, dynamic> warehouse) {
    StockOutSheet.show(
      context: context,
      ref: ref,
      warehouse: warehouse,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadInventoryData();
      },
    );
  }
  
  void _showTransferStockDialog(Map<String, dynamic> warehouse) {
    TransferStockSheet.show(
      context: context,
      ref: ref,
      fromWarehouse: warehouse,
      allWarehouses: ref.read(inventoryProvider).warehouses,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadInventoryData();
      },
    );
  }
  
  // Tab 2: Products
  Widget _buildProductsTab() {
    return Stack(
      children: [
        Column(
          children: [
            // Compact Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  _buildCompactStatItem('Tổng SP', '${ref.watch(inventoryProvider).totalProducts}', Colors.blue, Icons.inventory),
                  _buildCompactStatItem('Sắp hết', '${ref.watch(inventoryProvider).lowStockCount}', Colors.orange, Icons.warning),
                  _buildCompactStatItem('Hết hàng', '${ref.watch(inventoryProvider).outOfStockCount}', Colors.red, Icons.error),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm sản phẩm...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SaboRefreshButton(
                    onPressed: _refreshAll,
                    isLoading: ref.watch(inventoryProvider).isRefreshing,
                    tooltip: 'Làm mới',
                  ),
                ],
              ),
            ),

            // Category Chips
            Container(
              height: 38,
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCategoryChip('Tất cả', null, ref.watch(inventoryProvider).selectedCategory == null),
                  ...ref.watch(inventoryProvider).categoryData.map((cat) => _buildCategoryChip(
                    cat['name'] as String,
                    cat['id'] as String,
                    ref.watch(inventoryProvider).selectedCategory == cat['id'],
                  )),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _showCategoryManagementDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Quản lý',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

        // Product List
        Expanded(
          child: ref.watch(inventoryProvider).isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : ref.watch(inventoryProvider).allProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Không tìm thấy sản phẩm', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadStats();
                        await _loadInitial();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: ref.watch(inventoryProvider).allProducts.length + (ref.watch(inventoryProvider).isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= ref.watch(inventoryProvider).allProducts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildProductCard(ref.watch(inventoryProvider).allProducts[index]);
                        },
                      ),
                    ),
        ),
      ],
    ),
    // FAB Add Product
    Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        heroTag: 'addProduct',
        backgroundColor: Colors.teal,
        onPressed: _showAddProductSheet,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
      ),
    ),
      ],
    );
  }

  // Compact stat item for product tab
  Widget _buildCompactStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          ref.read(inventoryProvider.notifier).setSelectedCategory(isSelected ? null : categoryId);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryManagementDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryManagementSheet(
        categories: ref.read(inventoryProvider).categories,
        onCategoryUpdated: () {
          _loadCategories();
          _loadInitial();
        },
      ),
    );
  }

  Widget _buildProductCard(OdoriProduct product) {
    final stockColor = _getStockColor(product);
    final stockLabel = _getStockLabel(product);
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetail(product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.grey.shade100 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              getCategoryIcon(product.categoryName),
                              color: Colors.teal.shade400,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          getCategoryIcon(product.categoryName),
                          color: Colors.teal.shade400,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stockLabel,
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.unit,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giá lẻ',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                              Text(
                                currencyFormat.format(product.sellingPrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          if (product.wholesalePrice != null && product.wholesalePrice! > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giá sỉ',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                                Text(
                                  currencyFormat.format(product.wholesalePrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          
                          const Spacer(),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: stockColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory, size: 14, color: stockColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getProductTotalStock(product)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: stockColor,
                                  ),
                                ),
                                // Show warehouse count if stock > 0
                                if (_getProductWarehouseCount(product) > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${_getProductWarehouseCount(product)} kho',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDetail(OdoriProduct product) {
    final totalStock = _getProductTotalStock(product);
    final warehouseBreakdown = _getProductWarehouseBreakdown(product);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product, 
        currencyFormat: currencyFormat,
        totalStock: totalStock,
        warehouseBreakdown: warehouseBreakdown,
        onEdit: () {
          Navigator.pop(context);
          _showEditProductSheet(context, product);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDeleteProduct(product);
        },
      ),
    );
  }

  void _confirmDeleteProduct(OdoriProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(OdoriProduct product) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', product.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa sản phẩm "${product.name}"'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats();
        _loadInitial();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Không thể xóa sản phẩm';
        if (e.toString().contains('violates foreign key constraint')) {
          errorMsg = 'Không thể xóa sản phẩm đang có tồn kho hoặc đơn hàng';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddProductSheet(
        categories: ref.read(inventoryProvider).categories,
        onSaved: (product) {
          _loadStats();
          _loadInitial();
        },
      ),
    );
  }

  // Tab 3: Sample Products
  Widget _buildSampleProductsTab() {
    return Stack(
      children: [
        Column(
          children: [
            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  Expanded(child: _buildCompactStatItem('Tổng mẫu', '${ref.watch(inventoryProvider).totalSamples}', Colors.purple, Icons.content_copy)),
                  Expanded(child: _buildCompactStatItem('Chờ phản hồi', '${ref.watch(inventoryProvider).pendingSamples}', Colors.orange, Icons.schedule)),
                  Expanded(child: _buildCompactStatItem('Đã chuyển đơn', '${ref.watch(inventoryProvider).convertedSamples}', Colors.green, Icons.shopping_cart)),
                ],
              ),
            ),
        
        // Search & Filter
        Container(
          padding: EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm mẫu...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    ref.read(inventoryProvider.notifier).setSampleSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
                tooltip: 'Lọc theo trạng thái',
                onSelected: (value) {
                  ref.read(inventoryProvider.notifier).setSelectedSampleStatus(value == 'all' ? null : value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'all', child: Text('Tất cả', style: TextStyle(color: ref.watch(inventoryProvider).selectedSampleStatus == null ? Colors.teal : null))),
                  const PopupMenuItem(value: 'pending', child: Text('Đang chờ')),
                  const PopupMenuItem(value: 'delivered', child: Text('Đã giao')),
                  const PopupMenuItem(value: 'received', child: Text('Đã nhận')),
                  const PopupMenuItem(value: 'feedback_received', child: Text('Có phản hồi')),
                  const PopupMenuItem(value: 'converted', child: Text('Đã chuyển đơn')),
                ],
              ),
            ],
          ),
        ),
        
        // Sample List
        Expanded(
          child: ref.watch(inventoryProvider).isLoadingSamples
              ? const Center(child: CircularProgressIndicator())
              : ref.watch(inventoryProvider).samples.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_copy_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có sản phẩm mẫu nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gửi mẫu sản phẩm cho khách hàng để thử',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSamples,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ref.watch(inventoryProvider).samples.length,
                        itemBuilder: (context, index) => _buildSampleCard(ref.watch(inventoryProvider).samples[index]),
                      ),
                    ),
        ),
      ],
    ),
    
    // FAB for adding sample - with menu
    Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SampleManagementPage()),
            ).then((_) => _loadSamples()),
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.dashboard_customize),
            label: const Text('Quản lý'),
            heroTag: 'manageSample',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _showAddSampleDialog,
            backgroundColor: Colors.purple,
            icon: const Icon(Icons.add),
            label: const Text('Gửi mẫu'),
            heroTag: 'addSample',
          ),
        ],
      ),
    ),
  ],
);
  }
  
  Widget _buildSampleCard(Map<String, dynamic> sample) {
    final product = sample['products'] as Map<String, dynamic>?;
    final customer = sample['customers'] as Map<String, dynamic>?;
    final status = sample['status'] as String? ?? 'pending';
    final quantity = sample['quantity'] ?? 1;
    final unit = sample['unit'] ?? 'cái';
    final sentDate = DateTime.tryParse(sample['sent_date'] ?? '');
    final converted = sample['converted_to_order'] == true;
    
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (status) {
      case 'delivered':
        statusColor = Colors.blue;
        statusLabel = 'Đã giao';
        statusIcon = Icons.local_shipping;
        break;
      case 'received':
        statusColor = Colors.green;
        statusLabel = 'Đã nhận';
        statusIcon = Icons.check_circle;
        break;
      case 'feedback_received':
        statusColor = Colors.purple;
        statusLabel = 'Có phản hồi';
        statusIcon = Icons.rate_review;
        break;
      case 'converted':
        statusColor = Colors.teal;
        statusLabel = 'Đã chuyển đơn';
        statusIcon = Icons.shopping_cart;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Đang chờ';
        statusIcon = Icons.schedule;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product?['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product!['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.grey.shade400),
                          ),
                        )
                      : Icon(Icons.inventory_2, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample['product_name'] ?? product?['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (sample['product_sku'] != null || product?['sku'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                sample['product_sku'] ?? product?['sku'] ?? '',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '$quantity $unit',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            // Customer & Date Info
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customer?['name'] ?? 'Khách hàng không xác định',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  sentDate != null ? DateFormat('dd/MM/yyyy').format(sentDate) : 'N/A',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            
            // Converted badge
            if (converted) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Đã chuyển thành đơn hàng',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditProductSheet(BuildContext context, OdoriProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProductSheet(
        product: product,
        categoryData: ref.read(inventoryProvider).categoryData,
        onSaved: () {
          _loadStats();
          _loadInitial();
        },
      ),
    );
  }

  void _showAddSampleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSampleSheet(
        products: ref.read(inventoryProvider).allProducts,
        onSaved: () {
          _loadSamples();
        },
      ),
    );
  }
}
