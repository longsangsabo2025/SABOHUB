import '../services/base_service.dart';

/// Base repository providing common Supabase CRUD operations.
/// All repositories should extend this class to ensure consistent
/// error handling via [safeCall] and a single point of Supabase access.
abstract class BaseRepository extends BaseService {
  /// The Supabase table name this repository manages
  String get tableName;

  /// Fetch all records, optionally filtered
  Future<List<Map<String, dynamic>>> fetchAll({
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    return safeCall(
      operation: 'fetchAll',
      action: () async {
        var query = client.from(tableName).select(select ?? '*');

        if (filters != null) {
          for (final entry in filters.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }

        final result =
            query.order(orderBy ?? 'created_at', ascending: ascending);

        if (limit != null) {
          return await result.limit(limit);
        }
        return await result;
      },
    );
  }

  /// Fetch a single record by ID
  Future<Map<String, dynamic>?> fetchById(String id,
      {String? select}) async {
    return safeCall(
      operation: 'fetchById',
      action: () async {
        final result = await client
            .from(tableName)
            .select(select ?? '*')
            .eq('id', id)
            .maybeSingle();
        return result;
      },
    );
  }

  /// Insert a new record
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    return safeCall(
      operation: 'insert',
      action: () async {
        final result =
            await client.from(tableName).insert(data).select().single();
        return result;
      },
    );
  }

  /// Update a record by ID
  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    return safeCall(
      operation: 'update',
      action: () async {
        final result = await client
            .from(tableName)
            .update(data)
            .eq('id', id)
            .select()
            .single();
        return result;
      },
    );
  }

  /// Soft delete a record by ID (sets is_deleted = true)
  Future<void> softDelete(String id) async {
    return safeCall(
      operation: 'softDelete',
      action: () async {
        await client.from(tableName).update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      },
    );
  }

  /// Hard delete a record by ID
  Future<void> hardDelete(String id) async {
    return safeCall(
      operation: 'hardDelete',
      action: () async {
        await client.from(tableName).delete().eq('id', id);
      },
    );
  }

  /// Count records with optional filters
  Future<int> count({Map<String, dynamic>? filters}) async {
    return safeCall(
      operation: 'count',
      action: () async {
        var query = client.from(tableName).select('id');
        if (filters != null) {
          for (final entry in filters.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }
        final result = await query;
        return (result as List).length;
      },
    );
  }

  /// Subscribe to realtime changes
  Stream<List<Map<String, dynamic>>> subscribe({
    Map<String, dynamic>? filters,
  }) {
    var stream = client.from(tableName).stream(primaryKey: ['id']);
    // Note: Supabase stream doesn't support complex filters directly
    // Filter in the stream transformer if needed
    return stream;
  }
}
