import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance.dart';
import '../../models/daily_work_report.dart';
import '../../providers/attendance_provider.dart';
import '../../services/daily_work_report_service.dart';
import '../../widgets/work_report_preview_dialog.dart';

/// Test page for Daily Report Auto-Generation Feature
/// Demonstrates automatic end-of-day reporting
class DailyReportTestPage extends ConsumerStatefulWidget {
  const DailyReportTestPage({super.key});

  @override
  ConsumerState<DailyReportTestPage> createState() => _DailyReportTestPageState();
}

class _DailyReportTestPageState extends ConsumerState<DailyReportTestPage> {
  final _reportService = DailyWorkReportService();
  DailyWorkReport? _generatedReport;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: const Text(
          '🧪 Test: Báo cáo Tự động Cuối Ngày',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildTestControls(),
            const SizedBox(height: 24),
            if (_generatedReport != null) _buildReportPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tính năng Báo cáo Tự động',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Hệ thống tự động tạo báo cáo cuối ngày khi nhân viên checkout:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('⏰ Tính toán giờ làm việc tự động'),
          _buildFeatureItem('✅ Thu thập danh sách công việc hoàn thành'),
          _buildFeatureItem('📊 Tạo tóm tắt ca làm việc'),
          _buildFeatureItem('🎯 Đánh giá hiệu suất tự động'),
          _buildFeatureItem('✏️ Nhân viên có thể chỉnh sửa trước khi gửi'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mô phỏng kịch bản: Nhân viên checkout lúc cuối ca',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _simulateCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isGenerating
                    ? 'Đang tạo báo cáo...'
                    : '🚀 Simulate Checkout & Generate Report',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generatedReport == null ? null : _showReportDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigo),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.preview),
              label: const Text(
                '👁️ Preview Report Dialog',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreview() {
    if (_generatedReport == null) return const SizedBox.shrink();

    final report = _generatedReport!;
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Báo cáo đã tạo thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildReportField('👤 Nhân viên', report.userName),
          _buildReportField('📅 Ngày', DateFormat('dd/MM/yyyy').format(report.date)),
          _buildReportField(
            '⏰ Giờ làm việc',
            '${timeFormat.format(report.checkInTime)} - ${timeFormat.format(report.checkOutTime)} (${report.totalHours.toStringAsFixed(1)}h)',
          ),
          _buildReportField('✅ Công việc hoàn thành', '${report.tasksCompleted} tasks'),
          const SizedBox(height: 16),
          const Text(
            '📝 Tóm tắt tự động:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report.autoGeneratedSummary ?? 'Không có tóm tắt',
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (report.completedTasks.isNotEmpty) ...[
            const Text(
              '📋 Công việc đã hoàn thành:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...report.completedTasks.map((task) => _buildTaskItem(task)),
          ],
        ],
      ),
    );
  }

  Widget _buildReportField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskSummary task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.indigo.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.taskTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (task.taskDescription != null) ...[
            const SizedBox(height: 4),
            Text(
              task.taskDescription!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (task.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              '→ ${task.notes}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.indigo.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _simulateCheckout() async {
    setState(() {
      _isGenerating = true;
      _generatedReport = null;
    });

    try {
      // Simulate attendance data (mock check-in/check-out)
      final now = DateTime.now();
      final checkInTime = DateTime(now.year, now.month, now.day, 8, 0); // 8:00 AM
      final checkOutTime = DateTime(now.year, now.month, now.day, 17, 30); // 5:30 PM

      final mockAttendance = Attendance(
        id: 'test_attendance_${now.millisecondsSinceEpoch}',
        userId: 'test_user_123',
        branchId: 'test_branch_001',
        date: now,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        status: AttendanceStatus.present,
      );

      // Generate report
      final report = await _reportService.generateReportFromCheckout(
        attendance: mockAttendance,
        userName: 'Nguyễn Văn A (Test User)',
      );

      setState(() {
        _generatedReport = report;
        _isGenerating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Báo cáo tạo thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Đã tạo báo cáo cho ca làm việc ${report.totalHours.toStringAsFixed(1)}h',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog() {
    if (_generatedReport == null) return;

    showDialog(
      context: context,
      builder: (context) => WorkReportPreviewDialog(
        report: _generatedReport!,
        onSubmitted: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Báo cáo đã được gửi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
