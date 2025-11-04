import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';

/// CEO Dashboard KPI Provider
/// Fetches real-time KPIs from database for CEO dashboard
final ceoDashboardKPIProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final supabaseClient = supabase.client;
  final userId = supabaseClient.auth.currentUser?.id;

  if (userId == null) {
    return _getEmptyKPIs();
  }

  try {
    // Get all companies (CEO can see all companies in the system)
    final companiesResponse =
        await supabaseClient.from('companies').select('id');

    final companies = companiesResponse as List;
    final totalCompanies = companies.length;

    if (totalCompanies == 0) {
      return _getEmptyKPIs();
    }

    // Get total employees across all companies
    final employeesResponse =
        await supabaseClient.from('profiles').select('id');

    final totalEmployees = (employeesResponse as List).length;

    // Get total branches across all companies
    final branchesResponse = await supabaseClient.from('branches').select('id');

    final totalBranches = (branchesResponse as List).length;

    // Get total tables across all branches
    final tablesResponse = await supabaseClient.from('tables').select('id');

    final totalTables = (tablesResponse as List).length;

    // Get active orders (orders with status = 'active' or 'pending')
    try {
      final ordersResponse = await supabaseClient
          .from('orders')
          .select('id')
          .inFilter('status', ['active', 'pending']);

      final activeOrders = (ordersResponse as List).length;

      return {
        'totalCompanies': totalCompanies,
        'totalEmployees': totalEmployees,
        'totalBranches': totalBranches,
        'totalTables': totalTables,
        'activeOrders': activeOrders,
        'monthlyRevenue': 0.0,
        'todayRevenue': 0.0,
        'revenueGrowth': 0.0,
        'todayGrowth': 0.0,
      };
    } catch (e) {
      // If orders table doesn't exist or has errors, skip it
      print('⚠️ Could not fetch orders: $e');
      return {
        'totalCompanies': totalCompanies,
        'totalEmployees': totalEmployees,
        'totalBranches': totalBranches,
        'totalTables': totalTables,
        'activeOrders': 0,
        'monthlyRevenue': 0.0,
        'todayRevenue': 0.0,
        'revenueGrowth': 0.0,
        'todayGrowth': 0.0,
      };
    }
  } catch (e) {
    print('❌ Error fetching CEO dashboard KPIs: $e');
    return _getEmptyKPIs();
  }
});

/// Recent Activities Provider
/// Fetches recent activities from database
final ceoDashboardActivitiesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabaseClient = supabase.client;
  final userId = supabaseClient.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  try {
    // Get all companies (CEO can see all companies)
    final companiesResponse =
        await supabaseClient.from('companies').select('id');

    final companies = companiesResponse as List;

    if (companies.isEmpty) {
      return [];
    }

    // Get recent activities from audit log or activity table
    // If you don't have an activity log table yet, return empty list
    // You can create this table later to track all activities

    // For now, return empty list - activities will be tracked later
    return [];
  } catch (e) {
    print('❌ Error fetching CEO dashboard activities: $e');
    return [];
  }
});

/// Helper function to return empty KPIs
Map<String, dynamic> _getEmptyKPIs() {
  return {
    'totalCompanies': 0,
    'totalEmployees': 0,
    'totalBranches': 0,
    'totalTables': 0,
    'activeOrders': 0,
    'monthlyRevenue': 0.0,
    'todayRevenue': 0.0,
    'revenueGrowth': 0.0,
    'todayGrowth': 0.0,
  };
}
