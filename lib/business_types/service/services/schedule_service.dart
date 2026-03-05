import '../../../core/services/base_service.dart';
import '../../../utils/app_logger.dart';
import '../models/schedule.dart';

/// Service quản lý lịch ca làm việc (Shift Schedules).
///
/// ⚠️ EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!
/// - Caller PHẢI truyền companyId / branchId từ authProvider
/// - KHÔNG dùng client.auth.currentUser
///
/// Table: `shift_schedules`
/// Handles gracefully if table does not exist yet.
class ScheduleService extends BaseService {
  @override
  String get serviceName => 'ScheduleService';

  static const String _table = 'shift_schedules';

  // ─── Get Weekly Schedule ────────────────────────────────────────────────

  /// Lấy lịch ca theo tuần cho 1 chi nhánh
  Future<List<ShiftSchedule>> getWeeklySchedule({
    required String companyId,
    String? branchId,
    required DateTime weekStart,
  }) async {
    return safeCall(
      operation: 'getWeeklySchedule',
      action: () async {
        final weekEnd = weekStart.add(const Duration(days: 6));
        final startStr = _dateStr(weekStart);
        final endStr = _dateStr(weekEnd);

        var query = client
            .from(_table)
            .select('*, employees!inner(full_name)')
            .eq('company_id', companyId)
            .gte('date', startStr)
            .lte('date', endStr);

        if (branchId != null) {
          query = query.eq('branch_id', branchId);
        }

        final data = await query.order('date').order('start_time');
        return (data as List).map((json) {
          // Flatten employee name into the shift json
          final map = Map<String, dynamic>.from(json);
          if (map['employees'] != null) {
            map['employee_name'] = map['employees']['full_name'] ?? 'N/A';
          }
          return ShiftSchedule.fromJson(map);
        }).toList();
      },
    );
  }

  // ─── Get Employee Schedule ──────────────────────────────────────────────

  /// Lấy lịch ca của 1 nhân viên trong khoảng thời gian
  Future<List<ShiftSchedule>> getEmployeeSchedule({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return safeCall(
      operation: 'getEmployeeSchedule',
      action: () async {
        final data = await client
            .from(_table)
            .select('*, employees!inner(full_name)')
            .eq('employee_id', employeeId)
            .gte('date', _dateStr(startDate))
            .lte('date', _dateStr(endDate))
            .order('date');

        return (data as List).map((json) {
          final map = Map<String, dynamic>.from(json);
          if (map['employees'] != null) {
            map['employee_name'] = map['employees']['full_name'] ?? 'N/A';
          }
          return ShiftSchedule.fromJson(map);
        }).toList();
      },
    );
  }

  // ─── Create Shift ──────────────────────────────────────────────────────

  /// Tạo ca mới
  Future<ShiftSchedule> createShift({
    required String employeeId,
    required String companyId,
    String? branchId,
    required DateTime date,
    required ShiftType shiftType,
    required String startTime,
    required String endTime,
    bool isOff = false,
    String? note,
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
          'is_off': isOff,
          'note': note,
          'created_by': createdBy,
        };

        final data = await client
            .from(_table)
            .insert(payload)
            .select('*, employees!inner(full_name)')
            .single();

        final map = Map<String, dynamic>.from(data);
        if (map['employees'] != null) {
          map['employee_name'] = map['employees']['full_name'] ?? 'N/A';
        }
        AppLogger.info('Tạo ca: ${shiftType.label} cho $employeeId ngày ${_dateStr(date)}');
        return ShiftSchedule.fromJson(map);
      },
    );
  }

  // ─── Update Shift ──────────────────────────────────────────────────────

  /// Cập nhật ca
  Future<ShiftSchedule> updateShift({
    required String id,
    ShiftType? shiftType,
    String? startTime,
    String? endTime,
    bool? isOff,
    String? note,
  }) async {
    return safeCall(
      operation: 'updateShift',
      action: () async {
        final updates = <String, dynamic>{};
        if (shiftType != null) updates['shift_type'] = shiftType.value;
        if (startTime != null) updates['start_time'] = startTime;
        if (endTime != null) updates['end_time'] = endTime;
        if (isOff != null) updates['is_off'] = isOff;
        if (note != null) updates['note'] = note;
        updates['updated_at'] = DateTime.now().toIso8601String();

        if (updates.isEmpty) {
          throw Exception('Không có dữ liệu cập nhật');
        }

        final data = await client
            .from(_table)
            .update(updates)
            .eq('id', id)
            .select('*, employees!inner(full_name)')
            .single();

        final map = Map<String, dynamic>.from(data);
        if (map['employees'] != null) {
          map['employee_name'] = map['employees']['full_name'] ?? 'N/A';
        }
        AppLogger.info('Cập nhật ca: $id');
        return ShiftSchedule.fromJson(map);
      },
    );
  }

  // ─── Delete Shift ──────────────────────────────────────────────────────

  /// Xóa ca (soft delete)
  Future<void> deleteShift(String id) async {
    return safeCall(
      operation: 'deleteShift',
      action: () async {
        // Soft delete - sets is_active=false
        await client.from(_table).update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
        AppLogger.info('Soft-deleted ca: $id');
      },
    );
  }

  // ─── Publish Schedule ──────────────────────────────────────────────────

  /// Đánh dấu lịch tuần là "đã phát hành"
  /// Updates all shifts in the week to have status = published
  Future<void> publishSchedule({
    required String companyId,
    String? branchId,
    required DateTime weekStart,
  }) async {
    return safeCall(
      operation: 'publishSchedule',
      action: () async {
        final weekEnd = weekStart.add(const Duration(days: 6));
        var query = client
            .from(_table)
            .update({
              'status': ScheduleStatus.published.value,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('company_id', companyId)
            .gte('date', _dateStr(weekStart))
            .lte('date', _dateStr(weekEnd));

        if (branchId != null) {
          query = query.eq('branch_id', branchId);
        }

        await query;
        AppLogger.info(
            'Phát hành lịch tuần ${_dateStr(weekStart)} -> ${_dateStr(weekEnd)}');
      },
    );
  }

  // ─── Copy Week Schedule ────────────────────────────────────────────────

  /// Copy lịch từ tuần trước sang tuần hiện tại
  Future<List<ShiftSchedule>> copyWeekSchedule({
    required String companyId,
    String? branchId,
    required DateTime fromWeekStart,
    required DateTime toWeekStart,
    String? createdBy,
  }) async {
    return safeCall(
      operation: 'copyWeekSchedule',
      action: () async {
        // 1. Get source week shifts
        final sourceShifts = await getWeeklySchedule(
          companyId: companyId,
          branchId: branchId,
          weekStart: fromWeekStart,
        );

        if (sourceShifts.isEmpty) {
          AppLogger.warn('Không có ca nào trong tuần nguồn để copy');
          return <ShiftSchedule>[];
        }

        // 2. Calculate day offset
        final dayDiff = toWeekStart.difference(fromWeekStart).inDays;

        // 3. Create new shifts for target week
        final newShifts = <ShiftSchedule>[];
        for (final shift in sourceShifts) {
          final newDate = shift.date.add(Duration(days: dayDiff));
          final created = await createShift(
            employeeId: shift.employeeId,
            companyId: companyId,
            branchId: branchId,
            date: newDate,
            shiftType: shift.shiftType,
            startTime: ShiftSchedule.formatTime(shift.startTime),
            endTime: ShiftSchedule.formatTime(shift.endTime),
            isOff: shift.isOff,
            note: shift.note,
            createdBy: createdBy,
          );
          newShifts.add(created);
        }

        AppLogger.info(
            'Copy ${newShifts.length} ca từ tuần ${_dateStr(fromWeekStart)} -> ${_dateStr(toWeekStart)}');
        return newShifts;
      },
    );
  }

  // ─── Get Branch Employees ──────────────────────────────────────────────

  /// Lấy danh sách nhân viên trong chi nhánh (for schedule dropdowns)
  Future<List<Map<String, dynamic>>> getBranchEmployees({
    required String companyId,
    String? branchId,
  }) async {
    return safeCall(
      operation: 'getBranchEmployees',
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

  /// Format date to "yyyy-MM-dd"
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
