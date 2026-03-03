// Offline Data Sync Service
// Provides local caching and sync queue for offline support

import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/odori_models.dart';

/// Sync Operation Types
enum SyncOperation {
  create,
  update,
  delete,
}

/// Sync Status
enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
}

/// Pending Sync Item
class PendingSyncItem {
  final int? id;
  final String tableName;
  final String recordId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final String? errorMessage;

  const PendingSyncItem({
    this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'table_name': tableName,
    'record_id': recordId,
    'operation': operation.name,
    'data': jsonEncode(data),
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'retry_count': retryCount,
    'error_message': errorMessage,
  };

  factory PendingSyncItem.fromMap(Map<String, dynamic> map) {
    return PendingSyncItem(
      id: map['id'] as int?,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as String,
      operation: SyncOperation.values.byName(map['operation'] as String),
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: SyncStatus.values.byName(map['status'] as String),
      retryCount: map['retry_count'] as int,
      errorMessage: map['error_message'] as String?,
    );
  }
}

/// Offline Sync Service
class OfflineSyncService {
  static const String _dbName = 'odori_offline.db';
  static const int _dbVersion = 1;
  static const int _maxRetries = 3;

  Database? _database;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  // Callbacks
  Function(bool isOnline)? onConnectivityChange;
  Function(int pendingCount)? onPendingCountChange;
  Function(String message)? onSyncProgress;
  Function(String error)? onSyncError;

  /// Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT
      )
    ''');

    // Cached customers
    await db.execute('''
      CREATE TABLE cached_customers (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cached products
    await db.execute('''
      CREATE TABLE cached_products (
        id TEXT PRIMARY KEY,
        barcode TEXT,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cached orders
    await db.execute('''
      CREATE TABLE cached_orders (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cached deliveries
    await db.execute('''
      CREATE TABLE cached_deliveries (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_sync_status ON sync_queue(status)');
    await db.execute('CREATE INDEX idx_product_barcode ON cached_products(barcode)');
  }

  /// Initialize and start listening for connectivity
  Future<void> initialize() async {
    await database;
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      onConnectivityChange?.call(isOnline);
      
      if (isOnline) {
        syncPendingItems();
      }
    });
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ==================== SYNC QUEUE ====================

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    
    final item = PendingSyncItem(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    await db.insert('sync_queue', item.toMap());
    
    final count = await getPendingCount();
    onPendingCountChange?.call(count);
  }

  /// Get pending items count
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending' OR status = 'failed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get all pending items
  Future<List<PendingSyncItem>> getPendingItems() async {
    final db = await database;
    final results = await db.query(
      'sync_queue',
      where: "status = ? OR status = ?",
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
    return results.map((map) => PendingSyncItem.fromMap(map)).toList();
  }

  /// Sync all pending items
  Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    
    final online = await isOnline();
    if (!online) return;

    _isSyncing = true;
    onSyncProgress?.call('Đang đồng bộ dữ liệu...');

    try {
      final items = await getPendingItems();
      
      for (final item in items) {
        if (item.retryCount >= _maxRetries) continue;

        try {
          await _syncItem(item);
          await _updateSyncStatus(item.id!, SyncStatus.completed);
          onSyncProgress?.call('Đã đồng bộ: ${item.tableName}');
        } catch (e) {
          await _updateSyncStatus(
            item.id!,
            SyncStatus.failed,
            errorMessage: e.toString(),
            incrementRetry: true,
          );
          onSyncError?.call('Lỗi đồng bộ ${item.tableName}: $e');
        }
      }

      // Clean up completed items
      await _cleanupCompletedItems();
      
      final count = await getPendingCount();
      onPendingCountChange?.call(count);
      onSyncProgress?.call('Đồng bộ hoàn tất');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(PendingSyncItem item) async {
    switch (item.tableName) {
      case 'customers':
        await _syncCustomer(item);
        break;
      case 'products':
        await _syncProduct(item);
        break;
      case 'orders':
        await _syncOrder(item);
        break;
      case 'deliveries':
        await _syncDelivery(item);
        break;
      case 'payments':
        await _syncPayment(item);
        break;
      default:
        throw Exception('Unknown table: ${item.tableName}');
    }
  }

  Future<void> _syncCustomer(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _supabase.from('customers').insert(item.data);
        break;
      case SyncOperation.update:
        await _supabase.from('customers').update(item.data).eq('id', item.recordId);
        break;
      case SyncOperation.delete:
        await _supabase.from('customers').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', item.recordId);
        break;
    }
  }

  Future<void> _syncProduct(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _supabase.from('products').insert(item.data);
        break;
      case SyncOperation.update:
        await _supabase.from('products').update(item.data).eq('id', item.recordId);
        break;
      case SyncOperation.delete:
        await _supabase.from('products').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', item.recordId);
        break;
    }
  }

  Future<void> _syncOrder(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _supabase.from('sales_orders').insert(item.data);
        break;
      case SyncOperation.update:
        await _supabase.from('sales_orders').update(item.data).eq('id', item.recordId);
        break;
      case SyncOperation.delete:
        await _supabase.from('sales_orders').update({'status': 'cancelled'}).eq('id', item.recordId);
        break;
    }
  }

  Future<void> _syncDelivery(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _supabase.from('deliveries').insert(item.data);
        break;
      case SyncOperation.update:
        await _supabase.from('deliveries').update(item.data).eq('id', item.recordId);
        break;
      case SyncOperation.delete:
        await _supabase.from('deliveries').update({'status': 'cancelled'}).eq('id', item.recordId);
        break;
    }
  }

  Future<void> _syncPayment(PendingSyncItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        await _supabase.from('payments').insert(item.data);
        break;
      case SyncOperation.update:
        await _supabase.from('payments').update(item.data).eq('id', item.recordId);
        break;
      case SyncOperation.delete:
        await _supabase.from('payments').delete().eq('id', item.recordId);
        break;
    }
  }

  Future<void> _updateSyncStatus(
    int id,
    SyncStatus status, {
    String? errorMessage,
    bool incrementRetry = false,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (errorMessage != null) {
      updates['error_message'] = errorMessage;
    }
    if (incrementRetry) {
      await db.rawUpdate(
        'UPDATE sync_queue SET status = ?, error_message = ?, retry_count = retry_count + 1 WHERE id = ?',
        [status.name, errorMessage, id],
      );
    } else {
      await db.update('sync_queue', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> _cleanupCompletedItems() async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: "status = ?",
      whereArgs: ['completed'],
    );
  }

  // ==================== CACHE OPERATIONS ====================

  /// Cache customers
  Future<void> cacheCustomers(List<OdoriCustomer> customers) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final customer in customers) {
      batch.insert(
        'cached_customers',
        {
          'id': customer.id,
          'data': jsonEncode(customer.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached customers
  Future<List<OdoriCustomer>> getCachedCustomers() async {
    final db = await database;
    final results = await db.query('cached_customers');
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return OdoriCustomer.fromJson(data);
    }).toList();
  }

  /// Cache products
  Future<void> cacheProducts(List<OdoriProduct> products) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final product in products) {
      batch.insert(
        'cached_products',
        {
          'id': product.id,
          'barcode': product.barcode,
          'data': jsonEncode(product.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached products
  Future<List<OdoriProduct>> getCachedProducts() async {
    final db = await database;
    final results = await db.query('cached_products');
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return OdoriProduct.fromJson(data);
    }).toList();
  }

  /// Get cached product by barcode
  Future<OdoriProduct?> getCachedProductByBarcode(String barcode) async {
    final db = await database;
    final results = await db.query(
      'cached_products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final data = jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
    return OdoriProduct.fromJson(data);
  }

  /// Cache orders
  Future<void> cacheOrders(List<OdoriSalesOrder> orders) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final order in orders) {
      batch.insert(
        'cached_orders',
        {
          'id': order.id,
          'data': jsonEncode(order.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached orders
  Future<List<OdoriSalesOrder>> getCachedOrders() async {
    final db = await database;
    final results = await db.query('cached_orders');
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return OdoriSalesOrder.fromJson(data);
    }).toList();
  }

  /// Cache deliveries
  Future<void> cacheDeliveries(List<OdoriDelivery> deliveries) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final delivery in deliveries) {
      batch.insert(
        'cached_deliveries',
        {
          'id': delivery.id,
          'data': jsonEncode(delivery.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached deliveries
  Future<List<OdoriDelivery>> getCachedDeliveries() async {
    final db = await database;
    final results = await db.query('cached_deliveries');
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return OdoriDelivery.fromJson(data);
    }).toList();
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('cached_customers');
    await db.delete('cached_products');
    await db.delete('cached_orders');
    await db.delete('cached_deliveries');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _database?.close();
  }
}

// Singleton instance
final offlineSyncService = OfflineSyncService();
