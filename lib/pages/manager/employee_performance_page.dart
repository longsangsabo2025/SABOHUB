import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/kpi_service.dart';
import '../../services/performance_metrics_service.dart';
import '../../providers/auth_provider.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **MANAGER KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - ❌ KHÔNG ĐƯỢC dùng `supabase.client.auth.currentUser`
/// - ✅ PHẢI dùng `ref.read(authProvider).user`
/// - Manager login qua mã nhân viên, lưu trong `employees` table
/// - employee.id là userId cho mọi operation

/// Employee Performance Evaluation Page for Managers
/// Shows detailed performance metrics, KPI tracking, and evaluation
class EmployeePerformancePage extends ConsumerStatefulWidget {
  const EmployeePerformancePage({super.key});

  @override
  ConsumerState<EmployeePerformancePage> createState() =>
      _EmployeePerformancePageState();
}

class _EmployeePerformancePageState
    extends ConsumerState<EmployeePerformancePage> {
  final _kpiService = KPIService();
  final _metricsService = PerformanceMetricsService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _employeeEvaluations = [];
  String _selectedPeriod = '7days';
  String _sortBy = 'score'; // score, name, completion_rate
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user from authProvider (Manager is employee, not auth user)
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        debugPrint('🔴 [EmployeePerformance] No user logged in from authProvider');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('🔍 [EmployeePerformance] Loading data for employee: ${currentUser.id}');
      _companyId = currentUser.companyId;

      if (_companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Calculate date range based on selected period
      final endDate = DateTime.now();
      DateTime startDate;
      switch (_selectedPeriod) {
        case '7days':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case '30days':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case 'thisMonth':
          startDate = DateTime(endDate.year, endDate.month, 1);
          break;
        case 'lastMonth':
          final lastMonth = DateTime(endDate.year, endDate.month - 1, 1);
          startDate = lastMonth;
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // Get company-wide performance
      final evaluations = await _kpiService.getCompanyPerformance(
        companyId: _companyId!,
        startDate: startDate,
        endDate: endDate,
      );

      // Sort evaluations
      _sortEvaluations(evaluations);

      setState(() {
        _employeeEvaluations = evaluations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _sortEvaluations(List<Map<String, dynamic>> evaluations) {
    switch (_sortBy) {
      case 'score':
        evaluations.sort((a, b) => (b['overall_score'] as double)
            .compareTo(a['overall_score'] as double));
        break;
      case 'name':
        evaluations
            .sort((a, b) => (a['user_name'] as String).compareTo(b['user_name'] as String));
        break;
      case 'completion_rate':
        evaluations.sort((a, b) =>
            ((b['avg_completion_rate'] as double?) ?? 0)
                .compareTo((a['avg_completion_rate'] as double?) ?? 0));
        break;
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _calculateMetrics() async {
    if (_companyId == null) return;

    setState(() => _isLoading = true);

    try {
      // Calculate metrics for all employees today
      await _metricsService.calculateCompanyDailyMetrics(
        companyId: _companyId!,
        date: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tính toán metrics thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tính metrics: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá hiệu suất nhân viên'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: 'Tính toán metrics hôm nay',
            onPressed: _calculateMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_employeeEvaluations.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Chưa có dữ liệu đánh giá'),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _employeeEvaluations.length,
                  itemBuilder: (context, index) {
                    final evaluation = _employeeEvaluations[index];
                    return _buildEmployeeCard(evaluation, index + 1);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Khoảng thời gian',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '7days', child: Text('7 ngày qua')),
                    DropdownMenuItem(
                        value: '30days', child: Text('30 ngày qua')),
                    DropdownMenuItem(
                        value: 'thisMonth', child: Text('Tháng này')),
                    DropdownMenuItem(
                        value: 'lastMonth', child: Text('Tháng trước')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp theo',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'score', child: Text('Điểm tổng')),
                    DropdownMenuItem(value: 'name', child: Text('Tên')),
                    DropdownMenuItem(
                        value: 'completion_rate',
                        child: Text('Tỷ lệ hoàn thành')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                      _sortEvaluations(_employeeEvaluations);
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> evaluation, int rank) {
    final score = evaluation['overall_score'] as double;
    final userName = evaluation['user_name'] as String;
    final role = evaluation['role'] as String?;
    final targetsMet = evaluation['targets_met'] as int;
    final totalTargets = evaluation['total_targets'] as int;
    final evaluationText = evaluation['evaluation'] as String;
    final completionRate = evaluation['avg_completion_rate'] as double? ?? 0;
    final qualityScore = evaluation['avg_quality_score'] as double? ?? 0;
    final onTimeRate = evaluation['avg_on_time_rate'] as double? ?? 0;

    Color scoreColor;
    if (score >= 90) {
      scoreColor = Colors.green;
    } else if (score >= 80) {
      scoreColor = Colors.blue;
    } else if (score >= 70) {
      scoreColor = Colors.orange;
    } else if (score >= 60) {
      scoreColor = Colors.amber;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rank and name
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scoreColor.withOpacity(0.2),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (role != null)
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      evaluationText,
                      style: TextStyle(
                        fontSize: 12,
                        color: scoreColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI Targets
            Row(
              children: [
                const Icon(Icons.track_changes, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'KPI đạt: $targetsMet/$totalTargets',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (totalTargets > 0)
                  Text(
                    '${((targetsMet / totalTargets) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: targetsMet == totalTargets
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Performance Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Hoàn thành',
                    completionRate,
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Chất lượng',
                    qualityScore * 10,
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Đúng giờ',
                    onTimeRate,
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEmployeeDetails(evaluation),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Chi tiết'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEvaluationDialog(evaluation),
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Đánh giá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String label, double value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> evaluation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(evaluation['user_name'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Điểm tổng: ${(evaluation['overall_score'] as double).toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Đánh giá: ${evaluation['evaluation']}',
                style: const TextStyle(fontSize: 16),
              ),
              const Divider(height: 24),
              const Text(
                'Chi tiết KPI:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...((evaluation['details'] as List).map((detail) {
                final metricName = detail['metric_name'] as String;
                final targetValue = detail['target_value'] as double;
                final actualValue = detail['actual_value'] as double;
                final achievement = detail['achievement_percent'] as double;
                final isMet = detail['is_met'] as bool;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metricName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Mục tiêu: ${targetValue.toStringAsFixed(1)}'),
                          const SizedBox(width: 16),
                          Text('Thực tế: ${actualValue.toStringAsFixed(1)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: achievement / 100,
                        backgroundColor: Colors.grey[300],
                        color: isMet ? Colors.green : Colors.orange,
                      ),
                      Text(
                        '${achievement.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMet ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
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

  void _showEvaluationDialog(Map<String, dynamic> evaluation) {
    final TextEditingController notesController = TextEditingController();
    double manualScore = evaluation['overall_score'] as double;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Đánh giá ${evaluation['user_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm hệ thống: ${(evaluation['overall_score'] as double).toStringAsFixed(1)}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Điểm đánh giá thủ công:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: manualScore,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: manualScore.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() => manualScore = value);
                  },
                ),
                Text(
                  '${manualScore.toStringAsFixed(1)} / 100',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú đánh giá',
                    border: OutlineInputBorder(),
                    hintText: 'Nhận xét về hiệu suất làm việc...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final currentUser = ref.read(authProvider).user;
                  if (currentUser == null) {
                    throw Exception('User not authenticated');
                  }

                  // Save manual evaluation to employee_evaluations table
                  final supabase = Supabase.instance.client;
                  await supabase.from('employee_evaluations').insert({
                    'employee_id': evaluation['user_id'],
                    'evaluator_id': currentUser.id,
                    'company_id': currentUser.companyId,
                    'branch_id': currentUser.branchId,
                    'manual_score': manualScore,
                    'system_score': evaluation['overall_score'],
                    'notes': notesController.text.trim(),
                    'evaluated_at': DateTime.now().toIso8601String(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đánh giá đã được lưu thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Failed to save evaluation: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi khi lưu đánh giá: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu đánh giá'),
            ),
          ],
        ),
      ),
    );
  }
}
