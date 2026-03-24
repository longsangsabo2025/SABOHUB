import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/odori_product.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/postgrest_sanitizer.dart';

// =====================================================================
// InventoryState + InventoryNotifier
// Extracted from InventoryPage's 17+ state vars & 22 setState calls.
// =====================================================================


final _supabase = Supabase.instance.client;

class InventoryState {
  final String searchQuery;
  final String? selectedCategory;
  final List<String> categories;
  final List<Map<String, dynamic>> categoryData;
  final bool showLowStock;
  final List<OdoriProduct> allProducts;
  final int currentOffset;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final List<Map<String, dynamic>> warehouses;
  final bool isRefreshing;
  final Map<String, Map<String, dynamic>> productStockMap;

  // Sample products
  final List<Map<String, dynamic>> samples;
  final bool isLoadingSamples;
  final String sampleSearchQuery;
  final String? selectedSampleStatus;
  final int totalSamples;
  final int pendingSamples;
  final int convertedSamples;

  static const int pageSize = 50;

  const InventoryState({
    this.searchQuery = '',
    this.selectedCategory,
    this.categories = const [],
    this.categoryData = const [],
    this.showLowStock = false,
    this.allProducts = const [],
    this.currentOffset = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = true,
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.warehouses = const [],
    this.isRefreshing = false,
    this.productStockMap = const {},
    this.samples = const [],
    this.isLoadingSamples = true,
    this.sampleSearchQuery = '',
    this.selectedSampleStatus,
    this.totalSamples = 0,
    this.pendingSamples = 0,
    this.convertedSamples = 0,
  });

  InventoryState copyWith({
    String? searchQuery,
    String? Function()? selectedCategory,
    List<String>? categories,
    List<Map<String, dynamic>>? categoryData,
    bool? showLowStock,
    List<OdoriProduct>? allProducts,
    int? currentOffset,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    int? totalProducts,
    int? lowStockCount,
    int? outOfStockCount,
    List<Map<String, dynamic>>? warehouses,
    bool? isRefreshing,
    Map<String, Map<String, dynamic>>? productStockMap,
    List<Map<String, dynamic>>? samples,
    bool? isLoadingSamples,
    String? sampleSearchQuery,
    String? Function()? selectedSampleStatus,
    int? totalSamples,
    int? pendingSamples,
    int? convertedSamples,
  }) {
    return InventoryState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory != null ? selectedCategory() : this.selectedCategory,
      categories: categories ?? this.categories,
      categoryData: categoryData ?? this.categoryData,
      showLowStock: showLowStock ?? this.showLowStock,
      allProducts: allProducts ?? this.allProducts,
      currentOffset: currentOffset ?? this.currentOffset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      warehouses: warehouses ?? this.warehouses,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      productStockMap: productStockMap ?? this.productStockMap,
      samples: samples ?? this.samples,
      isLoadingSamples: isLoadingSamples ?? this.isLoadingSamples,
      sampleSearchQuery: sampleSearchQuery ?? this.sampleSearchQuery,
      selectedSampleStatus: selectedSampleStatus != null ? selectedSampleStatus() : this.selectedSampleStatus,
      totalSamples: totalSamples ?? this.totalSamples,
      pendingSamples: pendingSamples ?? this.pendingSamples,
      convertedSamples: convertedSamples ?? this.convertedSamples,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    // Kick off initial loading
    Future.microtask(() => _initAll());
    return const InventoryState();
  }

  String get _companyId => ref.read(currentUserProvider)?.companyId ?? '';

  Future<void> _initAll() async {
    await Future.wait<void>([
      loadCategories(),
      loadStats(),
      loadProducts(),
      loadInventoryData(),
      loadWarehouses(),
      loadSamples(),
    ]);
  }

  // ------- Products -------

  Future<void> loadProducts() async {
    state = state.copyWith(
      isInitialLoading: true,
      allProducts: [],
      currentOffset: 0,
      hasMore: true,
    );

    try {
      final companyId = _companyId;
      if (companyId.isEmpty) {
        state = state.copyWith(isInitialLoading: false);
        return;
      }

      var query = _supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      if (state.selectedCategory != null) {
        query = query.eq('category_id', state.selectedCategory!);
      }
      if (state.searchQuery.isNotEmpty) {
        final sanitized = PostgrestSanitizer.sanitizeSearch(state.searchQuery);
        query = query.or('name.ilike.%$sanitized%,sku.ilike.%$sanitized%');
      }

      final response = await query.order('name').range(0, InventoryState.pageSize - 1);

      var products = (response as List).map((json) => OdoriProduct.fromJson(json)).toList();

      if (state.showLowStock) {
        products = products.where((p) {
          final stock = p.minStock ?? 0;
          final reorderPoint = p.reorderPoint ?? 10;
          return stock == 0 || stock < reorderPoint;
        }).toList();
      }

      state = state.copyWith(
        allProducts: products,
        hasMore: products.length >= InventoryState.pageSize,
        isInitialLoading: false,
      );

      _updateStockCounts();
    } catch (e) {
      AppLogger.error('Error loading products: $e');
      state = state.copyWith(isInitialLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final newOffset = state.currentOffset + InventoryState.pageSize;
      final companyId = _companyId;

      var query = _supabase
          .from('products')
          .select('*')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      if (state.selectedCategory != null) {
        query = query.eq('category_id', state.selectedCategory!);
      }
      if (state.searchQuery.isNotEmpty) {
        final sanitized = PostgrestSanitizer.sanitizeSearch(state.searchQuery);
        query = query.or('name.ilike.%$sanitized%,sku.ilike.%$sanitized%');
      }

      final response = await query.order('name').range(newOffset, newOffset + InventoryState.pageSize - 1);

      var newProducts = (response as List).map((json) => OdoriProduct.fromJson(json)).toList();

      if (state.showLowStock) {
        newProducts = newProducts.where((p) {
          final stock = p.minStock ?? 0;
          final reorderPoint = p.reorderPoint ?? 10;
          return stock == 0 || stock < reorderPoint;
        }).toList();
      }

      state = state.copyWith(
        allProducts: [...state.allProducts, ...newProducts],
        currentOffset: newOffset,
        hasMore: newProducts.length >= InventoryState.pageSize,
        isLoadingMore: false,
      );

      _updateStockCounts();
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void _updateStockCounts() {
    if (state.allProducts.isEmpty) return;

    int lowStock = 0;
    int outOfStock = 0;

    for (var product in state.allProducts) {
      final stockInfo = state.productStockMap[product.id];
      final stock = stockInfo?['total'] as int? ?? 0;
      final reorderPoint = product.reorderPoint ?? 10;
      if (stock == 0) {
        outOfStock++;
      } else if (stock < reorderPoint) {
        lowStock++;
      }
    }

    state = state.copyWith(lowStockCount: lowStock, outOfStockCount: outOfStock);
  }

  // ------- Search / filters -------

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
    loadProducts();
  }

  void setSelectedCategory(String? categoryId) {
    state = state.copyWith(selectedCategory: () => categoryId);
    loadProducts();
  }

  void toggleLowStock() {
    state = state.copyWith(showLowStock: !state.showLowStock);
    loadProducts();
  }

  // ------- Categories -------

  Future<void> loadCategories() async {
    try {
      final companyId = _companyId;
      if (companyId.isEmpty) return;

      final response = await _supabase
          .from('product_categories')
          .select('id, name, description')
          .eq('company_id', companyId)
          .order('name');

      final cats = <String>[];
      final catData = List<Map<String, dynamic>>.from(response);
      for (var cat in catData) {
        cats.add(cat['name'] as String);
      }

      state = state.copyWith(categories: cats, categoryData: catData);
    } catch (e) {
      AppLogger.error('Error loading categories: $e');
    }
  }

  // ------- Stats -------

  Future<void> loadStats() async {
    try {
      final companyId = _companyId;
      if (companyId.isEmpty) return;

      final totalResponse = await _supabase
          .from('products')
          .select('id')
          .eq('company_id', companyId)
          .neq('status', 'inactive');

      state = state.copyWith(totalProducts: (totalResponse as List).length);
    } catch (e) {
      AppLogger.error('Error loading stats: $e');
    }
  }

  // ------- Inventory / warehouses -------

  Future<void> loadInventoryData() async {
    try {
      final companyId = _companyId;
      if (companyId.isEmpty) return;

      final data = await _supabase
          .from('inventory')
          .select('*, products(id, name, sku, unit), warehouses(id, name, code, type)')
          .eq('company_id', companyId)
          .order('products(name)')
          .limit(1000);

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

      state = state.copyWith(productStockMap: stockMap);
      _updateStockCounts();
    } catch (e) {
      AppLogger.error('Error loading inventory: $e');
    }
  }

  Future<void> loadWarehouses() async {
    try {
      final companyId = _companyId;
      if (companyId.isEmpty) return;

      final data = await _supabase
          .from('warehouses')
          .select('*')
          .eq('company_id', companyId)
          .order('name');

      state = state.copyWith(warehouses: List<Map<String, dynamic>>.from(data));
    } catch (e) {
      AppLogger.error('Error loading warehouses: $e');
    }
  }

  // ------- Samples -------

  Future<void> loadSamples() async {
    state = state.copyWith(isLoadingSamples: true);
    try {
      final companyId = _companyId;
      if (companyId.isEmpty) return;

      var query = _supabase
          .from('product_samples')
          .select('*, products(id, name, sku, unit, image_url), customers(id, name, phone)')
          .eq('company_id', companyId);

      if (state.selectedSampleStatus != null) {
        query = query.eq('status', state.selectedSampleStatus!);
      }

      if (state.sampleSearchQuery.isNotEmpty) {
        final sanitized = PostgrestSanitizer.sanitizeSearch(state.sampleSearchQuery);
        query = query.or('product_name.ilike.%$sanitized%,product_sku.ilike.%$sanitized%');
      }

      final data = await query.order('sent_date', ascending: false).limit(100);

      final allData = await _supabase
          .from('product_samples')
          .select('status, converted_to_order')
          .eq('company_id', companyId);

      int pending = 0;
      int converted = 0;
      for (var s in (allData as List)) {
        if (s['status'] == 'pending' || s['status'] == 'delivered') pending++;
        if (s['converted_to_order'] == true) converted++;
      }

      state = state.copyWith(
        samples: List<Map<String, dynamic>>.from(data),
        totalSamples: allData.length,
        pendingSamples: pending,
        convertedSamples: converted,
        isLoadingSamples: false,
      );
    } catch (e) {
      AppLogger.error('Error loading samples: $e');
      state = state.copyWith(isLoadingSamples: false);
    }
  }

  void setSampleSearchQuery(String value) {
    state = state.copyWith(sampleSearchQuery: value);
    loadSamples();
  }

  void setSelectedSampleStatus(String? value) {
    state = state.copyWith(selectedSampleStatus: () => value);
    loadSamples();
  }

  // ------- Refresh all -------

  Future<void> refreshAll() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      await Future.wait<void>([
        loadStats(),
        loadCategories(),
        loadProducts(),
        loadInventoryData(),
        loadWarehouses(),
      ]);
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
