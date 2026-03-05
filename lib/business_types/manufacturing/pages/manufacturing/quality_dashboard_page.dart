// Quality Dashboard Page - Manufacturing QC Overview
// Date: 2026-03-04

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../models/quality_inspection.dart';
import '../../services/quality_service.dart';
import 'quality_inspection_form_page.dart';

class QualityDashboardPage extends ConsumerStatefulWidget {
  const QualityDashboardPage({super.key});

  @override
  ConsumerState<QualityDashboardPage> createState() =>
      _QualityDashboardPageState();
}

class _QualityDashboardPageState extends ConsumerState<QualityDashboardPage> {
  late QualityService _service;
  List<QualityInspection> _inspections = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  // Date filter
  DateTime? _filterStart;
  DateTime? _filterEnd;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _service = QualityService(
      companyId: user?.companyId,
      employeeId: user?.id,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getInspections(),
        _service.getStats(),
      ]);
      var inspections = results[0] as List<QualityInspection>;

      // Áp dụng filter ngày
      if (_filterStart != null) {
        inspections = inspections
            .where((i) => !i.inspectionDate.isBefore(_filterStart!))
            .toList();
      }
      if (_filterEnd != null) {
        final endOfDay =
            _filterEnd!.add(const Duration(days: 1));
        inspections = inspections
            .where((i) => i.inspectionDate.isBefore(endOfDay))
            .toList();
      }

      setState(() {
        _inspections = inspections;
        _stats = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      AppLogger.error('QC Dashboard: Load failed', e);
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu QC: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm Tra Chất Lượng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Lọc theo ngày',
            onPressed: _showDateFilter,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const QualityInspectionFormPage()),
          ).then((_) => _load());
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo kiểm tra'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === SUMMARY CARDS ===
                  _buildSummaryCards(),
                  const SizedBox(height: 16),

                  // === DEFECT BREAKDOWN ===
                  _buildDefectChart(),
                  const SizedBox(height: 16),

                  // === FILTER INDICATOR ===
                  if (_filterStart != null || _filterEnd != null)
                    _buildFilterChip(),
                  if (_filterStart != null || _filterEnd != null)
                    const SizedBox(height: 8),

                  // === RECENT INSPECTIONS ===
                  _buildRecentInspections(),
                ],
              ),
            ),
    );
  }

  // ===== SUMMARY CARDS =====
  Widget _buildSummaryCards() {
    final total = _stats['total'] ?? 0;
    final passRate = (_stats['passRate'] as num?)?.toDouble() ?? 0;
    final failed = _stats['failed'] ?? 0;
    final pending = _stats['pending'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _summaryCard(
          'Tổng kiểm tra',
          '$total',
          Icons.fact_check,
          Colors.blue,
        ),
        _summaryCard(
          'Tỉ lệ đạt',
          '${passRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          passRate >= 90
              ? Colors.green
              : passRate >= 70
                  ? Colors.orange
                  : Colors.red,
        ),
        _summaryCard(
          'Không đạt',
          '$failed',
          Icons.cancel,
          Colors.red,
        ),
        _summaryCard(
          'Chờ kiểm tra',
          '$pending',
          Icons.pending,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DEFECT CHART (Container bars) =====
  Widget _buildDefectChart() {
    final defects =
        (_stats['defectBreakdown'] as Map<String, int>?) ?? {};
    if (defects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.bar_chart, size: 20),
                const SizedBox(width: 8),
                const Text('Phân tích lỗi',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              const Text('Chưa có dữ liệu lỗi',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final maxCount =
        defects.values.fold<int>(0, (a, b) => a > b ? a : b);
    final barColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 8),
              Text('Phân tích lỗi',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ...defects.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final type = entry.value.key;
              final count = entry.value.value;
              final ratio = maxCount > 0 ? count / maxCount : 0.0;
              final color = barColors[idx % barColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type, style: const TextStyle(fontSize: 13)),
                        Text('$count',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 14,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===== FILTER CHIP =====
  String _fmtDate(DateTime? d) =>
      d != null ? '${d.day}/${d.month}/${d.year}' : '';

  Widget _buildFilterChip() {
    String label = '';
    if (_filterStart != null && _filterEnd != null) {
      label = '${_fmtDate(_filterStart)} → ${_fmtDate(_filterEnd)}';
    } else if (_filterStart != null) {
      label = 'Từ ${_fmtDate(_filterStart)}';
    } else {
      label = 'Đến ${_fmtDate(_filterEnd)}';
    }

    return Row(
      children: [
        Chip(
          avatar: const Icon(Icons.filter_alt, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _filterStart = null;
              _filterEnd = null;
            });
            _load();
          },
        ),
      ],
    );
  }

  // ===== RECENT INSPECTIONS =====
  Widget _buildRecentInspections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.history, size: 20),
          SizedBox(width: 8),
          Text('Kiểm tra gần đây',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        if (_inspections.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.fact_check_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Chưa có lần kiểm tra nào',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_inspections.take(20).map((i) => _inspectionTile(i))),
      ],
    );
  }

  Widget _inspectionTile(QualityInspection inspection) {
    final statusColor = _getStatusColor(inspection.status);
    final statusText = QCStatusHelper.statusText(inspection.status);
    final date = inspection.inspectionDate;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            _getStatusIcon(inspection.status),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          inspection.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$dateStr • ${inspection.inspectorName}\n'
          'SL: ${inspection.totalQuantity} | '
          'Đạt: ${inspection.passedQuantity} | '
          'Lỗi: ${inspection.failedQuantity}',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  QualityInspectionFormPage(inspection: inspection),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }

  Color _getStatusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return Colors.orange;
      case InspectionStatus.inProgress:
        return Colors.blue;
      case InspectionStatus.passed:
        return Colors.green;
      case InspectionStatus.failed:
        return Colors.red;
      case InspectionStatus.conditional:
        return Colors.amber.shade700;
    }
  }

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.pending:
        return Icons.pending;
      case InspectionStatus.inProgress:
        return Icons.play_circle;
      case InspectionStatus.passed:
        return Icons.check_circle;
      case InspectionStatus.failed:
        return Icons.cancel;
      case InspectionStatus.conditional:
        return Icons.warning;
    }
  }

  // ===== DATE FILTER =====
  Future<void> _showDateFilter() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _filterStart != null && _filterEnd != null
          ? DateTimeRange(start: _filterStart!, end: _filterEnd!)
          : null,
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
      saveText: 'Lưu',
      locale: const Locale('vi', 'VN'),
    );

    if (range != null) {
      setState(() {
        _filterStart = range.start;
        _filterEnd = range.end;
      });
      _load();
    }
  }
}
