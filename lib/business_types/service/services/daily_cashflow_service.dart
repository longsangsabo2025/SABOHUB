import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_cashflow.dart';

/// ⚠️ CRITICAL: CEO Auth model — employees KHÔNG có auth.users
/// Truyền userId parameter từ authProvider.
///
/// DailyCashflow Service - Parse Excel POS cuối ngày & lưu vào DB
class DailyCashflowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════
  // EXCEL PARSER — Đọc file "Báo cáo cuối ngày tổng hợp" từ POS
  // ═══════════════════════════════════════════════════════════════

  /// Parse file Excel cuối ngày, trả về parsed data (chưa lưu DB).
  /// [bytes] - Raw bytes của file .xls/.xlsx
  /// [fileName] - Tên file gốc
  ParsedCashflowData parseExcelFile(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('File Excel trống, không có sheet nào.');
    }

    // Get first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    final rows = sheet.rows;

    if (rows.length < 10) {
      throw Exception('File không đủ dữ liệu (cần ít nhất 10 dòng).');
    }

    // ── Parse report date from row 3 (index 3): "Ngày bán 01/03/2026"
    DateTime? reportDate;
    String? branchName;

    for (int r = 0; r < rows.length && r < 10; r++) {
      final rowText = _rowToString(rows[r]);

      // Parse "Ngày bán DD/MM/YYYY"
      final dateMatch = RegExp(r'Ngày bán\s+(\d{2}/\d{2}/\d{4})').firstMatch(rowText);
      if (dateMatch != null) {
        final parts = dateMatch.group(1)!.split('/');
        reportDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      // Parse "Chi nhánh: ..."
      final branchMatch = RegExp(r'Chi nhánh:\s*(.+)').firstMatch(rowText);
      if (branchMatch != null) {
        branchName = branchMatch.group(1)!.trim();
      }
    }

    if (reportDate == null) {
      throw Exception('Không tìm thấy "Ngày bán" trong file Excel.');
    }

    // ── Parse revenue summary section (around row 8-9)
    // Row 8: Headers — Thu / Chi | Tiền mặt | CK | Thẻ | Ví điện tử | Điểm | Tổng thực thu
    // Row 9: Values
    double cashAmount = 0;
    double transferAmount = 0;
    double cardAmount = 0;
    double ewalletAmount = 0;
    double pointsAmount = 0;
    double totalRevenue = 0;

    // Find the "Thu / Chi" or "Tổng thu" header row
    for (int r = 5; r < rows.length && r < 20; r++) {
      final rowText = _rowToString(rows[r]);
      if (rowText.contains('Thu / Chi') || rowText.contains('Thu/ Chi')) {
        // Next row with numbers is the summary
        if (r + 1 < rows.length) {
          final values = _extractNumbers(rows[r + 1]);
          if (values.length >= 2) {
            cashAmount = values.isNotEmpty ? values[0] : 0;
            transferAmount = values.length > 1 ? values[1] : 0;
            cardAmount = values.length > 2 ? values[2] : 0;
            ewalletAmount = values.length > 3 ? values[3] : 0;
            pointsAmount = values.length > 4 ? values[4] : 0;
            totalRevenue = values.length > 5 ? values[5] : 0;
          }
        }
        break;
      }
    }

    // Fallback: look for "Tổng thu" row
    if (totalRevenue == 0) {
      for (int r = 5; r < rows.length && r < 25; r++) {
        final rowText = _rowToString(rows[r]);
        if (rowText.contains('Tổng thu')) {
          final values = _extractNumbers(rows[r]);
          if (values.length >= 2) {
            cashAmount = values.isNotEmpty ? values[0] : 0;
            transferAmount = values.length > 1 ? values[1] : 0;
            cardAmount = values.length > 2 ? values[2] : 0;
            ewalletAmount = values.length > 3 ? values[3] : 0;
            pointsAmount = values.length > 4 ? values[4] : 0;
            totalRevenue = values.length > 5 ? values[5] : 0;
          }
          break;
        }
      }
    }

    // ── Parse transaction count section (around row 29-33)
    int totalOrders = 0;
    int cashOrders = 0;
    int transferOrders = 0;
    int cardOrders = 0;
    int ewalletOrders = 0;
    int pointsOrders = 0;

    // Find "Số giao dịch" section
    for (int r = 20; r < rows.length; r++) {
      final rowText = _rowToString(rows[r]);
      if (rowText.contains('Số giao dịch') && !rowText.contains('Số mặt hàng')) {
        // Look for "Hóa đơn" row with numbers below
        for (int r2 = r + 1; r2 < rows.length && r2 < r + 8; r2++) {
          final rowText2 = _rowToString(rows[r2]);
          if (rowText2.contains('Hóa đơn') || _extractIntegers(rows[r2]).length >= 2) {
            final ints = _extractIntegers(rows[r2]);
            if (ints.isNotEmpty) {
              totalOrders = ints[0];
              cashOrders = ints.length > 1 ? ints[1] : 0;
              transferOrders = ints.length > 2 ? ints[2] : 0;
              cardOrders = ints.length > 3 ? ints[3] : 0;
              pointsOrders = ints.length > 4 ? ints[4] : 0;
              ewalletOrders = ints.length > 5 ? ints[5] : 0;
            }
            break;
          }
        }
        break;
      }
    }

    // ── Parse product info (around row 39-41)
    int uniqueItems = 0;
    int totalQuantity = 0;

    for (int r = 30; r < rows.length; r++) {
      final rowText = _rowToString(rows[r]);
      if (rowText.contains('Hàng hóa') || rowText.contains('Số mặt hàng')) {
        // Find the numbers row below
        for (int r2 = r; r2 < rows.length && r2 < r + 5; r2++) {
          final ints = _extractIntegers(rows[r2]);
          if (ints.length >= 2) {
            uniqueItems = ints[0];
            totalQuantity = ints[1];
            break;
          }
        }
        break;
      }
    }

    // Build raw JSON for reference
    final rawData = <String, dynamic>{
      'file_name': fileName,
      'sheet_name': sheetName,
      'total_rows': rows.length,
      'parsed_at': DateTime.now().toIso8601String(),
    };

    return ParsedCashflowData(
      reportDate: reportDate,
      branchName: branchName,
      cashAmount: cashAmount,
      transferAmount: transferAmount,
      cardAmount: cardAmount,
      ewalletAmount: ewalletAmount,
      pointsAmount: pointsAmount,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      cashOrders: cashOrders,
      transferOrders: transferOrders,
      cardOrders: cardOrders,
      ewalletOrders: ewalletOrders,
      pointsOrders: pointsOrders,
      uniqueItems: uniqueItems,
      totalQuantity: totalQuantity,
      sourceFile: fileName,
      rawData: rawData,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DB OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Save parsed data to DB
  Future<DailyCashflow> saveCashflow({
    required String companyId,
    required String userId,
    required ParsedCashflowData parsed,
    String? branchId,
    String? notes,
  }) async {
    final data = {
      'company_id': companyId,
      'branch_id': branchId,
      'report_date': parsed.reportDate.toIso8601String().substring(0, 10),
      'branch_name': parsed.branchName,
      'cash_amount': parsed.cashAmount,
      'transfer_amount': parsed.transferAmount,
      'card_amount': parsed.cardAmount,
      'ewallet_amount': parsed.ewalletAmount,
      'points_amount': parsed.pointsAmount,
      'total_revenue': parsed.totalRevenue,
      'total_orders': parsed.totalOrders,
      'cash_orders': parsed.cashOrders,
      'transfer_orders': parsed.transferOrders,
      'card_orders': parsed.cardOrders,
      'points_orders': parsed.pointsOrders,
      'ewallet_orders': parsed.ewalletOrders,
      'unique_items': parsed.uniqueItems,
      'total_quantity': parsed.totalQuantity,
      'source_file': parsed.sourceFile,
      'imported_by': userId,
      'notes': notes,
      'raw_data': parsed.rawData,
    };

    final response = await _supabase
        .from('daily_cashflow')
        .upsert(data, onConflict: 'company_id,branch_id,report_date')
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Get cashflow history for a company
  Future<List<DailyCashflow>> getCashflowHistory({
    required String companyId,
    String? branchId,
    int limit = 30,
  }) async {
    var query = _supabase
        .from('daily_cashflow')
        .select()
        .eq('company_id', companyId);

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final data = await query
        .order('report_date', ascending: false)
        .limit(limit);
    return (data as List).map((e) => DailyCashflow.fromJson(e)).toList();
  }

  /// Get single cashflow by date
  Future<DailyCashflow?> getCashflowByDate({
    required String companyId,
    required DateTime date,
    String? branchId,
  }) async {
    var query = _supabase
        .from('daily_cashflow')
        .select()
        .eq('company_id', companyId)
        .eq('report_date', date.toIso8601String().substring(0, 10));

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final data = await query.maybeSingle();
    return data != null ? DailyCashflow.fromJson(data) : null;
  }

  /// Delete a cashflow record
  Future<void> deleteCashflow(String id) async {
    // Soft delete - sets is_active=false
    await _supabase.from('daily_cashflow').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════════
  // WORKFLOW METHODS — Draft → Pending → Approved/Rejected
  // ═══════════════════════════════════════════════════════════════

  /// Staff creates draft report
  Future<DailyCashflow> createDraftReport({
    required String companyId,
    required String userId,
    required DateTime reportDate,
    required double cashAmount,
    required double transferAmount,
    required double cardAmount,
    required double ewalletAmount,
    required double totalRevenue,
    required int totalOrders,
    String? branchId,
    String? branchName,
    String? notes,
  }) async {
    final data = {
      'company_id': companyId,
      'branch_id': branchId,
      'report_date': reportDate.toIso8601String().substring(0, 10),
      'branch_name': branchName,
      'cash_amount': cashAmount,
      'transfer_amount': transferAmount,
      'card_amount': cardAmount,
      'ewallet_amount': ewalletAmount,
      'points_amount': 0.0,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'cash_orders': 0,
      'transfer_orders': 0,
      'card_orders': 0,
      'ewallet_orders': 0,
      'points_orders': 0,
      'unique_items': 0,
      'total_quantity': 0,
      'imported_by': userId,
      'notes': notes,
      'status': 'draft',
      'submitted_by': userId,
    };

    final response = await _supabase
        .from('daily_cashflow')
        .insert(data)
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Staff submits report for review
  Future<DailyCashflow> submitReport({
    required String reportId,
    required String userId,
  }) async {
    final response = await _supabase
        .from('daily_cashflow')
        .update({
          'status': 'pending',
          'submitted_by': userId,
          'submitted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId)
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Shift Leader reviews (can edit values if needed)
  Future<DailyCashflow> reviewReport({
    required String reportId,
    required String reviewerId,
    double? cashAmount,
    double? transferAmount,
    double? cardAmount,
    double? ewalletAmount,
    double? totalRevenue,
    int? totalOrders,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
    };

    // Allow adjustments
    if (cashAmount != null) updates['cash_amount'] = cashAmount;
    if (transferAmount != null) updates['transfer_amount'] = transferAmount;
    if (cardAmount != null) updates['card_amount'] = cardAmount;
    if (ewalletAmount != null) updates['ewallet_amount'] = ewalletAmount;
    if (totalRevenue != null) updates['total_revenue'] = totalRevenue;
    if (totalOrders != null) updates['total_orders'] = totalOrders;
    if (notes != null) updates['notes'] = notes;

    final response = await _supabase
        .from('daily_cashflow')
        .update(updates)
        .eq('id', reportId)
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Manager approves report
  Future<DailyCashflow> approveReport({
    required String reportId,
    required String approverId,
  }) async {
    final response = await _supabase
        .from('daily_cashflow')
        .update({
          'status': 'approved',
          'approved_by': approverId,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId)
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Manager rejects report
  Future<DailyCashflow> rejectReport({
    required String reportId,
    required String approverId,
    required String reason,
  }) async {
    final response = await _supabase
        .from('daily_cashflow')
        .update({
          'status': 'rejected',
          'approved_by': approverId,
          'approved_at': DateTime.now().toIso8601String(),
          'rejection_reason': reason,
        })
        .eq('id', reportId)
        .select()
        .single();

    return DailyCashflow.fromJson(response);
  }

  /// Get reports by status
  Future<List<DailyCashflow>> getReportsByStatus({
    required String companyId,
    required ReportStatus status,
    String? branchId,
    int limit = 50,
  }) async {
    var query = _supabase
        .from('daily_cashflow')
        .select()
        .eq('company_id', companyId)
        .eq('status', status.value);

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final data = await query
        .order('report_date', ascending: false)
        .limit(limit);

    return (data as List).map((e) => DailyCashflow.fromJson(e)).toList();
  }

  /// Get pending reports for shift leader review
  Future<List<DailyCashflow>> getPendingReports({
    required String companyId,
    String? branchId,
  }) async {
    return getReportsByStatus(
      companyId: companyId,
      status: ReportStatus.pending,
      branchId: branchId,
    );
  }

  /// Get approved reports (for manager view)
  Future<List<DailyCashflow>> getApprovedReports({
    required String companyId,
    String? branchId,
    int limit = 30,
  }) async {
    return getReportsByStatus(
      companyId: companyId,
      status: ReportStatus.approved,
      branchId: branchId,
      limit: limit,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Convert a row of cells to a single string for pattern matching
  String _rowToString(List<Data?> row) {
    return row.map((c) => c?.value?.toString() ?? '').join(' ').trim();
  }

  /// Extract all numeric values (doubles) from a row
  List<double> _extractNumbers(List<Data?> row) {
    final nums = <double>[];
    for (final cell in row) {
      if (cell == null || cell.value == null) continue;
      final v = cell.value;
      if (v is DoubleCellValue) {
        nums.add(v.value);
      } else if (v is IntCellValue) {
        nums.add(v.value.toDouble());
      } else {
        final str = v.toString();
        final parsed = double.tryParse(str.replaceAll(',', ''));
        if (parsed != null && parsed > 0) nums.add(parsed);
      }
    }
    return nums;
  }

  /// Extract all integer values from a row
  List<int> _extractIntegers(List<Data?> row) {
    final nums = <int>[];
    for (final cell in row) {
      if (cell == null || cell.value == null) continue;
      final v = cell.value;
      if (v is IntCellValue) {
        nums.add(v.value);
      } else if (v is DoubleCellValue) {
        final d = v.value;
        if (d == d.roundToDouble() && d > 0) nums.add(d.toInt());
      } else {
        final str = v.toString();
        final parsed = double.tryParse(str.replaceAll(',', ''));
        if (parsed != null && parsed > 0 && parsed == parsed.roundToDouble()) {
          nums.add(parsed.toInt());
        }
      }
    }
    return nums;
  }
}

/// Parsed data from Excel, before saving to DB
class ParsedCashflowData {
  final DateTime reportDate;
  final String? branchName;
  final double cashAmount;
  final double transferAmount;
  final double cardAmount;
  final double ewalletAmount;
  final double pointsAmount;
  final double totalRevenue;
  final int totalOrders;
  final int cashOrders;
  final int transferOrders;
  final int cardOrders;
  final int ewalletOrders;
  final int pointsOrders;
  final int uniqueItems;
  final int totalQuantity;
  final String? sourceFile;
  final Map<String, dynamic>? rawData;

  ParsedCashflowData({
    required this.reportDate,
    this.branchName,
    this.cashAmount = 0,
    this.transferAmount = 0,
    this.cardAmount = 0,
    this.ewalletAmount = 0,
    this.pointsAmount = 0,
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.cashOrders = 0,
    this.transferOrders = 0,
    this.cardOrders = 0,
    this.ewalletOrders = 0,
    this.pointsOrders = 0,
    this.uniqueItems = 0,
    this.totalQuantity = 0,
    this.sourceFile,
    this.rawData,
  });
}
