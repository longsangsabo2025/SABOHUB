import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/app_logger.dart';

/// Model cho kết quả phân tích hóa đơn từ AI
class InvoiceAnalysisResult {
  final bool success;
  final String? transactionId;
  final String? targetMonth;
  final String category;
  final double amount;
  final String? vendor;
  final String? invoiceDate;
  final String? invoiceNumber;
  final String? description;
  final double confidence;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? categoryInfo;
  final String? error;
  final bool saved;
  final String documentType; // invoice, bank_transfer, receipt, cash_note, other

  InvoiceAnalysisResult({
    required this.success,
    this.transactionId,
    this.targetMonth,
    this.category = 'other',
    this.amount = 0,
    this.vendor,
    this.invoiceDate,
    this.invoiceNumber,
    this.description,
    this.confidence = 0,
    this.items = const [],
    this.categoryInfo,
    this.error,
    this.saved = false,
    this.documentType = 'other',
  });

  factory InvoiceAnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return InvoiceAnalysisResult(
      success: json['success'] == true,
      transactionId: json['transaction_id'] as String?,
      targetMonth: json['target_month'] as String?,
      category: (analysis['category'] as String?) ?? 'other',
      amount: (analysis['amount'] as num?)?.toDouble() ?? 0,
      vendor: analysis['vendor'] as String?,
      invoiceDate: analysis['invoice_date'] as String?,
      invoiceNumber: analysis['invoice_number'] as String?,
      description: analysis['description'] as String?,
      confidence: (analysis['confidence'] as num?)?.toDouble() ?? 0,
      items: (analysis['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      categoryInfo: json['category_info'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      saved: json['saved'] == true,
      documentType: (analysis['document_type'] as String?) ?? 'other',
    );
  }

  factory InvoiceAnalysisResult.error(String message) {
    return InvoiceAnalysisResult(success: false, error: message);
  }

  /// Loại chứng từ tiếng Việt
  String get documentTypeLabel => _documentTypeLabelMap[documentType] ?? documentType;

  static const _documentTypeLabelMap = {
    'invoice': 'Hóa đơn',
    'bank_transfer': 'Chuyển khoản',
    'receipt': 'Biên lai',
    'cash_note': 'Phiếu thu/chi',
    'other': 'Khác',
  };

  /// Tên category tiếng Việt
  String get categoryLabel {
    return categoryInfo?['vi'] as String? ?? categoryLabelMap[category] ?? category;
  }

  static const categoryLabelMap = {
    'salary': 'Lương nhân viên',
    'rent': 'Mặt bằng',
    'electricity': 'Điện / Nước / Internet',
    'advertising': 'Quảng cáo',
    'invoiced_purchases': 'Nhập hàng có hóa đơn',
    'equipment_maintenance': 'Sửa chữa / Bảo trì thiết bị',
    'other_purchases': 'Mua hàng hóa/vật dụng khác',
    'other': 'Chi phí khác',
  };
}

/// Model cho expense transaction từ DB
class ExpenseTransaction {
  final String id;
  final String companyId;
  final String category;
  final double amount;
  final String? vendor;
  final String? invoiceDate;
  final String? invoiceNumber;
  final String? description;
  final String targetMonth;
  final double confidence;
  final String status; // pending, confirmed, applied, rejected
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;
  final String? imageUrl;

  ExpenseTransaction({
    required this.id,
    required this.companyId,
    required this.category,
    required this.amount,
    this.vendor,
    this.invoiceDate,
    this.invoiceNumber,
    this.description,
    required this.targetMonth,
    required this.confidence,
    required this.status,
    this.items = const [],
    required this.createdAt,
    this.imageUrl,
  });

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) {
    return ExpenseTransaction(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      category: json['category'] as String? ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      vendor: json['vendor'] as String?,
      invoiceDate: json['invoice_date'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      description: json['description'] as String?,
      targetMonth: json['target_month'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      imageUrl: json['image_url'] as String?,
    );
  }

  String get categoryLabel =>
      InvoiceAnalysisResult.categoryLabelMap[category] ?? category;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isApplied => status == 'applied';
  bool get isRejected => status == 'rejected';
}

/// Service gọi Edge Function phân tích hóa đơn + quản lý expense transactions
class InvoiceScanService {
  final _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // AI ANALYSIS — Gọi Edge Function analyze-invoice
  // ══════════════════════════════════════════════════════════════

  /// Gửi ảnh hóa đơn lên AI phân tích
  /// [imageBytes] - raw bytes của ảnh
  /// [mimeType] - loại ảnh (image/jpeg, image/png)
  /// [companyId] - ID công ty
  /// [employeeId] - ID nhân viên đang đăng nhập
  Future<InvoiceAnalysisResult> analyzeInvoice({
    required Uint8List imageBytes,
    required String mimeType,
    required String companyId,
    String? employeeId,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await _client.functions.invoke(
        'analyze-invoice',
        body: {
          'image_base64': base64Image,
          'mime_type': mimeType,
          'company_id': companyId,
          'employee_id': employeeId,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map
            ? (errorData['error'] ?? 'Unknown error')
            : 'Edge function error (status ${response.status})';
        return InvoiceAnalysisResult.error(errorMsg.toString());
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : jsonDecode(response.data.toString()) as Map<String, dynamic>;

      return InvoiceAnalysisResult.fromJson(data);
    } catch (e) {
      return InvoiceAnalysisResult.error('Lỗi phân tích: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // EXPENSE TRANSACTIONS — CRUD
  // ══════════════════════════════════════════════════════════════

  /// Lấy danh sách expense transactions theo company + month
  Future<List<ExpenseTransaction>> getTransactions({
    required String companyId,
    String? targetMonth,
    String? status,
  }) async {
    var query = _client
        .from('expense_transactions')
        .select()
        .eq('company_id', companyId);

    if (targetMonth != null) {
      query = query.eq('target_month', targetMonth);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => ExpenseTransaction.fromJson(json))
        .toList();
  }

  /// Lấy transactions đang pending cho company
  Future<List<ExpenseTransaction>> getPendingTransactions(
      String companyId) async {
    return getTransactions(companyId: companyId, status: 'pending');
  }

  /// Confirm (xác nhận) một transaction
  /// Có thể sửa amount, category trước khi confirm
  Future<void> confirmTransaction(
    String transactionId, {
    double? correctedAmount,
    String? correctedCategory,
  }) async {
    final updates = <String, dynamic>{
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (correctedAmount != null) updates['amount'] = correctedAmount;
    if (correctedCategory != null) updates['category'] = correctedCategory;

    await _client
        .from('expense_transactions')
        .update(updates)
        .eq('id', transactionId);
  }

  /// Reject (từ chối) một transaction
  Future<void> rejectTransaction(String transactionId) async {
    await _client.from('expense_transactions').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', transactionId);
  }

  /// Soft-delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('expense_transactions')
        .update({'is_active': false, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', transactionId);
  }

  // ══════════════════════════════════════════════════════════════
  // APPLY TO P&L — Tổng hợp & cập nhật monthly_pnl
  // ══════════════════════════════════════════════════════════════

  /// Apply tất cả confirmed transactions cho 1 tháng vào monthly_pnl
  /// Gọi RPC function apply_expenses_to_pnl
  Future<Map<String, dynamic>> applyExpensesToPnl({
    required String companyId,
    required String targetMonth,
  }) async {
    try {
      final result = await _client.rpc('apply_expenses_to_pnl', params: {
        'p_company_id': companyId,
        'p_target_month': targetMonth,
      });
      return {
        'success': true,
        'result': result,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Lấy tổng hợp chi phí theo category cho 1 tháng
  Future<List<Map<String, dynamic>>> getMonthlyAggregate({
    required String companyId,
    required String targetMonth,
  }) async {
    try {
      final result = await _client.rpc('aggregate_monthly_expenses', params: {
        'p_company_id': companyId,
        'p_target_month': targetMonth,
      });
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      return [];
    }
  }

  /// Đếm transactions theo status
  Future<Map<String, int>> getTransactionCounts(String companyId) async {
    try {
      final response = await _client
          .from('expense_transactions')
          .select('status')
          .eq('company_id', companyId);

      final list = response as List;
      final counts = <String, int>{
        'pending': 0,
        'confirmed': 0,
        'applied': 0,
        'rejected': 0,
      };
      for (final item in list) {
        final s = item['status'] as String? ?? '';
        counts[s] = (counts[s] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      AppLogger.error('Invoice status counts failed', e);
      return {'pending': 0, 'confirmed': 0, 'applied': 0, 'rejected': 0};
    }
  }
}
