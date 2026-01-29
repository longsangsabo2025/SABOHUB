// Extracted from distribution_manager_layout.dart
// Inventory Management Page with products, categories, stock tracking

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dvhcvn/dvhcvn.dart' as dvhcvn;
import 'package:geocoding/geocoding.dart';
import '../../models/odori_product.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;
final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

// ==================== INVENTORY PAGE ====================
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCategory;
  final List<String> _categories = [];
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
  
  // Tab controller for 3 tabs
  late TabController _tabController;
  
  // Inventory & Warehouses data
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoadingInventory = true;

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
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .order('products(name)');

      if (mounted) {
        setState(() {
          _inventory = List<Map<String, dynamic>>.from(data);
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
          .select('name')
          .eq('company_id', companyId)
          .order('name');

      if (mounted) {
        setState(() {
          _categories.clear();
          for (var cat in (response as List)) {
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

      final totalResponse = await supabase
          .from('products')
          .select('id')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      final lowStockResponse = await supabase
          .from('products')
          .select('id, min_stock, reorder_point')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      int lowStock = 0;
      int outOfStock = 0;
      for (var p in (lowStockResponse as List)) {
        final stock = (p['min_stock'] as num?)?.toInt() ?? 0;
        final reorderPoint = (p['reorder_point'] as num?)?.toInt() ?? 10;
        if (stock == 0) {
          outOfStock++;
        } else if (stock < reorderPoint) {
          lowStock++;
        }
      }

      if (mounted) {
        setState(() {
          _totalProducts = (totalResponse as List).length;
          _lowStockCount = lowStock;
          _outOfStockCount = outOfStock;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
    }
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
        query = query.eq('category_name', _selectedCategory!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,sku.ilike.%$_searchQuery%');
      }

      final response = await query
          .order('name')
          .range(0, _pageSize - 1);

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
        query = query.eq('category_name', _selectedCategory!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,sku.ilike.%$_searchQuery%');
      }

      final response = await query
          .order('name')
          .range(newOffset, newOffset + _pageSize - 1);

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
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm: $e')),
        );
      }
    }
  }

  Color _getStockColor(OdoriProduct product) {
    final stock = product.minStock ?? 0;
    final reorderPoint = product.reorderPoint ?? 10;
    if (stock == 0) return Colors.red;
    if (stock < reorderPoint) return Colors.orange;
    return Colors.green;
  }

  String _getStockLabel(OdoriProduct product) {
    final stock = product.minStock ?? 0;
    final reorderPoint = product.reorderPoint ?? 10;
    if (stock == 0) return 'Hết hàng';
    if (stock < reorderPoint) return 'Sắp hết';
    return 'Còn hàng';
  }

  IconData _getCategoryIcon(String? categoryName) {
    final name = (categoryName ?? '').toLowerCase();
    if (name.contains('đồ uống') || name.contains('nước')) return Icons.local_drink;
    if (name.contains('bánh') || name.contains('snack')) return Icons.cookie;
    if (name.contains('rau') || name.contains('củ')) return Icons.eco;
    if (name.contains('thịt') || name.contains('cá')) return Icons.set_meal;
    if (name.contains('sữa')) return Icons.water_drop;
    if (name.contains('gia vị')) return Icons.restaurant;
    return Icons.inventory_2;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadInitial();
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
            tabs: const [
              Tab(text: 'Sản phẩm', icon: Icon(Icons.inventory_2_outlined, size: 20)),
              Tab(text: 'Lịch sử', icon: Icon(Icons.history, size: 20)),
              Tab(text: 'DS Kho', icon: Icon(Icons.warehouse_outlined, size: 20)),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Products list (existing functionality)
              _buildProductsTab(),
              // Tab 2: Movement history
              _buildMovementHistoryTab(),
              // Tab 3: Warehouse list
              _buildWarehouseListTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  // Tab 1: Products (existing code refactored)
  Widget _buildProductsTab() {
    return Column(
      children: [
        // Stats Row
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.teal.shade50,
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Tổng SP', _totalProducts, Colors.blue, Icons.inventory)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Sắp hết', _lowStockCount, Colors.orange, Icons.warning)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Hết hàng', _outOfStockCount, Colors.red, Icons.error)),
            ],
          ),
        ),

        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _showLowStock ? Colors.orange.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.filter_list,
                      color: _showLowStock ? Colors.orange : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category Chips
        if (_categories.isNotEmpty)
          Container(
            height: 44,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip('Tất cả', _selectedCategory == null),
                ..._categories.map((cat) => _buildCategoryChip(cat, _selectedCategory == cat)),
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
    );
  }
  
  // Tab 2: Movement History
  Widget _buildMovementHistoryTab() {
    if (_movements.isEmpty) {
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
              child: Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử nhập/xuất kho',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          final movement = _movements[index];
          return _buildMovementCard(movement);
        },
      ),
    );
  }
  
  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final product = movement['products'] as Map<String, dynamic>?;
    final type = movement['type'] as String? ?? 'in';
    final quantity = movement['quantity'] as int? ?? 0;
    final reason = movement['reason'] as String?;
    final createdAt = movement['created_at'] as String?;
    
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    
    switch (type) {
      case 'in':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = 'Nhập kho';
        break;
      case 'out':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Xuất kho';
        break;
      case 'transfer':
        typeColor = Colors.blue;
        typeIcon = Icons.swap_horiz;
        typeLabel = 'Chuyển kho';
        break;
      case 'adjustment':
        typeColor = Colors.orange;
        typeIcon = Icons.edit;
        typeLabel = 'Điều chỉnh';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.sync;
        typeLabel = type;
    }

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: typeColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?['name'] ?? 'Sản phẩm',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${type == 'in' ? '+' : '-'}$quantity ${product?['unit'] ?? ''}',
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            formattedDate,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
  
  // Tab 3: Warehouse List
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
    
    Color typeColor;
    String typeLabel;
    IconData typeIcon;
    switch (type) {
      case 'main':
        typeColor = Colors.blue;
        typeLabel = 'Kho chính';
        typeIcon = Icons.home_work;
        break;
      case 'transit':
        typeColor = Colors.orange;
        typeLabel = 'Trung chuyển';
        typeIcon = Icons.local_shipping;
        break;
      case 'vehicle':
        typeColor = Colors.green;
        typeLabel = 'Xe tải';
        typeIcon = Icons.local_shipping_outlined;
        break;
      case 'virtual':
        typeColor = Colors.purple;
        typeLabel = 'Ảo';
        typeIcon = Icons.cloud_outlined;
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = type;
        typeIcon = Icons.warehouse;
    }

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
          onTap: () => _showEditWarehouseSheet(warehouse),
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
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 26),
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
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
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
  
  // Toggle warehouse active status
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
  
  // Confirm delete warehouse
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
  
  // Delete warehouse
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
  
  // Show edit warehouse sheet (same form as add but with data)
  void _showEditWarehouseSheet(Map<String, dynamic> warehouse) {
    final nameController = TextEditingController(text: warehouse['name'] ?? '');
    final codeController = TextEditingController(text: warehouse['code'] ?? '');
    final streetNumberController = TextEditingController(text: warehouse['street_number'] ?? '');
    final streetController = TextEditingController(text: warehouse['street'] ?? '');
    String selectedType = warehouse['type'] ?? 'main';
    bool isActive = warehouse['is_active'] ?? true;
    
    // Vietnamese Address Selection
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];
    
    // Initialize to Ho Chi Minh City by default
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;
      
      // Try to match existing address
      final warehouseDistrict = warehouse['district'] ?? '';
      final warehouseWard = warehouse['ward'] ?? '';
      
      if (warehouseDistrict.isNotEmpty) {
        for (var d in districts) {
          if (d.name.contains(warehouseDistrict) || 
              warehouseDistrict.contains(d.name.replaceAll('Quận ', '').replaceAll('Huyện ', ''))) {
            selectedDistrict = d;
            wards = d.children;
            break;
          }
        }
      }
      
      if (warehouseWard.isNotEmpty && selectedDistrict != null) {
        for (var w in wards) {
          if (w.name.contains(warehouseWard) ||
              warehouseWard.contains(w.name.replaceAll('Phường ', '').replaceAll('Xã ', ''))) {
            selectedWard = w;
            break;
          }
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sửa thông tin kho',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Cập nhật thông tin kho',
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
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên kho *',
                          hintText: 'VD: Kho Bình Thạnh',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã kho',
                          hintText: 'VD: KHO-BT-01',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Loại kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildTypeChip('main', 'Kho chính', Icons.home_work, Colors.blue, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('transit', 'Trung chuyển', Icons.local_shipping, Colors.orange, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('vehicle', 'Xe tải', Icons.local_shipping_outlined, Colors.green, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('virtual', 'Ảo', Icons.cloud_outlined, Colors.purple, selectedType, (v) => setSheetState(() => selectedType = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // === ĐỊA CHỈ VIỆT NAM ===
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Địa chỉ kho',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.teal.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Địa chỉ chính xác giúp tài xế xác định điểm xuất phát',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Số nhà + Tên đường
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: streetNumberController,
                              decoration: InputDecoration(
                                labelText: 'Số nhà',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: streetController,
                              decoration: InputDecoration(
                                labelText: 'Tên đường',
                                hintText: 'VD: Lê Văn Thọ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Quận/Huyện dropdown
                      DropdownButtonFormField<dvhcvn.Level2>(
                        value: selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'Quận/Huyện *',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: districts.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedDistrict = value;
                            selectedWard = null;
                            wards = value?.children ?? [];
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Phường/Xã dropdown
                      DropdownButtonFormField<dvhcvn.Level3>(
                        value: selectedWard,
                        decoration: InputDecoration(
                          labelText: 'Phường/Xã *',
                          prefixIcon: const Icon(Icons.house),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: wards.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) => setSheetState(() => selectedWard = value),
                      ),
                      const SizedBox(height: 20),
                      
                      // Active Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.check_circle : Icons.block, color: isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? Colors.green.shade700 : Colors.red.shade700),
                                  ),
                                  Text(
                                    isActive ? 'Kho này có thể nhận và xuất hàng' : 'Kho này không còn hoạt động',
                                    style: TextStyle(fontSize: 12, color: isActive ? Colors.green.shade600 : Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setSheetState(() => isActive = v),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên kho')),
                        );
                        return;
                      }
                      
                      try {
                        // Build full address from structured fields
                        final addressParts = <String>[];
                        if (streetNumberController.text.trim().isNotEmpty) {
                          addressParts.add(streetNumberController.text.trim());
                        }
                        if (streetController.text.trim().isNotEmpty) {
                          addressParts.add(streetController.text.trim());
                        }
                        if (selectedWard != null) {
                          addressParts.add(selectedWard!.name);
                        }
                        if (selectedDistrict != null) {
                          addressParts.add(selectedDistrict!.name);
                        }
                        if (selectedCity != null) {
                          addressParts.add(selectedCity!.name);
                        }
                        final fullAddress = addressParts.join(', ');
                        
                        // Auto geocode từ địa chỉ
                        double? lat;
                        double? lng;
                        if (fullAddress.isNotEmpty) {
                          try {
                            final locations = await locationFromAddress(fullAddress);
                            if (locations.isNotEmpty) {
                              lat = locations.first.latitude;
                              lng = locations.first.longitude;
                            }
                          } catch (e) {
                            debugPrint('Geocoding failed: $e');
                          }
                        }
                        
                        await supabase.from('warehouses').update({
                          'name': nameController.text,
                          'code': codeController.text.isEmpty ? null : codeController.text,
                          'type': selectedType,
                          // Structured address fields
                          'street_number': streetNumberController.text.trim().isEmpty ? null : streetNumberController.text.trim(),
                          'street': streetController.text.trim().isEmpty ? null : streetController.text.trim(),
                          'ward': selectedWard?.name.replaceAll('Phường ', '').replaceAll('Xã ', '').replaceAll('Thị trấn ', ''),
                          'district': selectedDistrict?.name.replaceAll('Quận ', '').replaceAll('Huyện ', '').replaceAll('Thành phố ', '').replaceAll('Thị xã ', ''),
                          'city': selectedCity?.name.replaceAll('Thành phố ', '').replaceAll('Tỉnh ', ''),
                          'address': fullAddress.isEmpty ? null : fullAddress,
                          'lat': lat,
                          'lng': lng,
                          'is_active': isActive,
                        }).eq('id', warehouse['id']);
                        
                        if (mounted) Navigator.pop(context);
                        _loadWarehouses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật kho'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cập nhật kho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeChip(String value, String label, IconData icon, Color color, String selected, Function(String) onSelect) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
  
  void _showAddWarehouseDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final streetNumberController = TextEditingController();
    final streetController = TextEditingController();
    String selectedType = 'main';
    bool isActive = true;
    
    // Vietnamese Address Selection
    dvhcvn.Level1? selectedCity;
    dvhcvn.Level2? selectedDistrict;
    dvhcvn.Level3? selectedWard;
    List<dvhcvn.Level2> districts = [];
    List<dvhcvn.Level3> wards = [];
    
    // Initialize to Ho Chi Minh City by default
    final hcm = dvhcvn.findLevel1ByName('Thành phố Hồ Chí Minh');
    if (hcm != null) {
      selectedCity = hcm;
      districts = hcm.children;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_business, color: Colors.teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thêm kho mới',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Điền thông tin kho cần tạo',
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
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên kho *',
                          hintText: 'VD: Kho Bình Thạnh',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã kho',
                          hintText: 'VD: KHO-BT-01',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Loại kho', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildTypeChip('main', 'Kho chính', Icons.home_work, Colors.blue, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('transit', 'Trung chuyển', Icons.local_shipping, Colors.orange, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('vehicle', 'Xe tải', Icons.local_shipping_outlined, Colors.green, selectedType, (v) => setSheetState(() => selectedType = v)),
                          _buildTypeChip('virtual', 'Ảo', Icons.cloud_outlined, Colors.purple, selectedType, (v) => setSheetState(() => selectedType = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // === ĐỊA CHỈ VIỆT NAM ===
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Địa chỉ kho',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.teal.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Địa chỉ chính xác giúp tài xế xác định điểm xuất phát',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Số nhà + Tên đường
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: streetNumberController,
                              decoration: InputDecoration(
                                labelText: 'Số nhà',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: streetController,
                              decoration: InputDecoration(
                                labelText: 'Tên đường',
                                hintText: 'VD: Lê Văn Thọ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Quận/Huyện dropdown
                      DropdownButtonFormField<dvhcvn.Level2>(
                        value: selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'Quận/Huyện *',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: districts.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedDistrict = value;
                            selectedWard = null;
                            wards = value?.children ?? [];
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Phường/Xã dropdown
                      DropdownButtonFormField<dvhcvn.Level3>(
                        value: selectedWard,
                        decoration: InputDecoration(
                          labelText: 'Phường/Xã *',
                          prefixIcon: const Icon(Icons.house),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        isExpanded: true,
                        items: wards.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (value) => setSheetState(() => selectedWard = value),
                      ),
                      const SizedBox(height: 20),
                      
                      // Active Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.check_circle : Icons.block, color: isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActive ? 'Đang hoạt động' : 'Ngưng hoạt động',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? Colors.green.shade700 : Colors.red.shade700),
                                  ),
                                  Text(
                                    isActive ? 'Kho này có thể nhận và xuất hàng' : 'Kho này không còn hoạt động',
                                    style: TextStyle(fontSize: 12, color: isActive ? Colors.green.shade600 : Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (v) => setSheetState(() => isActive = v),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Submit Button
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên kho')),
                        );
                        return;
                      }
                      
                      try {
                        final companyId = ref.read(authProvider).user?.companyId ?? '';
                        
                        // Build full address from structured fields
                        final addressParts = <String>[];
                        if (streetNumberController.text.trim().isNotEmpty) {
                          addressParts.add(streetNumberController.text.trim());
                        }
                        if (streetController.text.trim().isNotEmpty) {
                          addressParts.add(streetController.text.trim());
                        }
                        if (selectedWard != null) {
                          addressParts.add(selectedWard!.name);
                        }
                        if (selectedDistrict != null) {
                          addressParts.add(selectedDistrict!.name);
                        }
                        if (selectedCity != null) {
                          addressParts.add(selectedCity!.name);
                        }
                        final fullAddress = addressParts.join(', ');
                        
                        // Auto geocode từ địa chỉ
                        double? lat;
                        double? lng;
                        if (fullAddress.isNotEmpty) {
                          try {
                            final locations = await locationFromAddress(fullAddress);
                            if (locations.isNotEmpty) {
                              lat = locations.first.latitude;
                              lng = locations.first.longitude;
                            }
                          } catch (e) {
                            debugPrint('Geocoding failed: $e');
                          }
                        }
                        
                        await supabase.from('warehouses').insert({
                          'company_id': companyId,
                          'name': nameController.text,
                          'code': codeController.text.isEmpty ? null : codeController.text,
                          'type': selectedType,
                          // Structured address fields
                          'street_number': streetNumberController.text.trim().isEmpty ? null : streetNumberController.text.trim(),
                          'street': streetController.text.trim().isEmpty ? null : streetController.text.trim(),
                          'ward': selectedWard?.name.replaceAll('Phường ', '').replaceAll('Xã ', '').replaceAll('Thị trấn ', ''),
                          'district': selectedDistrict?.name.replaceAll('Quận ', '').replaceAll('Huyện ', '').replaceAll('Thành phố ', '').replaceAll('Thị xã ', ''),
                          'city': selectedCity?.name.replaceAll('Thành phố ', '').replaceAll('Tỉnh ', ''),
                          'address': fullAddress.isEmpty ? null : fullAddress,
                          'lat': lat,
                          'lng': lng,
                          'is_active': isActive,
                        });
                        
                        if (mounted) Navigator.pop(context);
                        _loadWarehouses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm kho mới thành công'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tạo kho mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = isSelected ? null : (label == 'Tất cả' ? null : label));
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
                              _getCategoryIcon(product.categoryName),
                              color: Colors.teal.shade400,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          _getCategoryIcon(product.categoryName),
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
                                  '${product.minStock ?? 0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: stockColor,
                                  ),
                                ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: product, 
        currencyFormat: currencyFormat,
        onEdit: () {
          Navigator.pop(context);
          _showEditProductSheet(context, product);
        },
        onAdjustStock: () {
          Navigator.pop(context);
          _showAdjustStockSheet(context, product);
        },
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductSheet(
        categories: _categories,
        onSaved: (product) {
          _loadStats();
          _loadInitial();
        },
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
        categories: _categories,
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
}

// ==================== PRODUCT DETAIL SHEET ====================
class ProductDetailSheet extends StatelessWidget {
  final OdoriProduct product;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.currencyFormat,
    required this.onEdit,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final stock = product.minStock ?? 0;
    final minStock = product.reorderPoint ?? 10;
    
    Color stockColor = Colors.green;
    String stockStatus = 'Còn hàng';
    if (stock == 0) {
      stockColor = Colors.red;
      stockStatus = 'Hết hàng';
    } else if (stock < minStock) {
      stockColor = Colors.orange;
      stockStatus = 'Sắp hết hàng';
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.inventory_2, color: Colors.teal.shade400, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.sku,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${product.unit}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceCard(
                        'Giá bán lẻ',
                        currencyFormat.format(product.sellingPrice),
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceCard(
                        'Giá bán sỉ',
                        currencyFormat.format(product.wholesalePrice ?? 0),
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: stockColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory, color: stockColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stockStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: stockColor,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Tồn kho: $stock ${product.unit}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tối thiểu',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          Text(
                            '$minStock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (product.description != null && product.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Mô tả',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAdjustStock,
                        icon: const Icon(Icons.add_box),
                        label: const Text('Điều chỉnh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String title, String price, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ADD PRODUCT SHEET ====================
class AddProductSheet extends ConsumerStatefulWidget {
  final List<String> categories;
  final Function(OdoriProduct) onSaved;

  const AddProductSheet({
    super.key,
    required this.categories,
    required this.onSaved,
  });

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _unitController = TextEditingController(text: 'cái');
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.companyId == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      final data = {
        'company_id': user.companyId,
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'selling_price': double.tryParse(_sellingPriceController.text) ?? 0,
        'wholesale_price': double.tryParse(_wholesalePriceController.text),
        'unit': _unitController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'status': 'active',
        'created_by': user.id,
      };

      final response = await supabase
          .from('products')
          .insert(data)
          .select()
          .single();

      final product = OdoriProduct.fromJson(response);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved(product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_box, color: Colors.teal.shade600),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thêm sản phẩm mới',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên sản phẩm *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _skuController,
                              decoration: InputDecoration(
                                labelText: 'Mã SKU *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập SKU' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: InputDecoration(
                                labelText: 'Đơn vị',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá bán lẻ *',
                                suffixText: 'đ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _wholesalePriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá bán sỉ',
                                suffixText: 'đ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (widget.categories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: widget.categories.map((cat) => 
                            DropdownMenuItem(value: cat, child: Text(cat))
                          ).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Thêm sản phẩm', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== EDIT PRODUCT SHEET ====================
class EditProductSheet extends ConsumerStatefulWidget {
  final OdoriProduct product;
  final List<String> categories;
  final VoidCallback onSaved;

  const EditProductSheet({
    super.key,
    required this.product,
    required this.categories,
    required this.onSaved,
  });

  @override
  ConsumerState<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _wholesalePriceController;
  late final TextEditingController _unitController;
  late final TextEditingController _descriptionController;
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku);
    _sellingPriceController = TextEditingController(text: widget.product.sellingPrice.toInt().toString());
    _wholesalePriceController = TextEditingController(text: widget.product.wholesalePrice?.toInt().toString() ?? '');
    _unitController = TextEditingController(text: widget.product.unit);
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    _selectedCategory = widget.product.categoryName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.from('products').update({
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'selling_price': double.tryParse(_sellingPriceController.text) ?? 0,
        'wholesale_price': double.tryParse(_wholesalePriceController.text),
        'unit': _unitController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.product.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật sản phẩm'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit, color: Colors.blue.shade600),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Chỉnh sửa sản phẩm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên sản phẩm *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _skuController,
                              decoration: InputDecoration(
                                labelText: 'Mã SKU *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập SKU' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: InputDecoration(
                                labelText: 'Đơn vị',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá bán lẻ *',
                                suffixText: 'đ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _wholesalePriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá bán sỉ',
                                suffixText: 'đ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ADJUST STOCK SHEET ====================
class AdjustStockSheet extends ConsumerStatefulWidget {
  final OdoriProduct product;
  final VoidCallback onSaved;

  const AdjustStockSheet({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  ConsumerState<AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<AdjustStockSheet> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  String _adjustType = 'add';
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số lượng hợp lệ'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('Vui lòng đăng nhập lại');

      final currentStock = widget.product.minStock ?? 0;
      
      int newStock;
      String reason;
      switch (_adjustType) {
        case 'add':
          newStock = currentStock + qty;
          reason = 'Nhập kho';
          break;
        case 'remove':
          newStock = (currentStock - qty).clamp(0, double.infinity).toInt();
          reason = 'Xuất kho';
          break;
        case 'set':
        default:
          newStock = qty;
          reason = 'Điều chỉnh tồn';
          break;
      }

      await supabase.from('products').update({
        'min_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.product.id);

      await supabase.from('stock_movements').insert({
        'product_id': widget.product.id,
        'company_id': widget.product.companyId,
        'type': _adjustType == 'add' ? 'in' : (_adjustType == 'remove' ? 'out' : 'adjustment'),
        'quantity': qty,
        'reason': reason,
        'notes': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'created_by': user.id,
      }).catchError((_) {});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật tồn kho: $newStock ${widget.product.unit}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = widget.product.minStock ?? 0;
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.inventory, color: Colors.orange.shade600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Điều chỉnh tồn kho',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                widget.product.name,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('Tồn kho hiện tại:'),
                          const Spacer(),
                          Text(
                            '$currentStock ${widget.product.unit}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text('Loại điều chỉnh', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildTypeChip('add', 'Nhập kho', Icons.add_circle, Colors.green)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('remove', 'Xuất kho', Icons.remove_circle, Colors.red)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('set', 'Đặt số lượng', Icons.edit, Colors.blue)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _adjustType == 'set' ? 'Số lượng mới' : 'Số lượng',
                        suffixText: widget.product.unit,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Xác nhận', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon, Color color) {
    final isSelected = _adjustType == value;
    return GestureDetector(
      onTap: () => setState(() => _adjustType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade500, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
