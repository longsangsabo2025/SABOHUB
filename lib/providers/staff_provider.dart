import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff.dart';
import '../services/staff_service.dart';

/// Staff Service Provider
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService();
});

/// All Staff Provider
final allStaffProvider =
    FutureProvider.family<List<Staff>, String?>((ref, branchId) async {
  final service = ref.read(staffServiceProvider);
  return service.getAllStaff(branchId: branchId);
});

/// Company Staff Provider - Get all staff in a specific company
final companyStaffProvider =
    FutureProvider.family<List<Staff>, String?>((ref, companyId) async {
  final service = ref.read(staffServiceProvider);
  return service.getAllStaff(companyId: companyId);
});

/// Single Staff Provider
final staffProvider =
    FutureProvider.family<Staff?, String>((ref, staffId) async {
  final service = ref.read(staffServiceProvider);
  return service.getStaffById(staffId);
});

/// Staff By Role Provider
final staffByRoleProvider =
    FutureProvider.family<List<Staff>, ({String role, String? branchId})>(
        (ref, params) async {
  final service = ref.read(staffServiceProvider);
  return service.getStaffByRole(params.role, branchId: params.branchId);
});

/// Staff Statistics Provider
final staffStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, branchId) async {
  final service = ref.read(staffServiceProvider);
  return service.getStaffStats(branchId: branchId);
});

/// Staff Stream Provider (Real-time updates)
final staffStreamProvider =
    StreamProvider.family<List<Staff>, String?>((ref, branchId) {
  final service = ref.read(staffServiceProvider);
  return service.subscribeToStaff(branchId: branchId);
});

/// Selected Staff ID Provider (for detail view)
final selectedStaffIdProvider =
    NotifierProvider<_SelectedStaffIdNotifier, String?>(
        () => _SelectedStaffIdNotifier());

class _SelectedStaffIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    state = id;
  }
}
