import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session.dart';

class SessionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all sessions for current company
  Future<List<TableSession>> getAllSessions() async {
    try {
      final response = await _supabase
          .from('table_sessions')
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .eq('billiards_tables.company_id', _supabase.auth.currentUser?.userMetadata?['company_id'])
          .order('start_time', ascending: false);

      return response.map<TableSession>((data) => _mapToTableSession(data)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách phiên chơi: $e');
    }
  }

  // Get sessions by status
  Future<List<TableSession>> getSessionsByStatus(SessionStatus status) async {
    try {
      final response = await _supabase
          .from('table_sessions')
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .eq('billiards_tables.company_id', _supabase.auth.currentUser?.userMetadata?['company_id'])
          .eq('status', status.name)
          .order('start_time', ascending: false);

      return response.map<TableSession>((data) => _mapToTableSession(data)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải phiên chơi theo trạng thái: $e');
    }
  }

  // Get active sessions (for real-time monitoring)
  Future<List<TableSession>> getActiveSessions() async {
    return await getSessionsByStatus(SessionStatus.active);
  }

  // Get session by ID
  Future<TableSession?> getSessionById(String sessionId) async {
    try {
      final response = await _supabase
          .from('table_sessions')
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .eq('id', sessionId)
          .eq('billiards_tables.company_id', _supabase.auth.currentUser?.userMetadata?['company_id'])
          .single();

      return _mapToTableSession(response);
    } catch (e) {
      return null;
    }
  }

  // Start a new session
  Future<TableSession> startSession({
    required String tableId,
    required double hourlyRate,
    String? customerName,
    String? notes,
  }) async {
    try {
      final sessionData = {
        'table_id': tableId,
        'start_time': DateTime.now().toIso8601String(),
        'hourly_rate': hourlyRate,
        'status': SessionStatus.active.name,
        'customer_name': customerName,
        'notes': notes,
        'total_paused_minutes': 0,
        'table_amount': 0.0,
        'orders_amount': 0.0,
        'total_amount': 0.0,
      };

      final response = await _supabase
          .from('table_sessions')
          .insert(sessionData)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      // Update table status to occupied
      await _supabase
          .from('billiards_tables')
          .update({'status': 'occupied'})
          .eq('id', tableId);

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi bắt đầu phiên chơi: $e');
    }
  }

  // Pause session
  Future<TableSession> pauseSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('table_sessions')
          .update({
            'status': SessionStatus.paused.name,
            'pause_time': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi tạm dừng phiên chơi: $e');
    }
  }

  // Resume session
  Future<TableSession> resumeSession(String sessionId) async {
    try {
      // Get current session to calculate paused time
      final currentSession = await getSessionById(sessionId);
      if (currentSession == null || currentSession.pauseTime == null) {
        throw Exception('Không tìm thấy phiên chơi hoặc phiên chơi không trong trạng thái tạm dừng');
      }

      final pauseDuration = DateTime.now().difference(currentSession.pauseTime!);
      final newTotalPausedMinutes = currentSession.totalPausedMinutes + pauseDuration.inMinutes;

      final response = await _supabase
          .from('table_sessions')
          .update({
            'status': SessionStatus.active.name,
            'pause_time': null,
            'total_paused_minutes': newTotalPausedMinutes,
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi tiếp tục phiên chơi: $e');
    }
  }

  // End session
  Future<TableSession> endSession(String sessionId) async {
    try {
      final session = await getSessionById(sessionId);
      if (session == null) {
        throw Exception('Không tìm thấy phiên chơi');
      }

      // Calculate final amounts
      final tableAmount = session.calculateTableAmount();
      final totalAmount = tableAmount + session.ordersAmount;

      final response = await _supabase
          .from('table_sessions')
          .update({
            'status': SessionStatus.completed.name,
            'end_time': DateTime.now().toIso8601String(),
            'table_amount': tableAmount,
            'total_amount': totalAmount,
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      // Update table status to available
      await _supabase
          .from('billiards_tables')
          .update({'status': 'available'})
          .eq('id', session.tableId);

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi kết thúc phiên chơi: $e');
    }
  }

  // Cancel session
  Future<TableSession> cancelSession(String sessionId) async {
    try {
      final session = await getSessionById(sessionId);
      if (session == null) {
        throw Exception('Không tìm thấy phiên chơi');
      }

      final response = await _supabase
          .from('table_sessions')
          .update({
            'status': SessionStatus.cancelled.name,
            'end_time': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      // Update table status to available
      await _supabase
          .from('billiards_tables')
          .update({'status': 'available'})
          .eq('id', session.tableId);

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi hủy phiên chơi: $e');
    }
  }

  // Update session details (customer name, notes)
  Future<TableSession> updateSession({
    required String sessionId,
    String? customerName,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('table_sessions')
          .update({
            if (customerName != null) 'customer_name': customerName,
            if (notes != null) 'notes': notes,
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật phiên chơi: $e');
    }
  }

  // Add order to session (called from OrderService)
  Future<TableSession> addOrderToSession(String sessionId, String orderId, double orderAmount) async {
    try {
      final session = await getSessionById(sessionId);
      if (session == null) {
        throw Exception('Không tìm thấy phiên chơi');
      }

      final updatedOrderIds = [...session.orderIds, orderId];
      final newOrdersAmount = session.ordersAmount + orderAmount;
      final newTotalAmount = session.tableAmount + newOrdersAmount;

      final response = await _supabase
          .from('table_sessions')
          .update({
            'order_ids': updatedOrderIds,
            'orders_amount': newOrdersAmount,
            'total_amount': newTotalAmount,
          })
          .eq('id', sessionId)
          .select('''
            *,
            billiards_tables!inner(
              name,
              company_id
            )
          ''')
          .single();

      return _mapToTableSession(response);
    } catch (e) {
      throw Exception('Lỗi khi thêm đơn hàng vào phiên chơi: $e');
    }
  }

  // Get sessions summary/statistics
  Future<Map<String, dynamic>> getSessionsStats() async {
    try {
      // Get all sessions for current company
      final sessions = await getAllSessions();
      
      final activeSessions = sessions.where((s) => s.status == SessionStatus.active).length;
      final pausedSessions = sessions.where((s) => s.status == SessionStatus.paused).length;
      final completedToday = sessions.where((s) => 
        s.status == SessionStatus.completed &&
        s.endTime != null &&
        s.endTime!.day == DateTime.now().day
      ).length;
      
      final todayRevenue = sessions.where((s) => 
        s.status == SessionStatus.completed &&
        s.endTime != null &&
        s.endTime!.day == DateTime.now().day
      ).fold(0.0, (sum, session) => sum + session.totalAmount);

      return {
        'activeSessions': activeSessions,
        'pausedSessions': pausedSessions,
        'completedToday': completedToday,
        'todayRevenue': todayRevenue,
      };
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê phiên chơi: $e');
    }
  }

  // Private helper method to map database response to TableSession
  TableSession _mapToTableSession(Map<String, dynamic> data) {
    return TableSession(
      id: data['id'] ?? '',
      tableId: data['table_id'] ?? '',
      tableName: data['billiards_tables']?['name'] ?? 'Không rõ',
      companyId: data['billiards_tables']?['company_id'] ?? '',
      startTime: DateTime.parse(data['start_time']),
      endTime: data['end_time'] != null ? DateTime.parse(data['end_time']) : null,
      pauseTime: data['pause_time'] != null ? DateTime.parse(data['pause_time']) : null,
      totalPausedMinutes: data['total_paused_minutes'] ?? 0,
      hourlyRate: (data['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      tableAmount: (data['table_amount'] as num?)?.toDouble() ?? 0.0,
      ordersAmount: (data['orders_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: SessionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SessionStatus.active,
      ),
      customerName: data['customer_name'],
      notes: data['notes'],
      orderIds: data['order_ids'] != null 
          ? List<String>.from(data['order_ids']) 
          : [],
    );
  }
}