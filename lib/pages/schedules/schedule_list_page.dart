import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import 'schedule_form_page.dart';
// import 'schedule_calendar_page.dart';
// import 'time_off_requests_page.dart';

class ScheduleListPage extends ConsumerStatefulWidget {
  const ScheduleListPage({super.key});

  @override
  ConsumerState<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends ConsumerState<ScheduleListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  ScheduleStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Auto-refresh every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshSchedules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _refreshSchedules() {
    final user = ref.read(authProvider);
    if (user.user?.companyId != null) {
      ref.read(scheduleActionsProvider).refreshScheduleData(user.user!.companyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    
    if (user.user?.companyId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy thông tin công ty'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch Làm Việc'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Filter by status
          PopupMenuButton<ScheduleStatus?>(
            icon: Icon(_selectedStatus != null ? Icons.filter_alt : Icons.filter_alt_outlined),
            onSelected: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tất cả'),
              ),
              ...ScheduleStatus.values.map((status) => PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.label),
                  ],
                ),
              )),
            ],
          ),
          // Refresh
          IconButton(
            onPressed: _refreshSchedules,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
          // Calendar view
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Xem lịch',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Sắp tới'),
            Tab(text: 'Tất cả'),
            Tab(text: 'Nghỉ phép'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(user.user!.companyId!),
          _buildUpcomingTab(user.user!.companyId!),
          _buildAllSchedulesTab(user.user!.companyId!),
          _buildTimeOffTab(user.user!.companyId!),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleFormPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm Lịch'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildTodayTab(String companyId) {
    return Column(
      children: [
        // Today's stats
        _buildTodayStats(companyId),
        
        // Today's schedules
        Expanded(
          child: _buildSchedulesList(
            ref.watch(todaySchedulesProvider(companyId)),
            emptyMessage: 'Không có lịch làm việc nào hôm nay',
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab(String companyId) {
    return _buildSchedulesList(
      ref.watch(upcomingSchedulesProvider(companyId)),
      emptyMessage: 'Không có lịch làm việc nào sắp tới',
    );
  }

  Widget _buildAllSchedulesTab(String companyId) {
    final schedulesAsync = _selectedStatus != null
        ? ref.watch(schedulesByStatusProvider({
            'companyId': companyId,
            'status': _selectedStatus,
          }))
        : ref.watch(allSchedulesProvider(companyId));

    return _buildSchedulesList(
      schedulesAsync,
      emptyMessage: _selectedStatus != null
          ? 'Không có lịch làm việc nào với trạng thái "${_selectedStatus!.label}"'
          : 'Chưa có lịch làm việc nào',
    );
  }

  Widget _buildTimeOffTab(String companyId) {
    return const Center(
      child: Text(
        'Tính năng Nghỉ phép đang phát triển',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildTodayStats(String companyId) {
    return ref.watch(scheduleStatsProvider(companyId)).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Lỗi: $error', style: TextStyle(color: Colors.red)),
      ),
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê hôm nay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng ca',
                    '${stats['today_total'] ?? 0}',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Đã xác nhận',
                    '${stats['today_confirmed'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Vắng mặt',
                    '${stats['today_absent'] ?? 0}',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList(AsyncValue<List<Schedule>> schedulesAsync, {required String emptyMessage}) {
    return RefreshIndicator(
      onRefresh: () async => _refreshSchedules(),
      child: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Lỗi: $error',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshSchedules,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleFormPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm lịch làm việc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _buildScheduleCard(schedule);
            },
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: schedule.status.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showScheduleDetails(schedule),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with employee name and date
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: schedule.shiftType.color.withOpacity(0.2),
                    child: Text(
                      schedule.employeeName.isNotEmpty 
                          ? schedule.employeeName[0].toUpperCase()
                          : 'N',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: schedule.shiftType.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          schedule.dateFormatted,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: schedule.status.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: schedule.status.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      schedule.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: schedule.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Shift info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: schedule.shiftType.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schedule.shiftType.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: schedule.shiftType.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    schedule.timeRange,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              
              // Notes if any
              if (schedule.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
              
              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  // Status update buttons
                  if (schedule.status != ScheduleStatus.confirmed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateScheduleStatus(
                          schedule,
                          ScheduleStatus.confirmed,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Xác nhận'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (schedule.status != ScheduleStatus.absent && schedule.isToday) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateScheduleStatus(
                          schedule,
                          ScheduleStatus.absent,
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Vắng mặt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Edit button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editSchedule(schedule),
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleDetails(Schedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Chi tiết lịch làm việc',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Nhân viên', schedule.employeeName),
                      if (schedule.employeeEmail != null)
                        _buildDetailRow('Email', schedule.employeeEmail!),
                      if (schedule.employeePhone != null)
                        _buildDetailRow('Số điện thoại', schedule.employeePhone!),
                      _buildDetailRow('Ngày làm việc', schedule.dateFormatted),
                      _buildDetailRow('Ca làm việc', schedule.shiftType.label),
                      _buildDetailRow('Giờ làm việc', schedule.timeRange),
                      _buildDetailRow('Trạng thái', schedule.status.label),
                      if (schedule.notes?.isNotEmpty == true)
                        _buildDetailRow('Ghi chú', schedule.notes!),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _editSchedule(schedule);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Chỉnh sửa'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteSchedule(schedule);
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Xóa'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateScheduleStatus(Schedule schedule, ScheduleStatus status) async {
    try {
      await ref.read(scheduleActionsProvider).updateScheduleStatus(
        schedule.id,
        schedule.companyId,
        status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái lịch làm việc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editSchedule(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormPage(schedule: schedule),
      ),
    );
  }

  void _deleteSchedule(Schedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa lịch làm việc của ${schedule.employeeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(scheduleActionsProvider).deleteSchedule(
          schedule.id,
          schedule.companyId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa lịch làm việc'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}