import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/odori_product.dart';
import '../../providers/odori_providers.dart';
import '../../../../pages/products/product_form_page.dart';
import 'product_samples_page.dart';

class OdoriProductsPage extends ConsumerStatefulWidget {
  const OdoriProductsPage({super.key});

  @override
  ConsumerState<OdoriProductsPage> createState() => _OdoriProductsPageState();
}

class _OdoriProductsPageState extends ConsumerState<OdoriProductsPage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _categoryFilter;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Sản phẩm'),
            Tab(icon: Icon(Icons.card_giftcard_outlined), text: 'Mẫu SP'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          const ProductSamplesPage(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final productsAsync = ref.watch(productsProvider(ProductFilters(
      categoryId: _categoryFilter,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    )));
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm tên, mã sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Category filter
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: _categoryFilter == cat.id,
                        onSelected: (_) => setState(() => _categoryFilter = cat.id),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Products grid
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(productsProvider(const ProductFilters())),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Chưa có sản phẩm nào'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productsProvider(ProductFilters(
                    categoryId: _categoryFilter,
                    search: _searchController.text.isEmpty ? null : _searchController.text,
                  )).future),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(product: product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _scanBarcode() {
    // TODO: Implement barcode scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng quét mã đang phát triển')),
    );
  }

  void _showAddProductSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );
    if (result == true) {
      ref.invalidate(productsProvider(const ProductFilters()));
    }
  }
}

class _ProductCard extends ConsumerWidget {
  final OdoriProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetail(context, ref),
        onLongPress: () => _showQuickMenu(context, ref),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                  ),
                ),
                // Product info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.sku,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                currencyFormat.format(product.sellingPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '/${product.unit}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Status badge
            if (!product.isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ngưng',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chỉnh sửa'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                );
                if (result == true) {
                  ref.invalidate(productsProvider(const ProductFilters()));
                }
              },
            ),
            ListTile(
              leading: Icon(
                product.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: product.isActive ? Colors.orange : Colors.green,
              ),
              title: Text(product.isActive ? 'Ngừng kinh doanh' : 'Kích hoạt lại'),
              onTap: () async {
                Navigator.pop(context);
                await _toggleProductStatus(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa sản phẩm', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteProduct(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProductStatus(BuildContext context, WidgetRef ref) async {
    try {
      final db = Supabase.instance.client;
      await db.from('products').update({
        'status': product.isActive ? 'inactive' : 'active',
      }).eq('id', product.id);

      ref.invalidate(productsProvider(const ProductFilters()));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isActive ? 'Đã ngừng kinh doanh' : 'Đã kích hoạt lại'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = Supabase.instance.client;
      await db.from('products').delete().eq('id', product.id);

      ref.invalidate(productsProvider(const ProductFilters()));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sản phẩm'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProductDetail(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Product image
              if (product.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.sku,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (product.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (product.description != null) ...[
                Text(
                  product.description!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Giá bán',
                value: currencyFormat.format(product.sellingPrice),
                valueColor: Colors.blue,
              ),
              _DetailRow(
                label: 'Giá vốn',
                value: currencyFormat.format(product.costPrice),
              ),
              _DetailRow(
                label: 'Biên lợi nhuận',
                value: '${product.margin.toStringAsFixed(1)}%',
                valueColor: product.margin > 0 ? Colors.green : Colors.red,
              ),
              _DetailRow(label: 'Đơn vị', value: product.unit),
              if (product.wholesalePrice != null)
                _DetailRow(
                  label: 'Giá sỉ',
                  value: '${currencyFormat.format(product.wholesalePrice)} (từ ${product.minWholesaleQty ?? 1})',
                ),
              if (product.weight != null)
                _DetailRow(label: 'Trọng lượng', value: '${product.weight} ${product.weightUnit ?? 'kg'}'),
              _DetailRow(
                label: 'Trạng thái',
                value: product.isActive ? 'Đang kinh doanh' : 'Ngừng kinh doanh',
                valueColor: product.isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductFormPage(product: product),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(productsProvider(const ProductFilters()));
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng thêm vào đơn đang phát triển')),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Thêm vào đơn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
