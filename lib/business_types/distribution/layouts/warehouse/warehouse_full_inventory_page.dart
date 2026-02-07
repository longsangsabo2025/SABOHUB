import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../pages/manager/inventory/warehouse_detail_page.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';
import 'sheets/warehouse_form_sheet.dart';
import 'sheets/stock_import_sheet.dart';
import 'sheets/stock_adjust_sheet.dart';

class WarehouseFullInventoryPage extends ConsumerStatefulWidget {
  const WarehouseFullInventoryPage({super.key});

  @override
  ConsumerState<WarehouseFullInventoryPage> createState() => _FullInventoryPageState();
}

class _FullInventoryPageState extends ConsumerState<WarehouseFullInventoryPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _warehouses = [];
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  String? _selectedWarehouseId; // null = All warehouses (Tất cả kho)
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  DateTimeRange? _movementDateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
    _loadMovements();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      var query = supabase
          .from('inventory_movements')
          .select('*, products(id, name, sku, unit)')
          .eq('company_id', companyId);

      if (_movementDateFilter != null) {
        query = query
            .gte('created_at', _movementDateFilter!.start.toIso8601String())
            .lte('created_at', _movementDateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(200);

      setState(() {
        _movements = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load movements', e);
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .order('name');

      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      AppLogger.error('Failed to load warehouses', e);
    }
  }

  Future<void> _loadInventory() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var query = supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit, image_url), warehouses(id, name, code, type)')
          .eq('company_id', companyId);

      if (_showLowStockOnly) {
        query = query.lt('quantity', 10);
      }

      final data = await query.order('products(name)');

      setState(() {
        _inventory = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load inventory', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredInventory {
    var result = _inventory.toList();
    
    // Filter by warehouse if selected
    if (_selectedWarehouseId != null) {
      result = result.where((item) => item['warehouse_id'] == _selectedWarehouseId).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        final product = item['products'] as Map<String, dynamic>?;
        final name = (product?['name'] ?? '').toString().toLowerCase();
        final sku = (product?['sku'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            sku.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return result;
  }

  void _showStockImportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockImportSheet(
        inventory: _inventory,
        onSuccess: () {
          _loadInventory();
          _loadMovements();
        },
      ),
    );
  }

  Widget _buildWarehouseFilterChip(String? warehouseId, String label) {
    final isSelected = _selectedWarehouseId == warehouseId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedWarehouseId = warehouseId);
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.teal,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showStockAdjustSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockAdjustSheet(
        item: item,
        onSuccess: () {
          _loadInventory();
          _loadMovements();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _inventory.where((item) => (item['quantity'] as int? ?? 0) < 10).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'warehouseStockImport',
        onPressed: _showStockImportSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('Nhập kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Quản lý kho',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (lowStockCount > 0)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showLowStockOnly = !_showLowStockOnly;
                              _isLoading = true;
                            });
                            _loadInventory();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showLowStockOnly ? Colors.orange : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: _showLowStockOnly ? Colors.white : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$lowStockCount sắp hết',
                                  style: TextStyle(
                                    color: _showLowStockOnly ? Colors.white : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Làm mới',
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadInventory();
                          _loadMovements();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Đã làm mới kho'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc SKU...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),

                  // Warehouse filter chips
                  if (_warehouses.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildWarehouseFilterChip(null, 'Tất cả kho'),
                          ..._warehouses.map((wh) => _buildWarehouseFilterChip(
                            wh['id'], 
                            wh['name'] ?? 'Kho',
                          )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.teal.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: Colors.teal,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Tồn kho', icon: Icon(Icons.inventory_2_outlined, size: 20)),
                      Tab(text: 'Lịch sử', icon: Icon(Icons.history, size: 20)),
                      Tab(text: 'DS Kho', icon: Icon(Icons.warehouse_outlined, size: 20)),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Inventory list
                  _buildInventoryList(),
                  // Tab 2: Movement history
                  _buildMovementHistory(),
                  // Tab 3: Warehouse management
                  _buildWarehouseList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredInventory.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy sản phẩm',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showStockImportSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Nhập kho ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadInventory();
                  await _loadMovements();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _filteredInventory.length,
                  itemBuilder: (context, index) {
                    final item = _filteredInventory[index];
                    return _buildInventoryCard(item);
                  },
                ),
              );
  }

  Widget _buildMovementDateFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final picked = await showQuickDateRangePicker(context, current: _movementDateFilter);
          if (picked != null) {
            if (picked.start.year == 1970) {
              setState(() => _movementDateFilter = null);
            } else {
              setState(() => _movementDateFilter = picked);
            }
            _loadMovements();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _movementDateFilter != null ? Colors.indigo.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _movementDateFilter != null ? Colors.indigo.shade400 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16,
                color: _movementDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _movementDateFilter != null
                      ? getDateRangeLabel(_movementDateFilter!)
                      : 'Tất cả thời gian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _movementDateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_movementDateFilter != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _movementDateFilter = null);
                    _loadMovements();
                  },
                  child: Icon(Icons.close, size: 16, color: Colors.indigo.shade700),
                )
              else
                Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementHistory() {
    return Column(
      children: [
        _buildMovementDateFilter(),
        Expanded(
          child: _movements.isEmpty
              ? Center(
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
                        _movementDateFilter != null
                            ? 'Không có lịch sử trong khoảng thời gian này'
                            : 'Chưa có lịch sử nhập/xuất kho',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMovements,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _movements.length,
                    itemBuilder: (context, index) {
                      final movement = _movements[index];
                      return _buildMovementCard(movement);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final product = movement['products'] as Map<String, dynamic>?;
    final type = movement['type'] as String? ?? 'in';
    final quantity = movement['quantity'] as int? ?? 0;
    final reason = movement['reason'] as String?;
    final createdAt = movement['created_at'] as String?;
    
    // Determine color and icon based on type
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

    // Format date
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
          // Type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product?['name'] ?? 'Sản phẩm',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (reason != null && reason.isNotEmpty)
                  Text(
                    reason,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${type == 'out' ? '-' : '+'}$quantity',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    final warehouse = item['warehouses'] as Map<String, dynamic>?;
    final quantity = item['quantity'] as int? ?? 0;
    final isLowStock = quantity < 10;
    final warehouseName = warehouse?['name'] ?? 'Kho mặc định';
    final isMainWarehouse = warehouse?['type'] == 'main';

    return GestureDetector(
      onTap: () => _showStockAdjustSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLowStock ? Border.all(color: Colors.orange.shade200, width: 1.5) : null,
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
            // Product image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: product?['image_url'] != null && (product!['image_url'] as String).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 28),
                      ),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?['name'] ?? 'Sản phẩm',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                          'SKU: ${product?['sku'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product?['unit'] ?? 'đơn vị',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isMainWarehouse ? Icons.home_work : Icons.warehouse,
                        size: 12,
                        color: isMainWarehouse ? Colors.blue.shade400 : Colors.orange.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        warehouseName,
                        style: TextStyle(
                          color: isMainWarehouse ? Colors.blue.shade600 : Colors.orange.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quantity display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLowStock ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isLowStock ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WAREHOUSE LIST TAB - Danh sách kho (Thêm/Sửa/Xóa)
  // ============================================================================
  Widget _buildWarehouseList() {
    return RefreshIndicator(
      onRefresh: _loadWarehouses,
      child: _warehouses.isEmpty
          ? Center(
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
                    onPressed: () => _showAddWarehouseSheet(),
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
            )
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _warehouses.length,
                  itemBuilder: (context, index) {
                    final warehouse = _warehouses[index];
                    return _buildWarehouseCard(warehouse);
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'addWarehouse',
                    onPressed: () => _showAddWarehouseSheet(),
                    backgroundColor: Colors.teal,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Thêm kho', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWarehouseCard(Map<String, dynamic> warehouse) {
    final name = warehouse['name'] ?? 'Kho';
    final code = warehouse['code'] ?? '';
    final type = warehouse['type'] ?? 'main';
    final address = warehouse['address'] ?? '';
    final isActive = warehouse['is_active'] ?? true;
    
    // Type color
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openWarehouseDetail(warehouse, typeColor, typeLabel, typeIcon),
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

  void _openWarehouseDetail(Map<String, dynamic> warehouse, Color typeColor, String typeLabel, IconData typeIcon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarehouseDetailPage(
          warehouse: warehouse,
          warehouseName: warehouse['name'] ?? 'Kho',
          warehouseCode: warehouse['code'] ?? '',
          warehouseAddress: warehouse['address'] ?? '',
          typeColor: typeColor,
          typeLabel: typeLabel,
          typeIcon: typeIcon,
          onStockIn: () {},
          onStockOut: () {},
          onTransfer: () {},
          onEdit: () => _showEditWarehouseSheet(warehouse),
          allWarehouses: _warehouses,
          onRefresh: () {
            _loadInventory();
            _loadMovements();
          },
        ),
      ),
    );
  }

  void _showAddWarehouseSheet() {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy công ty'), backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WarehouseFormSheet(
        companyId: companyId,
        onSaved: () => _loadWarehouses(),
      ),
    );
  }

  void _showEditWarehouseSheet(Map<String, dynamic> warehouse) {
    final authState = ref.read(authProvider);
    final companyId = authState.user?.companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy công ty'), backgroundColor: Colors.red),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WarehouseFormSheet(
        companyId: companyId,
        warehouse: warehouse,
        onSaved: () => _loadWarehouses(),
      ),
    );
  }

  Future<void> _toggleWarehouseStatus(Map<String, dynamic> warehouse) async {
    try {
      final supabase = Supabase.instance.client;
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
      final supabase = Supabase.instance.client;
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
}
