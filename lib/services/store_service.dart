import '../core/services/supabase_service.dart';
import '../models/store.dart';

/// Store Service
/// Handles all store-related database operations
class StoreService {
  final _supabase = supabase.client;

  /// Get all stores
  Future<List<Store>> getAllStores() async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stores: $e');
    }
  }

  /// Get store by ID
  Future<Store?> getStoreById(String id) async {
    try {
      final response =
          await _supabase.from('stores').select().eq('id', id).single();

      return Store.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new store
  Future<Store> createStore({
    required String name,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _supabase
          .from('stores')
          .insert({
            'name': name,
            'address': address,
            'phone': phone,
            'email': email,
            'status': 'ACTIVE',
          })
          .select()
          .single();

      return Store.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  /// Update store
  Future<Store> updateStore(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('stores')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Store.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  /// Delete store
  Future<void> deleteStore(String id) async {
    try {
      await _supabase.from('stores').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete store: $e');
    }
  }

  /// Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    try {
      // Get employee count for this store
      final employeesResponse =
          await _supabase.from('users').select('id').eq('store_id', storeId);

      // Note: Table counts and revenue would come from other tables
      // when they are properly configured with the new schema

      return {
        'employeeCount': (employeesResponse as List).length,
        'tableCount': 0, // Placeholder until tables schema is updated
        'monthlyRevenue': 0.0, // Placeholder until bookings schema is updated
      };
    } catch (e) {
      return {
        'employeeCount': 0,
        'tableCount': 0,
        'monthlyRevenue': 0.0,
      };
    }
  }

  /// Subscribe to store changes
  Stream<List<Store>> subscribeToStores() {
    return _supabase
        .from('stores')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Store.fromJson(json)).toList());
  }
}
