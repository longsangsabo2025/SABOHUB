import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift_schedule.dart';
import '../services/shift_scheduling_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';

// ─── Service Provider (singleton) ──────────────────────────────────────────

final shiftSchedulingServiceProvider = Provider<ShiftSchedulingService>((ref) {
  return ShiftSchedulingService();
});

// ─── Selected Week Provider ────────────────────────────────────────────────

final shiftWeekProvider = NotifierProvider<ShiftWeekNotifier, DateTime>(
  ShiftWeekNotifier.new,
);

class ShiftWeekNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _getMondayOfWeek(DateTime.now());

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void goToToday() {
    state = _getMondayOfWeek(DateTime.now());
  }

  void setWeek(DateTime date) {
    state = _getMondayOfWeek(date);
  }
}

DateTime _getMondayOfWeek(DateTime date) {
  final weekday = date.weekday; // 1=Mon, 7=Sun
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}

// ─── Weekly Shift Data State ───────────────────────────────────────────────

class WeeklyShiftState {
  final WeeklyShiftData? data;
  final bool isLoading;
  final String? error;

  const WeeklyShiftState({this.data, this.isLoading = false, this.error});

  WeeklyShiftState copyWith({
    WeeklyShiftData? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WeeklyShiftState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Weekly Shift Notifier ─────────────────────────────────────────────────

class WeeklyShiftNotifier extends Notifier<WeeklyShiftState> {
  late ShiftSchedulingService _service;

  @override
  WeeklyShiftState build() {
    _service = ref.watch(shiftSchedulingServiceProvider);
    return const WeeklyShiftState();
  }

  String? get _companyId => ref.read(currentUserProvider)?.companyId;
  String? get _branchId => ref.read(currentUserProvider)?.branchId;
  String? get _userId => ref.read(currentUserProvider)?.id;

  /// Load lịch ca tuần
  Future<void> loadWeek(DateTime weekStart) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) {
      state = state.copyWith(error: 'Chưa đăng nhập', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _service.getByWeek(
          companyId: companyId,
          branchId: _branchId,
          weekStart: weekStart,
        ),
        _service.getCompanyEmployees(
          companyId: companyId,
          branchId: _branchId,
        ),
      ]);

      final shifts = results[0] as List<StaffShiftSchedule>;
      final employees = results[1] as List<Map<String, dynamic>>;

      state = WeeklyShiftState(
        data: WeeklyShiftData(
          weekStart: weekStart,
          shifts: shifts,
          employees: employees,
        ),
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Lỗi tải lịch ca tuần', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải lịch: $e',
      );
    }
  }

  /// Tạo ca mới
  Future<bool> createShift({
    required String employeeId,
    required DateTime date,
    required ScheduleShiftType shiftType,
    required String startTime,
    required String endTime,
    String? notes,
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
        startTime: startTime,
        endTime: endTime,
        notes: notes,
        createdBy: _userId,
      );

      // Append to existing data
      final current = state.data;
      if (current != null) {
        state = state.copyWith(
          data: WeeklyShiftData(
            weekStart: current.weekStart,
            shifts: [...current.shifts, shift],
            employees: current.employees,
          ),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi tạo ca', e);
      return false;
    }
  }

  /// Gán ca cho nhiều NV
  Future<bool> bulkAssign({
    required List<String> employeeIds,
    required DateTime date,
    required ScheduleShiftType shiftType,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return false;

    try {
      final newShifts = await _service.assignShiftToMultipleEmployees(
        employeeIds: employeeIds,
        companyId: companyId,
        branchId: _branchId,
        date: date,
        shiftType: shiftType,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
        createdBy: _userId,
      );

      final current = state.data;
      if (current != null) {
        state = state.copyWith(
          data: WeeklyShiftData(
            weekStart: current.weekStart,
            shifts: [...current.shifts, ...newShifts],
            employees: current.employees,
          ),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi gán ca hàng loạt', e);
      return false;
    }
  }

  /// Cập nhật ca
  Future<bool> updateShift({
    required String shiftId,
    ScheduleShiftType? shiftType,
    String? startTime,
    String? endTime,
    ScheduleItemStatus? status,
    String? notes,
  }) async {
    try {
      final updated = await _service.updateShift(
        id: shiftId,
        shiftType: shiftType,
        startTime: startTime,
        endTime: endTime,
        status: status,
        notes: notes,
      );

      final current = state.data;
      if (current != null) {
        final updatedShifts =
            current.shifts.map((s) => s.id == shiftId ? updated : s).toList();
        state = state.copyWith(
          data: WeeklyShiftData(
            weekStart: current.weekStart,
            shifts: updatedShifts,
            employees: current.employees,
          ),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi cập nhật ca', e);
      return false;
    }
  }

  /// Xóa ca (soft delete → cancelled)
  Future<bool> deleteShift(String shiftId) async {
    try {
      await _service.deleteShift(shiftId);

      final current = state.data;
      if (current != null) {
        final updatedShifts =
            current.shifts.where((s) => s.id != shiftId).toList();
        state = state.copyWith(
          data: WeeklyShiftData(
            weekStart: current.weekStart,
            shifts: updatedShifts,
            employees: current.employees,
          ),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Lỗi xóa ca', e);
      return false;
    }
  }
}

final weeklyShiftDataProvider =
    NotifierProvider<WeeklyShiftNotifier, WeeklyShiftState>(
  WeeklyShiftNotifier.new,
);

// ─── Conflict Provider ─────────────────────────────────────────────────────

/// Check xung đột ca cho 1 nhân viên trong 1 ngày
final shiftConflictProvider = FutureProvider.autoDispose
    .family<List<StaffShiftSchedule>, ({String employeeId, DateTime date, String? excludeId})>(
  (ref, params) async {
    final service = ref.read(shiftSchedulingServiceProvider);
    return service.checkConflicts(
      employeeId: params.employeeId,
      date: params.date,
      excludeShiftId: params.excludeId,
    );
  },
);

// ─── Employee Shift Provider (by month) ────────────────────────────────────

final employeeShiftProvider = FutureProvider.autoDispose
    .family<List<StaffShiftSchedule>, ({String employeeId, int year, int month})>(
  (ref, params) async {
    final service = ref.read(shiftSchedulingServiceProvider);
    return service.getByEmployee(
      employeeId: params.employeeId,
      year: params.year,
      month: params.month,
    );
  },
);

// ─── Company Employees Provider ────────────────────────────────────────────

final shiftEmployeesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(shiftSchedulingServiceProvider);
  return service.getCompanyEmployees(
    companyId: user.companyId ?? '',
    branchId: user.branchId,
  );
});
