import '../core/services/supabase_service.dart';
import '../utils/app_logger.dart';

/// Analytics Service
/// Handles dashboard KPIs, metrics, and analytics data
class AnalyticsService {
  final _supabase = supabase.client;

  /// Helper to get current user's company_id
  /// This should be passed from the caller, NOT fetched from auth
  Future<String?> _getCompanyId() async {
    // Deprecated: auth.currentUser doesn't work for employee login
    // Callers should pass companyId directly
    return null;
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
          await _supabase.from('branches').select('id').eq('company_id', cid).eq('is_active', true).limit(500);
      final totalStores = (branchesResponse as List).length;

      // Get total tables for this company's stores
      final tablesResponse = await _supabase.from('tables').select('id').eq('company_id', cid).limit(1000);
      final totalTables = (tablesResponse as List).length;

      // Get total employees for this company
      final usersResponse = await _supabase.from('employees').select('id').eq('company_id', cid).limit(1000);
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

      // Calculate real revenue growth: compare this month vs last month
      double revenueGrowth = 0.0;
      try {
        final now = DateTime.now();
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        final prevMonthEnd = DateTime(now.year, now.month, 0);

        final prevRevenueResponse = await _supabase
            .from('daily_revenue')
            .select('total_revenue')
            .eq('company_id', cid)
            .gte('date', prevMonthStart.toIso8601String().split('T')[0])
            .lte('date', prevMonthEnd.toIso8601String().split('T')[0]);

        final prevRevenue = (prevRevenueResponse as List).fold<double>(
          0,
          (sum, item) =>
              sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
        );

        if (prevRevenue > 0) {
          revenueGrowth =
              ((monthlyRevenue - prevRevenue) / prevRevenue * 100);
        }
      } catch (e) {
        AppLogger.warn('Revenue growth calc failed: $e');
        revenueGrowth = 0.0;
      }

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
  /// Returns revenue data for analytics charts from daily_revenue table
  Future<List<Map<String, dynamic>>> getRevenueByPeriod({
    required String period, // 'week', 'month', 'quarter', 'year'
    String? companyId,
  }) async {
    try {
      final cid = companyId ?? await _getCompanyId();
      final now = DateTime.now();
      final List<Map<String, dynamic>> data = [];

      DateTime startDate;
      switch (period) {
        case 'week':
          startDate = now.subtract(const Duration(days: 6));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 29));
          break;
        case 'quarter':
          startDate = DateTime(now.year, now.month - 2, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, now.month - 11, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 6));
      }

      var query = _supabase
          .from('daily_revenue')
          .select('date, total_revenue')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', now.toIso8601String().split('T')[0]);

      if (cid != null) {
        query = query.eq('company_id', cid);
      }

      final orderedQuery = query.order('date', ascending: true);

      final response = await orderedQuery;
      final revenueMap = <String, double>{};
      for (final item in response as List) {
        final date = item['date'] as String;
        final revenue = (item['total_revenue'] as num?)?.toDouble() ?? 0;
        revenueMap[date] = (revenueMap[date] ?? 0) + revenue;
      }

      // Build daily/monthly data points
      if (period == 'week' || period == 'month') {
        final days = period == 'week' ? 7 : 30;
        for (int i = days - 1; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];
          data.add({
            'date': dateStr,
            'revenue': revenueMap[dateStr] ?? 0.0,
            'label': period == 'week'
                ? _getWeekdayName(date.weekday)
                : '${date.day}/${date.month}',
          });
        }
      } else {
        // Quarter/Year: aggregate by month
        final months = period == 'quarter' ? 3 : 12;
        for (int i = months - 1; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i, 1);
          double monthRevenue = 0;
          revenueMap.forEach((dateStr, rev) {
            final d = DateTime.tryParse(dateStr);
            if (d != null &&
                d.year == monthDate.year &&
                d.month == monthDate.month) {
              monthRevenue += rev;
            }
          });
          data.add({
            'date': monthDate.toIso8601String().split('T')[0],
            'revenue': monthRevenue,
            'label': 'T${monthDate.month}',
          });
        }
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
            await _supabase.from('employees').select('id').eq('branch_id', storeId).limit(500);
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

        // Calculate real growth: compare this month vs last month
        double growth = 0.0;
        try {
          final nowGrowth = DateTime.now();
          final prevMonthStart = DateTime(nowGrowth.year, nowGrowth.month - 1, 1);
          final prevMonthEnd = DateTime(nowGrowth.year, nowGrowth.month, 0);
          final prevRevResponse = await _supabase
              .from('daily_revenue')
              .select('total_revenue')
              .eq('branch_id', storeId)
              .gte('date', prevMonthStart.toIso8601String().split('T')[0])
              .lte('date', prevMonthEnd.toIso8601String().split('T')[0]);
          final prevRev = (prevRevResponse as List).fold<double>(
            0,
            (sum, item) =>
                sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
          );
          if (prevRev > 0) {
            growth = ((revenue - prevRev) / prevRev * 100);
          }
        } catch (e) {
          AppLogger.warn('Store growth calc failed: $e');
          growth = 0.0;
        }

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
  /// Returns customer-related metrics from customers table
  Future<Map<String, dynamic>> getCustomerAnalytics({String? companyId}) async {
    try {
      final cid = companyId ?? await _getCompanyId();

      // Total customers
      var totalQuery = _supabase.from('customers').select('id');
      if (cid != null) {
        totalQuery = totalQuery.eq('company_id', cid);
      }
      final totalResponse = await totalQuery.limit(5000);
      final totalCustomers = (totalResponse as List).length;

      // New customers this month
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);
      var newQuery = _supabase
          .from('customers')
          .select('id')
          .gte('created_at', firstOfMonth.toIso8601String());
      if (cid != null) {
        newQuery = newQuery.eq('company_id', cid);
      }
      final newResponse = await newQuery;
      final newCustomers = (newResponse as List).length;

      // Previous month customer count for growth calc
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevMonthEnd = DateTime(now.year, now.month, 0);
      var prevQuery = _supabase
          .from('customers')
          .select('id')
          .gte('created_at', prevMonthStart.toIso8601String())
          .lte('created_at', prevMonthEnd.toIso8601String());
      if (cid != null) {
        prevQuery = prevQuery.eq('company_id', cid);
      }
      final prevResponse = await prevQuery;
      final prevNewCustomers = (prevResponse as List).length;

      final customerGrowth = prevNewCustomers > 0
          ? ((newCustomers - prevNewCustomers) / prevNewCustomers * 100)
          : 0.0;

      return {
        'totalCustomers': totalCustomers,
        'newCustomers': newCustomers,
        'returningRate': totalCustomers > 0
            ? ((totalCustomers - newCustomers) / totalCustomers * 100)
            : 0.0,
        'averageBookingValue': 0.0, // Will calculate from orders if needed
        'customerGrowth': customerGrowth,
      };
    } catch (e) {
      return {
        'totalCustomers': 0,
        'newCustomers': 0,
        'returningRate': 0.0,
        'averageBookingValue': 0.0,
        'customerGrowth': 0.0,
      };
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

        // Get employee count from employees table
        final employeesResponse = await _supabase
            .from('employees')
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

        // Calculate real growth
        double growth = 0.0;
        try {
          final nowGrowth = DateTime.now();
          final prevMonthStart = DateTime(nowGrowth.year, nowGrowth.month - 1, 1);
          final prevMonthEnd = DateTime(nowGrowth.year, nowGrowth.month, 0);
          final prevRevResponse = await _supabase
              .from('daily_revenue')
              .select('total_revenue')
              .eq('company_id', companyId)
              .gte('date', prevMonthStart.toIso8601String().split('T')[0])
              .lte('date', prevMonthEnd.toIso8601String().split('T')[0]);
          final prevRev = (prevRevResponse as List).fold<double>(
            0,
            (sum, item) =>
                sum + ((item['total_revenue'] as num?)?.toDouble() ?? 0),
          );
          if (prevRev > 0) {
            growth = ((revenue - prevRev) / prevRev * 100);
          }
        } catch (e) {
          AppLogger.warn('Company growth calc failed: $e');
          growth = 0.0;
        }

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
