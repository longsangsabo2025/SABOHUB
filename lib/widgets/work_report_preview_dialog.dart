import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/daily_work_report.dart';
import '../services/daily_work_report_service.dart';

/// Work Report Preview Dialog
/// Shows auto-generated report for employee to review & edit before submit
class WorkReportPreviewDialog extends ConsumerStatefulWidget {
  final DailyWorkReport report;
  final VoidCallback? onSubmitted;

  const WorkReportPreviewDialog({
    super.key,
    required this.report,
    this.onSubmitted,
  });

  @override
  ConsumerState<WorkReportPreviewDialog> createState() =>
      _WorkReportPreviewDialogState();
}

class _WorkReportPreviewDialogState
    extends ConsumerState<WorkReportPreviewDialog> {
  late TextEditingController _notesController;
  late TextEditingController _achievementsController;
  late TextEditingController _challengesController;
  late TextEditingController _tomorrowPlanController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.report.employeeNotes);
    _achievementsController = TextEditingController(
      text: widget.report.achievements?.join('\n'),
    );
    _challengesController = TextEditingController(
      text: widget.report.challenges?.join('\n'),
    );
    _tomorrowPlanController = TextEditingController(
      text: widget.report.tomorrowPlan,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _achievementsController.dispose();
    _challengesController.dispose();
    _tomorrowPlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.assignment, color: Colors.blue[700], size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Báo cáo công việc hôm nay',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Xem lại và bổ sung thông tin',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-generated summary (read-only)
                    _buildSectionHeader(
                        '🤖 Tóm tắt tự động', Icons.auto_awesome),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Thời gian',
                            '${DateFormat('HH:mm').format(widget.report.checkInTime)} - ${DateFormat('HH:mm').format(widget.report.checkOutTime)}',
                          ),
                          _buildInfoRow(
                            'Tổng giờ',
                            '${widget.report.totalHours.toStringAsFixed(1)} giờ',
                          ),
                          _buildInfoRow(
                            'Công việc hoàn thành',
                            '${widget.report.tasksCompleted}/${widget.report.tasksAssigned} việc',
                          ),
                          const Divider(height: 24),
                          Text(
                            widget.report.autoGeneratedSummary ??
                                'Không có tóm tắt',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Completed tasks
                    if (widget.report.completedTasks.isNotEmpty) ...[
                      _buildSectionHeader(
                          '✅ Công việc đã hoàn thành', Icons.task_alt),
                      ...widget.report.completedTasks.map(
                        (task) => _buildTaskCard(task),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Employee notes (editable)
                    _buildSectionHeader(
                        '💭 Ghi chú thêm (tùy chọn)', Icons.edit_note),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Bổ sung thêm chi tiết về công việc hôm nay...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Achievements (editable)
                    _buildSectionHeader('🎯 Thành tựu (tùy chọn)', Icons.stars),
                    TextField(
                      controller: _achievementsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'VD: Hoàn thành sớm hơn dự kiến\nPhối hợp tốt với team\nHọc được kỹ năng mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Challenges (editable)
                    _buildSectionHeader(
                        '🚧 Khó khăn gặp phải (tùy chọn)', Icons.warning_amber),
                    TextField(
                      controller: _challengesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'VD: Thiếu công cụ\nGặp vấn đề kỹ thuật\nCần hỗ trợ từ quản lý',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tomorrow plan (editable)
                    _buildSectionHeader(
                        '📅 Kế hoạch ngày mai (tùy chọn)', Icons.event_note),
                    TextField(
                      controller: _tomorrowPlanController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'VD: Hoàn thành task ABC\nBắt đầu dự án XYZ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.edit),
                  label: const Text('Lưu nháp'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Đang nộp...' : 'Nộp báo cáo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskSummary task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (task.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.notes!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Hoàn thành: ${DateFormat('HH:mm').format(task.completedAt)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(dailyWorkReportServiceProvider);

      // Update report with employee input
      final updatedReport = await service.updateReport(
        reportId: widget.report.id,
        employeeNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        achievements: _achievementsController.text.trim().isEmpty
            ? null
            : _achievementsController.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        challenges: _challengesController.text.trim().isEmpty
            ? null
            : _challengesController.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        tomorrowPlan: _tomorrowPlanController.text.trim().isEmpty
            ? null
            : _tomorrowPlanController.text.trim(),
      );

      // Submit report
      await service.submitReport(updatedReport.id);

      if (mounted) {
        Navigator.pop(context, true);
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi nộp báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
