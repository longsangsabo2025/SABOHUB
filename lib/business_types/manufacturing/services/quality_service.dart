// Quality Control Service - In-memory + Supabase graceful fallback
// Date: 2026-03-04

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/app_logger.dart';
import '../models/quality_inspection.dart';
import '../models/manufacturing_models.dart';

/// ⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️
/// Employee KHÔNG có tài khoản auth Supabase!
/// Caller PHẢI truyền employeeId và companyId từ authProvider.

class QualityService {
  final SupabaseClient _client = Supabase.instance.client;
  final String? companyId;
  final String? employeeId;

  // In-memory storage (fallback khi Supabase table chưa tồn tại)
  static final List<QualityInspection> _localStore = [];
  static bool _supabaseAvailable = true;

  QualityService({this.companyId, this.employeeId});

  String _getCompanyId(String? overrideCompanyId) {
    final cid = overrideCompanyId ?? companyId;
    if (cid == null) throw Exception('Company ID is required');
    return cid;
  }

  // ===== CRUD =====

  /// Lấy tất cả inspections cho company
  Future<List<QualityInspection>> getInspections({
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);

    // Thử Supabase trước
    if (_supabaseAvailable) {
      try {
        final response = await _client
            .from('quality_inspections')
            .select()
            .eq('company_id', cid)
            .order('created_at', ascending: false);
        final list = (response as List)
            .map((json) => QualityInspection.fromJson(json))
            .toList();
        AppLogger.data('QC: Loaded ${list.length} inspections from Supabase');
        return list;
      } catch (e) {
        AppLogger.warn(
            'QC: Supabase quality_inspections not available, using local store',
            e);
        _supabaseAvailable = false;
      }
    }

    // Fallback: in-memory
    return _localStore
        .where((i) => i.companyId == cid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Lấy inspections theo production order
  Future<List<QualityInspection>> getByProductionOrder(
    String productionOrderId, {
    String? overrideCompanyId,
  }) async {
    final all = await getInspections(overrideCompanyId: overrideCompanyId);
    return all
        .where((i) => i.productionOrderId == productionOrderId)
        .toList();
  }

  /// Tạo inspection mới
  Future<QualityInspection> createInspection(
    QualityInspection inspection, {
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    final record = inspection.copyWith(companyId: cid);

    if (_supabaseAvailable) {
      try {
        final response = await _client
            .from('quality_inspections')
            .insert(record.toJson())
            .select()
            .single();
        final created = QualityInspection.fromJson(response);
        AppLogger.data('QC: Created inspection ${created.id} in Supabase');
        return created;
      } catch (e) {
        AppLogger.warn('QC: Supabase insert failed, saving locally', e);
        _supabaseAvailable = false;
      }
    }

    // Fallback: local
    _localStore.add(record);
    AppLogger.data('QC: Created inspection ${record.id} locally');
    return record;
  }

  /// Cập nhật inspection
  Future<QualityInspection> updateInspection(
    String id,
    QualityInspection inspection,
  ) async {
    final updated = inspection.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );

    if (_supabaseAvailable) {
      try {
        final response = await _client
            .from('quality_inspections')
            .update(updated.toJson())
            .eq('id', id)
            .select()
            .single();
        final result = QualityInspection.fromJson(response);
        AppLogger.data('QC: Updated inspection $id in Supabase');
        return result;
      } catch (e) {
        AppLogger.warn('QC: Supabase update failed, updating locally', e);
        _supabaseAvailable = false;
      }
    }

    // Fallback: local update
    final idx = _localStore.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _localStore[idx] = updated;
    } else {
      _localStore.add(updated);
    }
    AppLogger.data('QC: Updated inspection $id locally');
    return updated;
  }

  /// Xóa inspection (soft delete / remove from local)
  Future<void> deleteInspection(String id) async {
    if (_supabaseAvailable) {
      try {
        await _client.from('quality_inspections').delete().eq('id', id);
        AppLogger.data('QC: Deleted inspection $id from Supabase');
        return;
      } catch (e) {
        AppLogger.warn('QC: Supabase delete failed, removing locally', e);
        _supabaseAvailable = false;
      }
    }

    _localStore.removeWhere((i) => i.id == id);
    AppLogger.data('QC: Deleted inspection $id locally');
  }

  // ===== STATISTICS =====

  /// Tính tỉ lệ đạt (%)
  double calculatePassRate(List<QualityInspection> inspections) {
    if (inspections.isEmpty) return 0;
    final completed = inspections
        .where((i) =>
            i.status == InspectionStatus.passed ||
            i.status == InspectionStatus.failed ||
            i.status == InspectionStatus.conditional)
        .toList();
    if (completed.isEmpty) return 0;
    final passed = completed
        .where((i) =>
            i.status == InspectionStatus.passed ||
            i.status == InspectionStatus.conditional)
        .length;
    return (passed / completed.length) * 100;
  }

  /// Phân tích lỗi theo loại
  Map<String, int> defectBreakdown(List<QualityInspection> inspections) {
    final breakdown = <String, int>{};
    for (final inspection in inspections) {
      for (final defect in inspection.defectTypes) {
        breakdown[defect.type] =
            (breakdown[defect.type] ?? 0) + defect.count;
      }
    }
    return breakdown;
  }

  /// Xu hướng theo ngày (cho chart)
  Map<String, Map<String, int>> trendByDate(
      List<QualityInspection> inspections) {
    final trend = <String, Map<String, int>>{};
    for (final i in inspections) {
      final dateKey =
          '${i.inspectionDate.year}-${i.inspectionDate.month.toString().padLeft(2, '0')}-${i.inspectionDate.day.toString().padLeft(2, '0')}';
      trend.putIfAbsent(
          dateKey, () => {'total': 0, 'passed': 0, 'failed': 0});
      trend[dateKey]!['total'] = trend[dateKey]!['total']! + 1;
      if (i.status == InspectionStatus.passed ||
          i.status == InspectionStatus.conditional) {
        trend[dateKey]!['passed'] = trend[dateKey]!['passed']! + 1;
      } else if (i.status == InspectionStatus.failed) {
        trend[dateKey]!['failed'] = trend[dateKey]!['failed']! + 1;
      }
    }
    return Map.fromEntries(
        trend.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// Thống kê tổng hợp
  Future<Map<String, dynamic>> getStats({
    String? overrideCompanyId,
  }) async {
    final inspections =
        await getInspections(overrideCompanyId: overrideCompanyId);
    final passRate = calculatePassRate(inspections);
    final defects = defectBreakdown(inspections);

    final total = inspections.length;
    final pending =
        inspections.where((i) => i.status == InspectionStatus.pending).length;
    final passed =
        inspections.where((i) => i.status == InspectionStatus.passed).length;
    final failed =
        inspections.where((i) => i.status == InspectionStatus.failed).length;
    final conditional = inspections
        .where((i) => i.status == InspectionStatus.conditional)
        .length;

    return {
      'total': total,
      'pending': pending,
      'passed': passed,
      'failed': failed,
      'conditional': conditional,
      'passRate': passRate,
      'defectBreakdown': defects,
    };
  }

  // ===== HELPERS =====

  /// Tạo inspection từ production order (pre-fill thông tin)
  QualityInspection generateFromProductionOrder({
    required ProductionOrder order,
    required String inspectorId,
    required String inspectorName,
  }) {
    final cid = _getCompanyId(order.companyId);
    return QualityInspection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: cid,
      productionOrderId: order.id,
      productName: 'MO-${order.orderNumber} (${order.productId})',
      inspectorId: inspectorId,
      inspectorName: inspectorName,
      inspectionDate: DateTime.now(),
      status: InspectionStatus.pending,
      totalQuantity: order.producedQuantity > 0
          ? order.producedQuantity
          : order.plannedQuantity,
      passedQuantity: 0,
      failedQuantity: 0,
      defectTypes: [],
      notes: null,
      photos: [],
    );
  }

  /// Lấy danh sách production orders (proxy)
  Future<List<ProductionOrder>> getProductionOrders({
    String? overrideCompanyId,
  }) async {
    final cid = _getCompanyId(overrideCompanyId);
    try {
      final response = await _client
          .from('manufacturing_production_orders')
          .select()
          .eq('company_id', cid)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ProductionOrder.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warn('QC: Failed to load production orders', e);
      return [];
    }
  }
}
