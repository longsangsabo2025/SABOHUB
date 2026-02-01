/// Customer Revenue Service - Lấy dữ liệu doanh số khách hàng từ v_sales_by_customer
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_tier.dart';

class CustomerRevenueService {
  static final _supabase = Supabase.instance.client;

  /// Cache doanh số khách hàng theo company
  static final Map<String, Map<String, CustomerRevenue>> _revenueCache = {};
  static DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Kiểm tra cache còn hợp lệ không
  static bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  /// Lấy doanh số của tất cả khách hàng theo company
  static Future<Map<String, CustomerRevenue>> getRevenueByCompany(String companyId) async {
    // Kiểm tra cache
    if (_isCacheValid && _revenueCache.containsKey(companyId)) {
      return _revenueCache[companyId]!;
    }

    try {
      final response = await _supabase
          .from('v_sales_by_customer')
          .select()
          .eq('company_id', companyId);

      final revenueMap = <String, CustomerRevenue>{};
      for (final json in (response as List)) {
        final revenue = CustomerRevenue.fromJson(json);
        revenueMap[revenue.customerId] = revenue;
      }

      // Lưu cache
      _revenueCache[companyId] = revenueMap;
      _lastCacheTime = DateTime.now();

      debugPrint('✓ Loaded revenue data for ${revenueMap.length} customers');
      return revenueMap;
    } catch (e) {
      debugPrint('❌ Error loading customer revenue: $e');
      return _revenueCache[companyId] ?? {};
    }
  }

  /// Lấy doanh số của một khách hàng cụ thể
  static Future<CustomerRevenue?> getRevenueByCustomerId(String customerId) async {
    try {
      final response = await _supabase
          .from('v_sales_by_customer')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();

      if (response == null) return null;
      return CustomerRevenue.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error loading customer revenue: $e');
      return null;
    }
  }

  /// Lấy tier của khách hàng từ cache hoặc query
  static CustomerTier getTierFromCache(String companyId, String customerId) {
    final companyCache = _revenueCache[companyId];
    if (companyCache == null) return CustomerTier.none;
    
    final revenue = companyCache[customerId];
    if (revenue == null) return CustomerTier.none;
    
    return revenue.tier;
  }

  /// Thống kê số lượng khách hàng theo tier
  static Future<Map<CustomerTier, int>> getTierStatistics(String companyId) async {
    final revenueMap = await getRevenueByCompany(companyId);
    
    final stats = <CustomerTier, int>{
      CustomerTier.diamond: 0,
      CustomerTier.gold: 0,
      CustomerTier.silver: 0,
      CustomerTier.bronze: 0,
      CustomerTier.none: 0,
    };

    for (final revenue in revenueMap.values) {
      stats[revenue.tier] = (stats[revenue.tier] ?? 0) + 1;
    }

    return stats;
  }

  /// Xóa cache để refresh data
  static void clearCache() {
    _revenueCache.clear();
    _lastCacheTime = null;
  }

  /// Lấy top khách hàng theo doanh số
  static Future<List<CustomerRevenue>> getTopCustomers(String companyId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('v_sales_by_customer')
          .select()
          .eq('company_id', companyId)
          .gt('total_revenue', 0)
          .order('total_revenue', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CustomerRevenue.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading top customers: $e');
      return [];
    }
  }

  /// Lấy khách hàng theo tier
  static Future<List<CustomerRevenue>> getCustomersByTier(String companyId, CustomerTier tier) async {
    final revenueMap = await getRevenueByCompany(companyId);
    
    return revenueMap.values
        .where((r) => r.tier == tier)
        .toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }
}
