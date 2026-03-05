import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/shift_schedule.dart';
import '../../providers/shift_scheduling_provider.dart';
import 'shift_form_dialog.dart';

/// Trang lịch ca theo tuần — dạng lưới (7 cột = T2–CN, hàng = nhân viên)
class ShiftSchedulePage extends ConsumerStatefulWidget {
  const ShiftSchedulePage({super.key});

  @override
  ConsumerState<ShiftSchedulePage> createState() => _ShiftSchedulePageState();
}

class _ShiftSchedulePageState extends ConsumerState<ShiftSchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final weekStart = ref.read(shiftWeekProvider);
    ref.read(weeklyShiftDataProvider.notifier).loadWeek(weekStart);
  }

  void _prevWeek() {
    ref.read(shiftWeekProvider.notifier).previousWeek();
    final weekStart = ref.read(shiftWeekProvider);
    ref.read(weeklyShiftDataProvider.notifier).loadWeek(weekStart);
  }

  void _nextWeek() {
    ref.read(shiftWeekProvider.notifier).nextWeek();
    final weekStart = ref.read(shiftWeekProvider);
    ref.read(weeklyShiftDataProvider.notifier).loadWeek(weekStart);
  }

  void _goToToday() {
    ref.read(shiftWeekProvider.notifier).goToToday();
    final weekStart = ref.read(shiftWeekProvider);
    ref.read(weeklyShiftDataProvider.notifier).loadWeek(weekStart);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = ref.watch(shiftWeekProvider);
    final shiftState = ref.watch(weeklyShiftDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Ca Làm Việc'),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Về tuần hiện tại',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Week Navigator ──
          _WeekNavigator(
            weekStart: weekStart,
            onPrev: _prevWeek,
            onNext: _nextWeek,
          ),

          // ── Content ──
          Expanded(
            child: _buildContent(context, shiftState, weekStart),
          ),

          // ── Legend ──
          const _ShiftLegend(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context, weekStart),
        icon: const Icon(Icons.add),
        label: Text('Thêm ca'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeeklyShiftState shiftState, DateTime weekStart) {
    if (shiftState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shiftState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(shiftState.error!,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final data = shiftState.data;
    if (data == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final employees = data.allEmployees;
    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Chưa có nhân viên nào',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return _WeeklyGrid(
      data: data,
      employees: employees,
      onCellTap: (employeeId, employeeName, date, existingShift) {
        if (existingShift != null) {
          _openEditDialog(context, existingShift);
        } else {
          _openAddDialogForCell(
              context, employeeId, employeeName, date);
        }
      },
      onShiftDelete: (shiftId) => _confirmDelete(context, shiftId),
    );
  }

  void _openAddDialog(BuildContext ctx, DateTime weekStart) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftFormDialog(
        weekStart: weekStart,
        onSaved: _loadData,
      ),
    );
  }

  void _openAddDialogForCell(
      BuildContext ctx, String employeeId, String employeeName, DateTime date) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftFormDialog(
        preselectedEmployeeId: employeeId,
        preselectedEmployeeName: employeeName,
        preselectedDate: date,
        onSaved: _loadData,
      ),
    );
  }

  void _openEditDialog(BuildContext ctx, StaffShiftSchedule shift) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftFormDialog(
        existingShift: shift,
        onSaved: _loadData,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String shiftId) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ca?'),
        content: const Text('Bạn chắc chắn muốn hủy ca này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(weeklyShiftDataProvider.notifier)
                  .deleteShift(shiftId);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content:
                      Text(ok ? 'Đã hủy ca thành công' : 'Lỗi khi hủy ca'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
              }
            },
            child:
                const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Week Navigator
// ═══════════════════════════════════════════════════════════════════
class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('dd/MM');
    final label = '${fmt.format(weekStart)} — ${fmt.format(weekEnd)}';
    final now = DateTime.now();
    final isCurrentWeek = weekStart.isBefore(now.add(const Duration(days: 1))) &&
        weekEnd.isAfter(now.subtract(const Duration(days: 1)));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: onPrev,
            tooltip: 'Tuần trước',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (isCurrentWeek)
                  const Text('Tuần hiện tại',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.success)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: onNext,
            tooltip: 'Tuần sau',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Weekly Grid
// ═══════════════════════════════════════════════════════════════════
class _WeeklyGrid extends StatelessWidget {
  final WeeklyShiftData data;
  final List<Map<String, dynamic>> employees;
  final void Function(String employeeId, String employeeName, DateTime date,
      StaffShiftSchedule? existingShift) onCellTap;
  final void Function(String shiftId) onShiftDelete;

  const _WeeklyGrid({
    required this.data,
    required this.employees,
    required this.onCellTap,
    required this.onShiftDelete,
  });

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final dates = data.weekDates;
    final today = DateTime.now();

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header row: day columns ──
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.only(left: 100),
            child: Row(
              children: List.generate(7, (i) {
                final d = dates[i];
                final isToday = d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                            color: isToday
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            width: isToday ? 2 : 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isToday ? AppColors.primary : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isToday ? AppColors.primary : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Employee rows ──
          ...employees.map((emp) {
            final empId = emp['id'] as String;
            final empName = emp['full_name'] as String? ?? 'N/A';
            final shiftCount = data.countShiftsForEmployee(empId);

            return Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  // Employee name column
                  SizedBox(
                    width: 100,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$shiftCount ca',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7 day cells
                  ...List.generate(7, (i) {
                    final date = dates[i];
                    final shifts = data.getShifts(empId, date);

                    return Expanded(
                      child: _ShiftCell(
                        shifts: shifts,
                        onTap: () {
                          onCellTap(
                            empId,
                            empName,
                            date,
                            shifts.isNotEmpty ? shifts.first : null,
                          );
                        },
                        onDelete: shifts.isNotEmpty
                            ? () => onShiftDelete(shifts.first.id)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Individual Shift Cell
// ═══════════════════════════════════════════════════════════════════
class _ShiftCell extends StatelessWidget {
  final List<StaffShiftSchedule> shifts;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ShiftCell({
    required this.shifts,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.all(2),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: shifts.isEmpty
              ? Colors.grey.shade50
              : shifts.first.shiftType.bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: shifts.isEmpty
                ? Colors.grey.shade200
                : shifts.first.shiftType.color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: shifts.isEmpty
            ? Center(
                child: Icon(Icons.add, size: 14, color: Colors.grey.shade400),
              )
            : _buildShiftContent(shifts.first),
      ),
    );
  }

  Widget _buildShiftContent(StaffShiftSchedule shift) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            shift.shiftType.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 1),
          Text(
            shift.startTime,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: shift.shiftType.color,
            ),
          ),
          if (shift.status != ScheduleItemStatus.scheduled)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: shift.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                shift.status.label,
                style: TextStyle(
                  fontSize: 7,
                  color: shift.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Legend
// ═══════════════════════════════════════════════════════════════════
class _ShiftLegend extends StatelessWidget {
  const _ShiftLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border:
            Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ScheduleShiftType.values.map((type) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: type.bgColor,
                  border: Border.all(color: type.color, width: 1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${type.emoji} ${type.label}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
