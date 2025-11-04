import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store.dart';
import '../services/store_service.dart';

/// Store Service Provider
final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

/// All Stores Provider
/// Fetches and caches all stores from Supabase
final storesProvider = FutureProvider<List<Store>>((ref) async {
  final service = ref.watch(storeServiceProvider);
  return await service.getAllStores();
});

/// Single Store Provider
/// Gets a specific store by ID
final storeProvider = FutureProvider.family<Store?, String>((ref, id) async {
  final service = ref.watch(storeServiceProvider);
  return await service.getStoreById(id);
});

/// Store Stats Provider
/// Fetches store statistics
final storeStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  final service = ref.watch(storeServiceProvider);
  return await service.getStoreStats(storeId);
});

/// Stores Stream Provider
/// Real-time stream of stores
final storesStreamProvider = StreamProvider<List<Store>>((ref) {
  final service = ref.watch(storeServiceProvider);
  return service.subscribeToStores();
});

/// Current User's Store Provider
/// Gets the store for the currently logged-in user
final currentUserStoreProvider = Provider<AsyncValue<Store?>>((ref) {
  // This would typically get the current user's store
  // Implementation depends on authentication logic
  return const AsyncValue.loading();
});

/// Selected Store Provider (for multi-store scenarios)
/// Use ref.read(selectedStoreProvider.notifier).state = value to update
final selectedStoreProvider = Provider<String?>((ref) => null);
