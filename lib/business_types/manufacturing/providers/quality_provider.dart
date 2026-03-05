// Quality Control Providers - Riverpod 3
// Date: 2026-03-04

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';
import '../models/quality_inspection.dart';
import '../services/quality_service.dart';

// ===== QUALITY SERVICE PROVIDER =====
final qualityServiceProvider = Provider<QualityService>((ref) {
  final user = ref.watch(currentUserProvider);
  return QualityService(
    companyId: user?.companyId,
    employeeId: user?.id,
  );
});

// ===== INSPECTION LIST =====
class QualityInspectionListNotifier
    extends AsyncNotifier<List<QualityInspection>> {
  @override
  FutureOr<List<QualityInspection>> build() async {
    final service = ref.read(qualityServiceProvider);
    try {
      return await service.getInspections();
    } catch (e) {
      AppLogger.error('QC Provider: Failed to load inspections', e);
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(qualityServiceProvider);
      return service.getInspections();
    });
  }

  Future<void> addInspection(QualityInspection inspection) async {
    final service = ref.read(qualityServiceProvider);
    try {
      await service.createInspection(inspection);
      await refresh();
    } catch (e) {
      AppLogger.error('QC Provider: Failed to add inspection', e);
      rethrow;
    }
  }

  Future<void> updateInspection(
      String id, QualityInspection inspection) async {
    final service = ref.read(qualityServiceProvider);
    try {
      await service.updateInspection(id, inspection);
      await refresh();
    } catch (e) {
      AppLogger.error('QC Provider: Failed to update inspection', e);
      rethrow;
    }
  }

  Future<void> deleteInspection(String id) async {
    final service = ref.read(qualityServiceProvider);
    try {
      await service.deleteInspection(id);
      await refresh();
    } catch (e) {
      AppLogger.error('QC Provider: Failed to delete inspection', e);
      rethrow;
    }
  }
}

final qualityInspectionListProvider = AsyncNotifierProvider<
    QualityInspectionListNotifier, List<QualityInspection>>(
  () => QualityInspectionListNotifier(),
);

// ===== QUALITY STATS =====
class QualityStatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    final service = ref.read(qualityServiceProvider);
    try {
      return await service.getStats();
    } catch (e) {
      AppLogger.error('QC Provider: Failed to load stats', e);
      return {
        'total': 0,
        'pending': 0,
        'passed': 0,
        'failed': 0,
        'conditional': 0,
        'passRate': 0.0,
        'defectBreakdown': <String, int>{},
      };
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(qualityServiceProvider);
      return service.getStats();
    });
  }
}

final qualityStatsProvider =
    AsyncNotifierProvider<QualityStatsNotifier, Map<String, dynamic>>(
  () => QualityStatsNotifier(),
);

// ===== INSPECTION BY ORDER =====
final inspectionByOrderProvider = FutureProvider.family<
    List<QualityInspection>, String>((ref, orderId) async {
  final service = ref.read(qualityServiceProvider);
  try {
    return await service.getByProductionOrder(orderId);
  } catch (e) {
    AppLogger.error('QC Provider: Failed to load inspections for order $orderId', e);
    return [];
  }
});
