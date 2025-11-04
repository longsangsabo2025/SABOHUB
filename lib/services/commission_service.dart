import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_commission.dart';
import '../models/commission_summary.dart';

/// Commission Service - Quản lý hoa hồng nhân viên
class CommissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tính toán hoa hồng cho bill (gọi PostgreSQL function)
  Future<List<BillCommission>> calculateBillCommissions({
    required String billId,
    List<String>? employeeIds,
  }) async {
    await _supabase.rpc(
      'calculate_bill_commissions',
      params: {
        'p_bill_id': billId,
        'p_employee_ids': employeeIds,
      },
    );

    // Sau khi calculate, fetch bill_commissions
    final commissions = await getBillCommissions(billId);
    return commissions;
  }

  /// Lấy danh sách hoa hồng của bill
  Future<List<BillCommission>> getBillCommissions(String billId) async {
    final response = await _supabase
        .from('bill_commissions')
        .select()
        .eq('bill_id', billId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BillCommission.fromJson(json))
        .toList();
  }

  /// Lấy danh sách hoa hồng của nhân viên
  Future<List<BillCommission>> getEmployeeCommissions({
    required String employeeId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Build filter query
    var query = _supabase
        .from('bill_commissions')
        .select('*, bills!inner(*)')
        .eq('employee_id', employeeId);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (fromDate != null) {
      query = query.gte('bills.bill_date', fromDate.toIso8601String());
    }

    if (toDate != null) {
      query = query.lte('bills.bill_date', toDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => BillCommission.fromJson(json))
        .toList();
  }

  /// Lấy tổng hợp hoa hồng của nhân viên (gọi PostgreSQL function)
  Future<CommissionSummary> getEmployeeCommissionSummary({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _supabase.rpc(
      'get_employee_commission_summary',
      params: {
        'p_employee_id': employeeId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
      },
    );

    if (response == null || (response as List).isEmpty) {
      return CommissionSummary.empty();
    }

    return CommissionSummary.fromJson(response[0]);
  }

  /// Approve commission (CEO)
  Future<BillCommission> approveCommission(
    String commissionId, {
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'status': 'approved',
      'approved_by': userId,
      'approved_at': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('bill_commissions')
        .update(data)
        .eq('id', commissionId)
        .select()
        .single();

    return BillCommission.fromJson(response);
  }

  /// Reject commission (CEO)
  Future<BillCommission> rejectCommission(
    String commissionId, {
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'status': 'rejected',
      'approved_by': userId,
      'approved_at': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('bill_commissions')
        .update(data)
        .eq('id', commissionId)
        .select()
        .single();

    return BillCommission.fromJson(response);
  }

  /// Mark commission as paid (CEO)
  Future<BillCommission> markCommissionAsPaid(
    String commissionId, {
    String? paymentReference,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'status': 'paid',
      'paid_by': userId,
      'paid_at': DateTime.now().toIso8601String(),
      'payment_reference': paymentReference,
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('bill_commissions')
        .update(data)
        .eq('id', commissionId)
        .select()
        .single();

    return BillCommission.fromJson(response);
  }

  /// Bulk approve commissions for a bill
  Future<void> approveBillCommissions(String billId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('bill_commissions').update({
      'status': 'approved',
      'approved_by': userId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('bill_id', billId).eq('status', 'pending');
  }

  /// Bulk mark commissions as paid for a bill
  Future<void> markBillCommissionsAsPaid(
    String billId, {
    String? paymentReference,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('bill_commissions').update({
      'status': 'paid',
      'paid_by': userId,
      'paid_at': DateTime.now().toIso8601String(),
      'payment_reference': paymentReference,
    }).eq('bill_id', billId).eq('status', 'approved');
  }

  /// Stream employee commissions real-time
  Stream<List<BillCommission>> streamEmployeeCommissions(String employeeId) {
    return _supabase
        .from('bill_commissions')
        .stream(primaryKey: ['id'])
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .map((data) =>
            (data as List).map((json) => BillCommission.fromJson(json)).toList());
  }

  /// Get commission statistics for company
  Future<Map<String, dynamic>> getCompanyCommissionStats(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get all commissions for the company
    var query = _supabase
        .from('bill_commissions')
        .select('*, bills!inner(company_id, bill_date)')
        .eq('bills.company_id', companyId);

    if (startDate != null) {
      query = query.gte('bills.bill_date', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('bills.bill_date', endDate.toIso8601String());
    }

    final response = await query;
    final commissions =
        (response as List).map((json) => BillCommission.fromJson(json)).toList();

    // Calculate stats
    double totalCommission = 0;
    double pendingCommission = 0;
    double approvedCommission = 0;
    double paidCommission = 0;
    int totalCount = commissions.length;
    int pendingCount = 0;
    int approvedCount = 0;
    int paidCount = 0;

    for (final commission in commissions) {
      totalCommission += commission.commissionAmount;

      switch (commission.status) {
        case 'pending':
          pendingCommission += commission.commissionAmount;
          pendingCount++;
          break;
        case 'approved':
          approvedCommission += commission.commissionAmount;
          approvedCount++;
          break;
        case 'paid':
          paidCommission += commission.commissionAmount;
          paidCount++;
          break;
      }
    }

    return {
      'total_commission': totalCommission,
      'pending_commission': pendingCommission,
      'approved_commission': approvedCommission,
      'paid_commission': paidCommission,
      'total_count': totalCount,
      'pending_count': pendingCount,
      'approved_count': approvedCount,
      'paid_count': paidCount,
    };
  }
}
