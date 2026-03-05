import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/schedule.dart';
import '../../services/schedule_service.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

final _scheduleServiceProvider = Provider((_) => ScheduleService());

final _scheduleStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(_scheduleServiceProvider);
  final user = ref.read(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return {};
  return service.getScheduleStats(companyId);
});

final _weekSchedulesProvider =
    FutureProvider<List<Schedule>>((ref) async {
  final service = ref.read(_scheduleServiceProvider);
  final user = ref.read(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return [];
  return service.getUpcomingSchedules(companyId);
});

class CEOScheduleOverviewPage extends ConsumerStatefulWidget {
  const CEOScheduleOverviewPage({super.key});

  @override
  ConsumerState<CEOScheduleOverviewPage> createState() =>
      _CEOScheduleOverviewPageState();
}

class _CEOScheduleOverviewPageState
    extends ConsumerState<CEOScheduleOverviewPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dayFormat = DateFormat('EEE', 'vi');

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_scheduleStatsProvider);
    final schedulesAsync = ref.watch(_weekSchedulesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Lịch làm việc'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_scheduleStatsProvider);
          ref.invalidate(_weekSchedulesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(statsAsync),
              const SizedBox(height: 20),
              _buildWeekSchedule(schedulesAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return _buildEmptyCard('Chưa có dữ liệu lịch làm việc');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng quan hôm nay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _statCard('Ca hôm nay', '${stats['today_total'] ?? 0}',
                    Icons.today, Colors.blue),
                _statCard('Đã xác nhận', '${stats['today_confirmed'] ?? 0}',
                    Icons.check_circle, Colors.green),
                _statCard('Vắng mặt', '${stats['today_absent'] ?? 0}',
                    Icons.cancel, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _statCard('Ca tuần này', '${stats['week_total'] ?? 0}',
                    Icons.date_range, Colors.indigo),
                _statCard('Xác nhận', '${stats['week_confirmed'] ?? 0}',
                    Icons.verified, Colors.teal),
                _statCard('Vắng', '${stats['week_absent'] ?? 0}',
                    Icons.person_off, Colors.orange),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorCard('Lỗi tải thống kê', '$e', () {
        ref.invalidate(_scheduleStatsProvider);
      }),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWeekSchedule(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return _buildEmptyCard('Chưa có lịch làm việc trong 7 ngày tới.\nHãy tạo lịch cho nhân viên.');
        }

        final grouped = <String, List<Schedule>>{};
        for (final s in schedules) {
          final key = _dateFormat.format(s.date);
          grouped.putIfAbsent(key, () => []).add(s);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lịch 7 ngày tới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...grouped.entries.map((entry) {
              final date = DateFormat('dd/MM/yyyy').parse(entry.key);
              final isToday = _isToday(date);

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday ? Border.all(color: Colors.blue, width: 1.5) : null,
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_dayFormat.format(date).toUpperCase()} ${entry.key}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isToday ? Colors.blue : Theme.of(context).colorScheme.onSurface87,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('HÔM NAY',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                          const Spacer(),
                          Text('${entry.value.length} ca',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    ...entry.value.map((schedule) => _buildScheduleRow(schedule)),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorCard('Lỗi tải lịch', '$e', () {
        ref.invalidate(_weekSchedulesProvider);
      }),
    );
  }

  Widget _buildScheduleRow(Schedule schedule) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: schedule.shiftType.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(schedule.employeeName,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: schedule.shiftType.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(schedule.shiftType.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: schedule.shiftType.color)),
          ),
          const SizedBox(width: 8),
          Text(schedule.timeRange,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: schedule.status.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title, String detail, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
