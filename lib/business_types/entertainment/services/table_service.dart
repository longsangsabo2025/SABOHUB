import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/table.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users
/// - ❌ KHÔNG ĐƯỢC dùng `_supabase.auth.currentUser`
/// - ✅ Caller PHẢI truyền employeeId từ authProvider

/// Table Service
/// Handles all billiards table-related database operations
/// Uses 'tables' table in Supabase
class TableService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all tables for a company
  Future<List<BilliardsTable>> getAllTables({String? companyId}) async {
    try {
      var query = _supabase.from('tables').select('*');

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('table_number', ascending: true);
      return (response as List).map((json) => _tableFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tables: $e');
    }
  }

  /// Get tables by status
  Future<List<BilliardsTable>> getTablesByStatus(
    TableStatus status, {
    String? companyId,
  }) async {
    try {
      var query = _supabase
          .from('tables')
          .select('*')
          .eq('status', _statusToDbString(status));

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('table_number', ascending: true);
      return (response as List).map((json) => _tableFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tables by status: $e');
    }
  }

  /// Create new table
  /// [employeeId] - ID của employee từ authProvider (KHÔNG phải từ auth.currentUser)
  Future<BilliardsTable> createTable({
    required String tableNumber,
    required String companyId,
    required String tableType,
    required double hourlyRate,
    String? employeeId,
  }) async {
    try {
      final data = {
        'table_number': int.tryParse(tableNumber) ?? tableNumber,
        'company_id': companyId,
        'table_type': tableType,
        'hourly_rate': hourlyRate,
        'status': 'available',
        'created_by': employeeId,
      };

      final response =
          await _supabase.from('tables').insert(data).select().single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to create table: $e');
    }
  }

  /// Update existing table
  Future<BilliardsTable> updateTable({
    required String tableId,
    String? tableNumber,
    String? tableType,
    double? hourlyRate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (tableNumber != null) {
        updates['table_number'] = int.tryParse(tableNumber) ?? tableNumber;
      }
      if (tableType != null) updates['table_type'] = tableType;
      if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;

      final response = await _supabase
          .from('tables')
          .update(updates)
          .eq('id', tableId)
          .select()
          .single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to update table: $e');
    }
  }

  /// Update table status
  Future<BilliardsTable> updateTableStatus(String tableId, TableStatus status) async {
    try {
      final response = await _supabase
          .from('tables')
          .update({
            'status': _statusToDbString(status),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tableId)
          .select()
          .single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to update table status: $e');
    }
  }

  /// Start table session (occupy table)
  /// [employeeId] - ID của employee từ authProvider (KHÔNG phải từ auth.currentUser)
  Future<BilliardsTable> startTableSession({
    required String tableId,
    String? customerName,
    String? notes,
    String? employeeId,
  }) async {
    try {
      final table = await getTableById(tableId);
      final rate = table?.hourlyRate ?? 50000;

      final sessionData = {
        'table_id': tableId,
        'start_time': DateTime.now().toIso8601String(),
        'hourly_rate': rate,
        'status': 'active',
        'customer_name': customerName,
        'notes': notes,
        'created_by': employeeId,
        'total_paused_minutes': 0,
        'table_amount': 0.0,
        'orders_amount': 0.0,
        'total_amount': 0.0,
      };

      final sessionResponse = await _supabase
          .from('table_sessions')
          .insert(sessionData)
          .select()
          .single();

      final response = await _supabase
          .from('tables')
          .update({
            'status': 'occupied',
            'current_session_id': sessionResponse['id'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tableId)
          .select()
          .single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to start table session: $e');
    }
  }

  /// End table session (make table available)
  Future<BilliardsTable> endTableSession(String tableId) async {
    try {
      // First get current session and end it
      final table = await getTableById(tableId);
      if (table?.status != TableStatus.occupied) {
        throw Exception('Table is not currently occupied');
      }

      await _supabase
          .from('table_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('table_id', tableId)
          .eq('status', 'active');

      final response = await _supabase
          .from('tables')
          .update({
            'status': 'available',
            'current_session_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tableId)
          .select()
          .single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to end table session: $e');
    }
  }

  /// Delete table
  Future<void> deleteTable(String tableId) async {
    try {
      await _supabase.from('tables').delete().eq('id', tableId);
    } catch (e) {
      throw Exception('Failed to delete table: $e');
    }
  }

  /// Get table by ID
  Future<BilliardsTable?> getTableById(String tableId) async {
    try {
      final response = await _supabase
          .from('tables')
          .select('*')
          .eq('id', tableId)
          .single();

      return _tableFromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get table statistics
  Future<Map<String, int>> getTableStats({String? companyId}) async {
    try {
      var query = _supabase.from('tables').select('status');

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query;
      final tables = response as List;

      final stats = <String, int>{
        'total': tables.length,
        'available': 0,
        'occupied': 0,
        'reserved': 0,
        'maintenance': 0,
      };

      for (final table in tables) {
        final status = table['status'] as String?;
        switch (status?.toUpperCase()) {
          case 'AVAILABLE':
            stats['available'] = (stats['available'] ?? 0) + 1;
            break;
          case 'OCCUPIED':
            stats['occupied'] = (stats['occupied'] ?? 0) + 1;
            break;
          case 'RESERVED':
            stats['reserved'] = (stats['reserved'] ?? 0) + 1;
            break;
          case 'MAINTENANCE':
            stats['maintenance'] = (stats['maintenance'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch table stats: $e');
    }
  }

  BilliardsTable _tableFromJson(Map<String, dynamic> json) {
    return BilliardsTable(
      id: json['id'] as String,
      tableNumber: json['table_number'].toString(),
      companyId: json['company_id'] as String? ?? '',
      status: _statusFromDbString(json['status'] as String?),
      tableType: json['table_type'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 50000,
      currentSessionId: json['current_session_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  String _statusToDbString(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'available';
      case TableStatus.occupied:
        return 'occupied';
      case TableStatus.reserved:
        return 'reserved';
      case TableStatus.maintenance:
        return 'maintenance';
      case TableStatus.cleaning:
        return 'maintenance';
    }
  }

  TableStatus _statusFromDbString(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'maintenance':
        return TableStatus.maintenance;
      default:
        return TableStatus.available;
    }
  }
}