import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/monthly_pnl.dart';

/// Service to fetch Monthly P&L data from Supabase
class MonthlyPnlService {
  final _client = Supabase.instance.client;

  /// Check if a company is a corporation (parent company)
  Future<bool> _isCorporation(String companyId) async {
    final response = await _client
        .from('companies')
        .select('business_type')
        .eq('id', companyId)
        .maybeSingle();
    
    if (response == null) return false;
    return response['business_type'] == 'corporation';
  }

  /// Get all P&L records across all companies (for corporation view)
  /// Aggregates data by month
  Future<List<MonthlyPnl>> _getConsolidatedPnlHistory({int? limit}) async {
    // Get all P&L records from all companies
    final response = await _client
        .from('monthly_pnl')
        .select()
        .order('report_month', ascending: false);

    final allRecords = (response as List)
        .map((json) => MonthlyPnl.fromJson(json))
        .toList();

    if (allRecords.isEmpty) return [];

    // Group by month and aggregate
    final Map<String, List<MonthlyPnl>> byMonth = {};
    for (final record in allRecords) {
      final monthKey = record.reportMonth.toIso8601String().substring(0, 7); // YYYY-MM
      byMonth.putIfAbsent(monthKey, () => []);
      byMonth[monthKey]!.add(record);
    }

    // Create aggregated records for each month
    final aggregated = <MonthlyPnl>[];
    final sortedMonths = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final monthKey in sortedMonths) {
      final monthRecords = byMonth[monthKey]!;
      if (monthRecords.isEmpty) continue;

      // Sum all values across companies for this month
      final consolidated = MonthlyPnl(
        id: 'consolidated_$monthKey',
        companyId: 'consolidated',
        branchId: null,
        branchName: 'Tổng hợp tập đoàn',
        reportMonth: monthRecords.first.reportMonth,
        grossRevenue: monthRecords.fold(0.0, (s, r) => s + r.grossRevenue),
        revenueDeductions: monthRecords.fold(0.0, (s, r) => s + r.revenueDeductions),
        invoiceDiscounts: monthRecords.fold(0.0, (s, r) => s + r.invoiceDiscounts),
        returnsValue: monthRecords.fold(0.0, (s, r) => s + r.returnsValue),
        netRevenue: monthRecords.fold(0.0, (s, r) => s + r.netRevenue),
        cogs: monthRecords.fold(0.0, (s, r) => s + r.cogs),
        grossProfit: monthRecords.fold(0.0, (s, r) => s + r.grossProfit),
        totalExpenses: monthRecords.fold(0.0, (s, r) => s + r.totalExpenses),
        deliveryFees: monthRecords.fold(0.0, (s, r) => s + r.deliveryFees),
        qrTransactionFees: monthRecords.fold(0.0, (s, r) => s + r.qrTransactionFees),
        destroyedGoods: monthRecords.fold(0.0, (s, r) => s + r.destroyedGoods),
        pointsPayment: monthRecords.fold(0.0, (s, r) => s + r.pointsPayment),
        salaryExpenses: monthRecords.fold(0.0, (s, r) => s + r.salaryExpenses),
        operatingProfit: monthRecords.fold(0.0, (s, r) => s + r.operatingProfit),
        otherIncome: monthRecords.fold(0.0, (s, r) => s + r.otherIncome),
        returnFees: monthRecords.fold(0.0, (s, r) => s + r.returnFees),
        salaryRefunds: monthRecords.fold(0.0, (s, r) => s + r.salaryRefunds),
        otherExpenses: monthRecords.fold(0.0, (s, r) => s + r.otherExpenses),
        netProfit: monthRecords.fold(0.0, (s, r) => s + r.netProfit),
        sourceFile: null,
        importedBy: null,
        notes: 'Dữ liệu tổng hợp từ ${monthRecords.length} công ty',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      aggregated.add(consolidated);
    }

    return limit != null ? aggregated.take(limit).toList() : aggregated;
  }

  /// Get all monthly P&L records for a company, ordered by report_month descending
  Future<List<MonthlyPnl>> getPnlHistory({
    required String companyId,
    String? branchId,
    int? limit,
  }) async {
    var query = _client
        .from('monthly_pnl')
        .select()
        .eq('company_id', companyId);

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = limit != null
        ? await query.order('report_month', ascending: false).limit(limit)
        : await query.order('report_month', ascending: false);

    return (response as List)
        .map((json) => MonthlyPnl.fromJson(json))
        .toList();
  }

  /// Get P&L records for a specific year
  Future<List<MonthlyPnl>> getPnlByYear({
    required String companyId,
    required int year,
    String? branchId,
  }) async {
    final startDate = '$year-01-01';
    final endDate = '$year-12-31';

    var query = _client
        .from('monthly_pnl')
        .select()
        .eq('company_id', companyId)
        .gte('report_month', startDate)
        .lte('report_month', endDate);

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = await query.order('report_month', ascending: true);

    return (response as List)
        .map((json) => MonthlyPnl.fromJson(json))
        .toList();
  }

  /// Get latest P&L record for a company
  Future<MonthlyPnl?> getLatestPnl({
    required String companyId,
    String? branchId,
  }) async {
    var query = _client
        .from('monthly_pnl')
        .select()
        .eq('company_id', companyId);

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = await query
        .order('report_month', ascending: false)
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;
    return MonthlyPnl.fromJson(list.first);
  }

  /// Get subsidiary breakdown for corporation view
  /// Returns list of subsidiaries with their total revenue/profit
  Future<List<Map<String, dynamic>>> _getSubsidiaryBreakdown() async {
    // Get all P&L records
    final pnlResponse = await _client
        .from('monthly_pnl')
        .select('company_id, net_revenue, net_profit')
        .order('report_month', ascending: false);
    
    final pnlRecords = pnlResponse as List;
    
    // Group by company_id and sum
    final Map<String, Map<String, double>> byCompany = {};
    for (final record in pnlRecords) {
      final companyId = record['company_id'] as String;
      byCompany.putIfAbsent(companyId, () => {'revenue': 0.0, 'profit': 0.0, 'count': 0.0});
      byCompany[companyId]!['revenue'] = 
          byCompany[companyId]!['revenue']! + (record['net_revenue'] as num).toDouble();
      byCompany[companyId]!['profit'] = 
          byCompany[companyId]!['profit']! + (record['net_profit'] as num).toDouble();
      byCompany[companyId]!['count'] = byCompany[companyId]!['count']! + 1;
    }
    
    // Get company names
    final companyIds = byCompany.keys.toList();
    if (companyIds.isEmpty) return [];
    
    final companiesResponse = await _client
        .from('companies')
        .select('id, name, business_type')
        .inFilter('id', companyIds);
    
    final companiesMap = <String, Map<String, dynamic>>{};
    for (final c in companiesResponse as List) {
      companiesMap[c['id'] as String] = c;
    }
    
    // Build result with company names, excluding corporation itself
    final result = <Map<String, dynamic>>[];
    for (final entry in byCompany.entries) {
      final companyInfo = companiesMap[entry.key];
      if (companyInfo == null) continue;
      // Skip corporation (parent company) from breakdown
      if (companyInfo['business_type'] == 'corporation') continue;
      
      result.add({
        'companyId': entry.key,
        'companyName': companyInfo['name'] ?? 'Unknown',
        'businessType': companyInfo['business_type'] ?? 'unknown',
        'totalRevenue': entry.value['revenue']!,
        'totalProfit': entry.value['profit']!,
        'monthCount': entry.value['count']!.toInt(),
        'avgMonthlyRevenue': entry.value['revenue']! / entry.value['count']!,
        'avgMonthlyProfit': entry.value['profit']! / entry.value['count']!,
        'profitMargin': entry.value['revenue']! > 0 
            ? (entry.value['profit']! / entry.value['revenue']!) * 100 
            : 0.0,
      });
    }
    
    // Sort by total revenue descending
    result.sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));
    
    return result;
  }

  /// Get financial summary for a company
  /// Returns aggregated stats from the latest 12 months
  /// For corporations, aggregates data from ALL subsidiary companies
  Future<Map<String, dynamic>> getFinancialSummary({
    required String companyId,
  }) async {
    // Check if this is a corporation - if so, get consolidated data
    final isCorp = await _isCorporation(companyId);
    final records = isCorp 
        ? await _getConsolidatedPnlHistory(limit: 12)
        : await getPnlHistory(companyId: companyId, limit: 12);

    if (records.isEmpty) {
      return {
        'hasData': false,
        'totalMonths': 0,
        'isCorporation': isCorp,
        'subsidiaryBreakdown': <Map<String, dynamic>>[],
      };
    }

    final latest = records.first;
    final totalRevenue = records.fold<double>(0, (sum, r) => sum + r.netRevenue);
    final totalProfit = records.fold<double>(0, (sum, r) => sum + r.netProfit);
    final totalCogs = records.fold<double>(0, (sum, r) => sum + r.cogs);
    final avgMonthlyRevenue = totalRevenue / records.length;
    final avgMonthlyProfit = totalProfit / records.length;

    // Revenue trend: compare latest 3 months vs previous 3 months
    double revenueGrowth = 0;
    if (records.length >= 6) {
      final recent3 = records.take(3).fold<double>(0, (s, r) => s + r.netRevenue);
      final prev3 = records.skip(3).take(3).fold<double>(0, (s, r) => s + r.netRevenue);
      if (prev3 > 0) revenueGrowth = ((recent3 - prev3) / prev3) * 100;
    }

    // Get subsidiary breakdown for corporations
    final subsidiaryBreakdown = isCorp 
        ? await _getSubsidiaryBreakdown() 
        : <Map<String, dynamic>>[];

    return {
      'hasData': true,
      'isCorporation': isCorp,
      'totalMonths': records.length,
      'latestMonth': latest.monthLabel,
      'latestNetRevenue': latest.netRevenue,
      'latestNetProfit': latest.netProfit,
      'latestGrossMargin': latest.grossMarginPct,
      'latestNetMargin': latest.netMarginPct,
      'totalRevenue12m': totalRevenue,
      'totalProfit12m': totalProfit,
      'totalCogs12m': totalCogs,
      'avgMonthlyRevenue': avgMonthlyRevenue,
      'avgMonthlyProfit': avgMonthlyProfit,
      'revenueGrowthPct': revenueGrowth,
      'isProfitable': latest.isProfitable,
      'records': records,
      'subsidiaryBreakdown': subsidiaryBreakdown,
    };
  }
}
