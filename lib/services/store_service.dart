import '../core/services/supabase_service.dart';
import '../models/store.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền companyId từ authProvider

/// Store Service
/// Handles all store-related database operations
class StoreService {
  final _supabase = supabase.client;

  /// Get all stores for current user's company
  /// [companyId] - REQUIRED: ID công ty từ authProvider
  Future<List<Store>> getAllStores({required String companyId}) async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stores: $e');
    }
  }

  /// Get store by ID (with company validation)
  Future<Store?> getStoreById(String id, {required String companyId}) async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .eq('id', id)
          .eq('company_id', companyId)
          .maybeSingle();

      if (response == null) return null;
      return Store.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new store (for current user's company)
  Future<Store> createStore({
    required String name,
    String? address,
    String? phone,
    String? email,
    required String companyId,
  }) async {
    try {
      final response = await _supabase
          .from('stores')
          .insert({
            'name': name,
            'address': address,
            'phone': phone,
            'email': email,
            'company_id': companyId,
            'status': 'ACTIVE',
          })
          .select()
          .single();

      return Store.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  /// Update store (with company validation)
  Future<Store> updateStore(String id, Map<String, dynamic> updates, {required String companyId}) async {
    try {
      final response = await _supabase
          .from('stores')
          .update(updates)
          .eq('id', id)
          .eq('company_id', companyId)
          .select()
          .single();

      return Store.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  /// Delete store (with company validation)
  Future<void> deleteStore(String id, {required String companyId}) async {
    try {
      await _supabase.from('stores').delete().eq('id', id).eq('company_id', companyId);
    } catch (e) {
      throw Exception('Failed to delete store: $e');
    }
  }

  /// Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    try {
      // Get employee count for this store
      final employeesResponse =
          await _supabase.from('employees').select('id').eq('store_id', storeId);

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
