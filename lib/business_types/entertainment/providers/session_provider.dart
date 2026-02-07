import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/session_service.dart';
import '../../../providers/auth_provider.dart';

// Session service provider
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

// All sessions provider
final allSessionsProvider = FutureProvider<List<TableSession>>((ref) async {
  final sessionService = ref.read(sessionServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await sessionService.getAllSessions();
});

// Sessions by status provider (family)
final sessionsByStatusProvider = FutureProvider.family<List<TableSession>, SessionStatus>((ref, status) async {
  final sessionService = ref.read(sessionServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await sessionService.getSessionsByStatus(status);
});

// Active sessions provider (for real-time monitoring)
final activeSessionsProvider = FutureProvider<List<TableSession>>((ref) async {
  final sessionService = ref.read(sessionServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return [];
  }
  
  return await sessionService.getActiveSessions();
});

// Session stats provider
final sessionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sessionService = ref.read(sessionServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return {
      'activeSessions': 0,
      'pausedSessions': 0,
      'completedToday': 0,
      'todayRevenue': 0.0,
    };
  }
  
  return await sessionService.getSessionsStats();
});

// Individual session provider (family)
final sessionProvider = FutureProvider.family<TableSession?, String>((ref, sessionId) async {
  final sessionService = ref.read(sessionServiceProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    return null;
  }
  
  return await sessionService.getSessionById(sessionId);
});

// Session actions provider
final sessionActionsProvider = Provider<SessionActions>((ref) {
  return SessionActions(ref);
});

class SessionActions {
  final Ref _ref;
  SessionActions(this._ref);

  SessionService get _sessionService => _ref.read(sessionServiceProvider);

  // Start a new session
  Future<TableSession> startSession({
    required String tableId,
    required double hourlyRate,
    String? customerName,
    String? notes,
  }) async {
    try {
      final session = await _sessionService.startSession(
        tableId: tableId,
        hourlyRate: hourlyRate,
        customerName: customerName,
        notes: notes,
      );

      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể bắt đầu phiên chơi: $e');
    }
  }

  // Pause session
  Future<TableSession> pauseSession(String sessionId) async {
    try {
      final session = await _sessionService.pauseSession(sessionId);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể tạm dừng phiên chơi: $e');
    }
  }

  // Resume session
  Future<TableSession> resumeSession(String sessionId) async {
    try {
      final session = await _sessionService.resumeSession(sessionId);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể tiếp tục phiên chơi: $e');
    }
  }

  // End session
  Future<TableSession> endSession(String sessionId) async {
    try {
      final session = await _sessionService.endSession(sessionId);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể kết thúc phiên chơi: $e');
    }
  }

  // Cancel session
  Future<TableSession> cancelSession(String sessionId) async {
    try {
      final session = await _sessionService.cancelSession(sessionId);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể hủy phiên chơi: $e');
    }
  }

  // Update session details
  Future<TableSession> updateSession({
    required String sessionId,
    String? customerName,
    String? notes,
  }) async {
    try {
      final session = await _sessionService.updateSession(
        sessionId: sessionId,
        customerName: customerName,
        notes: notes,
      );
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể cập nhật phiên chơi: $e');
    }
  }

  // Add order to session
  Future<TableSession> addOrderToSession(String sessionId, String orderId, double orderAmount) async {
    try {
      final session = await _sessionService.addOrderToSession(sessionId, orderId, orderAmount);
      
      // Invalidate providers to refresh data
      _invalidateProviders();
      
      return session;
    } catch (e) {
      throw Exception('Không thể thêm đơn hàng vào phiên chơi: $e');
    }
  }

  // Private method to invalidate related providers
  void _invalidateProviders() {
    _ref.invalidate(allSessionsProvider);
    _ref.invalidate(activeSessionsProvider);
    _ref.invalidate(sessionStatsProvider);
    // Invalidate sessions by status for all statuses
    for (final status in SessionStatus.values) {
      _ref.invalidate(sessionsByStatusProvider(status));
    }
  }
}