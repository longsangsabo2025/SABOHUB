import '../core/services/supabase_service.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **MANAGER KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Service này được dùng bởi Manager Dashboard
/// - Manager login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId và companyId từ authProvider

/// Manager KPI Service
/// Provides KPIs and metrics for Manager Dashboard
class ManagerKPIService {
  final _supabase = supabase.client;

  /// Get Manager Dashboard KPIs
  /// 
  /// [employeeId] - ID của manager từ employees table (KHÔNG phải auth.user.id)
  /// [companyId] - ID công ty của manager
  /// [branchId] - Optional: ID chi nhánh để filter thêm
  Future<Map<String, dynamic>> getDashboardKPIs({
    required String employeeId,
    required String companyId,
    String? branchId,
  }) async {
    try {
      // Get staff count from employees table - FILTER BY COMPANY
      final staffQuery =
          _supabase.from('employees').select('id, is_active').eq('role', 'STAFF');

      // Manager sees all staff in their company (not just branch)
      staffQuery.eq('company_id', companyId);

      final staffData = await staffQuery;
      final totalStaff = (staffData as List).length;
      final activeStaff =
          staffData.where((s) => s['is_active'] == true).length;

      // Get tables count - FILTER BY COMPANY
      final tablesQuery = _supabase.from('tables').select('id, status');

      // Manager sees all tables in their company
      tablesQuery.eq('company_id', companyId);

      final tablesData = await tablesQuery;
      final totalTables = (tablesData as List).length;
      final activeTables = tablesData
          .where((t) => t['status'] == 'OCCUPIED' || t['status'] == 'RESERVED')
          .length;

      // Get tasks for today - FILTER BY COMPANY
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final tasksQuery = _supabase
          .from('tasks')
          .select('id, status, assigned_to')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      // Manager sees all tasks in their company
      tasksQuery.eq('company_id', companyId);

      final tasksData = await tasksQuery;
      final totalOrders = (tasksData as List).length;
      final completedOrders =
          tasksData.where((t) => t['status'] == 'completed').length;

      // Calculate revenue (mock for now - will be real when orders table exists)
      final todayRevenue = totalOrders * 350000; // Average order: 350k VND
      final yesterdayRevenue =
          (totalOrders * 0.88) * 350000; // Mock -12% from yesterday
      final revenueChange = yesterdayRevenue > 0
          ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100)
          : 0.0;

      // Calculate performance
      final performance =
          completedOrders > 0 ? (completedOrders / totalOrders * 100) : 0.0;

      return {
        'totalStaff': totalStaff,
        'activeStaff': activeStaff,
        'totalTables': totalTables,
        'activeTables': activeTables,
        'todayRevenue': todayRevenue.toDouble(),
        'revenueChange': revenueChange,
        'totalCustomers': totalOrders,
        'customerChange': 8.0, // Mock
        'totalOrders': totalOrders,
        'orderChange': 15.0, // Mock
        'performance': performance,
        'performanceChange': 3.0, // Mock
      };
    } catch (e) {
      // Return default values on error
      return {
        'totalStaff': 0,
        'activeStaff': 0,
        'totalTables': 0,
        'activeTables': 0,
        'todayRevenue': 0.0,
        'revenueChange': 0.0,
        'totalCustomers': 0,
        'customerChange': 0.0,
        'totalOrders': 0,
        'orderChange': 0.0,
        'performance': 0.0,
        'performanceChange': 0.0,
      };
    }
  }

  /// Get team members for today
  /// 
  /// [employeeId] - ID của manager từ employees table
  /// [companyId] - ID công ty của manager
  /// [branchId] - Optional: ID chi nhánh để filter thêm
  Future<List<Map<String, dynamic>>> getTeamMembers({
    required String employeeId,
    required String companyId,
    String? branchId,
  }) async {
    try {
      // Query staff from employees table - FILTER BY COMPANY
      final baseQuery =
          _supabase.from('employees').select('id, full_name, role, is_active');

      // Manager sees all team members in their company
      final filteredQuery = baseQuery.eq('company_id', companyId);

      final response = await filteredQuery
          .or('role.eq.STAFF,role.eq.SHIFT_LEADER')
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((member) {
        final name = member['full_name'] ?? member['name'] ?? 'Unknown';
        // Unused: final role = member['role'] as String? ?? 'staff';
        final status = member['status'] as String? ?? 'inactive';

        String shift = 'Ca sáng';
        if (DateTime.now().hour >= 14 && DateTime.now().hour < 18) {
          shift = 'Ca chiều';
        } else if (DateTime.now().hour >= 18) {
          shift = 'Ca tối';
        }

        String statusText = 'Chờ checkin';
        if (status == 'active') {
          statusText = 'Đang làm';
        } else if (status == 'on_leave') {
          statusText = 'Nghỉ phép';
        }

        return {
          'id': member['id'],
          'name': name,
          'shift': shift,
          'status': statusText,
          'statusColor': status == 'active'
              ? 'green'
              : (status == 'on_leave' ? 'orange' : 'grey'),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent activities
  /// 
  /// [employeeId] - ID của manager từ employees table
  /// [companyId] - ID công ty của manager
  /// [branchId] - Optional: ID chi nhánh để filter thêm
  /// [limit] - Số lượng activities tối đa
  Future<List<Map<String, dynamic>>> getRecentActivities({
    required String employeeId,
    required String companyId,
    String? branchId,
    int limit = 10,
  }) async {
    try {
      // Query tasks - FILTER BY COMPANY  
      // Note: Cannot use JOIN without FK, will populate names separately if needed
      final baseQuery = _supabase.from('tasks').select('*');

      // Manager sees all activities in their company
      final filteredQuery = baseQuery.eq('company_id', companyId);

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((activity) {
        final title = activity['title'] as String? ?? 'Unknown Activity';
        final createdAt = DateTime.parse(activity['created_at'] as String);
        final timeAgo = _getTimeAgo(createdAt);

        String icon = 'info';
        if (title.contains('thanh toán') || title.contains('payment')) {
          icon = 'payment';
        } else if (title.contains('check-in') || title.contains('checkin')) {
          icon = 'login';
        } else if (activity['status'] == 'completed') {
          icon = 'check_circle';
        }

        return {
          'id': activity['id'],
          'title': title,
          'time': timeAgo,
          'icon': icon,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }
}
