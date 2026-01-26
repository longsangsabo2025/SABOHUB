import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

final supabase = Supabase.instance.client;

// Provider for stock levels
final stockLevelsProvider = FutureProvider.autoDispose<List<StockItem>>((ref) async {
  final authState = ref.watch(authProvider);
  final companyId = authState.user?.companyId;
  if (companyId == null) return [];

  final response = await supabase
      .from('products')
      .select('id, name, sku, unit, stock_quantity, reorder_level')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('name', ascending: true);

  return (response as List).map((json) => StockItem.fromJson(json)).toList();
});

class StockItem {
  final String id;
  final String name;
  final String? sku;
  final String? unit;
  final int quantity;
  final int? reorderLevel;

  StockItem({
    required this.id,
    required this.name,
    this.sku,
    this.unit,
    required this.quantity,
    this.reorderLevel,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      unit: json['unit'],
      quantity: json['stock_quantity'] ?? 0,
      reorderLevel: json['reorder_level'],
    );
  }

  bool get isLowStock => reorderLevel != null && quantity <= reorderLevel!;
  bool get isOutOfStock => quantity <= 0;
}

/// Warehouse Stock View Page
/// Read-only page showing current stock levels
class WarehouseStockViewPage extends ConsumerStatefulWidget {
  const WarehouseStockViewPage({super.key});

  @override
  ConsumerState<WarehouseStockViewPage> createState() => _WarehouseStockViewPageState();
}

class _WarehouseStockViewPageState extends ConsumerState<WarehouseStockViewPage> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, low_stock, out_of_stock
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockLevelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tồn kho'),
        actions: [
          PopupMenuButton<String>(
            icon: Badge(
              isLabelVisible: _filterType != 'all',
              child: const Icon(Icons.filter_list),
            ),
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, 
                      color: _filterType == 'all' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    const Text('Tất cả'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'low_stock',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, 
                      color: _filterType == 'low_stock' ? Colors.orange : null),
                    const SizedBox(width: 8),
                    const Text('Sắp hết'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'out_of_stock',
                child: Row(
                  children: [
                    Icon(Icons.error_outline, 
                      color: _filterType == 'out_of_stock' ? Colors.red : null),
                    const SizedBox(width: 8),
                    const Text('Hết hàng'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(stockLevelsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(stockLevelsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (items) {
          // Apply filters
          var filtered = items.where((item) {
            // Search filter
            if (_searchQuery.isNotEmpty) {
              final nameMatch = item.name.toLowerCase().contains(_searchQuery);
              final skuMatch = item.sku?.toLowerCase().contains(_searchQuery) ?? false;
              if (!nameMatch && !skuMatch) return false;
            }
            // Type filter
            switch (_filterType) {
              case 'low_stock':
                return item.isLowStock && !item.isOutOfStock;
              case 'out_of_stock':
                return item.isOutOfStock;
              default:
                return true;
            }
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Summary stats
          final totalItems = items.length;
          final lowStockItems = items.where((i) => i.isLowStock && !i.isOutOfStock).length;
          final outOfStockItems = items.where((i) => i.isOutOfStock).length;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(stockLevelsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _buildSummaryCard(totalItems, lowStockItems, outOfStockItems),
                const SizedBox(height: 16),
                
                // Stock list
                ...filtered.map((item) => _StockCard(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'Không tìm thấy sản phẩm';
    }
    switch (_filterType) {
      case 'low_stock':
        return 'Không có sản phẩm sắp hết';
      case 'out_of_stock':
        return 'Không có sản phẩm hết hàng';
      default:
        return 'Chưa có sản phẩm trong kho';
    }
  }

  Widget _buildSummaryCard(int total, int lowStock, int outOfStock) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.inventory_2,
              label: 'Tổng SP',
              value: '$total',
              color: Colors.blue,
            ),
            _StatItem(
              icon: Icons.warning_amber,
              label: 'Sắp hết',
              value: '$lowStock',
              color: Colors.orange,
            ),
            _StatItem(
              icon: Icons.error_outline,
              label: 'Hết hàng',
              value: '$outOfStock',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

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
            // Product icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (item.sku != null)
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
