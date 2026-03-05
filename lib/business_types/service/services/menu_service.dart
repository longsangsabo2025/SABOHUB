import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_item.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId từ authProvider

/// Menu Service
/// Handles all menu item database operations
/// Uses 'menu_items' table in Supabase (NOT products)
/// DB columns: id, company_id, name, description, category, price, cost_price,
///   has_stock, current_stock, min_stock, unit, image_url, is_available, is_active
class MenuService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all menu items for a company
  Future<List<MenuItem>> getAllMenuItems({String? companyId}) async {
    try {
      var query = _supabase.from('menu_items').select('*').eq('is_active', true);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('created_at', ascending: false).limit(200);
      return (response as List).map((json) => _menuItemFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu items: $e');
    }
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(
    MenuCategory category, {
    String? companyId,
  }) async {
    try {
      var query = _supabase
          .from('menu_items')
          .select('*')
          .eq('is_active', true)
          .eq('category', _categoryToDbString(category));

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('name', ascending: true).limit(200);
      return (response as List).map((json) => _menuItemFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu items by category: $e');
    }
  }

  /// Create new menu item
  /// [employeeId] - ID của employee từ authProvider (KHÔNG phải từ auth.currentUser)
  Future<MenuItem> createMenuItem({
    required String name,
    required MenuCategory category,
    required double price,
    String? description,
    String? imageUrl,
    String? companyId,
    String? employeeId,
    double? costPrice,
    String? unit,
  }) async {
    try {
      final data = {
        'name': name,
        'category': _categoryToDbString(category),
        'price': price,
        'cost_price': costPrice,
        'unit': unit ?? 'pcs',
        'description': description,
        'image_url': imageUrl,
        'is_available': true,
        'is_active': true,
        'company_id': companyId,
      };

      final response =
          await _supabase.from('menu_items').insert(data).select().single();

      return _menuItemFromJson(response);
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
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
    double? costPrice,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (category != null) updateData['category'] = _categoryToDbString(category);
      if (price != null) updateData['price'] = price;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (costPrice != null) updateData['cost_price'] = costPrice;

      final response = await _supabase
          .from('menu_items')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return _menuItemFromJson(response);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// Delete menu item (soft delete)
  Future<void> deleteMenuItem(String id) async {
    try {
      await _supabase.from('menu_items').update({
        'is_active': false,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  /// Toggle menu item availability
  Future<MenuItem> toggleAvailability(String id, bool isAvailable) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return _menuItemFromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle menu item availability: $e');
    }
  }

  /// Get menu item by ID
  Future<MenuItem?> getMenuItemById(String id) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select('*')
          .eq('id', id)
          .single();

      return _menuItemFromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Convert JSON to MenuItem model
  MenuItem _menuItemFromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: _categoryFromDbString(json['category'] as String?),
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      companyId: json['company_id'] as String? ?? '',
    );
  }

  /// Convert MenuCategory to database string
  /// DB CHECK: food, beverage, snack, equipment, other
  String _categoryToDbString(MenuCategory category) {
    switch (category) {
      case MenuCategory.food:
        return 'food';
      case MenuCategory.drink:
        return 'beverage';
      case MenuCategory.snack:
        return 'snack';
      case MenuCategory.other:
        return 'other';
    }
  }

  /// Convert database string to MenuCategory
  MenuCategory _categoryFromDbString(String? categoryString) {
    switch (categoryString?.toLowerCase()) {
      case 'food':
        return MenuCategory.food;
      case 'beverage':
        return MenuCategory.drink;
      case 'snack':
        return MenuCategory.snack;
      case 'equipment':
      case 'other':
        return MenuCategory.other;
      default:
        return MenuCategory.other;
    }
  }
}