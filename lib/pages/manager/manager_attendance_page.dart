import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

/// Manager Attendance Page - Simple version
class ManagerAttendancePage extends ConsumerStatefulWidget {
  const ManagerAttendancePage({super.key});

  @override
  ConsumerState<ManagerAttendancePage> createState() => _ManagerAttendancePageState();
}

class _ManagerAttendancePageState extends ConsumerState<ManagerAttendancePage> {

  @override
  Widget build(BuildContext context) {
    // Get userId from authProvider
    final currentUser = ref.watch(authProvider).user;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chấm công')),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }
    
    final userId = currentUser.id;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chấm công'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          _buildTodayAttendanceCard(userId),
          const SizedBox(height: 16),
          _buildAttendanceHistory(userId),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard(String userId) {
    final todayAttendanceAsync = ref.watch(userTodayAttendanceProvider(userId));

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chấm công hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              todayAttendanceAsync.when(
                data: (attendance) => _buildAttendanceStatus(attendance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Lỗi: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(Attendance? attendance) {
    if (attendance == null) {
      return Column(
        children: [
          const Text('Chưa chấm công vào ca hôm nay'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checkIn,
            icon: const Icon(Icons.login),
            label: const Text('Check In'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTimeInfo(
                'Check In',
                attendance.checkInTime,
                Icons.login,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildTimeInfo(
                'Check Out',
                attendance.checkOutTime,
                Icons.logout,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (attendance.checkOutTime == null)
          ElevatedButton.icon(
            onPressed: _checkOut,
            icon: const Icon(Icons.logout),
            label: const Text('Check Out'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, DateTime? time, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('HH:mm').format(time) : '--:--',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistory(String userId) {
    final historyAsync = ref.watch(userAttendanceHistoryProvider(userId));

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Lịch sử chấm công',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: historyAsync.when(
                  data: (attendanceList) {
                    if (attendanceList.isEmpty) {
                      return const Center(
                        child: Text('Chưa có lịch sử chấm công'),
                      );
                    }

                    return ListView.builder(
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final attendance = attendanceList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorForStatus(attendance.status),
                            child: Icon(
                              _getIconForStatus(attendance.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(attendance.date),
                          ),
                          subtitle: Text(_getTextForStatus(attendance.status)),
                          trailing: attendance.checkInTime != null && attendance.checkOutTime != null
                              ? Text(
                                  _calculateWorkingHours(attendance.checkInTime!, attendance.checkOutTime!),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )
                              : null,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Lỗi: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateWorkingHours(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Color _getColorForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.leftEarly:
        return Colors.blue;
      case AttendanceStatus.onBreak:
        return Colors.purple;
      case AttendanceStatus.onLeave:
        return Colors.grey;
    }
  }

  IconData _getIconForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.leftEarly:
        return Icons.logout;
      case AttendanceStatus.onBreak:
        return Icons.coffee;
      case AttendanceStatus.onLeave:
        return Icons.event_busy;
    }
  }

  String _getTextForStatus(AttendanceStatus status) {
    return status.label;
  }


  Future<void> _checkIn() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;
    final userId = currentUser.id;
    
    try {
      final service = ref.read(attendanceServiceProvider);
      await service.checkIn(userId: userId);
      
      // Refresh data
      ref.invalidate(userTodayAttendanceProvider(userId));
      ref.invalidate(userAttendanceHistoryProvider(userId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi check-in: $e')),
        );
      }
    }
  }

  Future<void> _checkOut() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;
    final userId = currentUser.id;
    
    try {
      final service = ref.read(attendanceServiceProvider);
      final attendance = await ref.read(userTodayAttendanceProvider(userId).future);
      
      if (attendance != null) {
        await service.checkOut(userId: userId);
        
        // Refresh data
        ref.invalidate(userTodayAttendanceProvider(userId));
        ref.invalidate(userAttendanceHistoryProvider(userId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-out thành công')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi check-out: $e')),
        );
      }
    }
  }
}