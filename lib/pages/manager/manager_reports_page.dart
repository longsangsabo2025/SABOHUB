import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/daily_work_report.dart';
import '../../models/user.dart' as app_user;
import '../../providers/auth_provider.dart';
import '../../services/daily_work_report_service.dart';
import '../../services/report_ai_service.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Manager Reports Page - View all employee reports in branch
class ManagerReportsPage extends ConsumerStatefulWidget {
  const ManagerReportsPage({super.key});

  @override
  ConsumerState<ManagerReportsPage> createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends ConsumerState<ManagerReportsPage> {
  DateTime _selectedMonth = DateTime.now();
  String? _selectedEmployeeId;
  
  // AI Analysis state
  final _aiService = ReportAIService();
  TeamAIInsight? _teamInsight;
  bool _isAnalyzing = false;

  Future<void> _analyzeTeamReports(List<DailyWorkReport> reports) async {
    if (_isAnalyzing || reports.isEmpty) return;
    
    setState(() => _isAnalyzing = true);
    
    try {
      final insight = await _aiService.analyzeTeamReports(
        allReports: reports,
        branchName: 'Chi nhánh',
      );
      setState(() => _teamInsight = insight);
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Báo cáo công việc',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface87),
        actions: [
          // AI Analysis button
          IconButton(
            icon: _isAnalyzing 
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.purple),
            tooltip: 'Phân tích AI',
            onPressed: () {
              final branchId = ref.read(currentUserProvider)?.branchId ?? '';
              final reportsAsync = ref.read(branchWorkReportsProvider(branchId));
              reportsAsync.whenData((reports) => _analyzeTeamReports(reports));
            },
          ),
          // Filter by employee
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc theo nhân viên',
            onSelected: (employeeId) {
              setState(() {
                _selectedEmployeeId = employeeId;
              });
            },
            itemBuilder: (context) {
              final branchId = ref.read(currentUserProvider)?.branchId ?? '';
              final reportsAsync = ref.read(branchWorkReportsProvider(branchId));
              final employeeItems = reportsAsync.whenData((reports) {
                final employeeMap = <String, String>{};
                for (final r in reports) {
                  employeeMap[r.userId] = r.userName;
                }
                return employeeMap.entries.map((e) => PopupMenuItem<String?>(
                  value: e.key,
                  child: Text(e.value),
                )).toList();
              });
              return [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả nhân viên'),
                ),
                ...employeeItems.value ?? [],
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    final now = DateTime.now();
                    final nextMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                    if (nextMonth.isBefore(now) ||
                        nextMonth.month == now.month) {
                      setState(() {
                        _selectedMonth = nextMonth;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // AI Team Insight Card
          if (_teamInsight != null)
            _TeamAIInsightCard(insight: _teamInsight!),
          
          // Reports list
          Expanded(
            child: _buildReportsList(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, app_user.User user) {
    // Get all reports for branch
    final reportsAsync = ref.watch(branchWorkReportsProvider(user.branchId ?? ''));

    return reportsAsync.when(
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
              onPressed: () {
                ref.invalidate(branchWorkReportsProvider);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (allReports) {
        // Filter by selected month
        final filteredReports = allReports.where((report) {
          final isSameMonth = report.date.year == _selectedMonth.year &&
              report.date.month == _selectedMonth.month;
          
          if (_selectedEmployeeId != null) {
            return isSameMonth && report.userId == _selectedEmployeeId;
          }
          return isSameMonth;
        }).toList();

        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có báo cáo nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Báo cáo sẽ tự động được tạo khi\nnhân viên check-out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Group reports by employee
        final reportsByEmployee = <String, List<DailyWorkReport>>{};
        for (final report in filteredReports) {
          reportsByEmployee.putIfAbsent(report.userId, () => []).add(report);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportsByEmployee.length,
          itemBuilder: (context, index) {
            final employeeId = reportsByEmployee.keys.elementAt(index);
            final employeeReports = reportsByEmployee[employeeId]!;
            final employeeName = employeeReports.first.userName;

            return _EmployeeReportsCard(
              employeeName: employeeName,
              reports: employeeReports,
              onReportTap: (report) => _showReportDetails(context, report),
            );
          },
        );
      },
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

/// Employee Reports Card - Shows all reports for one employee
class _EmployeeReportsCard extends StatefulWidget {
  final String employeeName;
  final List<DailyWorkReport> reports;
  final Function(DailyWorkReport) onReportTap;

  const _EmployeeReportsCard({
    required this.employeeName,
    required this.reports,
    required this.onReportTap,
  });

  @override
  State<_EmployeeReportsCard> createState() => _EmployeeReportsCardState();
}

class _EmployeeReportsCardState extends State<_EmployeeReportsCard> {
  final _aiService = ReportAIService();
  ReportAIInsight? _insight;
  bool _isAnalyzing = false;

  Future<void> _analyzeEmployee() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    
    try {
      final insight = await _aiService.analyzeEmployeeReports(
        reports: widget.reports,
        employeeName: widget.employeeName,
      );
      setState(() => _insight = insight);
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final totalHours = widget.reports.fold<double>(0, (sum, r) => sum + r.totalHours);
    final avgHours = totalHours / widget.reports.length;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              widget.employeeName.isNotEmpty ? widget.employeeName[0].toUpperCase() : 'N',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.employeeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // AI Analyze button
              IconButton(
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _insight != null ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                        color: Colors.purple,
                        size: 20,
                      ),
                tooltip: 'Phân tích AI',
                onPressed: _analyzeEmployee,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.assignment, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${widget.reports.length} báo cáo'),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('TB: ${avgHours.toStringAsFixed(1)}h/ngày'),
                if (_insight != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_insight!.trendEmoji} ${_insight!.trendLabel}',
                      style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            // AI Insight section
            if (_insight != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.blue.shade50],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Phân tích AI',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _insight!.analysis,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            // Original report items
            ...widget.reports.map((report) {
              return _ReportListItem(
                report: report,
                onTap: () => widget.onReportTap(report),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Report List Item - Single report in employee's list
class _ReportListItem extends StatelessWidget {
  final DailyWorkReport report;
  final VoidCallback onTap;

  const _ReportListItem({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 48), // Align with subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy - EEEE', 'vi').format(report.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${DateFormat('HH:mm').format(report.checkInTime)} - ${DateFormat('HH:mm').format(report.checkOutTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${report.totalHours.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Report Details Sheet - Full report details
class _ReportDetailsSheet extends StatelessWidget {
  final DailyWorkReport report;

  const _ReportDetailsSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            DateFormat('dd/MM/yyyy - EEEE', 'vi').format(report.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.login,
                      label: DateFormat('HH:mm').format(report.checkInTime),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.logout,
                      label: DateFormat('HH:mm').format(report.checkOutTime),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.access_time,
                      label: '${report.totalHours.toStringAsFixed(1)}h',
                      color: Colors.blue,
                    ),
                  ],
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
                  // Tasks
                  if (report.completedTasks.isNotEmpty) ...[
                    const _SectionTitle(
                      icon: Icons.check_circle,
                      title: 'Công việc đã hoàn thành',
                    ),
                    const SizedBox(height: 8),
                    ...report.completedTasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.taskTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (task.taskDescription != null)
                                    Text(
                                      task.taskDescription!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  
                  // Auto-generated summary
                  if (report.autoGeneratedSummary != null &&
                      report.autoGeneratedSummary!.isNotEmpty) ...[
                    const _SectionTitle(
                      icon: Icons.summarize,
                      title: 'Tóm tắt tự động',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
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
                  if (report.employeeNotes != null &&
                      report.employeeNotes!.isNotEmpty) ...[
                    const _SectionTitle(
                      icon: Icons.note,
                      title: 'Ghi chú',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.employeeNotes!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Achievements
                  if (report.achievements != null &&
                      report.achievements!.isNotEmpty) ...[
                    const _SectionTitle(
                      icon: Icons.star,
                      title: 'Thành tựu',
                    ),
                    const SizedBox(height: 8),
                    ...report.achievements!.map((achievement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            Expanded(child: Text(achievement)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  
                  // Challenges
                  if (report.challenges != null &&
                      report.challenges!.isNotEmpty) ...[
                    const _SectionTitle(
                      icon: Icons.flag,
                      title: 'Khó khăn',
                    ),
                    const SizedBox(height: 8),
                    ...report.challenges!.map((challenge) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.flag, size: 16, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Expanded(child: Text(challenge)),
                          ],
                        ),
                      );
                    }),
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

/// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

/// Team AI Insight Card
class _TeamAIInsightCard extends StatefulWidget {
  final TeamAIInsight insight;

  const _TeamAIInsightCard({required this.insight});

  @override
  State<_TeamAIInsightCard> createState() => _TeamAIInsightCardState();
}

class _TeamAIInsightCardState extends State<_TeamAIInsightCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phân tích AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          '${widget.insight.employeeCount} nhân viên • ${widget.insight.totalReports} báo cáo',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.access_time,
                        label: 'TB giờ/ngày',
                        value: '${widget.insight.avgHoursPerDay.toStringAsFixed(1)}h',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.star,
                        label: 'Top performer',
                        value: widget.insight.topPerformer.split(' ').first,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // AI Analysis
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.insight.analysis,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  
                  // Generated time
                  const SizedBox(height: 8),
                  Text(
                    '🕐 Cập nhật: ${DateFormat('HH:mm dd/MM').format(widget.insight.generatedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat Badge Widget
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
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
}
