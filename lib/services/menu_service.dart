import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_item.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId từ authProvider

/// Menu Service
/// Handles all menu item/product-related database operations
/// Uses 'products' table in Supabase for menu items
class MenuService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all menu items for a company
  Future<List<MenuItem>> getAllMenuItems({String? companyId}) async {
    try {
      var query = _supabase.from('products').select('*').eq('is_active', true);

      if (companyId != null) {
        query = query.eq('store_id', companyId); // Using store_id as company_id
      }

      final response = await query.order('created_at', ascending: false);
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
          .from('products')
          .select('*')
          .eq('is_active', true)
          .eq('category', _categoryToDbString(category));

      if (companyId != null) {
        query = query.eq('store_id', companyId);
      }

      final response = await query.order('name', ascending: true);
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
  }) async {
    try {
      final data = {
        'name': name,
        'category': _categoryToDbString(category),
        'price': price,
        'cost': null, // Optional cost field
        'unit': 'pcs', // Default unit
        'description': description,
        'image_url': imageUrl,
        'is_active': true,
        'store_id': companyId, // Using store_id as company_id
        'created_by': employeeId,
      };

      final response =
          await _supabase.from('products').insert(data).select().single();

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
      if (isAvailable != null) updateData['is_active'] = isAvailable;

      final response = await _supabase
          .from('products')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return _menuItemFromJson(response);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// Delete menu item (soft delete by setting is_active = false)
  Future<void> deleteMenuItem(String id) async {
    try {
      await _supabase.from('products').update({
        'is_active': false,
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
          .from('products')
          .update({
            'is_active': isAvailable,
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
          .from('products')
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
      isAvailable: json['is_active'] as bool? ?? true,
      companyId: json['store_id'] as String? ?? '',
    );
  }

  /// Convert MenuCategory to database string
  String _categoryToDbString(MenuCategory category) {
    switch (category) {
      case MenuCategory.food:
        return 'FOOD';
      case MenuCategory.drink:
        return 'DRINKS';
      case MenuCategory.snack:
        return 'FOOD'; // Snacks are also food
      case MenuCategory.other:
        return 'SUPPLIES';
    }
  }

  /// Convert database string to MenuCategory
  MenuCategory _categoryFromDbString(String? categoryString) {
    switch (categoryString?.toUpperCase()) {
      case 'FOOD':
        return MenuCategory.food;
      case 'DRINKS':
        return MenuCategory.drink;
      case 'SUPPLIES':
        return MenuCategory.other;
      default:
        return MenuCategory.other;
    }
  }
}