import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

/// ============================================================================
/// CEO BUSINESS PROVIDER — Real data from sales_orders, customers, deliveries
/// Replaces mock data with actual distribution business metrics
/// ============================================================================

SupabaseClient get _supabase => Supabase.instance.client;

final _ceoCompanyIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = ref.read(authProvider).user;
  return _getCEOCompanyIds(user?.id);
});

// ---------------------------------------------------------------------------
// 1. TODAY'S BUSINESS PULSE — What CEO sees first thing in the morning
// ---------------------------------------------------------------------------

/// Today's real-time business numbers
final todayBusinessPulseProvider =
    FutureProvider.autoDispose<TodayPulse>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return TodayPulse.empty();

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    // Get all company IDs this CEO owns
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return TodayPulse.empty();

    // Parallel queries for today's data
    final results = await Future.wait([
      // Orders created today
      _supabase
          .from('sales_orders')
          .select('id, total, status, payment_status')
          .inFilter('company_id', companyIds)
          .gte('created_at', '${todayStr}T00:00:00')
          .lt('created_at', '${todayStr}T23:59:59'),

      // Deliveries today
      _supabase
          .from('deliveries')
          .select('id, status')
          .inFilter('company_id', companyIds)
          .gte('created_at', '${todayStr}T00:00:00'),

      // Payments received today
      _supabase
          .from('payments')
          .select('id, amount, status')
          .inFilter('company_id', companyIds)
          .eq('status', 'completed')
          .gte('created_at', '${todayStr}T00:00:00'),

      // New customers today
      _supabase
          .from('customers')
          .select('id')
          .inFilter('company_id', companyIds)
          .gte('created_at', '${todayStr}T00:00:00'),
    ]);

    final todayOrders = results[0] as List;
    final todayDeliveries = results[1] as List;
    final todayPayments = results[2] as List;
    final newCustomers = results[3] as List;

    // Calculate today's revenue from completed/confirmed orders
    double todayRevenue = 0;
    int completedOrders = 0;
    int pendingOrders = 0;
    for (final o in todayOrders) {
      final total = ((o['total'] ?? 0) as num).toDouble();
      final status = o['status'] as String? ?? '';
      if (status == 'completed') {
        todayRevenue += total;
        completedOrders++;
      } else if (status == 'draft' ||
          status == 'pending_approval' ||
          status == 'confirmed' ||
          status == 'processing') {
        pendingOrders++;
      }
    }

    // Deliveries in progress
    int deliveringCount = 0;
    int deliveredCount = 0;
    for (final d in todayDeliveries) {
      final status = d['status'] as String? ?? '';
      if (status == 'in_progress' || status == 'loading') {
        deliveringCount++;
      } else if (status == 'completed') {
        deliveredCount++;
      }
    }

    // Total payments collected today
    double paymentsCollected = 0;
    for (final p in todayPayments) {
      paymentsCollected += ((p['amount'] ?? 0) as num).toDouble();
    }

    return TodayPulse(
      ordersCreated: todayOrders.length,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      todayRevenue: todayRevenue,
      deliveringCount: deliveringCount,
      deliveredCount: deliveredCount,
      paymentsCollected: paymentsCollected,
      paymentsCount: todayPayments.length,
      newCustomers: newCustomers.length,
    );
  } catch (e) {
    return TodayPulse.empty();
  }
});

// ---------------------------------------------------------------------------
// 2. REAL KPIs — Monthly revenue, growth, profit (from actual sales_orders)
// ---------------------------------------------------------------------------

/// Real KPIs calculated from sales_orders + employees + customers
final realCEOKPIsProvider =
    FutureProvider.autoDispose<CEOKPIs>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return CEOKPIs.empty();

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return CEOKPIs.empty();

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);

    // Parallel queries
    final results = await Future.wait([
      // This month's completed orders
      _supabase
          .from('sales_orders')
          .select('total')
          .inFilter('company_id', companyIds)
          .eq('status', 'completed')
          .gte('created_at', firstDayThisMonth.toIso8601String()),

      // Last month's completed orders (for growth comparison)
      _supabase
          .from('sales_orders')
          .select('total')
          .inFilter('company_id', companyIds)
          .eq('status', 'completed')
          .gte('created_at', firstDayLastMonth.toIso8601String())
          .lt('created_at', firstDayThisMonth.toIso8601String()),

      // Total active employees
      _supabase
          .from('employees')
          .select('id')
          .inFilter('company_id', companyIds)
          .eq('is_active', true),

      // Total active customers
      _supabase
          .from('customers')
          .select('id')
          .inFilter('company_id', companyIds)
          .eq('status', 'active'),

      // Total companies
      _supabase.from('companies').select('id').inFilter('id', companyIds).limit(500),

      // Cost of goods (from sales_order_items this month)
      _supabase
          .from('sales_order_items')
          .select('quantity, cost_price, sales_orders!inner(company_id, status, created_at)')
          .inFilter('sales_orders.company_id', companyIds)
          .eq('sales_orders.status', 'completed')
          .gte('sales_orders.created_at', firstDayThisMonth.toIso8601String()),

      // Outstanding receivables
      _supabase
          .from('receivables')
          .select('original_amount, paid_amount, write_off_amount')
          .inFilter('company_id', companyIds)
          .inFilter('status', ['open', 'partial', 'overdue']),
    ]);

    final thisMonthOrders = results[0] as List;
    final lastMonthOrders = results[1] as List;
    final employees = results[2] as List;
    final customers = results[3] as List;
    final companies = results[4] as List;
    final orderItems = results[5] as List;
    final receivables = results[6] as List;

    // Calculate monthly revenue
    double monthlyRevenue = 0;
    for (final o in thisMonthOrders) {
      monthlyRevenue += ((o['total'] ?? 0) as num).toDouble();
    }

    double lastMonthRevenue = 0;
    for (final o in lastMonthOrders) {
      lastMonthRevenue += ((o['total'] ?? 0) as num).toDouble();
    }

    // Growth percentage
    double revenueGrowth = 0;
    if (lastMonthRevenue > 0) {
      revenueGrowth =
          ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
    }

    // Cost of goods sold (COGS)
    double cogs = 0;
    for (final item in orderItems) {
      final qty = ((item['quantity'] ?? 0) as num).toDouble();
      final cost = ((item['cost_price'] ?? 0) as num).toDouble();
      cogs += qty * cost;
    }

    // Gross profit
    double grossProfit = monthlyRevenue - cogs;
    double grossMargin = monthlyRevenue > 0 ? (grossProfit / monthlyRevenue) * 100 : 0;

    // Outstanding debt (balance = original_amount - paid_amount - write_off_amount)
    double totalOutstanding = 0;
    for (final r in receivables) {
      final original = ((r['original_amount'] ?? 0) as num).toDouble();
      final paid = ((r['paid_amount'] ?? 0) as num).toDouble();
      final writeOff = ((r['write_off_amount'] ?? 0) as num).toDouble();
      totalOutstanding += (original - paid - writeOff);
    }

    return CEOKPIs(
      monthlyRevenue: monthlyRevenue,
      lastMonthRevenue: lastMonthRevenue,
      revenueGrowth: revenueGrowth,
      grossProfit: grossProfit,
      grossMargin: grossMargin,
      cogs: cogs,
      totalEmployees: employees.length,
      totalCustomers: customers.length,
      totalCompanies: companies.length,
      totalOutstanding: totalOutstanding,
      completedOrdersThisMonth: thisMonthOrders.length,
    );
  } catch (e) {
    return CEOKPIs.empty();
  }
});

// ---------------------------------------------------------------------------
// 3. PENDING APPROVALS — CEO Decision Center
// ---------------------------------------------------------------------------

/// Items waiting for CEO decision
final pendingApprovalsProvider =
    FutureProvider.autoDispose<PendingApprovals>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return PendingApprovals.empty();

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return PendingApprovals.empty();

    final results = await Future.wait([
      // Orders pending approval
      _supabase
          .from('sales_orders')
          .select('id, order_number, total, customer_id, customers(name), created_at')
          .inFilter('company_id', companyIds)
          .eq('status', 'pending_approval')
          .order('created_at', ascending: false)
          .limit(20),

      // Task approvals pending
      _supabase
          .from('task_approvals')
          .select('id, task_id, type, created_at, tasks(title)')
          .inFilter('company_id', companyIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(20),

      // Approval requests pending
      _supabase
          .from('approval_requests')
          .select('id, type, description, created_at')
          .inFilter('company_id', companyIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(20),
    ]);

    return PendingApprovals(
      pendingOrders: results[0] as List,
      pendingTaskApprovals: results[1] as List,
      pendingApprovalRequests: results[2] as List,
    );
  } catch (e) {
    return PendingApprovals.empty();
  }
});

// ---------------------------------------------------------------------------
// 4. CUSTOMER INSIGHTS — CEO needs to know customer health
// ---------------------------------------------------------------------------

/// Customer analytics for CEO
final customerInsightsProvider =
    FutureProvider.autoDispose<CustomerInsights>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return CustomerInsights.empty();

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return CustomerInsights.empty();

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final firstDayThisMonth = DateTime(now.year, now.month, 1);

    final results = await Future.wait([
      // All active customers with tier
      _supabase
          .from('customers')
          .select('id, name, tier, total_debt, created_at')
          .inFilter('company_id', companyIds)
          .eq('status', 'active'),

      // New customers this month
      _supabase
          .from('customers')
          .select('id')
          .inFilter('company_id', companyIds)
          .eq('status', 'active')
          .gte('created_at', firstDayThisMonth.toIso8601String()),

      // Top 10 customers by order value (this month)
      _supabase
          .from('sales_orders')
          .select('customer_id, total, customers(name)')
          .inFilter('company_id', companyIds)
          .eq('status', 'completed')
          .gte('created_at', firstDayThisMonth.toIso8601String()),

      // Customers with recent orders (last 30 days) — to find at-risk
      _supabase
          .from('sales_orders')
          .select('customer_id')
          .inFilter('company_id', companyIds)
          .gte('created_at', thirtyDaysAgo.toIso8601String()),
    ]);

    final allCustomers = results[0] as List;
    final newCustomers = results[1] as List;
    final recentOrders = results[2] as List;
    final activeOrderCustomers = results[3] as List;

    // Tier distribution
    final tierCount = <String, int>{
      'diamond': 0,
      'gold': 0,
      'silver': 0,
      'bronze': 0,
      'none': 0,
    };
    for (final c in allCustomers) {
      final tier = (c['tier'] as String?)?.toLowerCase() ?? 'none';
      tierCount[tier] = (tierCount[tier] ?? 0) + 1;
    }

    // Top customers by revenue
    final customerRevenue = <String, double>{};
    final customerNames = <String, String>{};
    for (final o in recentOrders) {
      final custId = o['customer_id'] as String? ?? '';
      final total = ((o['total'] ?? 0) as num).toDouble();
      final custName =
          (o['customers'] as Map?)?['name'] as String? ?? 'N/A';
      customerRevenue[custId] = (customerRevenue[custId] ?? 0) + total;
      customerNames[custId] = custName;
    }

    // Sort top 10
    final sortedCustomers = customerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sortedCustomers.take(10).map((e) {
      return {
        'id': e.key,
        'name': customerNames[e.key] ?? 'N/A',
        'revenue': e.value,
      };
    }).toList();

    // At-risk: active customers without orders in 30 days
    final recentCustomerIds =
        activeOrderCustomers.map((o) => o['customer_id'] as String).toSet();
    final atRiskCount = allCustomers
        .where((c) => !recentCustomerIds.contains(c['id'] as String))
        .length;

    // Total debt
    double totalDebt = 0;
    for (final c in allCustomers) {
      totalDebt += ((c['total_debt'] ?? 0) as num).toDouble();
    }

    return CustomerInsights(
      totalActive: allCustomers.length,
      newThisMonth: newCustomers.length,
      atRiskCount: atRiskCount,
      totalDebt: totalDebt,
      tierDistribution: tierCount,
      top10Customers: top10,
    );
  } catch (e) {
    return CustomerInsights.empty();
  }
});

// ---------------------------------------------------------------------------
// 5. COMPANY COMPARISON — Compare performance across companies
// ---------------------------------------------------------------------------

/// Compare all CEO's companies
final companyComparisonProvider =
    FutureProvider.autoDispose<List<CompanyStats>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return [];

    // Get company info
    final companies = await _supabase
        .from('companies')
        .select('id, name, business_type')
        .inFilter('id', companyIds) as List;

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final stats = <CompanyStats>[];

    for (final company in companies) {
      final companyId = company['id'] as String;

      final results = await Future.wait([
        // Monthly revenue
        _supabase
            .from('sales_orders')
            .select('total')
            .eq('company_id', companyId)
            .eq('status', 'completed')
            .gte('created_at', firstDayThisMonth.toIso8601String()),
        // Active employees
        _supabase
            .from('employees')
            .select('id')
            .eq('company_id', companyId)
            .eq('is_active', true),
        // Active customers
        _supabase
            .from('customers')
            .select('id')
            .eq('company_id', companyId)
            .eq('status', 'active'),
        // Orders this month
        _supabase
            .from('sales_orders')
            .select('id')
            .eq('company_id', companyId)
            .gte('created_at', firstDayThisMonth.toIso8601String()),
      ]);

      double revenue = 0;
      for (final o in (results[0] as List)) {
        revenue += ((o['total'] ?? 0) as num).toDouble();
      }

      stats.add(CompanyStats(
        id: companyId,
        name: company['name'] as String? ?? '',
        businessType: company['business_type'] as String? ?? '',
        monthlyRevenue: revenue,
        employeeCount: (results[1] as List).length,
        customerCount: (results[2] as List).length,
        orderCount: (results[3] as List).length,
      ));
    }

    // Sort by revenue descending
    stats.sort((a, b) => b.monthlyRevenue.compareTo(a.monthlyRevenue));
    return stats;
  } catch (e) {
    return [];
  }
});

// ---------------------------------------------------------------------------
// 6. DAILY REVENUE CHART DATA — For fl_chart
// ---------------------------------------------------------------------------

/// Daily revenue data for chart (last 30 days)
final dailyRevenueChartProvider =
    FutureProvider.autoDispose<List<DailyRevenue>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return [];

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final orders = await _supabase
        .from('sales_orders')
        .select('total, created_at')
        .inFilter('company_id', companyIds)
        .eq('status', 'completed')
        .gte('created_at', thirtyDaysAgo.toIso8601String())
        .order('created_at') as List;

    // Group by date
    final dailyMap = <String, double>{};
    for (final o in orders) {
      final date = (o['created_at'] as String).substring(0, 10);
      final total = ((o['total'] ?? 0) as num).toDouble();
      dailyMap[date] = (dailyMap[date] ?? 0) + total;
    }

    // Fill in all 30 days (including zero-revenue days)
    final result = <DailyRevenue>[];
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add(DailyRevenue(
        date: date,
        revenue: dailyMap[dateStr] ?? 0,
      ));
    }

    return result;
  } catch (e) {
    return [];
  }
});

// ---------------------------------------------------------------------------
// 7. PERIOD REVENUE ANALYTICS — Replaces old ceoRevenueAnalyticsProvider
//    (which wrongly queried sessions table)
// ---------------------------------------------------------------------------

/// Period-aware revenue analytics from sales_orders
/// Returns same structure for drop-in replacement in analytics page
final ceoPeriodRevenueProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, period) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return _emptyPeriodRevenue(period);
  }

  try {
    final companyIds = await ref.watch(_ceoCompanyIdsProvider.future);
    if (companyIds.isEmpty) return _emptyPeriodRevenue(period);

    // Calculate date range based on period
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'quarter':
        startDate = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Fetch completed orders for current period
    final ordersResponse = await _supabase
        .from('sales_orders')
        .select('total, company_id')
        .inFilter('company_id', companyIds)
        .eq('status', 'completed')
        .gte('created_at', startDate.toIso8601String()) as List;

    double totalRevenue = 0.0;
    final Map<String, double> revenueByCompany = {};

    for (var order in ordersResponse) {
      final amount = ((order['total'] ?? 0) as num).toDouble();
      final companyId = order['company_id'] as String?;
      totalRevenue += amount;
      if (companyId != null) {
        revenueByCompany[companyId] =
            (revenueByCompany[companyId] ?? 0.0) + amount;
      }
    }

    // Calculate previous period for growth comparison
    final periodDuration = now.difference(startDate);
    final previousStartDate = startDate.subtract(periodDuration);

    final previousResponse = await _supabase
        .from('sales_orders')
        .select('total')
        .inFilter('company_id', companyIds)
        .eq('status', 'completed')
        .gte('created_at', previousStartDate.toIso8601String())
        .lt('created_at', startDate.toIso8601String()) as List;

    double previousRevenue = 0.0;
    for (var order in previousResponse) {
      previousRevenue += ((order['total'] ?? 0) as num).toDouble();
    }

    // Growth percentage
    double growthPercentage = 0.0;
    if (previousRevenue > 0) {
      growthPercentage =
          ((totalRevenue - previousRevenue) / previousRevenue) * 100;
    }

    // Fetch company names for breakdown
    final List<Map<String, dynamic>> revenueBreakdown = [];
    if (revenueByCompany.isNotEmpty) {
      final companiesResponse = await _supabase
          .from('companies')
          .select('id, name, business_type')
          .inFilter('id', revenueByCompany.keys.toList()) as List;

      for (var company in companiesResponse) {
        final companyId = company['id'] as String;
        final revenue = revenueByCompany[companyId] ?? 0.0;
        final percentage =
            totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0.0;

        revenueBreakdown.add({
          'id': companyId,
          'name': company['name'],
          'businessType': company['business_type'],
          'revenue': revenue,
          'percentage': percentage,
        });
      }

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
    return _emptyPeriodRevenue(period);
  }
});

Map<String, dynamic> _emptyPeriodRevenue(String period) => {
      'totalRevenue': 0.0,
      'previousRevenue': 0.0,
      'growthPercentage': 0.0,
      'revenueBreakdown': <Map<String, dynamic>>[],
      'period': period,
    };

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

/// Get all company IDs owned by this CEO
Future<List<String>> _getCEOCompanyIds(String? userId) async {
  if (userId == null) return [];
  try {
    // Get employee record to find company
    final employee = await _supabase
        .from('employees')
        .select('company_id, role')
        .eq('id', userId)
        .maybeSingle();

    if (employee == null) {
      // Try by auth_user_id
      final byAuth = await _supabase
          .from('employees')
          .select('company_id, role')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (byAuth != null) {
        return [byAuth['company_id'] as String];
      }

      // Fallback: get all companies owned by this user
      final companies = await _supabase
          .from('companies')
          .select('id')
          .eq('owner_id', userId) as List;
      return companies.map((c) => c['id'] as String).toList();
    }

    final role = (employee['role'] as String?)?.toLowerCase() ?? '';
    if (role == 'super_admin') {
      // Super admin sees all companies
      final all = await _supabase.from('companies').select('id').limit(500) as List;
      return all.map((c) => c['id'] as String).toList();
    }

    return [employee['company_id'] as String];
  } catch (e) {
    return [];
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class TodayPulse {
  final int ordersCreated;
  final int completedOrders;
  final int pendingOrders;
  final double todayRevenue;
  final int deliveringCount;
  final int deliveredCount;
  final double paymentsCollected;
  final int paymentsCount;
  final int newCustomers;

  const TodayPulse({
    required this.ordersCreated,
    required this.completedOrders,
    required this.pendingOrders,
    required this.todayRevenue,
    required this.deliveringCount,
    required this.deliveredCount,
    required this.paymentsCollected,
    required this.paymentsCount,
    required this.newCustomers,
  });

  factory TodayPulse.empty() => const TodayPulse(
        ordersCreated: 0,
        completedOrders: 0,
        pendingOrders: 0,
        todayRevenue: 0,
        deliveringCount: 0,
        deliveredCount: 0,
        paymentsCollected: 0,
        paymentsCount: 0,
        newCustomers: 0,
      );

  int get totalApprovalNeeded => pendingOrders;
}

class CEOKPIs {
  final double monthlyRevenue;
  final double lastMonthRevenue;
  final double revenueGrowth;
  final double grossProfit;
  final double grossMargin;
  final double cogs;
  final int totalEmployees;
  final int totalCustomers;
  final int totalCompanies;
  final double totalOutstanding;
  final int completedOrdersThisMonth;

  const CEOKPIs({
    required this.monthlyRevenue,
    required this.lastMonthRevenue,
    required this.revenueGrowth,
    required this.grossProfit,
    required this.grossMargin,
    required this.cogs,
    required this.totalEmployees,
    required this.totalCustomers,
    required this.totalCompanies,
    required this.totalOutstanding,
    required this.completedOrdersThisMonth,
  });

  factory CEOKPIs.empty() => const CEOKPIs(
        monthlyRevenue: 0,
        lastMonthRevenue: 0,
        revenueGrowth: 0,
        grossProfit: 0,
        grossMargin: 0,
        cogs: 0,
        totalEmployees: 0,
        totalCustomers: 0,
        totalCompanies: 0,
        totalOutstanding: 0,
        completedOrdersThisMonth: 0,
      );
}

class PendingApprovals {
  final List pendingOrders;
  final List pendingTaskApprovals;
  final List pendingApprovalRequests;

  const PendingApprovals({
    required this.pendingOrders,
    required this.pendingTaskApprovals,
    required this.pendingApprovalRequests,
  });

  factory PendingApprovals.empty() => const PendingApprovals(
        pendingOrders: [],
        pendingTaskApprovals: [],
        pendingApprovalRequests: [],
      );

  int get totalPending =>
      pendingOrders.length +
      pendingTaskApprovals.length +
      pendingApprovalRequests.length;
}

class CustomerInsights {
  final int totalActive;
  final int newThisMonth;
  final int atRiskCount;
  final double totalDebt;
  final Map<String, int> tierDistribution;
  final List<Map<String, dynamic>> top10Customers;

  const CustomerInsights({
    required this.totalActive,
    required this.newThisMonth,
    required this.atRiskCount,
    required this.totalDebt,
    required this.tierDistribution,
    required this.top10Customers,
  });

  factory CustomerInsights.empty() => const CustomerInsights(
        totalActive: 0,
        newThisMonth: 0,
        atRiskCount: 0,
        totalDebt: 0,
        tierDistribution: {},
        top10Customers: [],
      );
}

class CompanyStats {
  final String id;
  final String name;
  final String businessType;
  final double monthlyRevenue;
  final int employeeCount;
  final int customerCount;
  final int orderCount;

  const CompanyStats({
    required this.id,
    required this.name,
    required this.businessType,
    required this.monthlyRevenue,
    required this.employeeCount,
    required this.customerCount,
    required this.orderCount,
  });
}

class DailyRevenue {
  final DateTime date;
  final double revenue;

  const DailyRevenue({required this.date, required this.revenue});
}
