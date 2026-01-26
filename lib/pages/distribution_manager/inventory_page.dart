// Extracted from distribution_manager_layout.dart
// Inventory Management Page with products, categories, stock tracking

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class _InventoryPageState extends ConsumerState<InventoryPage> {
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadStats();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
