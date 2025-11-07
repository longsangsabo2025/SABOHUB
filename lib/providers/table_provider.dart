import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/table.dart';
import '../services/table_service.dart';
import 'auth_provider.dart';

/// Table Service Provider
final tableServiceProvider = Provider<TableService>((ref) {
  return TableService();
});

/// All Tables Provider
/// Fetches tables for current company
final tablesProvider = FutureProvider<List<BilliardsTable>>((ref) async {
  final service = ref.watch(tableServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getAllTables(companyId: authState.user!.companyId!);
});

/// Tables by Status Provider
/// Gets tables filtered by status
final tablesByStatusProvider = 
    FutureProvider.family<List<BilliardsTable>, TableStatus>((ref, status) async {
  final service = ref.watch(tableServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return [];
  
  return await service.getTablesByStatus(status, companyId: authState.user!.companyId!);
});

/// Single Table Provider
/// Gets table details by ID
final tableProvider = FutureProvider.family<BilliardsTable?, String>((ref, tableId) async {
  final service = ref.watch(tableServiceProvider);
  return await service.getTableById(tableId);
});

/// Table Statistics Provider
/// Gets table stats (available, occupied, etc.)
final tableStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(tableServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) return {};
  
  return await service.getTableStats(companyId: authState.user!.companyId!);
});

/// Tables Stream Provider
/// Real-time tables stream (simulated with periodic refresh)
final tablesStreamProvider = StreamProvider<List<BilliardsTable>>((ref) {
  final service = ref.watch(tableServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user?.companyId == null) {
    return Stream.value([]);
  }
  
  // Periodic refresh for real-time updates (table status changes frequently)
  return Stream.periodic(const Duration(seconds: 15), (_) async {
    return await service.getAllTables(companyId: authState.user!.companyId!);
  }).asyncMap((future) => future);
});

/// Table Actions Provider
/// Provides table CRUD and session operations
final tableActionsProvider = Provider<TableActions>((ref) {
  return TableActions(ref);
});

class TableActions {
  final Ref ref;
  
  TableActions(this.ref);
  
  /// Create new table
  Future<BilliardsTable> createTable({
    required String tableNumber,
    required String tableType,
    required double hourlyRate,
  }) async {
    final service = ref.read(tableServiceProvider);
    final authState = ref.read(authProvider);
    
    if (authState.user?.companyId == null) {
      throw Exception('Company ID not found');
    }
    
    final table = await service.createTable(
      tableNumber: tableNumber,
      companyId: authState.user!.companyId!,
      tableType: tableType,
      hourlyRate: hourlyRate,
    );
    
    // Refresh tables
    ref.invalidate(tablesProvider);
    ref.invalidate(tablesByStatusProvider);
    ref.invalidate(tableStatsProvider);
    
    return table;
  }
  
  /// Update table status
  Future<BilliardsTable> updateTableStatus(String tableId, TableStatus status) async {
    final service = ref.read(tableServiceProvider);
    
    final table = await service.updateTableStatus(tableId, status);
    
    // Refresh tables
    ref.invalidate(tablesProvider);
    ref.invalidate(tablesByStatusProvider);
    ref.invalidate(tableProvider(tableId));
    ref.invalidate(tableStatsProvider);
    
    return table;
  }
  
  /// Start table session (customer starts playing)
  Future<BilliardsTable> startTableSession({
    required String tableId,
    String? customerName,
    String? notes,
  }) async {
    final service = ref.read(tableServiceProvider);
    
    final table = await service.startTableSession(
      tableId: tableId,
      customerName: customerName,
      notes: notes,
    );
    
    // Refresh tables
    ref.invalidate(tablesProvider);
    ref.invalidate(tablesByStatusProvider);
    ref.invalidate(tableProvider(tableId));
    ref.invalidate(tableStatsProvider);
    
    return table;
  }
  
  /// End table session (customer finishes playing)
  Future<BilliardsTable> endTableSession(String tableId) async {
    final service = ref.read(tableServiceProvider);
    
    final table = await service.endTableSession(tableId);
    
    // Refresh tables
    ref.invalidate(tablesProvider);
    ref.invalidate(tablesByStatusProvider);
    ref.invalidate(tableProvider(tableId));
    ref.invalidate(tableStatsProvider);
    
    return table;
  }
  
  /// Delete table
  Future<void> deleteTable(String tableId) async {
    final service = ref.read(tableServiceProvider);
    
    await service.deleteTable(tableId);
    
    // Refresh tables
    ref.invalidate(tablesProvider);
    ref.invalidate(tablesByStatusProvider);
    ref.invalidate(tableProvider(tableId));
    ref.invalidate(tableStatsProvider);
  }
}