import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/supabase_service.dart';

/// CEO Analytics Data Provider
/// Fetches real analytics data from Supabase for CEO dashboard

/// Revenue Analytics Provider by Period
/// Fetches total revenue and breakdown by company for selected period
final ceoRevenueAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  final supabaseClient = supabase.client;

  try {
    // Calculate date range based on period
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'quarter':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Fetch total revenue from sessions (table_amount + orders_amount)
    final sessionsResponse = await supabaseClient
        .from('sessions')
        .select('table_amount, orders_amount, company_id, created_at, status')
        .gte('created_at', startDate.toIso8601String())
        .eq('status', 'completed') as List<dynamic>;

    double totalRevenue = 0.0;
    final Map<String, double> revenueByCompany = {};

    for (var session in sessionsResponse) {
      final sessionMap = session as Map<String, dynamic>;
      final tableAmount =
          (sessionMap['table_amount'] as num?)?.toDouble() ?? 0.0;
      final ordersAmount =
          (sessionMap['orders_amount'] as num?)?.toDouble() ?? 0.0;
      final amount = tableAmount + ordersAmount;
      final companyId = sessionMap['company_id'] as String?;

      totalRevenue += amount;

      if (companyId != null) {
        revenueByCompany[companyId] =
            (revenueByCompany[companyId] ?? 0.0) + amount;
      }
    }

    // Calculate previous period for comparison
    final previousStartDate = DateTime(
      startDate.year,
      startDate.month - 1,
      startDate.day,
    );

    final previousSessionsResponse = await supabaseClient
        .from('sessions')
        .select('table_amount, orders_amount')
        .gte('created_at', previousStartDate.toIso8601String())
        .lt('created_at', startDate.toIso8601String())
        .eq('status', 'completed') as List<dynamic>;

    double previousRevenue = 0.0;
    for (var session in previousSessionsResponse) {
      final sessionMap = session as Map<String, dynamic>;
      final tableAmount =
          (sessionMap['table_amount'] as num?)?.toDouble() ?? 0.0;
      final ordersAmount =
          (sessionMap['orders_amount'] as num?)?.toDouble() ?? 0.0;
      previousRevenue += (tableAmount + ordersAmount);
    }

    // Calculate growth percentage
    double growthPercentage = 0.0;
    if (previousRevenue > 0) {
      growthPercentage =
          ((totalRevenue - previousRevenue) / previousRevenue) * 100;
    }

    // Fetch company names for revenue breakdown
    final List<Map<String, dynamic>> revenueBreakdown = [];

    if (revenueByCompany.isNotEmpty) {
      final companiesResponse = await supabaseClient
          .from('companies')
          .select('id, name, business_type')
          .inFilter('id', revenueByCompany.keys.toList()) as List<dynamic>;

      for (var company in companiesResponse) {
        final companyMap = company as Map<String, dynamic>;
        final companyId = companyMap['id'] as String;
        final revenue = revenueByCompany[companyId] ?? 0.0;
        final percentage =
            totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0.0;

        revenueBreakdown.add({
          'id': companyId,
          'name': companyMap['name'],
          'businessType': companyMap['business_type'],
          'revenue': revenue,
          'percentage': percentage,
        });
      }

      // Sort by revenue descending
      revenueBreakdown.sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    }

    return {
      'totalRevenue': totalRevenue,
      'previousRevenue': previousRevenue,
      'growthPercentage': growthPercentage,
      'revenueBreakdown': revenueBreakdown,
      'period': period,
    };
  } catch (e) {
    return {
      'totalRevenue': 0.0,
      'previousRevenue': 0.0,
      'growthPercentage': 0.0,
      'revenueBreakdown': [],
      'period': period,
    };
  }
});

/// Customer Analytics Provider
/// Fetches customer-related metrics across all companies
final ceoCustomerAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  final supabaseClient = supabase.client;

  try {
    // Calculate date range
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'quarter':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Fetch sessions with customer info
    final sessionsResponse = await supabaseClient
        .from('sessions')
        .select(
            'customer_name, table_amount, orders_amount, created_at, status')
        .gte('created_at', startDate.toIso8601String())
        .eq('status', 'completed') as List<dynamic>;

    final Set<String> uniqueCustomers = {};
    double totalSpent = 0.0;

    for (var session in sessionsResponse) {
      final sessionMap = session as Map<String, dynamic>;
      final customerName = sessionMap['customer_name'] as String?;
      if (customerName != null && customerName.isNotEmpty) {
        uniqueCustomers.add(customerName);
      }
      final tableAmount =
          (sessionMap['table_amount'] as num?)?.toDouble() ?? 0.0;
      final ordersAmount =
          (sessionMap['orders_amount'] as num?)?.toDouble() ?? 0.0;
      totalSpent += (tableAmount + ordersAmount);
    }

    final totalOrders = sessionsResponse.length;
    final totalCustomers = uniqueCustomers.length;
    final averageOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0.0;

    return {
      'totalCustomers': totalCustomers,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'totalSpent': totalSpent,
    };
  } catch (e) {
    return {
      'totalCustomers': 0,
      'totalOrders': 0,
      'averageOrderValue': 0.0,
      'totalSpent': 0.0,
    };
  }
});

/// Performance Analytics Provider
/// Fetches performance metrics for all companies
final ceoPerformanceAnalyticsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabaseClient = supabase.client;

  try {
    // Fetch all companies
    final companiesResponse = await supabaseClient
        .from('companies')
        .select('id, name, business_type, created_at') as List<dynamic>;

    final List<Map<String, dynamic>> performance = [];

    for (var company in companiesResponse) {
      final companyMap = company as Map<String, dynamic>;
      final companyId = companyMap['id'] as String;

      // Get employee count
      final employeesResponse = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('company_id', companyId) as List<dynamic>;

      // Get branch count
      final branchesResponse = await supabaseClient
          .from('branches')
          .select('id')
          .eq('company_id', companyId) as List<dynamic>;

      // Get table count
      final tablesResponse = await supabaseClient
          .from('tables')
          .select('id')
          .eq('company_id', companyId) as List<dynamic>;

      // Get monthly revenue from completed sessions
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final sessionsResponse = await supabaseClient
              .from('sessions')
              .select('table_amount, orders_amount')
              .eq('company_id', companyId)
              .eq('status', 'completed')
              .gte('created_at', firstDayOfMonth.toIso8601String())
          as List<dynamic>;

      double monthlyRevenue = 0.0;
      for (var session in sessionsResponse) {
        final sessionMap = session as Map<String, dynamic>;
        final tableAmount =
            (sessionMap['table_amount'] as num?)?.toDouble() ?? 0.0;
        final ordersAmount =
            (sessionMap['orders_amount'] as num?)?.toDouble() ?? 0.0;
        monthlyRevenue += (tableAmount + ordersAmount);
      }

      performance.add({
        'id': companyId,
        'name': companyMap['name'],
        'businessType': companyMap['business_type'],
        'employeeCount': employeesResponse.length,
        'branchCount': branchesResponse.length,
        'tableCount': tablesResponse.length,
        'monthlyRevenue': monthlyRevenue,
      });
    }

    return performance;
  } catch (e) {
    return [];
  }
});
