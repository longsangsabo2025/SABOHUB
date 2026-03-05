import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/token_provider.dart';
import '../../services/daily_work_report_service.dart';
import '../../business_types/service/services/mood_service.dart';
import '../../widgets/common/mood_checkin_dialog.dart';
import '../../widgets/location_status_widget.dart';
import '../../widgets/work_report_preview_dialog.dart';
import 'staff_reports_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Staff Check-in Page
/// Attendance and scheduling for staff members
class StaffCheckinPage extends ConsumerStatefulWidget {
  const StaffCheckinPage({super.key});

  @override
  ConsumerState<StaffCheckinPage> createState() => _StaffCheckinPageState();
}

class _StaffCheckinPageState extends ConsumerState<StaffCheckinPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final todayAttendanceAsync =
        ref.watch(userTodayAttendanceProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userTodayAttendanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: todayAttendanceAsync.when(
            data: (attendance) => Column(
              children: [
                _buildCheckinCard(user, attendance),
                const SizedBox(height: 24),
                _buildTodaySchedule(),
                const SizedBox(height: 24),
                _buildAttendanceHistory(),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(userTodayAttendanceProvider),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Điểm danh',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface87,
        ),
      ),
      actions: [
        // View Reports button
        IconButton(
          icon: Icon(Icons.assignment, color: Theme.of(context).colorScheme.onSurface87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StaffReportsPage(),
              ),
            );
          },
          tooltip: 'Xem báo cáo',
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📅 Lịch sử điểm danh'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onSurface54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📆 Xem lịch làm việc'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.info,
              ),
            );
          },
          icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface54),
        ),
        IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurface54),
          tooltip: 'Hồ sơ cá nhân',
        ),
      ],
    );
  }

  Widget _buildCheckinCard(User user, AttendanceRecord? attendance) {
    final isCheckedIn =
        attendance?.checkOutTime == null && attendance?.checkInTime != null;
    final currentShift = _getCurrentShift();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCheckedIn
              ? [AppColors.success, AppColors.successDark]
              : [AppColors.neutral500, AppColors.neutral600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn
                    ? AppColors.success
                    : AppColors.neutral500)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.email?.split('@').first ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      currentShift,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCheckedIn ? 'ĐÃ VÀO CA' : 'CHƯA VÀO CA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  isCheckedIn ? 'Thời gian làm việc' : 'Sẵn sàng vào ca?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isCheckedIn
                      ? _formatWorkingTime(attendance?.checkInTime)
                      : DateTime.now().toString().substring(11, 16),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                // Location validation status
                LocationStatusWidget(
                  companyId: user.companyId ?? '',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (isCheckedIn) {
                              _handleCheckOut(user);
                            } else {
                              _handleCheckIn(user);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: isCheckedIn
                          ? AppColors.error
                          : AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final shift = _getCurrentShift();
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ca làm việc hôm nay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(shift,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return SizedBox.shrink();

    final historyAsync = ref.watch(userAttendanceHistoryProvider(user.id));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Lịch sử điểm danh (7 ngày qua)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Chưa có lịch sử điểm danh',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(records.length, (index) {
                  final record = records[index];
                  final date = record.date;
                  final isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month;
                  final dateStr = isToday
                      ? 'Hôm nay'
                      : '${date.day}/${date.month}';
                  final checkIn = record.checkInTime != null
                      ? '${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  final checkOut = record.checkOutTime != null
                      ? '${record.checkOutTime!.hour.toString().padLeft(2, '0')}:${record.checkOutTime!.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  final hasCheckOut = record.checkOutTime != null;
                  final statusText = hasCheckOut ? 'Hoàn thành' : 'Đang làm';
                  final statusColor = hasCheckOut ? AppColors.success : Colors.orange;
                  final shift = _getShiftLabel(record.checkInTime);

                  return _buildHistoryItem(
                    dateStr, shift, checkIn, checkOut,
                    statusText, statusColor,
                    index == records.length - 1,
                  );
                }),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  String _getShiftLabel(DateTime? checkIn) {
    if (checkIn == null) return 'N/A';
    final hour = checkIn.hour;
    if (hour >= 6 && hour < 14) return 'Ca sáng';
    if (hour >= 14 && hour < 22) return 'Ca chiều';
    return 'Ca đêm';
  }

  Widget _buildHistoryItem(String date, String shift, String checkIn,
      String checkOut, String status, Color statusColor, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'Nghỉ phép' ? Icons.event_busy : Icons.schedule,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$shift - $date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status == 'Nghỉ phép'
                      ? 'Đã phê duyệt nghỉ phép'
                      : 'Vào: $checkIn • Ra: $checkOut',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentShift() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 14) {
      return 'Ca sáng (06:00-14:00)';
    } else if (hour >= 14 && hour < 22) {
      return 'Ca chiều (14:00-22:00)';
    } else {
      return 'Ca đêm (22:00-06:00)';
    }
  }

  String _formatWorkingTime(DateTime? checkInTime) {
    if (checkInTime == null) return '00:00';

    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  Future<void> _handleCheckIn(User user) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Check in with location validation
      await ref.read(attendanceServiceProvider).checkInWithLocation(
            userId: user.id,
            branchId: user.branchId,
            companyId: user.companyId,
          );

      ref.invalidate(userTodayAttendanceProvider);

      // 🪙 SABO Token: Thưởng token khi điểm danh
      try {
        await ref.read(tokenWalletProvider.notifier).earnTokens(
          5,
          sourceType: 'attendance',
          description: 'Điểm danh vào ca',
        );
      } catch (_) {
        // Token reward is non-critical
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Đã điểm danh vào ca thành công!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Hiện dialog cảm xúc sau khi điểm danh thành công
      if (!mounted) return;
      final mood = await MoodCheckinDialog.show(context);
      if (mood != null) {
        // Save mood to DB (silent fail — non-blocking)
        try {
          await MoodService().logMood(
            employeeId: user.id,
            companyId: user.companyId ?? '',
            mood: mood,
          );
        } catch (_) {}

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('${mood.emoji} Cảm ơn bạn! Chúc ca làm việc tốt lành.'),
              backgroundColor: mood.color,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi điểm danh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut(User user) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Perform check-out
      final attendance = await ref.read(attendanceServiceProvider).checkOutByUserId(
            userId: user.id,
            branchId: user.branchId,
          );

      // Step 2: Auto-generate daily work report
      final reportService = ref.read(dailyWorkReportServiceProvider);
      final report = await reportService.generateReportFromCheckout(
        attendance: attendance,
        userName: user.name ?? 'Nhân viên',
        companyId: user.companyId, // Pass companyId from user
        userRole: user.role.name,  // Pass user role
      );

      // Step 3: Show report preview dialog
      if (mounted) {
        final submitted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => WorkReportPreviewDialog(
            report: report,
            onSubmitted: () {
              // Refresh providers after submission
              ref.invalidate(todayWorkReportProvider(user.id));
              ref.invalidate(userWorkReportsProvider(user.id));
            },
          ),
        );

        // Step 4: Show result
        if (mounted) {
          ref.invalidate(userTodayAttendanceProvider);

          if (submitted == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('✅ Đã điểm danh ra ca và nộp báo cáo thành công!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã điểm danh ra ca! Báo cáo đã lưu nháp.'),
                backgroundColor: AppColors.info,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi điểm danh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
