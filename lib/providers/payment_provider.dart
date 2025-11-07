import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// All payments provider
final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await paymentService.getAllPayments();
});

// Payments by status provider (family)
final paymentsByStatusProvider = FutureProvider.family<List<Payment>, PaymentStatus>((ref, status) async {
  final paymentService = ref.read(paymentServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await paymentService.getPaymentsByStatus(status);
});

// Payments by session provider (family)
final paymentsBySessionProvider = FutureProvider.family<List<Payment>, String>((ref, sessionId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await paymentService.getPaymentsBySessionId(sessionId);
});

// Payment stats provider
final paymentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return {
      'totalPayments': 0,
      'completedToday': 0,
      'todayRevenue': 0.0,
      'pendingPayments': 0,
      'failedPayments': 0,
      'cashPayments': 0.0,
      'cardPayments': 0.0,
      'qrPayments': 0.0,
      'transferPayments': 0.0,
    };
  }
  
  return await paymentService.getPaymentStats();
});

// Individual payment provider (family)
final paymentProvider = FutureProvider.family<Payment?, String>((ref, paymentId) async {
  final paymentService = ref.read(paymentServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return null;
  }
  
  return await paymentService.getPaymentById(paymentId);
});

// Payment actions provider
final paymentActionsProvider = Provider<PaymentActions>((ref) {
  return PaymentActions(ref);
});

class PaymentActions {
  final Ref _ref;
  PaymentActions(this._ref);

  PaymentService get _paymentService => _ref.read(paymentServiceProvider);

  // Create a new payment
  Future<Payment> createPayment({
    required String sessionId,
    required double amount,
    required PaymentMethod method,
    String? notes,
    String? referenceNumber,
    String? customerName,
  }) async {
    try {
      final payment = await _paymentService.createPayment(
        sessionId: sessionId,
        amount: amount,
        method: method,
        notes: notes,
        referenceNumber: referenceNumber,
        customerName: customerName,
      );

      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return payment;
    } catch (e) {
      throw Exception('Không thể tạo thanh toán: $e');
    }
  }

  // Complete payment
  Future<Payment> completePayment(String paymentId) async {
    try {
      final payment = await _paymentService.completePayment(paymentId);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return payment;
    } catch (e) {
      throw Exception('Không thể hoàn thành thanh toán: $e');
    }
  }

  // Fail payment
  Future<Payment> failPayment(String paymentId, {String? reason}) async {
    try {
      final payment = await _paymentService.failPayment(paymentId, reason: reason);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return payment;
    } catch (e) {
      throw Exception('Không thể đánh dấu thanh toán thất bại: $e');
    }
  }

  // Refund payment
  Future<Payment> refundPayment(String paymentId, {String? reason}) async {
    try {
      final payment = await _paymentService.refundPayment(paymentId, reason: reason);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return payment;
    } catch (e) {
      throw Exception('Không thể hoàn tiền: $e');
    }
  }

  // Process payment and complete session (main payment flow)
  Future<Map<String, dynamic>> processPaymentAndCompleteSession({
    required String sessionId,
    required PaymentMethod method,
    double? paidAmount,
    String? customerName,
    String? notes,
  }) async {
    try {
      final result = await _paymentService.processPaymentAndCompleteSession(
        sessionId: sessionId,
        method: method,
        paidAmount: paidAmount,
        customerName: customerName,
        notes: notes,
      );

      // Invalidate all related providers
      _invalidateProviders();
      _ref.invalidate(allSessionsProvider); // Also invalidate session providers
      
      return result;
    } catch (e) {
      throw Exception('Không thể xử lý thanh toán: $e');
    }
  }

  // Private method to invalidate related providers
  void _invalidateProviders() {
    _ref.invalidate(allPaymentsProvider);
    _ref.invalidate(paymentStatsProvider);
    // Invalidate payments by status for all statuses
    for (final status in PaymentStatus.values) {
      _ref.invalidate(paymentsByStatusProvider(status));
    }
  }
}