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
        query = query.eq('store_id', companyId); // Using store_id as company_id
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
        query = query.eq('store_id', companyId);
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
        'table_number': int.parse(tableNumber),
        'store_id': companyId,
        'table_type': tableType,
        'hourly_rate': hourlyRate,
        'status': 'AVAILABLE',
        'created_by': employeeId,
      };

      final response =
          await _supabase.from('tables').insert(data).select().single();

      return _tableFromJson(response);
    } catch (e) {
      throw Exception('Failed to create table: $e');
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
      // First create table session
      final sessionData = {
        'table_id': tableId,
        'start_time': DateTime.now().toIso8601String(),
        'hourly_rate': 50000, // Default rate, should get from table
        'status': 'ACTIVE',
        'created_by': employeeId,
      };

      final sessionResponse = await _supabase
          .from('table_sessions')
          .insert(sessionData)
          .select()
          .single();

      // Then update table status to occupied
      final response = await _supabase
          .from('tables')
          .update({
            'status': 'OCCUPIED',
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

      // Update current session to completed
      await _supabase
          .from('table_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'status': 'COMPLETED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('table_id', tableId)
          .eq('status', 'ACTIVE');

      // Then update table status to available
      final response = await _supabase
          .from('tables')
          .update({
            'status': 'AVAILABLE',
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
        query = query.eq('store_id', companyId);
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

  /// Convert JSON to BilliardsTable model
  BilliardsTable _tableFromJson(Map<String, dynamic> json) {
    return BilliardsTable(
      id: json['id'] as String,
      tableNumber: json['table_number'].toString(),
      companyId: json['store_id'] as String? ?? '',
      status: _statusFromDbString(json['status'] as String?),
      startTime: null, // Will be calculated from active session if needed
      currentAmount: null, // Will be calculated from session if needed
      customerName: null, // Will come from session data if needed
      notes: null, // Additional notes if added to schema
    );
  }

  /// Convert TableStatus to database string
  String _statusToDbString(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'AVAILABLE';
      case TableStatus.occupied:
        return 'OCCUPIED';
      case TableStatus.reserved:
        return 'RESERVED';
      case TableStatus.maintenance:
        return 'MAINTENANCE';
      case TableStatus.cleaning:
        return 'MAINTENANCE'; // Map cleaning to maintenance
    }
  }

  /// Convert database string to TableStatus
  TableStatus _statusFromDbString(String? status) {
    switch (status?.toUpperCase()) {
      case 'AVAILABLE':
        return TableStatus.available;
      case 'OCCUPIED':
        return TableStatus.occupied;
      case 'RESERVED':
        return TableStatus.reserved;
      case 'MAINTENANCE':
        return TableStatus.maintenance;
      default:
        return TableStatus.available;
    }
  }
}