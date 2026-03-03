import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/daily_work_report.dart';
import '../../services/daily_work_report_service.dart';
import '../../providers/auth_provider.dart';

/// CEO Daily Reports Dashboard
/// View all employee daily work reports with filters
class DailyReportsDashboardPage extends ConsumerStatefulWidget {
  const DailyReportsDashboardPage({super.key});

  @override
  ConsumerState<DailyReportsDashboardPage> createState() =>
      _DailyReportsDashboardPageState();
}

class _DailyReportsDashboardPageState
    extends ConsumerState<DailyReportsDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'all';
  String _selectedPeriod = 'today'; // today, week, month, quarter, year
  List<DailyWorkReport> _reports = [];
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(dailyWorkReportServiceProvider);
      final authUser = ref.read(authProvider).user;

      if (authUser != null) {
        // Get company ID
        final companyId = authUser.companyId;

        if (companyId == null) {
          // User doesn't have a company yet
          setState(() {
            _reports = [];
            _statistics = {};
          });
          return;
        }

        // Get reports for selected date
        final reports =
            await service.getCompanyReports(companyId, _selectedDate);

        // Filter by status if needed
        List<DailyWorkReport> filteredReports = reports;
        if (_selectedStatus != 'all') {
          filteredReports = reports
              .where((r) => r.status.name == _selectedStatus)
              .toList();
        }

        // Get statistics
        final stats = await service.getReportStatistics(
          companyId: companyId,
          date: _selectedDate,
        );

        setState(() {
          _reports = filteredReports;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Báo cáo cuối ngày',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: Colors.black87),
          tooltip: 'Làm mới',
        ),
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list, color: Colors.black87),
          tooltip: 'Lọc',
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodTabs(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            if (_statistics != null) _buildStatisticsCard(),
            const SizedBox(height: 16),
            _buildStatusFilter(),
            const SizedBox(height: 16),
            _buildReportsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodTab('Hôm nay', 'today'),
          _buildPeriodTab('Tuần này', 'week'),
          _buildPeriodTab('Tháng này', 'month'),
          _buildPeriodTab('Quý này', 'quarter'),
          _buildPeriodTab('Năm này', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
            // Set date based on period
            switch (value) {
              case 'today':
                _selectedDate = DateTime.now();
                break;
              case 'week':
                // Start of week (Monday)
                final now = DateTime.now();
                _selectedDate = now.subtract(Duration(days: now.weekday - 1));
                break;
              case 'month':
                final now = DateTime.now();
                _selectedDate = DateTime(now.year, now.month, 1);
                break;
              case 'quarter':
                final now = DateTime.now();
                final quarter = ((now.month - 1) ~/ 3) + 1;
                _selectedDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
                break;
              case 'year':
                final now = DateTime.now();
                _selectedDate = DateTime(now.year, 1, 1);
                break;
            }
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ngày báo cáo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () => _changeDate(1),
            icon: const Icon(Icons.chevron_right),
          ),
          TextButton(
            onPressed: () => _pickDate(),
            child: const Text('Chọn ngày'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics!;
    final totalReports = stats['total_reports'] ?? 0;
    final submittedReports = stats['submitted_reports'] ?? 0;
    final avgHours = (stats['average_hours'] ?? 0.0) as double;
    final totalTasks = stats['total_tasks_completed'] ?? 0;
    final submissionRate = (stats['submission_rate'] ?? 0.0) as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Thống kê tổng quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tổng báo cáo',
                  totalReports.toString(),
                  Icons.description,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Đã nộp',
                  submittedReports.toString(),
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Giờ làm TB',
                  '${avgHours.toStringAsFixed(1)}h',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Công việc',
                  totalTasks.toString(),
                  Icons.task_alt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tỷ lệ nộp báo cáo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${submissionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tất cả', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Nháp', 'draft'),
          const SizedBox(width: 8),
          _buildFilterChip('Đã nộp', 'submitted'),
          const SizedBox(width: 8),
          _buildFilterChip('Đã xem', 'reviewed'),
          const SizedBox(width: 8),
          _buildFilterChip('Đã duyệt', 'approved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
        _loadData();
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có báo cáo nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn ngày khác hoặc đổi bộ lọc',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_reports.length} báo cáo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reports.length,
          itemBuilder: (context, index) => _buildReportCard(_reports[index]),
        ),
      ],
    );
  }

  Widget _buildReportCard(DailyWorkReport report) {
    final completionRate = report.tasksAssigned > 0
        ? (report.tasksCompleted / report.tasksAssigned * 100).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReportDetail(report),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: report.status.color.withValues(alpha: 0.2),
                      child: Text(
                        report.userName
                            .split(' ')
                            .map((n) => n[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: report.status.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('HH:mm').format(report.checkInTime)} - ${DateFormat('HH:mm').format(report.checkOutTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: report.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: report.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        '${report.totalHours.toStringAsFixed(1)} giờ',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.task_alt,
                        '${report.tasksCompleted}/${report.tasksAssigned}',
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.percent,
                        '$completionRate%',
                        completionRate >= 80
                            ? Colors.green
                            : completionRate >= 50
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (report.autoGeneratedSummary != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.autoGeneratedSummary!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Theo trạng thái'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Theo nhân viên'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Theo chi nhánh'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showReportDetail(DailyWorkReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportDetailSheet(report),
    );
  }

  Widget _buildReportDetailSheet(DailyWorkReport report) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                                  .format(report.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: report.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.status.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: report.status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailSection(
                    'Thông tin chấm công',
                    Icons.access_time,
                    [
                      _buildDetailRow('Giờ vào',
                          DateFormat('HH:mm').format(report.checkInTime)),
                      _buildDetailRow('Giờ ra',
                          DateFormat('HH:mm').format(report.checkOutTime)),
                      _buildDetailRow('Tổng giờ làm',
                          '${report.totalHours.toStringAsFixed(1)} giờ'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    'Công việc',
                    Icons.task_alt,
                    [
                      _buildDetailRow('Được giao',
                          '${report.tasksAssigned} công việc'),
                      _buildDetailRow('Hoàn thành',
                          '${report.tasksCompleted} công việc'),
                      _buildDetailRow(
                        'Tỷ lệ',
                        report.tasksAssigned > 0
                            ? '${(report.tasksCompleted / report.tasksAssigned * 100).toInt()}%'
                            : 'N/A',
                      ),
                    ],
                  ),
                  if (report.completedTasks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildTasksList(report.completedTasks),
                  ],
                  if (report.autoGeneratedSummary != null) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      'Tóm tắt tự động',
                      Icons.auto_awesome,
                      [
                        Text(
                          report.autoGeneratedSummary!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (report.employeeNotes != null) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      'Ghi chú nhân viên',
                      Icons.note,
                      [
                        Text(
                          report.employeeNotes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (report.achievements != null &&
                      report.achievements!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildListSection(
                      'Thành tựu',
                      Icons.emoji_events,
                      report.achievements!,
                      Colors.amber,
                    ),
                  ],
                  if (report.challenges != null &&
                      report.challenges!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildListSection(
                      'Khó khăn',
                      Icons.warning,
                      report.challenges!,
                      Colors.orange,
                    ),
                  ],
                  if (report.tomorrowPlan != null) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection(
                      'Kế hoạch ngày mai',
                      Icons.event_note,
                      [
                        Text(
                          report.tomorrowPlan!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (report.status != ReportStatus.approved)
                    ElevatedButton.icon(
                      onPressed: () => _approveReport(report),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Duyệt báo cáo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<TaskSummary> tasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist,
                  size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              const Text(
                'Danh sách công việc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskSummary task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.taskTitle,
                  style: const TextStyle(
                    fontSize: 14,
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
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (task.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              '📝 ${task.notes}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Hoàn thành: ${DateFormat('HH:mm').format(task.completedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
      String title, IconData icon, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveReport(DailyWorkReport report) async {
    try {
      final service = ref.read(dailyWorkReportServiceProvider);
      await service.updateReport(
        reportId: report.id,
        employeeNotes: report.employeeNotes,
        achievements: report.achievements,
        challenges: report.challenges,
        tomorrowPlan: report.tomorrowPlan,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã duyệt báo cáo'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
