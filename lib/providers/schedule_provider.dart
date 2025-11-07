import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

// All schedules provider
final allSchedulesProvider = FutureProvider.family<List<Schedule>, String>((ref, companyId) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getAllSchedules(companyId);
});

// Schedules by date range provider
final schedulesByDateRangeProvider = FutureProvider.family<List<Schedule>, Map<String, dynamic>>((ref, params) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getSchedulesByDateRange(
    params['companyId'] as String,
    params['startDate'] as DateTime,
    params['endDate'] as DateTime,
  );
});

// Today's schedules provider
final todaySchedulesProvider = FutureProvider.family<List<Schedule>, String>((ref, companyId) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getTodaySchedules(companyId);
});

// Upcoming schedules provider
final upcomingSchedulesProvider = FutureProvider.family<List<Schedule>, String>((ref, companyId) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getUpcomingSchedules(companyId);
});

// Schedules by employee provider
final schedulesByEmployeeProvider = FutureProvider.family<List<Schedule>, Map<String, String>>((ref, params) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getSchedulesByEmployee(
    params['companyId']!,
    params['employeeId']!,
  );
});

// Time-off requests provider
final timeOffRequestsProvider = FutureProvider.family<List<TimeOffRequest>, String>((ref, companyId) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getTimeOffRequests(companyId);
});

// Time-off requests by employee provider
final timeOffRequestsByEmployeeProvider = FutureProvider.family<List<TimeOffRequest>, Map<String, String>>((ref, params) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getTimeOffRequestsByEmployee(
    params['companyId']!,
    params['employeeId']!,
  );
});

// Schedule statistics provider
final scheduleStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, companyId) async {
  final scheduleService = ref.read(scheduleServiceProvider);
  return scheduleService.getScheduleStats(companyId);
});

// Schedule actions provider for state mutations
final scheduleActionsProvider = Provider<ScheduleActions>((ref) {
  return ScheduleActions(ref);
});

class ScheduleActions {
  final Ref _ref;
  
  ScheduleActions(this._ref);
  
  ScheduleService get _scheduleService => _ref.read(scheduleServiceProvider);

  // Create a new schedule
  Future<Schedule> createSchedule(Schedule schedule) async {
    try {
      final newSchedule = await _scheduleService.createSchedule(schedule);
      
      // Invalidate related providers
      _invalidateScheduleProviders(schedule.companyId);
      
      return newSchedule;
    } catch (e) {
      throw Exception('Lỗi khi tạo lịch làm việc: $e');
    }
  }

  // Create multiple schedules
  Future<List<Schedule>> createMultipleSchedules(List<Schedule> schedules) async {
    try {
      final newSchedules = await _scheduleService.createMultipleSchedules(schedules);
      
      // Invalidate related providers
      if (schedules.isNotEmpty) {
        _invalidateScheduleProviders(schedules.first.companyId);
      }
      
      return newSchedules;
    } catch (e) {
      throw Exception('Lỗi khi tạo nhiều lịch làm việc: $e');
    }
  }

  // Update schedule
  Future<Schedule> updateSchedule(Schedule schedule) async {
    try {
      final updatedSchedule = await _scheduleService.updateSchedule(schedule);
      
      // Invalidate related providers
      _invalidateScheduleProviders(schedule.companyId);
      
      return updatedSchedule;
    } catch (e) {
      throw Exception('Lỗi khi cập nhật lịch làm việc: $e');
    }
  }

  // Update schedule status
  Future<Schedule> updateScheduleStatus(
    String scheduleId,
    String companyId,
    ScheduleStatus status, {
    String? notes,
  }) async {
    try {
      final updatedSchedule = await _scheduleService.updateScheduleStatus(
        scheduleId,
        status,
        notes: notes,
      );
      
      // Invalidate related providers
      _invalidateScheduleProviders(companyId);
      
      return updatedSchedule;
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái lịch làm việc: $e');
    }
  }

  // Delete schedule
  Future<void> deleteSchedule(String scheduleId, String companyId) async {
    try {
      await _scheduleService.deleteSchedule(scheduleId);
      
      // Invalidate related providers
      _invalidateScheduleProviders(companyId);
    } catch (e) {
      throw Exception('Lỗi khi xóa lịch làm việc: $e');
    }
  }

  // Delete multiple schedules
  Future<void> deleteMultipleSchedules(List<String> scheduleIds, String companyId) async {
    try {
      await _scheduleService.deleteMultipleSchedules(scheduleIds);
      
      // Invalidate related providers
      _invalidateScheduleProviders(companyId);
    } catch (e) {
      throw Exception('Lỗi khi xóa nhiều lịch làm việc: $e');
    }
  }

  // Create time-off request
  Future<TimeOffRequest> createTimeOffRequest(TimeOffRequest request) async {
    try {
      final newRequest = await _scheduleService.createTimeOffRequest(request);
      
      // Invalidate time-off requests providers
      _ref.invalidate(timeOffRequestsProvider);
      _ref.invalidate(timeOffRequestsByEmployeeProvider);
      
      return newRequest;
    } catch (e) {
      throw Exception('Lỗi khi tạo đơn xin nghỉ phép: $e');
    }
  }

  // Update time-off request status
  Future<TimeOffRequest> updateTimeOffRequestStatus(
    String requestId,
    String companyId,
    RequestStatus status, {
    String? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final updatedRequest = await _scheduleService.updateTimeOffRequestStatus(
        requestId,
        status,
        approvedBy: approvedBy,
        rejectionReason: rejectionReason,
      );
      
      // Invalidate time-off requests providers
      _ref.invalidate(timeOffRequestsProvider);
      _ref.invalidate(timeOffRequestsByEmployeeProvider);
      
      return updatedRequest;
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái đơn xin nghỉ phép: $e');
    }
  }

  // Delete time-off request
  Future<void> deleteTimeOffRequest(String requestId, String companyId) async {
    try {
      await _scheduleService.deleteTimeOffRequest(requestId);
      
      // Invalidate time-off requests providers
      _ref.invalidate(timeOffRequestsProvider);
      _ref.invalidate(timeOffRequestsByEmployeeProvider);
    } catch (e) {
      throw Exception('Lỗi khi xóa đơn xin nghỉ phép: $e');
    }
  }

  // Helper method to invalidate schedule-related providers
  void _invalidateScheduleProviders(String companyId) {
    _ref.invalidate(allSchedulesProvider);
    _ref.invalidate(schedulesByDateRangeProvider);
    _ref.invalidate(todaySchedulesProvider);
    _ref.invalidate(upcomingSchedulesProvider);
    _ref.invalidate(schedulesByEmployeeProvider);
    _ref.invalidate(scheduleStatsProvider);
  }

  // Refresh all schedule data for a company
  void refreshScheduleData(String companyId) {
    _invalidateScheduleProviders(companyId);
    _ref.invalidate(timeOffRequestsProvider);
    _ref.invalidate(timeOffRequestsByEmployeeProvider);
  }
}

// Helper providers for filtered data
final schedulesByStatusProvider = Provider.family<AsyncValue<List<Schedule>>, Map<String, dynamic>>((ref, params) {
  final companyId = params['companyId'] as String;
  final status = params['status'] as ScheduleStatus?;
  
  return ref.watch(allSchedulesProvider(companyId)).when(
    data: (schedules) {
      if (status == null) return AsyncValue.data(schedules);
      return AsyncValue.data(schedules.where((s) => s.status == status).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final schedulesByShiftTypeProvider = Provider.family<AsyncValue<List<Schedule>>, Map<String, dynamic>>((ref, params) {
  final companyId = params['companyId'] as String;
  final shiftType = params['shiftType'] as ShiftType?;
  
  return ref.watch(allSchedulesProvider(companyId)).when(
    data: (schedules) {
      if (shiftType == null) return AsyncValue.data(schedules);
      return AsyncValue.data(schedules.where((s) => s.shiftType == shiftType).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final timeOffRequestsByStatusProvider = Provider.family<AsyncValue<List<TimeOffRequest>>, Map<String, dynamic>>((ref, params) {
  final companyId = params['companyId'] as String;
  final status = params['status'] as RequestStatus?;
  
  return ref.watch(timeOffRequestsProvider(companyId)).when(
    data: (requests) {
      if (status == null) return AsyncValue.data(requests);
      return AsyncValue.data(requests.where((r) => r.status == status).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});