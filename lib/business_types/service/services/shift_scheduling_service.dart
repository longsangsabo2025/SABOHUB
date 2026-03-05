import '../../../core/services/base_service.dart';
import '../../../utils/app_logger.dart';
import '../models/shift_schedule.dart';

/// Service quản lý lịch ca sử dụng bảng `schedules`.
///
/// ⚠️ EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!
/// - Caller PHẢI truyền companyId / branchId từ authProvider
/// - KHÔNG dùng client.auth.currentUser
///
/// Table: `schedules` (13 cols, RLS: YES)
/// CHECK: shift_type in (morning, afternoon, evening, full_day)
/// CHECK: status in (scheduled, confirmed, absent, late, cancelled)
class ShiftSchedulingService extends BaseService {
  @override
  String get serviceName => 'ShiftSchedulingService';

  static const String _table = 'schedules';

  // ─── Get Shifts by Week ─────────────────────────────────────────────────

  /// Lấy tất cả ca trong 1 tuần cho company (+ optional branch)
  Future<List<StaffShiftSchedule>> getByWeek({
    required String companyId,
    String? branchId,
    required DateTime weekStart,
  }) async {
    return safeCall(
      operation: 'getByWeek',
      action: () async {
        final weekEnd = weekStart.add(const Duration(days: 6));

        var query = client
            .from(_table)
            .select('*, employees!inner(full_name)')
            .eq('company_id', companyId)
            .gte('date', _dateStr(weekStart))
            .lte('date', _dateStr(weekEnd))
            .neq('status', 'cancelled');

        if (branchId != null) {
          query = query.eq('branch_id', branchId);
        }

        final data = await query.order('date').order('start_time');
        return _mapList(data);
      },
    );
  }

  // ─── Get Shifts by Employee ─────────────────────────────────────────────

  /// Lấy lịch ca của 1 nhân viên theo tháng
  Future<List<StaffShiftSchedule>> getByEmployee({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    return safeCall(
      operation: 'getByEmployee',
      action: () async {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 0); // last day of month

        final data = await client
            .from(_table)
            .select('*, employees!inner(full_name)')
            .eq('employee_id', employeeId)
            .gte('date', _dateStr(start))
            .lte('date', _dateStr(end))
            .neq('status', 'cancelled')
            .order('date');

        return _mapList(data);
      },
    );
  }

  // ─── Create Shift ──────────────────────────────────────────────────────

  /// Tạo 1 ca mới
  Future<StaffShiftSchedule> createShift({
    required String employeeId,
    required String companyId,
    String? branchId,
    required DateTime date,
    required ScheduleShiftType shiftType,
    required String startTime,
    required String endTime,
    String? notes,
    String? createdBy,
  }) async {
    return safeCall(
      operation: 'createShift',
      action: () async {
        final payload = {
          'employee_id': employeeId,
          'company_id': companyId,
          'branch_id': branchId,
          'date': _dateStr(date),
          'shift_type': shiftType.value,
          'start_time': startTime,
          'end_time': endTime,
          'status': 'scheduled',
          'notes': notes,
          'created_by': createdBy,
        };

        final data = await client
            .from(_table)
            .insert(payload)
            .select('*, employees!inner(full_name)')
            .single();

        AppLogger.info(
            'Tạo ca ${shiftType.label} cho $employeeId ngày ${_dateStr(date)}');
        return _mapOne(data);
      },
    );
  }

  // ─── Bulk Assign ───────────────────────────────────────────────────────

  /// Gán ca cho nhiều nhân viên cùng lúc
  Future<List<StaffShiftSchedule>> assignShiftToMultipleEmployees({
    required List<String> employeeIds,
    required String companyId,
    String? branchId,
    required DateTime date,
    required ScheduleShiftType shiftType,
    required String startTime,
    required String endTime,
    String? notes,
    String? createdBy,
  }) async {
    return safeCall(
      operation: 'assignShiftToMultipleEmployees',
      action: () async {
        final payloads = employeeIds.map((eid) => {
              'employee_id': eid,
              'company_id': companyId,
              'branch_id': branchId,
              'date': _dateStr(date),
              'shift_type': shiftType.value,
              'start_time': startTime,
              'end_time': endTime,
              'status': 'scheduled',
              'notes': notes,
              'created_by': createdBy,
            }).toList();

        final data = await client
            .from(_table)
            .insert(payloads)
            .select('*, employees!inner(full_name)');

        AppLogger.info(
            'Gán ca ${shiftType.label} cho ${employeeIds.length} NV ngày ${_dateStr(date)}');
        return _mapList(data);
      },
    );
  }

  // ─── Update Shift ──────────────────────────────────────────────────────

  /// Cập nhật ca
  Future<StaffShiftSchedule> updateShift({
    required String id,
    ScheduleShiftType? shiftType,
    String? startTime,
    String? endTime,
    ScheduleItemStatus? status,
    String? notes,
  }) async {
    return safeCall(
      operation: 'updateShift',
      action: () async {
        final updates = <String, dynamic>{};
        if (shiftType != null) updates['shift_type'] = shiftType.value;
        if (startTime != null) updates['start_time'] = startTime;
        if (endTime != null) updates['end_time'] = endTime;
        if (status != null) updates['status'] = status.value;
        if (notes != null) updates['notes'] = notes;
        updates['updated_at'] = DateTime.now().toIso8601String();

        if (updates.length == 1) {
          throw Exception('Không có dữ liệu cập nhật');
        }

        final data = await client
            .from(_table)
            .update(updates)
            .eq('id', id)
            .select('*, employees!inner(full_name)')
            .single();

        AppLogger.info('Cập nhật ca: $id');
        return _mapOne(data);
      },
    );
  }

  // ─── Delete Shift (soft) ───────────────────────────────────────────────

  /// Soft-delete: chuyển status = cancelled
  Future<void> deleteShift(String id) async {
    return safeCall(
      operation: 'deleteShift',
      action: () async {
        await client.from(_table).update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
        AppLogger.info('Soft-deleted (cancelled) ca: $id');
      },
    );
  }

  // ─── Conflict Detection ────────────────────────────────────────────────

  /// Kiểm tra xung đột: nhân viên đã có ca trong cùng ngày + khoảng thời gian?
  Future<List<StaffShiftSchedule>> checkConflicts({
    required String employeeId,
    required DateTime date,
    String? excludeShiftId,
  }) async {
    return safeCall(
      operation: 'checkConflicts',
      action: () async {
        var query = client
            .from(_table)
            .select('*, employees!inner(full_name)')
            .eq('employee_id', employeeId)
            .eq('date', _dateStr(date))
            .neq('status', 'cancelled');

        if (excludeShiftId != null) {
          query = query.neq('id', excludeShiftId);
        }

        final data = await query;
        return _mapList(data);
      },
    );
  }

  // ─── Weekly Summary ────────────────────────────────────────────────────

  /// Đếm số ca theo nhân viên trong tuần
  Future<Map<String, int>> getWeeklySummary({
    required String companyId,
    String? branchId,
    required DateTime weekStart,
  }) async {
    return safeCall(
      operation: 'getWeeklySummary',
      action: () async {
        final weekEnd = weekStart.add(const Duration(days: 6));

        var query = client
            .from(_table)
            .select('employee_id')
            .eq('company_id', companyId)
            .gte('date', _dateStr(weekStart))
            .lte('date', _dateStr(weekEnd))
            .neq('status', 'cancelled');

        if (branchId != null) {
          query = query.eq('branch_id', branchId);
        }

        final data = await query;
        final counts = <String, int>{};
        for (final row in data as List) {
          final eid = row['employee_id'] as String? ?? '';
          if (eid.isNotEmpty) {
            counts[eid] = (counts[eid] ?? 0) + 1;
          }
        }
        return counts;
      },
    );
  }

  // ─── Get Branch Employees ──────────────────────────────────────────────

  /// Lấy danh sách nhân viên hoạt động trong company/branch
  Future<List<Map<String, dynamic>>> getCompanyEmployees({
    required String companyId,
    String? branchId,
  }) async {
    return safeCall(
      operation: 'getCompanyEmployees',
      action: () async {
        var query = client
            .from('employees')
            .select('id, full_name, role')
            .eq('company_id', companyId)
            .eq('is_active', true);

        if (branchId != null) {
          query = query.eq('branch_id', branchId);
        }

        final data = await query.order('full_name');
        return (data as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  List<StaffShiftSchedule> _mapList(dynamic data) {
    return (data as List).map((json) => _mapOne(json)).toList();
  }

  StaffShiftSchedule _mapOne(dynamic json) {
    final map = Map<String, dynamic>.from(json);
    if (map['employees'] != null) {
      map['employee_name'] = map['employees']['full_name'] ?? 'N/A';
    }
    return StaffShiftSchedule.fromJson(map);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
