import '../core/services/supabase_service.dart';

/// Analytics Service
/// Handles dashboard KPIs, metrics, and analytics data
class AnalyticsService {
  final _supabase = supabase.client;

  /// Helper to get current user's company_id
  Future<String?> _getCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user.userMetadata?['company_id'] as String?;
  }

  /// Get Dashboard KPIs for a specific company
  /// Returns overview metrics for CEO dashboard
  Future<Map<String, dynamic>> getDashboardKPIs({String? companyId}) async {
    try {
      // Get company_id from parameter or current user
      final cid = companyId ?? await _getCompanyId();
      if (cid == null) throw Exception('Company ID not found');

      // Get total branches (stores) for this company
      final branchesResponse =
          await _supabase.from('branches').select('id').eq('company_id', cid).eq('is_active', true);
      final totalStores = (branchesResponse as List).length;

      // Get total tables for this company's stores
      final tablesResponse = await _supabase.from('tables').select('id').eq('company_id', cid);
      final totalTables = (tablesResponse as List).length;

      // Get total employees for this company
      final usersResponse = await _supabase.from('employees').select('id').eq('company_id', cid);
      final totalEmployees = (usersResponse as List).length;

      // Get active tasks today for this company
      final today = DateTime.now().toIso8601String().split('T')[0];
      final tasksResponse = await _supabase
          .from('tasks')
          .select('id')
          .eq('company_id', cid)
          .gte('created_at', today)
          .eq('status', 'in_progress');
      final activeTasks = (tasksResponse as List).length;

      // Calculate monthly revenue from revenue_summary or daily_revenue
      double monthlyRevenue = 0.0;
      try {
        // Try to get from revenue_summary for current month
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        final revenueResponse = await _supabase
            .from('daily_revenue')
            .select('total_revenue')
            .eq('company_id', cid)
            .gte('date', firstDayOfMonth.toIso8601String().split('T')[0])
            .lte('date', lastDayOfMonth.toIso8601String().split('T')[0]);

        monthlyRevenue = (revenueResponse as List).fold<double>(
          0,
          (sum, item) =>
              sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
        );
      } catch (e) {
        // If no revenue data, use 0
        monthlyRevenue = 0.0;
      }

      final revenueGrowth = 12.5; // Mock growth rate for now

      return {
        'totalStores': totalStores,
        'totalTables': totalTables,
        'totalEmployees': totalEmployees,
        'activeTasks': activeTasks,
        'monthlyRevenue': monthlyRevenue,
        'revenueGrowth': revenueGrowth,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard KPIs: $e');
    }
  }

  /// Get Revenue by Period
  /// Returns revenue data for analytics charts
  Future<List<Map<String, dynamic>>> getRevenueByPeriod({
    required String period, // 'week', 'month', 'quarter', 'year'
  }) async {
    try {
      // Mock data for now - will implement real calculation from orders/bookings table
      final now = DateTime.now();
      final List<Map<String, dynamic>> data = [];

      switch (period) {
        case 'week':
          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            data.add({
              'date': date.toIso8601String().split('T')[0],
              'revenue': (50000000 + (i * 10000000)).toDouble(), // Mock
              'label': _getWeekdayName(date.weekday),
            });
          }
          break;
        case 'month':
          for (int i = 29; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            data.add({
              'date': date.toIso8601String().split('T')[0],
              'revenue': (20000000 + (i * 5000000)).toDouble(),
              'label': '${date.day}/${date.month}',
            });
          }
          break;
        case 'quarter':
          for (int i = 11; i >= 0; i--) {
            final date = DateTime(now.year, now.month - i, 1);
            data.add({
              'date': date.toIso8601String().split('T')[0],
              'revenue': (600000000 + (i * 50000000)).toDouble(),
              'label': 'T${date.month}',
            });
          }
          break;
        case 'year':
          for (int i = 11; i >= 0; i--) {
            final date = DateTime(now.year, now.month - i, 1);
            data.add({
              'date': date.toIso8601String().split('T')[0],
              'revenue': (800000000 + (i * 100000000)).toDouble(),
              'label': 'T${date.month}',
            });
          }
          break;
      }

      return data;
    } catch (e) {
      throw Exception('Failed to fetch revenue data: $e');
    }
  }

  /// Get Store Performance Stats
  /// Returns performance metrics for each store
  Future<List<Map<String, dynamic>>> getStorePerformance() async {
    try {
      // Get all active stores (using branches table since stores were consolidated)
      final storesResponse = await _supabase
          .from('branches')
          .select('id, name')
          .eq('is_active', true);
      final stores = storesResponse as List;

      final List<Map<String, dynamic>> performance = [];

      for (final store in stores) {
        final storeId = store['id'] as String;

        // Get table count
        final tablesResponse = await _supabase
            .from('tables')
            .select('id')
            .eq('branch_id', storeId);
        final tableCount = (tablesResponse as List).length;

        // Get employee count
        final employeesResponse =
            await _supabase.from('employees').select('id').eq('branch_id', storeId);
        final employeeCount = (employeesResponse as List).length;

        // Calculate revenue from daily_revenue table
        double revenue = 0.0;
        try {
          final now = DateTime.now();
          final firstDayOfMonth = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

          final revenueResponse = await _supabase
              .from('daily_revenue')
              .select('total_revenue')
              .eq('branch_id', storeId)
              .gte('date', firstDayOfMonth.toIso8601String().split('T')[0])
              .lte('date', lastDayOfMonth.toIso8601String().split('T')[0]);

          revenue = (revenueResponse as List).fold<double>(
            0,
            (sum, item) =>
                sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
          );
        } catch (e) {
          revenue = 0.0;
        }

        final growth = (10 + (employeeCount * 0.5)).toDouble(); // Mock growth

        performance.add({
          'storeId': storeId,
          'storeName': store['name'] as String,
          'tableCount': tableCount,
          'employeeCount': employeeCount,
          'revenue': revenue,
          'growth': growth,
        });
      }

      // Sort by revenue descending
      performance.sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      return performance;
    } catch (e) {
      throw Exception('Failed to fetch store performance: $e');
    }
  }

  /// Get Recent Activity Log
  /// Returns recent system activities across all stores
  Future<List<Map<String, dynamic>>> getActivityLog({int limit = 20}) async {
    try {
      // Get recent tasks
      final tasksResponse = await _supabase
          .from('tasks')
          .select('id, title, status, created_at, assigned_to')
          .order('created_at', ascending: false)
          .limit(limit);

      final tasks = tasksResponse as List;
      final activities = <Map<String, dynamic>>[];

      for (final task in tasks) {
        activities.add({
          'id': task['id'],
          'type': 'task',
          'title': task['title'],
          'status': task['status'],
          'timestamp': task['created_at'],
          'icon': 'task',
        });
      }

      // Sort by timestamp descending
      activities.sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));

      return activities.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch activity log: $e');
    }
  }

  /// Get Customer Analytics
  /// Returns customer-related metrics
  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    try {
      // Mock data - will implement real calculation from bookings table
      return {
        'totalCustomers': 1250,
        'newCustomers': 85,
        'returningRate': 68.5,
        'averageBookingValue': 350000.0,
        'customerGrowth': 15.2,
      };
    } catch (e) {
      throw Exception('Failed to fetch customer analytics: $e');
    }
  }

  /// Get Company Performance
  /// Returns performance metrics for all companies
  Future<List<Map<String, dynamic>>> getCompanyPerformance() async {
    try {
      // Get all active companies
      final companiesResponse = await _supabase
          .from('companies')
          .select('id, name, business_type')
          .eq('is_active', true); // Use is_active instead of status
      final companies = companiesResponse as List;

      final List<Map<String, dynamic>> performance = [];

      for (final company in companies) {
        final companyId = company['id'] as String;

        // Get branch count (stores)
        final branchesResponse = await _supabase
            .from('branches')
            .select('id')
            .eq('company_id', companyId);
        final storeCount = (branchesResponse as List).length;

        // Get table count
        final tablesResponse = await _supabase
            .from('tables')
            .select('id')
            .eq('company_id', companyId);
        final tableCount = (tablesResponse as List).length;

        // Get employee count
        final employeesResponse = await _supabase
            .from('users')
            .select('id')
            .eq('company_id', companyId);
        final employeeCount = (employeesResponse as List).length;

        // Calculate revenue from daily_revenue table
        double revenue = 0.0;
        try {
          final now = DateTime.now();
          final firstDayOfMonth = DateTime(now.year, now.month, 1);
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

          final revenueResponse = await _supabase
              .from('daily_revenue')
              .select('total_revenue')
              .eq('company_id', companyId)
              .gte('date', firstDayOfMonth.toIso8601String().split('T')[0])
              .lte('date', lastDayOfMonth.toIso8601String().split('T')[0]);

          revenue = (revenueResponse as List).fold<double>(
            0,
            (sum, item) =>
                sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
          );
        } catch (e) {
          revenue = 0.0;
        }

        final growth = (10 + (storeCount * 2.5)).toDouble(); // Mock growth

        performance.add({
          'companyId': companyId,
          'companyName': company['name'] as String,
          'businessType': company['business_type'] as String,
          'storeCount': storeCount,
          'tableCount': tableCount,
          'employeeCount': employeeCount,
          'revenue': revenue,
          'growth': growth,
        });
      }

      // Sort by revenue descending
      performance.sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      return performance;
    } catch (e) {
      throw Exception('Failed to fetch company performance: $e');
    }
  }

  /// Helper: Get weekday name in Vietnamese
  String _getWeekdayName(int weekday) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[weekday % 7];
  }
}
