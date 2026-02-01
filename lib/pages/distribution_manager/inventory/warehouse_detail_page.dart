// Warehouse Detail Page - Full page view when selecting a warehouse

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/odori_product.dart';
import '../../../providers/auth_provider.dart';
import 'inventory_constants.dart';
import 'warehouse_dialogs.dart';

class WarehouseDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> warehouse;
  final String? warehouseName;
  final String? warehouseCode;
  final String? warehouseAddress;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback? onStockIn;
  final VoidCallback? onStockOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onEdit;
  final List<Map<String, dynamic>>? allWarehouses; // For transfer stock
  final VoidCallback? onRefresh; // Callback to refresh parent data
  final bool isEmbedded; // If true, hide back button and use as tab content

  const WarehouseDetailPage({
    super.key,
    required this.warehouse,
    this.warehouseName,
    this.warehouseCode,
    this.warehouseAddress,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
    this.onStockIn,
    this.onStockOut,
    this.onTransfer,
    this.onEdit,
    this.allWarehouses,
    this.onRefresh,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends ConsumerState<WarehouseDetailPage> with SingleTickerProviderStateMixin {
  // Stock data
  List<Map<String, dynamic>> _stocks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _totalProducts = 0;
  int _totalQuantity = 0;
  int _lowStockCount = 0;
  
  // All products for stock-in selection
  List<OdoriProduct> _allProducts = [];
  
  // All warehouses for embedded mode
  List<Map<String, dynamic>> _allWarehouses = [];
  
  // Movement history
  List<Map<String, dynamic>> _movements = [];
  bool _isLoadingMovements = false;
  
  // Tab controller
  late TabController _tabController;
  
  // Getters for warehouse info (use props if available, else from warehouse data)
  String get _warehouseName => widget.warehouseName ?? widget.warehouse['name'] ?? 'Kho';
  String get _warehouseCode => widget.warehouseCode ?? widget.warehouse['code'] ?? '';
  String get _warehouseAddress => widget.warehouseAddress ?? widget.warehouse['address'] ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStocks();
    _loadAllProducts();
    _loadMovements();
    if (widget.isEmbedded) {
      _loadAllWarehouses();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load all warehouses for embedded mode (transfer feature)
  Future<void> _loadAllWarehouses() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;
      
      final data = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('name');
      
      if (mounted) {
        setState(() {
          _allWarehouses = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    }
  }
  
  // Load movement history
  Future<void> _loadMovements() async {
    setState(() => _isLoadingMovements = true);
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final warehouseId = widget.warehouse['id'];
      if (warehouseId == null) {
        if (mounted) setState(() => _isLoadingMovements = false);
        return;
      }
      
      debugPrint('📦 Loading movements for warehouse: $warehouseId');
      
      final data = await supabase
          .from('inventory_movements')
          .select('*, products(id, name, sku, unit, image_url)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .order('created_at', ascending: false)
          .limit(100);

      debugPrint('📦 Loaded ${(data as List).length} movements');

      if (mounted) {
        setState(() {
          _movements = List<Map<String, dynamic>>.from(data);
          _isLoadingMovements = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading movements: $e');
      debugPrint('❌ Error loading movements: $e');
      if (mounted) setState(() => _isLoadingMovements = false);
    }
  }
  
  // Load all products for stock-in selection only
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

  Future<void> _loadStocks() async {
    setState(() => _isLoading = true);
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final warehouseId = widget.warehouse['id'];
      if (warehouseId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final data = await supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit, category_id, selling_price, image_url)')
          .eq('company_id', companyId)
          .eq('warehouse_id', warehouseId)
          .order('products(name)');

      final stocks = List<Map<String, dynamic>>.from(data);
      
      int totalProducts = stocks.length;
      int totalQuantity = 0;
      int lowStock = 0;
      
      for (var stock in stocks) {
        final qty = stock['quantity'] ?? 0;
        totalQuantity += qty as int;
        if (qty > 0 && qty <= 10) lowStock++;
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

  // Helper method to get warehouse stock for stock out/transfer
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

  // Open Stock In sheet directly
  void _openStockInSheet() {
    StockInSheet.show(
      context: context,
      ref: ref,
      warehouse: widget.warehouse,
      products: _allProducts,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
        widget.onRefresh?.call();
      },
    );
  }

  // Open Stock Out sheet directly
  void _openStockOutSheet() {
    StockOutSheet.show(
      context: context,
      ref: ref,
      warehouse: widget.warehouse,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
        widget.onRefresh?.call();
      },
    );
  }

  // Open Transfer Stock sheet directly
  void _openTransferSheet() {
    final warehouses = widget.allWarehouses ?? _allWarehouses;
    TransferStockSheet.show(
      context: context,
      ref: ref,
      fromWarehouse: widget.warehouse,
      allWarehouses: warehouses,
      getWarehouseStock: _getWarehouseStock,
      onSuccess: () {
        _loadStocks();
        _loadAllProducts();
        _loadMovements();
        widget.onRefresh?.call();
      },
    );
  }

  List<Map<String, dynamic>> get _filteredStocks {
    if (_searchQuery.isEmpty) return _stocks;
    return _stocks.where((stock) {
      final product = stock['products'] as Map<String, dynamic>? ?? {};
      final name = (product['name'] ?? '').toString().toLowerCase();
      final sku = (product['sku'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             sku.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Collapsible SliverAppBar
          SliverAppBar(
            title: Text(_warehouseName),
            backgroundColor: widget.typeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            floating: true, // AppBar appears when scroll up
            snap: true, // Snap to full size when appearing
            pinned: true, // Keep minimal height when collapsed
            expandedHeight: 140, // Height when expanded
            collapsedHeight: 56,
            automaticallyImplyLeading: !widget.isEmbedded, // Hide back button if embedded
            actions: [
              IconButton(
                onPressed: _loadStocks,
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
              if (!widget.isEmbedded) // Only show edit menu if not embedded
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa thông tin kho'),
                      ]),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pop(context);
                      widget.onEdit?.call();
                    }
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: widget.typeColor,
                padding: const EdgeInsets.only(top: 56), // Below AppBar
                child: Column(
                  children: [
                    // Warehouse Info Header (will hide when collapsed)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Row(
                        children: [
                          // Icon + Info
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(widget.typeIcon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.typeLabel,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (_warehouseCode.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mã: $_warehouseCode',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_warehouseAddress.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.white70),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          _warehouseAddress,
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
          
          // Quick Actions - will hide when scrolling
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
          
          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: TextField(
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
                  fillColor: Colors.grey.shade50,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          
          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.teal,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2, size: 16), SizedBox(width: 6), Text('Sản phẩm')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, size: 16), SizedBox(width: 6), Text('Lịch sử')])),
                ],
              ),
            ),
          ),
        ],
        // Tab Content
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStockContent(),
            _buildHistoryContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStockContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Luôn hiển thị danh sách sản phẩm để dễ nhập kho
    return _buildProductListForStockIn();
  }
  
  Widget _buildHistoryContent() {
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử xuất nhập kho',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
        itemBuilder: (context, index) {
          final movement = _movements[index];
          return _buildMovementCard(movement);
        },
      ),
    );
  }
  
  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final product = movement['products'] as Map<String, dynamic>? ?? {};
    final user = movement['users'] as Map<String, dynamic>? ?? {};
    final productName = product['name'] ?? 'Sản phẩm';
    final productSku = product['sku'] ?? '';
    final imageUrl = product['image_url'];
    final unit = product['unit'] ?? '';
    final type = movement['type'] ?? '';
    final quantity = movement['quantity'] ?? 0;
    final beforeQty = movement['before_quantity'] ?? 0;
    final afterQty = movement['after_quantity'] ?? 0;
    final reason = movement['reason'] ?? movement['notes'] ?? '';
    final createdAt = DateTime.tryParse(movement['created_at'] ?? '');
    final createdBy = user['full_name'] ?? 'Hệ thống';
    
    // Type styling
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    
    switch (type) {
      case 'in':
        typeColor = Colors.green;
        typeIcon = Icons.add_box;
        typeLabel = 'Nhập kho';
        break;
      case 'out':
        typeColor = Colors.red;
        typeIcon = Icons.outbox;
        typeLabel = 'Xuất kho';
        break;
      case 'transfer':
        typeColor = Colors.blue;
        typeIcon = Icons.swap_horiz;
        typeLabel = 'Chuyển kho';
        break;
      case 'adjustment':
      case 'count':
        typeColor = Colors.orange;
        typeIcon = Icons.edit;
        typeLabel = 'Điều chỉnh';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
        typeLabel = type;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.inventory_2,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 20),
            ),
            const SizedBox(width: 10),
            
            // Movement Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 12, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              typeLabel,
                              style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type == 'in' ? '+$quantity' : '-$quantity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        ' $unit',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (productSku.isNotEmpty)
                    Text(
                      productSku,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Time & Stock Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (createdAt != null)
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$beforeQty → $afterQty',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  createdBy,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    
    return '${dt.day}/${dt.month}/${dt.year}';
  }
  
  // Widget hiển thị danh sách sản phẩm để nhập kho
  Widget _buildProductListForStockIn() {
    // Filter products based on search
    final filteredProducts = _searchQuery.isEmpty
        ? _allProducts
        : _allProducts.where((p) => 
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.sku.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
    
    if (_allProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Không tìm thấy sản phẩm' 
                  : 'Chưa có sản phẩm nào',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Chọn sản phẩm để nhập kho (${filteredProducts.length})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllProducts,
            child: ListView.builder(
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductQuickStockCard(product);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  // Card sản phẩm compact với nút nhập kho nhanh
  Widget _buildProductQuickStockCard(OdoriProduct product) {
    // Tìm tồn kho của sản phẩm trong kho này
    final stockRecord = _stocks.firstWhere(
      (s) => s['product_id'] == product.id,
      orElse: () => {},
    );
    final currentStock = stockRecord.isNotEmpty ? (stockRecord['quantity'] ?? 0) : 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.inventory_2,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 24),
            ),
            const SizedBox(width: 10),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (product.sku.isNotEmpty) ...[
                        Text(
                          product.sku,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        product.unit,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                  if (product.sellingPrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(product.sellingPrice),
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            
            // Stock info + Quick Stock In Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Current Stock Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentStock > 0 
                        ? (currentStock <= 10 ? Colors.orange.shade50 : Colors.blue.shade50)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 12,
                        color: currentStock > 0 
                            ? (currentStock <= 10 ? Colors.orange : Colors.blue)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentStock > 0 
                              ? (currentStock <= 10 ? Colors.orange.shade700 : Colors.blue.shade700)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Quick Stock In Button
                ElevatedButton.icon(
                  onPressed: () => _showQuickStockInDialog(product),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Nhập', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Dialog nhập kho nhanh
  void _showQuickStockInDialog(OdoriProduct product) {
    final qtyController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_box, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Nhập kho nhanh', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (product.sku.isNotEmpty) Text('SKU: ${product.sku}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số lượng',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số lượng hợp lệ')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _performQuickStockIn(product, qty);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Nhập kho'),
          ),
        ],
      ),
    );
  }
  
  // Thực hiện nhập kho nhanh
  Future<void> _performQuickStockIn(OdoriProduct product, int quantity) async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      final userId = ref.read(authProvider).user?.id ?? '';
      final warehouseId = widget.warehouse['id'];
      if (warehouseId == null) {
        throw Exception('Kho không hợp lệ');
      }
      
      // Only create movement - trigger will handle inventory update
      await supabase.from('inventory_movements').insert({
        'company_id': companyId,
        'warehouse_id': warehouseId,
        'product_id': product.id,
        'type': 'in',
        'quantity': quantity,
        'reason': 'Nhập kho nhanh',
        'created_by': userId,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhập $quantity ${product.unit} ${product.name}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStocks(); // Refresh
        _loadMovements(); // Refresh history
      }
    } catch (e) {
      debugPrint('❌ Error quick stock in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductStockCard(Map<String, dynamic> stock) {
    final product = stock['products'] as Map<String, dynamic>? ?? {};
    final productName = product['name'] ?? 'Sản phẩm';
    final productSku = product['sku'] ?? '';
    final unit = product['unit'] ?? 'Cái';
    final category = product['category'] ?? '';
    final imageUrl = product['image_url'];
    final quantity = stock['quantity'] ?? 0;
    final minQuantity = stock['min_quantity'] ?? 10;
    
    final Color qtyColor;
    final IconData qtyIcon;
    // Status used in tooltip
    if (quantity <= 0) {
      qtyColor = Colors.red;
      qtyIcon = Icons.error;
    } else if (quantity <= minQuantity) {
      qtyColor = Colors.orange;
      qtyIcon = Icons.warning;
    } else {
      qtyColor = Colors.green;
      qtyIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade400,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (productSku.isNotEmpty)
                    Text(
                      'SKU: $productSku',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  if (category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: qtyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(qtyIcon, size: 14, color: qtyColor),
                      const SizedBox(width: 4),
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: qtyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Delegate for TabBar in SliverPersistentHeader
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
    return false;
  }
}
