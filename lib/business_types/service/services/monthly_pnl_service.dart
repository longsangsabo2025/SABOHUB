import 'dart:typed_data';

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

  // ═══════════════════════════════════════════════════════════════
  // UPSERT — Tạo / Cập nhật Monthly P&L record
  // ═══════════════════════════════════════════════════════════════

  /// Upsert a monthly P&L record — creates if not exists, updates if it does.
  /// Uses (company_id, report_month) as the logical unique key.
  Future<MonthlyPnl> upsertMonthlyPnl({
    required String companyId,
    required DateTime reportMonth,
    String? branchId,
    String? branchName,
    // Revenue
    double grossRevenue = 0,
    double revenueDeductions = 0,
    double invoiceDiscounts = 0,
    double returnsValue = 0,
    double netRevenue = 0,
    // Costs
    double cogs = 0,
    double grossProfit = 0,
    // Expenses
    double totalExpenses = 0,
    double deliveryFees = 0,
    double qrTransactionFees = 0,
    double destroyedGoods = 0,
    double pointsPayment = 0,
    double salaryExpenses = 0,
    double operatingProfit = 0,
    // Monthly Expense Categories
    double rentExpense = 0,
    double electricityExpense = 0,
    double advertisingExpense = 0,
    double invoicedPurchases = 0,
    double otherPurchases = 0,
    // Other
    double otherIncome = 0,
    double returnFees = 0,
    double salaryRefunds = 0,
    double otherExpenses = 0,
    double netProfit = 0,
    String? notes,
    String? importedBy,
  }) async {
    // Normalize month to first day
    final normalizedMonth = DateTime(reportMonth.year, reportMonth.month, 1);
    final monthStr = normalizedMonth.toIso8601String().substring(0, 10);

    // Check if record already exists for this company + month
    final existing = await _client
        .from('monthly_pnl')
        .select('id')
        .eq('company_id', companyId)
        .eq('report_month', monthStr)
        .maybeSingle();

    final data = {
      'company_id': companyId,
      'report_month': monthStr,
      'branch_id': branchId,
      'branch_name': branchName,
      'gross_revenue': grossRevenue,
      'revenue_deductions': revenueDeductions,
      'invoice_discounts': invoiceDiscounts,
      'returns_value': returnsValue,
      'net_revenue': netRevenue,
      'cogs': cogs,
      'gross_profit': grossProfit,
      'total_expenses': totalExpenses,
      'delivery_fees': deliveryFees,
      'qr_transaction_fees': qrTransactionFees,
      'destroyed_goods': destroyedGoods,
      'points_payment': pointsPayment,
      'salary_expenses': salaryExpenses,
      'operating_profit': operatingProfit,
      'rent_expense': rentExpense,
      'electricity_expense': electricityExpense,
      'advertising_expense': advertisingExpense,
      'invoiced_purchases': invoicedPurchases,
      'other_purchases': otherPurchases,
      'other_income': otherIncome,
      'return_fees': returnFees,
      'salary_refunds': salaryRefunds,
      'other_expenses': otherExpenses,
      'net_profit': netProfit,
      'notes': notes,
      'imported_by': importedBy,
      'source_file': 'manual_entry',
    };

    Map<String, dynamic> response;

    if (existing != null) {
      // Update existing record
      data['updated_at'] = DateTime.now().toIso8601String();
      response = await _client
          .from('monthly_pnl')
          .update(data)
          .eq('id', existing['id'] as String)
          .select()
          .single();
    } else {
      // Insert new record
      response = await _client
          .from('monthly_pnl')
          .insert(data)
          .select()
          .single();
    }

    return MonthlyPnl.fromJson(response);
  }

  /// Update only expense categories for an existing record
  Future<MonthlyPnl> updateExpenses({
    required String recordId,
    double? salaryExpenses,
    double? rentExpense,
    double? electricityExpense,
    double? advertisingExpense,
    double? invoicedPurchases,
    double? otherPurchases,
    double? totalExpenses,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (salaryExpenses != null) data['salary_expenses'] = salaryExpenses;
    if (rentExpense != null) data['rent_expense'] = rentExpense;
    if (electricityExpense != null) data['electricity_expense'] = electricityExpense;
    if (advertisingExpense != null) data['advertising_expense'] = advertisingExpense;
    if (invoicedPurchases != null) data['invoiced_purchases'] = invoicedPurchases;
    if (otherPurchases != null) data['other_purchases'] = otherPurchases;
    if (totalExpenses != null) data['total_expenses'] = totalExpenses;
    if (notes != null) data['notes'] = notes;

    final response = await _client
        .from('monthly_pnl')
        .update(data)
        .eq('id', recordId)
        .select()
        .single();

    return MonthlyPnl.fromJson(response);
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTACHMENTS — Upload / List / Delete chứng từ hóa đơn
  // ═══════════════════════════════════════════════════════════════

  /// Upload file attachment for a P&L record
  Future<Map<String, dynamic>> uploadPnlAttachment({
    required String pnlRecordId,
    required String companyId,
    required String fileName,
    required List<int> fileBytes,
    String? category,
    String? uploadedBy,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = fileName.split('.').last.toLowerCase();
    final uniqueName = 'pnl_${pnlRecordId}_$timestamp.$ext';
    final storagePath = 'pnl-attachments/$companyId/$uniqueName';

    // Upload to Supabase Storage
    await _client.storage.from('documents').uploadBinary(
      storagePath,
      Uint8List.fromList(fileBytes),
      fileOptions: FileOptions(
        contentType: _getMimeType(ext),
        upsert: false,
      ),
    );

    final fileUrl = _client.storage.from('documents').getPublicUrl(storagePath);

    // Save metadata
    final response = await _client
        .from('pnl_attachments')
        .insert({
          'pnl_record_id': pnlRecordId,
          'company_id': companyId,
          'file_name': fileName,
          'file_url': fileUrl,
          'file_size': fileBytes.length,
          'file_type': _getMimeType(ext),
          'category': category,
          'uploaded_by': uploadedBy,
          'storage_path': storagePath,
        })
        .select()
        .single();

    return response;
  }

  /// Get all attachments for a P&L record
  Future<List<Map<String, dynamic>>> getPnlAttachments(String pnlRecordId) async {
    final response = await _client
        .from('pnl_attachments')
        .select()
        .eq('pnl_record_id', pnlRecordId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Delete an attachment
  Future<void> deletePnlAttachment(String attachmentId) async {
    // Get the record first to find storage path
    final record = await _client
        .from('pnl_attachments')
        .select('storage_path')
        .eq('id', attachmentId)
        .single();

    // Delete from storage
    final storagePath = record['storage_path'] as String?;
    if (storagePath != null) {
      await _client.storage.from('documents').remove([storagePath]);
    }

    // Soft-delete from DB
    await _client
        .from('pnl_attachments')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', attachmentId);
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get financial summary for a company
  /// Returns aggregated stats from the latest 12 months
  /// For corporations, aggregates data from ALL subsidiary companies
  Future<Map<String, dynamic>> getFinancialSummary({
    required String companyId,
  }) async {
    // Check if this is a corporation - if so, get consolidated data
    final isCorp = await _isCorporation(companyId);
    // Fetch ALL records for month selector navigation
    final records = isCorp 
        ? await _getConsolidatedPnlHistory()
        : await getPnlHistory(companyId: companyId);
    // 12-month subset for summary calculations
    final records12m = records.length > 12 ? records.sublist(0, 12) : records;

    if (records.isEmpty) {
      return {
        'hasData': false,
        'totalMonths': 0,
        'isCorporation': isCorp,
        'subsidiaryBreakdown': <Map<String, dynamic>>[],
      };
    }

    final latest = records.first;
    final totalRevenue = records12m.fold<double>(0, (sum, r) => sum + r.netRevenue);
    final totalProfit = records12m.fold<double>(0, (sum, r) => sum + r.netProfit);
    final totalCogs = records12m.fold<double>(0, (sum, r) => sum + r.cogs);
    final avgMonthlyRevenue = records12m.isNotEmpty ? totalRevenue / records12m.length : 0.0;
    final avgMonthlyProfit = records12m.isNotEmpty ? totalProfit / records12m.length : 0.0;

    // Revenue trend: compare latest 3 months vs previous 3 months
    double revenueGrowth = 0;
    if (records12m.length >= 6) {
      final recent3 = records12m.take(3).fold<double>(0, (s, r) => s + r.netRevenue);
      final prev3 = records12m.skip(3).take(3).fold<double>(0, (s, r) => s + r.netRevenue);
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
