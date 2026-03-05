import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';

// ─── Service Provider (singleton) ──────────────────────────────────────────

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

// ─── Selected Week Provider ────────────────────────────────────────────────

/// Provider for the currently selected week (Monday of that week)
final selectedWeekProvider = NotifierProvider<SelectedWeekNotifier, DateTime>(
  SelectedWeekNotifier.new,
);

class SelectedWeekNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _getMondayOfWeek(DateTime.now());

  void setWeek(DateTime date) {
    state = _getMondayOfWeek(date);
  }
}

/// Helper: lấy Monday của tuần chứa [date]
DateTime _getMondayOfWeek(DateTime date) {
  final weekday = date.weekday; // 1=Mon, 7=Sun
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}

// ─── Branch Employees Provider ─────────────────────────────────────────────

final branchEmployeesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(scheduleServiceProvider);
  return service.getBranchEmployees(
    companyId: user.companyId ?? '',
    branchId: user.branchId,
  );
});

// ─── Weekly Schedule State ─────────────────────────────────────────────────

class WeeklyScheduleState {
  final WeeklySchedule? schedule;
  final bool isLoading;
  final String? errorMessage;

  const WeeklyScheduleState({
    this.schedule,
    this.isLoading = false,
    this.errorMessage,
  });

  WeeklyScheduleState copyWith({
    WeeklySchedule? schedule,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeeklyScheduleState(
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Weekly Schedule Notifier (Riverpod 3.x pattern) ───────────────────────

class WeeklyScheduleNotifier extends Notifier<WeeklyScheduleState> {
  late ScheduleService _service;

  @override
  WeeklyScheduleState build() {
    _service = ref.watch(scheduleServiceProvider);
    return const WeeklyScheduleState();
  }

  String? get _companyId => ref.read(currentUserProvider)?.companyId;
  String? get _branchId => ref.read(currentUserProvider)?.branchId;
  String? get _userId => ref.read(currentUserProvider)?.id;

  /// Load lịch ca của tuần đã chọn
  Future<void> loadWeek(DateTime weekStart) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Chưa đăng nhập',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shifts = await _service.getWeeklySchedule(
        companyId: companyId,
        branchId: _branchId,
        weekStart: weekStart,
      );

      state = WeeklyScheduleState(
        schedule: WeeklySchedule(
          weekStart: weekStart,
          shifts: shifts,
        ),
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Lỗi tải lịch tuần', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải lịch: $e',
      );
    }
  }

  /// Tạo ca mới
  Future<bool> createShift({
    required String employeeId,
    required DateTime date,
    required ShiftType shiftType,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isOff = false,
    String? note,
  }) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return false;

    try {
      final shift = await _service.createShift(
        employeeId: employeeId,
        companyId: companyId,
        branchId: _branchId,
        date: date,
        shiftType: shiftType,
        startTime: _formatTime(startTime),
        endTime: _formatTime(endTime),
        isOff: isOff,
        note: note,
        createdBy: _userId,
      );

      // Append to current schedule
      final currentSchedule = state.schedule;
      if (currentSchedule != null) {
        final updatedShifts = [...currentSchedule.shifts, shift];
        state = state.copyWith(
          schedule: currentSchedule.copyWith(shifts: updatedShifts),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi tạo ca', e);
      return false;
    }
  }

  /// Cập nhật ca
  Future<bool> updateShift({
    required String shiftId,
    ShiftType? shiftType,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isOff,
    String? note,
  }) async {
    try {
      final updated = await _service.updateShift(
        id: shiftId,
        shiftType: shiftType,
        startTime: startTime != null ? _formatTime(startTime) : null,
        endTime: endTime != null ? _formatTime(endTime) : null,
        isOff: isOff,
        note: note,
      );

      // Replace in current schedule
      final currentSchedule = state.schedule;
      if (currentSchedule != null) {
        final updatedShifts = currentSchedule.shifts
            .map((s) => s.id == shiftId ? updated : s)
            .toList();
        state = state.copyWith(
          schedule: currentSchedule.copyWith(shifts: updatedShifts),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi cập nhật ca', e);
      return false;
    }
  }

  /// Xóa ca
  Future<bool> deleteShift(String shiftId) async {
    try {
      await _service.deleteShift(shiftId);

      // Remove from current schedule
      final currentSchedule = state.schedule;
      if (currentSchedule != null) {
        final updatedShifts =
            currentSchedule.shifts.where((s) => s.id != shiftId).toList();
        state = state.copyWith(
          schedule: currentSchedule.copyWith(shifts: updatedShifts),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi xóa ca', e);
      return false;
    }
  }

  /// Phát hành lịch tuần
  Future<bool> publishWeek() async {
    final companyId = _companyId;
    final weekStart = state.schedule?.weekStart;
    if (companyId == null || weekStart == null) return false;

    try {
      await _service.publishSchedule(
        companyId: companyId,
        branchId: _branchId,
        weekStart: weekStart,
      );

      state = state.copyWith(
        schedule: state.schedule?.copyWith(status: ScheduleStatus.published),
      );
      return true;
    } catch (e) {
      AppLogger.error('Lỗi phát hành lịch', e);
      return false;
    }
  }

  /// Copy lịch từ tuần trước
  Future<bool> copyPreviousWeek() async {
    final companyId = _companyId;
    final currentWeek = state.schedule?.weekStart;
    if (companyId == null || currentWeek == null) return false;

    final previousWeek = currentWeek.subtract(const Duration(days: 7));

    try {
      state = state.copyWith(isLoading: true);

      final newShifts = await _service.copyWeekSchedule(
        companyId: companyId,
        branchId: _branchId,
        fromWeekStart: previousWeek,
        toWeekStart: currentWeek,
        createdBy: _userId,
      );

      if (newShifts.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Tuần trước không có ca nào để copy',
        );
        return false;
      }

      // Merge with existing shifts
      final currentShifts = state.schedule?.shifts ?? [];
      state = state.copyWith(
        schedule: state.schedule?.copyWith(
          shifts: [...currentShifts, ...newShifts],
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      AppLogger.error('Lỗi copy tuần trước', e);
      state = state.copyWith(isLoading: false, errorMessage: 'Lỗi copy: $e');
      return false;
    }
  }

  /// Format TimeOfDay to "HH:mm"
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Provider ──────────────────────────────────────────────────────────────

final weeklyScheduleProvider =
    NotifierProvider<WeeklyScheduleNotifier, WeeklyScheduleState>(
  WeeklyScheduleNotifier.new,
);
