import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/odori_product.dart';
import '../distribution_manager/inventory/warehouse_dialogs.dart';

final supabase = Supabase.instance.client;

class StockItem {
  final String id;
  final String name;
  final String? sku;
  final String? unit;
  final int quantity;
  final int? reorderLevel;
  final String? imageUrl;
  final double? sellingPrice;

  StockItem({
    required this.id,
    required this.name,
    this.sku,
    this.unit,
    required this.quantity,
    this.reorderLevel,
    this.imageUrl,
    this.sellingPrice,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    return StockItem(
      id: product?['id'] ?? json['product_id'] ?? '',
      name: product?['name'] ?? '',
      sku: product?['sku'],
      unit: product?['unit'],
      quantity: json['quantity'] ?? 0,
      reorderLevel: product?['reorder_level'],
      imageUrl: product?['image_url'],
      sellingPrice: (product?['selling_price'] as num?)?.toDouble(),
    );
  }

  bool get isLowStock => reorderLevel != null && quantity <= reorderLevel!;
  bool get isOutOfStock => quantity <= 0;
}

/// Warehouse Stock View Page  
/// Full-featured page with stock management (similar to manager's warehouse)
class WarehouseStockViewPage extends ConsumerStatefulWidget {
  const WarehouseStockViewPage({super.key});

  @override
  ConsumerState<WarehouseStockViewPage> createState() => _WarehouseStockViewPageState();
}

class _WarehouseStockViewPageState extends ConsumerState<WarehouseStockViewPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // Stock data
  List<StockItem> _stocks = [];
  bool _isLoading = true;
  int _totalProducts = 0;
  int _totalQuantity = 0;
  int _lowStockCount = 0;
  
  // All products for stock-in selection
  List<OdoriProduct> _allProducts = [];
  
  // Movement history
  List<Map<String, dynamic>> _movements = [];
  bool _isLoadingMovements = false;
  
  // Warehouse data
  Map<String, dynamic>? _warehouse;
  List<Map<String, dynamic>> _allWarehouses = [];
  
  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWarehouse();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Load warehouse assigned to this user
  Future<void> _loadWarehouse() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      final userId = authState.user?.id;
      if (companyId == null) return;
      
      // Get warehouse assigned to this warehouse staff (or first warehouse)
      final warehousesData = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .eq('is_active', true);
      
      final warehouses = List<Map<String, dynamic>>.from(warehousesData);
      
      if (warehouses.isNotEmpty) {
        // Try to find warehouse assigned to this user, else use first one
        var userWarehouse = warehouses.firstWhere(
          (w) => w['manager_id'] == userId,
          orElse: () => warehouses.first,
        );
        
        setState(() {
          _warehouse = userWarehouse;
          _allWarehouses = warehouses;
        });
        
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
      }
    } catch (e) {
      debugPrint('❌ Error loading warehouse: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // Load stocks for this warehouse
  Future<void> _loadStocks() async {
    if (_warehouse == null) return;
    setState(() => _isLoading = true);
    
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final warehouseId = _warehouse!['id'];
      
      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit, category_id, selling_price, image_url, reorder_level)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .order('products(name)');

      final stocks = (data as List).map((json) => StockItem.fromJson(json)).toList();
      
      int totalProducts = stocks.length;
      int totalQuantity = 0;
      int lowStock = 0;
      
      for (var stock in stocks) {
        totalQuantity += stock.quantity;
        if (stock.quantity > 0 && stock.quantity <= 10) lowStock++;
      }

      if (mounted) {
        setState(() {
          _stocks = stocks;
          _totalProducts = totalProducts;
          _totalQuantity = totalQuantity;
          _lowStockCount = lowStock;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stocks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Load all products for stock-in selection
  Future<void> _loadAllProducts() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final data = await supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .order('name')
          .limit(200);
      
      final products = (data as List).map((e) => OdoriProduct.fromJson(e)).toList();

      if (mounted) {
        setState(() => _allProducts = products);
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
    }
  }
  
  // Load movement history
  Future<void> _loadMovements() async {
    if (_warehouse == null) return;
    setState(() => _isLoadingMovements = true);
    
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final warehouseId = _warehouse!['id'];
      
      final data = await supabase
          .from('inventory_movements')
          .select('*, products(id, name, sku, unit, image_url)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) {
        setState(() {
          _movements = List<Map<String, dynamic>>.from(data);
          _isLoadingMovements = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading movements: $e');
      if (mounted) setState(() => _isLoadingMovements = false);
    }
  }
  
  // Get warehouse stock for stock out/transfer
  Future<List<Map<String, dynamic>>> _getWarehouseStock(String warehouseId) async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .gt('quantity', 0);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ Error getting warehouse stock: $e');
      return [];
    }
  }
  
  // Open Stock In sheet
  void _openStockInSheet() {
    if (_warehouse == null) return;
    StockInSheet.show(
      context: context,
      ref: ref,
      warehouse: _warehouse!,
      products: _allProducts,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
      },
    );
  }

  // Open Stock Out sheet
  void _openStockOutSheet() {
    if (_warehouse == null) return;
    StockOutSheet.show(
      context: context,
      ref: ref,
      warehouse: _warehouse!,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
      },
    );
  }

  // Open Transfer Stock sheet
  void _openTransferSheet() {
    if (_warehouse == null) return;
    TransferStockSheet.show(
      context: context,
      ref: ref,
      fromWarehouse: _warehouse!,
      allWarehouses: _allWarehouses,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
      },
    );
  }
  
  List<StockItem> get _filteredStocks {
    if (_searchQuery.isEmpty) return _stocks;
    return _stocks.where((stock) {
      final name = stock.name.toLowerCase();
      final sku = (stock.sku ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             sku.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final warehouseName = _warehouse?['name'] ?? 'Kho hàng';
    final warehouseType = _warehouse?['type'] ?? 'main';
    final typeColor = warehouseType == 'main' ? Colors.blue : Colors.teal;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Collapsible SliverAppBar
          SliverAppBar(
            title: Text(warehouseName),
            backgroundColor: typeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 100,
            collapsedHeight: 56,
            actions: [
              IconButton(
                onPressed: () {
                  _loadStocks();
                  _loadMovements();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: typeColor,
                padding: const EdgeInsets.only(top: 56),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              warehouseType == 'main' ? Icons.warehouse : Icons.store,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    warehouseType == 'main' ? 'Kho chính' : 'Kho phụ',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (_warehouse?['address']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.white70),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          _warehouse!['address'],
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Quick Actions
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactQuickAction(
                      icon: Icons.add_box,
                      label: 'Nhập kho',
                      color: Colors.green,
                      onTap: _openStockInSheet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactQuickAction(
                      icon: Icons.outbox,
                      label: 'Xuất kho',
                      color: Colors.red,
                      onTap: _openStockOutSheet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactQuickAction(
                      icon: Icons.swap_horiz,
                      label: 'Chuyển kho',
                      color: Colors.blue,
                      onTap: _openTransferSheet,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  Expanded(child: _buildCompactStatItem('Sản phẩm', '$_totalProducts', Colors.blue, Icons.inventory_2)),
                  Expanded(child: _buildCompactStatItem('Tổng SL', '$_totalQuantity', Colors.green, Icons.shopping_bag)),
                  Expanded(child: _buildCompactStatItem('Sắp hết', '$_lowStockCount', Colors.orange, Icons.warning)),
                ],
              ),
            ),
          ),
          
          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: typeColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: typeColor,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Sản phẩm'),
                  Tab(icon: Icon(Icons.history, size: 18), text: 'Lịch sử'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsContent(),
            _buildHistoryContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _warehouse == null ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactStatItem(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }
  
  // Products Tab Content
  Widget _buildProductsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm trong kho...',
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
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        
        // Product list
        Expanded(
          child: _filteredStocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'Không tìm thấy sản phẩm' : 'Chưa có sản phẩm trong kho',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStocks,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _filteredStocks.length,
                    itemBuilder: (context, index) => _StockCard(item: _filteredStocks[index]),
                  ),
                ),
        ),
      ],
    );
  }
  
  // History Tab Content
  Widget _buildHistoryContent() {
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử nhập/xuất',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _movements.length,
        itemBuilder: (context, index) => _buildMovementCard(_movements[index]),
      ),
    );
  }
  
  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final type = movement['type'] as String? ?? 'in';
    final quantity = movement['quantity'] ?? 0;
    final createdAt = DateTime.tryParse(movement['created_at'] ?? '');
    final product = movement['products'] as Map<String, dynamic>?;
    final productName = product?['name'] ?? 'Sản phẩm';
    final unit = product?['unit'] ?? '';
    final note = movement['note'] as String?;
    
    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    String prefix;
    
    switch (type) {
      case 'in':
        typeIcon = Icons.add_box;
        typeColor = Colors.green;
        typeLabel = 'Nhập';
        prefix = '+';
        break;
      case 'out':
        typeIcon = Icons.outbox;
        typeColor = Colors.red;
        typeLabel = 'Xuất';
        prefix = '-';
        break;
      case 'transfer_in':
        typeIcon = Icons.call_received;
        typeColor = Colors.blue;
        typeLabel = 'Nhận';
        prefix = '+';
        break;
      case 'transfer_out':
        typeIcon = Icons.call_made;
        typeColor = Colors.orange;
        typeLabel = 'Chuyển';
        prefix = '-';
        break;
      default:
        typeIcon = Icons.swap_horiz;
        typeColor = Colors.grey;
        typeLabel = type;
        prefix = '';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(typeIcon, color: typeColor, size: 18),
            ),
            const SizedBox(width: 10),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note?.isNotEmpty == true)
                    Text(
                      note!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // Quantity and time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$prefix$quantity $unit',
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  createdAt != null 
                      ? DateFormat('dd/MM HH:mm').format(createdAt)
                      : '',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Stock Card widget
class _StockCard extends StatelessWidget {
  final StockItem item;

  const _StockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (item.isOutOfStock) {
      statusColor = Colors.red;
      statusLabel = 'Hết hàng';
      statusIcon = Icons.error;
    } else if (item.isLowStock) {
      statusColor = Colors.orange;
      statusLabel = 'Sắp hết';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.green;
      statusLabel = 'Còn hàng';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product icon/image
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.inventory, color: Colors.blue),
                      ),
                    )
                  : const Icon(Icons.inventory, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (item.sku != null)
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            
            // Quantity
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.unit ?? 'pcs',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
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
    );
  }
}

// SliverPersistentHeader delegate for pinned TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
