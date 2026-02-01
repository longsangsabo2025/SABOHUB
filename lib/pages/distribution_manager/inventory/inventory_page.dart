// Main Inventory Page - Refactored version
// This file contains only the main InventoryPage widget and imports other modules

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/odori_product.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/sabo_refresh_button.dart';
import 'inventory_constants.dart';
import 'product_sheets.dart';
import 'category_management.dart';
import 'warehouse_detail_page.dart';
import 'warehouse_dialogs.dart';
import 'sample_management_page.dart';

// ==================== INVENTORY PAGE ====================
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCategory; // Stores category ID, not name
  final List<String> _categories = [];
  List<Map<String, dynamic>> _categoryData = [];
  bool _showLowStock = false;
  final List<OdoriProduct> _allProducts = [];
  int _currentOffset = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();
  
  // Stats
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _outOfStockCount = 0;
  
  // Tab controller
  late TabController _tabController;
  
  // Inventory & Warehouses data
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoadingInventory = true;
  bool _isRefreshing = false;
  
  // Product stock from inventory table (product_id -> {total, warehouseCount, warehouses})
  Map<String, Map<String, dynamic>> _productStockMap = {};
  
  // Sample Products data
  List<Map<String, dynamic>> _samples = [];
  bool _isLoadingSamples = true;
  String _sampleSearchQuery = '';
  String? _selectedSampleStatus;
  int _totalSamples = 0;
  int _pendingSamples = 0;
  int _convertedSamples = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadStats();
    _loadInitial();
    _loadInventoryData();
    _loadMovements();
    _loadWarehouses();
    _loadSamples();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInventoryData() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit), warehouses(id, name, code, type)')
          .eq('company_id', companyId)
          .order('products(name)');

      // Build product stock map from inventory
      final stockMap = <String, Map<String, dynamic>>{};
      for (var inv in data) {
        final productId = inv['product_id'] as String?;
        final qty = (inv['quantity'] as num?)?.toInt() ?? 0;
        final warehouse = inv['warehouses'] as Map<String, dynamic>?;
        
        if (productId != null && qty > 0) {
          if (!stockMap.containsKey(productId)) {
            stockMap[productId] = {
              'total': 0,
              'warehouseCount': 0,
              'warehouses': <Map<String, dynamic>>[],
            };
          }
          stockMap[productId]!['total'] = (stockMap[productId]!['total'] as int) + qty;
          stockMap[productId]!['warehouseCount'] = (stockMap[productId]!['warehouseCount'] as int) + 1;
          (stockMap[productId]!['warehouses'] as List).add({
            'name': warehouse?['name'] ?? 'Unknown',
            'code': warehouse?['code'] ?? '',
            'type': warehouse?['type'] ?? 'main',
            'quantity': qty,
          });
        }
      }

      if (mounted) {
        setState(() {
          _inventory = List<Map<String, dynamic>>.from(data);
          _productStockMap = stockMap;
          _isLoadingInventory = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading inventory: $e');
      if (mounted) setState(() => _isLoadingInventory = false);
    }
  }

  Future<void> _loadMovements() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('inventory_movements')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _movements = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading movements: $e');
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        setState(() {
          _warehouses = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading warehouses: $e');
    }
  }
  
  Future<void> _loadSamples() async {
    setState(() => _isLoadingSamples = true);
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      var query = supabase
          .from('product_samples')
          .select('*, products(id, name, sku, unit, image_url), customers(id, name, phone)')
          .eq('company_id', companyId);
      
      if (_selectedSampleStatus != null) {
        query = query.eq('status', _selectedSampleStatus!);
      }
      
      if (_sampleSearchQuery.isNotEmpty) {
        query = query.or('product_name.ilike.%$_sampleSearchQuery%,product_sku.ilike.%$_sampleSearchQuery%');
      }
      
      final data = await query.order('sent_date', ascending: false).limit(100);
      
      // Calculate stats
      final allData = await supabase
          .from('product_samples')
          .select('status, converted_to_order')
          .eq('company_id', companyId);
      
      int pending = 0;
      int converted = 0;
      for (var s in (allData as List)) {
        if (s['status'] == 'pending' || s['status'] == 'delivered') pending++;
        if (s['converted_to_order'] == true) converted++;
      }

      if (mounted) {
        setState(() {
          _samples = List<Map<String, dynamic>>.from(data);
          _totalSamples = (allData).length;
          _pendingSamples = pending;
          _convertedSamples = converted;
          _isLoadingSamples = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading samples: $e');
      if (mounted) setState(() => _isLoadingSamples = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final response = await supabase
          .from('product_categories')
          .select('id, name, description')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        setState(() {
          _categories.clear();
          _categoryData = List<Map<String, dynamic>>.from(response);
          for (var cat in _categoryData) {
            _categories.add(cat['name'] as String);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      // Count total products
      final totalResponse = await supabase
          .from('products')
          .select('id')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      if (mounted) {
        setState(() {
          _totalProducts = (totalResponse as List).length;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
    }
  }
  
  // Update low/out of stock counts based on actual inventory data
  void _updateStockCounts() {
    if (_allProducts.isEmpty) return;
    
    int lowStock = 0;
    int outOfStock = 0;
    
    for (var product in _allProducts) {
      final stock = _getProductTotalStock(product);
      final reorderPoint = product.reorderPoint ?? 10;
      if (stock == 0) {
        outOfStock++;
      } else if (stock < reorderPoint) {
        lowStock++;
      }
    }
    
    setState(() {
      _lowStockCount = lowStock;
      _outOfStockCount = outOfStock;
    });
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _allProducts.clear();
      _currentOffset = 0;
      _hasMore = true;
    });

    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) {
        setState(() => _isInitialLoading = false);
        return;
      }

      var query = supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      if (_selectedCategory != null) {
        query = query.eq('category_id', _selectedCategory!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,sku.ilike.%$_searchQuery%');
      }

      final response = await query.order('name').range(0, _pageSize - 1);

      var products = (response as List).map((json) => OdoriProduct.fromJson(json)).toList();

      if (_showLowStock) {
        products = products.where((p) {
          final stock = p.minStock ?? 0;
          final reorderPoint = p.reorderPoint ?? 10;
          return stock == 0 || stock < reorderPoint;
        }).toList();
      }

      setState(() {
        _allProducts.addAll(products);
        _hasMore = products.length >= _pageSize;
        _isInitialLoading = false;
      });
      
      // Update stock counts based on actual inventory
      _updateStockCounts();
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final newOffset = _currentOffset + _pageSize;
      final companyId = ref.read(authProvider).user?.companyId ?? '';

      var query = supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      if (_selectedCategory != null) {
        query = query.eq('category_id', _selectedCategory!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,sku.ilike.%$_searchQuery%');
      }

      final response = await query.order('name').range(newOffset, newOffset + _pageSize - 1);

      var newProducts = (response as List).map((json) => OdoriProduct.fromJson(json)).toList();

      if (_showLowStock) {
        newProducts = newProducts.where((p) {
          final stock = p.minStock ?? 0;
          final reorderPoint = p.reorderPoint ?? 10;
          return stock == 0 || stock < reorderPoint;
        }).toList();
      }

      setState(() {
        _allProducts.addAll(newProducts);
        _currentOffset = newOffset;
        _hasMore = newProducts.length >= _pageSize;
        _isLoadingMore = false;
      });
      
      // Update stock counts
      _updateStockCounts();
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm: $e')),
        );
      }
    }
  }

  // Get actual stock from inventory table (not from product.minStock)
  int _getProductTotalStock(OdoriProduct product) {
    final stockInfo = _productStockMap[product.id];
    return stockInfo?['total'] as int? ?? 0;
  }
  
  int _getProductWarehouseCount(OdoriProduct product) {
    final stockInfo = _productStockMap[product.id];
    return stockInfo?['warehouseCount'] as int? ?? 0;
  }
  
  List<Map<String, dynamic>> _getProductWarehouseBreakdown(OdoriProduct product) {
    final stockInfo = _productStockMap[product.id];
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
    setState(() => _searchQuery = value);
    _loadInitial();
  }

  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait<void>([
        _loadStats(),
        _loadCategories(),
        _loadInitial(),
        _loadInventoryData(),
        _loadWarehouses(),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bộ lọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilterOption('Tất cả sản phẩm', !_showLowStock, () {
              setState(() => _showLowStock = false);
              Navigator.pop(context);
              _loadInitial();
            }),
            _buildFilterOption('Sắp hết / Hết hàng', _showLowStock, () {
              setState(() => _showLowStock = true);
              Navigator.pop(context);
              _loadInitial();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Colors.teal : Colors.grey,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar Header
        Container(
          color: Colors.white,
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
    if (_warehouses.isEmpty) {
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
              label: const Text('Thêm kho mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = _warehouses[index];
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
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Thêm kho', style: TextStyle(color: Colors.white)),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isActive ? Border.all(color: Colors.red.shade200) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                                    color: isActive ? Colors.black87 : Colors.grey,
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWarehouse(warehouse);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteWarehouse(Map<String, dynamic> warehouse) async {
    try {
      await supabase.from('warehouses').delete().eq('id', warehouse['id']);
      
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
          allWarehouses: _warehouses,
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
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .gt('quantity', 0)
          .order('products(name)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ Error loading warehouse stock: $e');
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
      products: _allProducts,
      onSuccess: () {
        _loadInventoryData();
        _loadMovements();
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
        _loadMovements();
      },
    );
  }
  
  void _showTransferStockDialog(Map<String, dynamic> warehouse) {
    TransferStockSheet.show(
      context: context,
      ref: ref,
      fromWarehouse: warehouse,
      allWarehouses: _warehouses,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadInventoryData();
        _loadMovements();
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
                  _buildCompactStatItem('Tổng SP', '$_totalProducts', Colors.blue, Icons.inventory),
                  _buildCompactStatItem('Sắp hết', '$_lowStockCount', Colors.orange, Icons.warning),
                  _buildCompactStatItem('Hết hàng', '$_outOfStockCount', Colors.red, Icons.error),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
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
                    isLoading: _isRefreshing,
                    tooltip: 'Làm mới',
                  ),
                ],
              ),
            ),

            // Category Chips
            Container(
              height: 38,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCategoryChip('Tất cả', null, _selectedCategory == null),
                  ..._categoryData.map((cat) => _buildCategoryChip(
                    cat['name'] as String,
                    cat['id'] as String,
                    _selectedCategory == cat['id'],
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
          child: _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : _allProducts.isEmpty
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
                        itemCount: _allProducts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _allProducts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildProductCard(_allProducts[index]);
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
        child: const Icon(Icons.add, color: Colors.white),
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
  
  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          setState(() => _selectedCategory = isSelected ? null : categoryId);
          _loadInitial();
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
        categories: _categories,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
          .delete()
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
        categories: _categories,
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
                  Expanded(child: _buildCompactStatItem('Tổng mẫu', '$_totalSamples', Colors.purple, Icons.content_copy)),
                  Expanded(child: _buildCompactStatItem('Chờ phản hồi', '$_pendingSamples', Colors.orange, Icons.schedule)),
                  Expanded(child: _buildCompactStatItem('Đã chuyển đơn', '$_convertedSamples', Colors.green, Icons.shopping_cart)),
                ],
              ),
            ),
        
        // Search & Filter
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
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
                    setState(() => _sampleSearchQuery = value);
                    _loadSamples();
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
                tooltip: 'Lọc theo trạng thái',
                onSelected: (value) {
                  setState(() => _selectedSampleStatus = value == 'all' ? null : value);
                  _loadSamples();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'all', child: Text('Tất cả', style: TextStyle(color: _selectedSampleStatus == null ? Colors.teal : null))),
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
          child: _isLoadingSamples
              ? const Center(child: CircularProgressIndicator())
              : _samples.isEmpty
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
                        itemCount: _samples.length,
                        itemBuilder: (context, index) => _buildSampleCard(_samples[index]),
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
        categoryData: _categoryData,
        onSaved: () {
          _loadStats();
          _loadInitial();
        },
      ),
    );
  }

  void _showAdjustStockSheet(BuildContext context, OdoriProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdjustStockSheet(
        product: product,
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
      builder: (context) => _AddSampleSheet(
        products: _allProducts,
        onSaved: () {
          _loadSamples();
        },
      ),
    );
  }
}

// ==================== ADD SAMPLE SHEET ====================
class _AddSampleSheet extends ConsumerStatefulWidget {
  final List<OdoriProduct> products;
  final VoidCallback onSaved;

  const _AddSampleSheet({
    required this.products,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddSampleSheet> createState() => _AddSampleSheetState();
}

class _AddSampleSheetState extends ConsumerState<_AddSampleSheet> {
  OdoriProduct? _selectedProduct;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  String _customerSearchQuery = '';
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = false;
  bool _isLoadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _filterCustomers(String query) {
    setState(() {
      _customerSearchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = (customer['name'] as String? ?? '').toLowerCase();
          final phone = (customer['phone'] as String? ?? '').toLowerCase();
          final address = (customer['address'] as String? ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower) || address.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('customers')
          .select('id, name, phone, address, contact_person, type')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        final customers = List<Map<String, dynamic>>.from(data);
        setState(() {
          _customers = customers;
          _filteredCustomers = customers;
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  void _showCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chọn khách hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Search TextField
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên, SĐT, địa chỉ...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) => setState(() => _filterCustomers(value)),
              ),
              const SizedBox(height: 12),

              // Customer List
              Expanded(
                child: _filteredCustomers.isEmpty
                    ? Center(
                        child: Text(
                          _customerSearchQuery.isEmpty ? 'Chưa có khách hàng' : 'Không tìm thấy khách hàng',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final isSelected = customer['id'] == _selectedCustomerId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? Colors.purple.shade50 : Colors.white,
                            ),
                            child: ListTile(
                              onTap: () {
                                this.setState(() {
                                  _selectedCustomerId = customer['id'] as String;
                                  _selectedCustomerName = customer['name'] as String;
                                });
                                Navigator.pop(ctx);
                              },
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                customer['name'] as String? ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  if (customer['phone'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            customer['phone'] as String,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['address'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              customer['address'] as String,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['contact_person'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            customer['contact_person'] as String,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (customer['type'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              customer['type'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected ? Icon(Icons.check, color: Colors.purple.shade700) : null,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSample() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm')),
      );
      return;
    }

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng phải lớn hơn 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final userId = ref.read(authProvider).user?.id ?? '';
      final userName = ref.read(authProvider).user?.displayName ?? '';

      // Step 1: Create Sales Order with order_type: 'sample'
      final orderNumber = 'SO-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final subtotal = quantity * (_selectedProduct!.sellingPrice ?? 0);
      
      final orderResponse = await supabase.from('sales_orders').insert({
        'company_id': companyId,
        'customer_id': _selectedCustomerId,
        'order_number': orderNumber,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'pending_approval',
        'payment_status': 'unpaid',
        'delivery_status': 'pending',
        'order_type': 'sample', // Mark as sample order
        'subtotal': subtotal,
        'total': subtotal,
        'sale_id': userId,
        'notes': 'Mẫu sản phẩm - ${_notesController.text.trim()}',
      }).select().single();

      final orderId = orderResponse['id'];

      // Step 2: Create Sales Order Item
      await supabase.from('sales_order_items').insert({
        'order_id': orderId,
        'product_id': _selectedProduct!.id,
        'product_sku': _selectedProduct!.sku,
        'product_name': _selectedProduct!.name,
        'unit': _selectedProduct!.unit,
        'quantity': quantity,
        'unit_price': _selectedProduct!.sellingPrice ?? 0,
        'line_total': subtotal,
      });

      // Step 3: Create Product Sample record with order link
      await supabase.from('product_samples').insert({
        'company_id': companyId,
        'order_id': orderId, // Link to sales order
        'product_id': _selectedProduct!.id,
        'customer_id': _selectedCustomerId,
        'quantity': quantity,
        'unit': _selectedProduct!.unit,
        'product_name': _selectedProduct!.name,
        'product_sku': _selectedProduct!.sku,
        'sent_by_id': userId,
        'sent_by_name': userName,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'status': 'pending',
        'sent_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Đã ghi nhận gửi mẫu (tạo đơn hàng #$orderNumber)')),
        );
        widget.onSaved();
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
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.content_copy, color: Colors.purple.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gửi sản phẩm mẫu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Product Dropdown
                const Text(
                  'Sản phẩm *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<OdoriProduct>(
                  value: _selectedProduct,
                  decoration: InputDecoration(
                    hintText: 'Chọn sản phẩm...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProduct = value),
                ),

                const SizedBox(height: 16),

                // Customer Selector with Search
                const Text(
                  'Khách hàng *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _isLoadingCustomers
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onTap: () => _showCustomerSelector(context),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedCustomerName ?? 'Chọn khách hàng...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedCustomerName != null ? Colors.black : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 16),

                // Quantity
                const Text(
                  'Số lượng *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nhập số lượng',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixText: _selectedProduct?.unit ?? 'cái',
                  ),
                ),

                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Ghi chú',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú về mẫu này...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSample,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Gửi mẫu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
