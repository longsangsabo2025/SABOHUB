import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';
import '../services/menu_service.dart';
import 'auth_provider.dart';

/// Menu Service Provider
final menuServiceProvider = Provider<MenuService>((ref) {
  return MenuService();
});

/// All Menu Items Provider
/// Fetches menu items for current company
final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final service = ref.watch(menuServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getAllMenuItems(companyId: authState.user!.companyId!);
});

/// Menu Items by Category Provider
/// Gets menu items filtered by category
final menuItemsByCategoryProvider = 
    FutureProvider.family<List<MenuItem>, MenuCategory>((ref, category) async {
  final service = ref.watch(menuServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getMenuItemsByCategory(
    category, 
    companyId: authState.user!.companyId!,
  );
});

/// Single Menu Item Provider
/// Gets menu item details by ID
final menuItemProvider = FutureProvider.family<MenuItem?, String>((ref, itemId) async {
  final service = ref.watch(menuServiceProvider);
  return await service.getMenuItemById(itemId);
});

/// Menu Items Stream Provider
/// Real-time menu items stream (simulated with periodic refresh)
final menuItemsStreamProvider = StreamProvider<List<MenuItem>>((ref) {
  final service = ref.watch(menuServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) {
    return Stream.value([]);
  }
  
  // Periodic refresh for real-time updates
  return Stream.periodic(const Duration(seconds: 30), (_) async {
    return await service.getAllMenuItems(companyId: authState.user!.companyId!);
  }).asyncMap((future) => future);
});

/// Menu Actions Provider
/// Provides menu item CRUD operations
final menuActionsProvider = Provider<MenuActions>((ref) {
  return MenuActions(ref);
});

class MenuActions {
  final Ref ref;
  
  MenuActions(this.ref);
  
  /// Create new menu item
  Future<MenuItem> createMenuItem({
    required String name,
    required MenuCategory category,
    required double price,
    String? description,
    String? imageUrl,
  }) async {
    final service = ref.read(menuServiceProvider);
    final authState = ref.read(authProvider);
    
    if (authState.user?.companyId == null) {
      throw Exception('Company ID not found');
    }
    
    final menuItem = await service.createMenuItem(
      name: name,
      category: category,
      price: price,
      description: description,
      imageUrl: imageUrl,
      companyId: authState.user!.companyId!,
    );
    
    // Refresh menu items
    ref.invalidate(menuItemsProvider);
    ref.invalidate(menuItemsByCategoryProvider);
    
    return menuItem;
  }
  
  /// Update menu item
  Future<MenuItem> updateMenuItem({
    required String id,
    String? name,
    MenuCategory? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    final service = ref.read(menuServiceProvider);
    
    final menuItem = await service.updateMenuItem(
      id: id,
      name: name,
      category: category,
      price: price,
      description: description,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
    
    // Refresh menu items
    ref.invalidate(menuItemsProvider);
    ref.invalidate(menuItemsByCategoryProvider);
    ref.invalidate(menuItemProvider(id));
    
    return menuItem;
  }
  
  /// Delete menu item
  Future<void> deleteMenuItem(String id) async {
    final service = ref.read(menuServiceProvider);
    
    await service.deleteMenuItem(id);
    
    // Refresh menu items
    ref.invalidate(menuItemsProvider);
    ref.invalidate(menuItemsByCategoryProvider);
    ref.invalidate(menuItemProvider(id));
  }
  
  /// Toggle menu item availability
  Future<MenuItem> toggleAvailability(String id, bool isAvailable) async {
    final service = ref.read(menuServiceProvider);
    
    final menuItem = await service.toggleAvailability(id, isAvailable);
    
    // Refresh menu items
    ref.invalidate(menuItemsProvider);
    ref.invalidate(menuItemsByCategoryProvider);
    ref.invalidate(menuItemProvider(id));
    
    return menuItem;
  }
}