import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/daily_work_report.dart';
import '../../services/daily_work_report_service.dart';
import '../../providers/auth_provider.dart';

/// Staff Reports Page - View all submitted daily work reports
class StaffReportsPage extends ConsumerStatefulWidget {
  const StaffReportsPage({super.key});

  @override
  ConsumerState<StaffReportsPage> createState() => _StaffReportsPageState();
}

class _StaffReportsPageState extends ConsumerState<StaffReportsPage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

        final reportsAsync = ref.watch(userWorkReportsProvider(user.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('📊 Báo Cáo Công Việc'),
            backgroundColor: AppColors.success,
          ),
          body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userWorkReportsProvider(user.id)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có báo cáo nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Báo cáo sẽ tự động tạo khi bạn điểm danh ra ca',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Month selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'vi').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Reports list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportCard(
                      report: report,
                      onTap: () => _showReportDetails(context, report),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportDetails(BuildContext context, DailyWorkReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsSheet(report: report),
    );
  }
}

/// Report Card Widget
class _ReportCard extends StatelessWidget {
  final DailyWorkReport report;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm', 'vi');

    // Status color
    final statusColor = report.status == ReportStatus.submitted
        ? AppColors.success
        : Colors.orange;

    final statusText = report.status == ReportStatus.submitted
        ? 'Đã nộp'
        : 'Nháp';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(report.date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Work hours
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${timeFormat.format(report.checkInTime)} - ${timeFormat.format(report.checkOutTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${report.totalHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tasks completed
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hoàn thành: ${report.tasksCompleted} công việc',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              
              // Employee notes (if any)
              if (report.employeeNotes != null && report.employeeNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.employeeNotes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Report Details Bottom Sheet
class _ReportDetailsSheet extends StatelessWidget {
  final DailyWorkReport report;

  const _ReportDetailsSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm', 'vi');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết báo cáo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  _SectionTitle('📅 Ngày làm việc'),
                  Text(
                    dateFormat.format(report.date),
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time
                  _SectionTitle('⏰ Thời gian'),
                  Text(
                    'Check-in: ${timeFormat.format(report.checkInTime)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Check-out: ${timeFormat.format(report.checkOutTime)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Tổng: ${report.totalHours.toStringAsFixed(1)} giờ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tasks
                  _SectionTitle('✅ Công việc'),
                  Text(
                    'Hoàn thành: ${report.tasksCompleted}/${report.tasksAssigned}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  if (report.completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...report.completedTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.taskTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (task.notes != null)
                                  Text(
                                    task.notes!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Auto summary
                  if (report.autoGeneratedSummary != null) ...[
                    _SectionTitle('📊 Tóm tắt tự động'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.autoGeneratedSummary!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Employee notes
                  if (report.employeeNotes != null && report.employeeNotes!.isNotEmpty) ...[
                    _SectionTitle('📝 Ghi chú'),
                    Text(
                      report.employeeNotes!,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Achievements
                  if (report.achievements != null && report.achievements!.isNotEmpty) ...[
                    _SectionTitle('🎯 Thành tựu'),
                    ...report.achievements!.map((achievement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              achievement,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Challenges
                  if (report.challenges != null && report.challenges!.isNotEmpty) ...[
                    _SectionTitle('⚠️ Khó khăn'),
                    ...report.challenges!.map((challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              challenge,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Tomorrow plan
                  if (report.tomorrowPlan != null && report.tomorrowPlan!.isNotEmpty) ...[
                    _SectionTitle('📅 Kế hoạch ngày mai'),
                    Text(
                      report.tomorrowPlan!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}
