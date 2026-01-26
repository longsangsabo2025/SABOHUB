import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';
import '../models/session.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền companyId từ authProvider

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ⚠️ Lưu companyId từ caller thay vì dùng auth
  final String? companyId;
  
  PaymentService({this.companyId});
  
  // Helper để validate và lấy companyId
  String _getCompanyId([String? overrideCompanyId]) {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    return cid;
  }

  // Get all payments for current company
  Future<List<Payment>> getAllPayments({String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            table_sessions!inner(
              billiards_tables!inner(
                company_id
              )
            )
          ''')
          .eq('table_sessions.billiards_tables.company_id', cid)
          .order('paid_at', ascending: false);

      return response.map<Payment>((data) => _mapToPayment(data)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách thanh toán: $e');
    }
  }

  // Get payments by status
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status, {String? overrideCompanyId}) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            table_sessions!inner(
              billiards_tables!inner(
                company_id
              )
            )
          ''')
          .eq('table_sessions.billiards_tables.company_id', cid)
          .eq('status', status.name)
          .order('paid_at', ascending: false);

      return response.map<Payment>((data) => _mapToPayment(data)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải thanh toán theo trạng thái: $e');
    }
  }

  // Get payments by session ID
  Future<List<Payment>> getPaymentsBySessionId(String sessionId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('session_id', sessionId)
          .order('paid_at', ascending: false);

      return response.map<Payment>((data) => _mapToPayment(data)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải thanh toán theo phiên: $e');
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('id', paymentId)
          .single();

      return _mapToPayment(response);
    } catch (e) {
      return null;
    }
  }

  // Create a new payment
  Future<Payment> createPayment({
    required String sessionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
    String? referenceNumber,
    String? customerName,
    String? overrideCompanyId,
  }) async {
    try {
      final cid = _getCompanyId(overrideCompanyId);
      
      final paymentData = {
        'session_id': sessionId,
        'company_id': cid,
        'amount': amount,
        'method': method.name,
        'status': PaymentStatus.pending.name,
        'paid_at': DateTime.now().toIso8601String(),
        'notes': notes,
        'reference_number': referenceNumber,
        'customer_name': customerName,
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return _mapToPayment(response);
    } catch (e) {
      throw Exception('Lỗi khi tạo thanh toán: $e');
    }
  }

  // Complete payment (mark as paid)
  Future<Payment> completePayment(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .update({
            'status': PaymentStatus.completed.name,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId)
          .select()
          .single();

      return _mapToPayment(response);
    } catch (e) {
      throw Exception('Lỗi khi hoàn thành thanh toán: $e');
    }
  }

  // Fail payment
  Future<Payment> failPayment(String paymentId, {String? reason}) async {
    try {
      final response = await _supabase
          .from('payments')
          .update({
            'status': PaymentStatus.failed.name,
            'notes': reason ?? 'Thanh toán thất bại',
          })
          .eq('id', paymentId)
          .select()
          .single();

      return _mapToPayment(response);
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu thanh toán thất bại: $e');
    }
  }

  // Refund payment
  Future<Payment> refundPayment(String paymentId, {String? reason}) async {
    try {
      final response = await _supabase
          .from('payments')
          .update({
            'status': PaymentStatus.refunded.name,
            'notes': reason ?? 'Đã hoàn tiền',
          })
          .eq('id', paymentId)
          .select()
          .single();

      return _mapToPayment(response);
    } catch (e) {
      throw Exception('Lỗi khi hoàn tiền: $e');
    }
  }

  // Process payment and complete session
  Future<Map<String, dynamic>> processPaymentAndCompleteSession({
    required String sessionId,
    required PaymentMethod method,
    double? paidAmount, // For cash payments with change calculation
    String? customerName,
    String? notes,
  }) async {
    try {
      // Get session details
      final sessionResponse = await _supabase
          .from('table_sessions')
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .eq('id', sessionId)
          .single();

      final session = TableSession(
        id: sessionResponse['id'],
        tableId: sessionResponse['table_id'],
        tableName: sessionResponse['billiards_tables']['name'],
        companyId: sessionResponse['billiards_tables']['company_id'],
        startTime: DateTime.parse(sessionResponse['start_time']),
        endTime: sessionResponse['end_time'] != null 
            ? DateTime.parse(sessionResponse['end_time']) 
            : null,
        totalPausedMinutes: sessionResponse['total_paused_minutes'] ?? 0,
        hourlyRate: (sessionResponse['hourly_rate'] as num).toDouble(),
        tableAmount: (sessionResponse['table_amount'] as num?)?.toDouble() ?? 0.0,
        ordersAmount: (sessionResponse['orders_amount'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (sessionResponse['total_amount'] as num?)?.toDouble() ?? 0.0,
        status: SessionStatus.values.firstWhere(
          (s) => s.name == sessionResponse['status'],
          orElse: () => SessionStatus.active,
        ),
        customerName: sessionResponse['customer_name'],
        notes: sessionResponse['notes'],
        orderIds: sessionResponse['order_ids'] != null 
            ? List<String>.from(sessionResponse['order_ids']) 
            : [],
      );

      // Calculate final amounts if not already calculated
      final tableAmount = session.tableAmount > 0 
          ? session.tableAmount 
          : session.calculateTableAmount();
      final totalAmount = tableAmount + session.ordersAmount;

      // End session first
      await _supabase
          .from('table_sessions')
          .update({
            'status': SessionStatus.completed.name,
            'end_time': DateTime.now().toIso8601String(),
            'table_amount': tableAmount,
            'total_amount': totalAmount,
          })
          .eq('id', sessionId);

      // Update table status to available
      await _supabase
          .from('billiards_tables')
          .update({'status': 'available'})
          .eq('id', session.tableId);

      // Create payment
      final payment = await createPayment(
        sessionId: sessionId,
        amount: totalAmount,
        method: method,
        customerName: customerName,
        notes: notes,
      );

      // Complete payment immediately for cash/card
      final completedPayment = await completePayment(payment.id);

      // Calculate change for cash payments
      double changeAmount = 0;
      if (method == PaymentMethod.cash && paidAmount != null && paidAmount > totalAmount) {
        changeAmount = paidAmount - totalAmount;
      }

      return {
        'payment': completedPayment,
        'session': session,
        'totalAmount': totalAmount,
        'tableAmount': tableAmount,
        'ordersAmount': session.ordersAmount,
        'paidAmount': paidAmount ?? totalAmount,
        'changeAmount': changeAmount,
      };
    } catch (e) {
      throw Exception('Lỗi khi xử lý thanh toán: $e');
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final payments = await getAllPayments();
      
      final today = DateTime.now();
      final todayPayments = payments.where((p) => 
        p.paidAt.day == today.day &&
        p.paidAt.month == today.month &&
        p.paidAt.year == today.year
      ).toList();

      final completedToday = todayPayments.where((p) => 
        p.status == PaymentStatus.completed
      ).length;

      final todayRevenue = todayPayments.where((p) => 
        p.status == PaymentStatus.completed
      ).fold(0.0, (sum, payment) => sum + payment.amount);

      final pendingPayments = payments.where((p) => 
        p.status == PaymentStatus.pending
      ).length;

      final failedPayments = payments.where((p) => 
        p.status == PaymentStatus.failed
      ).length;

      // Payment method breakdown for today
      final cashPayments = todayPayments.where((p) => 
        p.method == PaymentMethod.cash && p.status == PaymentStatus.completed
      ).fold(0.0, (sum, payment) => sum + payment.amount);

      final cardPayments = todayPayments.where((p) => 
        p.method == PaymentMethod.card && p.status == PaymentStatus.completed
      ).fold(0.0, (sum, payment) => sum + payment.amount);

      final qrPayments = todayPayments.where((p) => 
        p.method == PaymentMethod.qr && p.status == PaymentStatus.completed
      ).fold(0.0, (sum, payment) => sum + payment.amount);

      final transferPayments = todayPayments.where((p) => 
        p.method == PaymentMethod.transfer && p.status == PaymentStatus.completed
      ).fold(0.0, (sum, payment) => sum + payment.amount);

      return {
        'totalPayments': payments.length,
        'completedToday': completedToday,
        'todayRevenue': todayRevenue,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'cashPayments': cashPayments,
        'cardPayments': cardPayments,
        'qrPayments': qrPayments,
        'transferPayments': transferPayments,
      };
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê thanh toán: $e');
    }
  }

  // Private helper method to map database response to Payment
  Payment _mapToPayment(Map<String, dynamic> data) {
    return Payment(
      id: data['id'] ?? '',
      sessionId: data['session_id'] ?? '',
      companyId: data['company_id'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == data['method'],
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paidAt: data['paid_at'] != null ? DateTime.parse(data['paid_at']) : DateTime.now(),
      notes: data['notes'],
      referenceNumber: data['reference_number'],
      customerName: data['customer_name'],
    );
  }
}