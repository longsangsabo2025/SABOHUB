import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// 
/// SABOHUB sử dụng "CEO Auth" model:
/// - Chỉ CEO có tài khoản Supabase Auth thực sự
/// - Employees/Managers đăng nhập qua mã nhân viên, KHÔNG có auth.users
/// 
/// ❌ KHÔNG DÙNG: _supabase.auth.currentUser (chỉ CEO có)
/// ✅ PHẢI DÙNG: Truyền userId parameter từ authProvider của caller
///
/// Bill Service - Quản lý bills (Manager upload, CEO approve)
class BillService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload bill mới (Manager)
  /// 
  /// [userId] - Required: ID của user upload (từ authProvider.user.id)
  Future<Bill> uploadBill({
    required String companyId,
    required String userId,
    required String billNumber,
    required DateTime billDate,
    required double totalAmount,
    String? storeName,
    String? billImageUrl,
    Map<String, dynamic>? ocrData,
    String? notes,
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    final data = {
      'company_id': companyId,
      'bill_number': billNumber,
      'bill_date': billDate.toIso8601String(),
      'total_amount': totalAmount,
      'store_name': storeName,
      'bill_image_url': billImageUrl,
      'ocr_data': ocrData,
      'notes': notes,
      'uploaded_by': userId,
      'status': 'pending',
    };

    final response =
        await _supabase.from('bills').insert(data).select().single();

    return Bill.fromJson(response);
  }

  /// Lấy danh sách bills theo company
  Future<List<Bill>> getBillsByCompany({
    required String companyId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _supabase.from('bills').select().eq('company_id', companyId);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (fromDate != null) {
      query = query.gte('bill_date', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query = query.lt('bill_date', toDate.add(const Duration(days: 1)).toIso8601String());
    }

    final response = await query.order('bill_date', ascending: false);
    return (response as List).map((json) => Bill.fromJson(json)).toList();
  }

  /// Lấy bill theo ID
  Future<Bill?> getBillById(String billId) async {
    final response =
        await _supabase.from('bills').select().eq('id', billId).maybeSingle();

    return response != null ? Bill.fromJson(response) : null;
  }

  /// Approve bill (CEO)
  /// 
  /// [userId] - Required: ID của CEO approve (từ authProvider.user.id)
  Future<Bill> approveBill(String billId, {required String userId, String? notes}) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    final data = {
      'status': 'approved',
      'approved_by': userId,
      'approved_at': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('bills')
        .update(data)
        .eq('id', billId)
        .select()
        .single();

    return Bill.fromJson(response);
  }

  /// Reject bill (CEO)
  /// 
  /// [userId] - Required: ID của CEO reject (từ authProvider.user.id)
  Future<Bill> rejectBill(String billId, {required String userId, String? notes}) async {
    if (userId.isEmpty) throw Exception('User not authenticated');

    final data = {
      'status': 'rejected',
      'approved_by': userId,
      'approved_at': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('bills')
        .update(data)
        .eq('id', billId)
        .select()
        .single();

    return Bill.fromJson(response);
  }

  /// Mark bill as paid (CEO)
  Future<Bill> markAsPaid(String billId) async {
    final response = await _supabase
        .from('bills')
        .update({'status': 'paid'})
        .eq('id', billId)
        .select()
        .single();

    return Bill.fromJson(response);
  }

  /// Upload bill image to storage
  Future<String> uploadBillImage(
    String companyId,
    String billNumber,
    List<int> imageBytes,
    String fileExtension,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$companyId/${billNumber}_$timestamp.$fileExtension';

    await _supabase.storage.from('bills').uploadBinary(
          fileName,
          Uint8List.fromList(imageBytes),
        );

    final publicUrl = _supabase.storage.from('bills').getPublicUrl(fileName);

    return publicUrl;
  }

  /// Delete bill (CEO only)
  Future<void> deleteBill(String billId) async {
    await _supabase.from('bills').delete().eq('id', billId);
  }

  /// Update bill
  Future<Bill> updateBill(String billId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('bills')
        .update(updates)
        .eq('id', billId)
        .select()
        .single();

    return Bill.fromJson(response);
  }

  /// Stream bills real-time
  Stream<List<Bill>> streamBillsByCompany(String companyId) {
    return _supabase
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .order('bill_date', ascending: false)
        .map((data) =>
            (data as List).map((json) => Bill.fromJson(json)).toList());
  }
}
