import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import '../services/branch_service.dart';

/// Branch Service Provider
final branchServiceProvider = Provider<BranchService>((ref) {
  return BranchService();
});

/// All Branches Provider
/// Fetches and caches all branches from Supabase
final branchesProvider =
    FutureProvider.autoDispose.family<List<Branch>, String?>((ref, companyId) async {
  final service = ref.watch(branchServiceProvider);
  return await service.getAllBranches(companyId: companyId);
});

/// Active Branches Provider
/// Fetches only active branches
final activeBranchesProvider =
    FutureProvider.autoDispose.family<List<Branch>, String?>((ref, companyId) async {
  final service = ref.watch(branchServiceProvider);
  return await service.getActiveBranches(companyId: companyId);
});

/// Single Branch Provider
/// Gets a specific branch by ID
final branchProvider = FutureProvider.autoDispose.family<Branch?, String>((ref, id) async {
  final service = ref.watch(branchServiceProvider);
  return await service.getBranchById(id);
});

/// Branch Stats Provider
/// Fetches branch statistics
final branchStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, branchId) async {
  final service = ref.watch(branchServiceProvider);
  return await service.getBranchStats(branchId);
});

/// Branches Stream Provider
/// Real-time stream of branches
final branchesStreamProvider =
    StreamProvider.autoDispose.family<List<Branch>, String?>((ref, companyId) {
  final service = ref.watch(branchServiceProvider);
  return service.subscribeToBranches(companyId: companyId);
});

/// Current User's Branch Provider
/// Gets the branch for the currently logged-in user
final currentUserBranchProvider = Provider<AsyncValue<Branch?>>((ref) {
  // This would typically get the current user's branch
  // Implementation depends on authentication logic
  return const AsyncValue.loading();
});

/// Selected Branch Provider (for multi-branch scenarios)
/// Use ref.read(selectedBranchProvider.notifier).state = value to update
final selectedBranchProvider = Provider<String?>((ref) => null);
