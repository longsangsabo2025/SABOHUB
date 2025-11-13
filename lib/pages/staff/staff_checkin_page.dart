import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/daily_work_report_service.dart';
import '../../widgets/location_status_widget.dart';
import '../../widgets/work_report_preview_dialog.dart';

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
      return const Scaffold(
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
      backgroundColor: Colors.white,
      title: const Text(
        'Điểm danh',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📅 Lịch sử điểm danh'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF8B5CF6),
              ),
            );
          },
          icon: const Icon(Icons.history, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📆 Xem lịch làm việc'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
          },
          icon: const Icon(Icons.calendar_today, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: const Icon(Icons.person_outline, color: Colors.black54),
          tooltip: 'Hồ sơ cá nhân',
        ),
      ],
    );
  }

  Widget _buildCheckinCard(User user, Attendance? attendance) {
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
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6B7280))
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
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? user.email?.split('@').first ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentShift,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCheckedIn ? 'ĐÃ VÀO CA' : 'CHƯA VÀO CA',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  isCheckedIn ? 'Thời gian làm việc' : 'Sẵn sàng vào ca?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCheckedIn
                      ? _formatWorkingTime(attendance?.checkInTime)
                      : DateTime.now().toString().substring(11, 16),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Location validation status
                LocationStatusWidget(
                  companyId: user.companyId,
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
                      backgroundColor: Colors.white,
                      foregroundColor: isCheckedIn
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch làm việc hôm nay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScheduleItem(
                    'Thời gian', '14:00 - 22:00', Icons.schedule),
              ),
              Expanded(
                child: _buildScheduleItem(
                    'Khu vực', 'Khu A & Bar', Icons.location_on),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    _buildScheduleItem('Nhiệm vụ', '12 việc', Icons.assignment),
              ),
              Expanded(
                child: _buildScheduleItem('Ca làm', 'Chiều', Icons.wb_sunny),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hôm nay có ca tăng cường. Nhớ kiểm tra nhiệm vụ bổ sung.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
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

  Widget _buildScheduleItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF10B981),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(7, (index) {
            final dates = [
              'Hôm nay',
              'Hôm qua',
              '29/10',
              '28/10',
              '27/10',
              '26/10',
              '25/10'
            ];
            final checkIns = [
              '14:00',
              '08:00',
              '14:05',
              '08:00',
              '13:58',
              'Nghỉ',
              '08:02'
            ];
            final checkOuts = [
              '--:--',
              '16:15',
              '22:10',
              '16:20',
              '22:05',
              'Nghỉ',
              '16:18'
            ];
            final shifts = [
              'Ca chiều',
              'Ca sáng',
              'Ca chiều',
              'Ca sáng',
              'Ca chiều',
              'Nghỉ phép',
              'Ca sáng'
            ];
            final statuses = [
              'Đang làm',
              'Hoàn thành',
              'Hoàn thành',
              'Hoàn thành',
              'Hoàn thành',
              'Nghỉ phép',
              'Hoàn thành'
            ];
            final colors = [
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              const Color(0xFF10B981),
              Colors.grey,
              const Color(0xFF10B981)
            ];

            return _buildHistoryItem(
              dates[index],
              shifts[index],
              checkIns[index],
              checkOuts[index],
              statuses[index],
              colors[index],
              index == 6, // isLast
            );
          }),
        ],
      ),
    );
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
            branchId: null, // TODO: Add branchId to User model
          );

      ref.invalidate(userTodayAttendanceProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Đã điểm danh vào ca thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
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
      final attendance = await ref.read(attendanceServiceProvider).checkOut(
            userId: user.id,
            branchId: null, // TODO: Add branchId to User model
          );

      // Step 2: Auto-generate daily work report
      final reportService = ref.read(dailyWorkReportServiceProvider);
      final report = await reportService.generateReportFromCheckout(
        attendance: attendance,
        userName: user.name ?? 'Nhân viên',
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
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã điểm danh ra ca! Báo cáo đã lưu nháp.'),
                backgroundColor: Color(0xFF3B82F6),
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
