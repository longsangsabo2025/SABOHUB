import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

final _performanceDataProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = ref.read(authProvider).user;
  final companyId = user?.companyId;

  if (companyId == null) return [];

  final employees = await supabase
      .from('employees')
      .select('id, full_name, role, department')
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('full_name');

  final employeeList = List<Map<String, dynamic>>.from(employees);

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;

  final tasks = await supabase
      .from('tasks')
      .select('assigned_to, status, progress, completed_at')
      .eq('company_id', companyId);

  final attendance = await supabase
      .from('attendance')
      .select('employee_id, check_in, status')
      .eq('company_id', companyId)
      .gte('check_in', monthStart);

  final taskList = List<Map<String, dynamic>>.from(tasks);
  final attendanceList = List<Map<String, dynamic>>.from(attendance);

  final results = <Map<String, dynamic>>[];
  for (final emp in employeeList) {
    final empId = emp['id'] as String;

    final empTasks = taskList.where((t) => t['assigned_to'] == empId).toList();
    final totalTasks = empTasks.length;
    final completedTasks =
        empTasks.where((t) => t['status'] == 'completed').length;
    final avgProgress = totalTasks > 0
        ? empTasks.fold<int>(0, (s, t) => s + ((t['progress'] as num?)?.toInt() ?? 0)) ~/
            totalTasks
        : 0;

    final empAttendance =
        attendanceList.where((a) => a['employee_id'] == empId).toList();
    final attendanceDays = empAttendance.length;
    final onTime = empAttendance
        .where((a) => a['status'] != 'late' && a['status'] != 'absent')
        .length;

    final taskScore = totalTasks > 0
        ? (completedTasks / totalTasks * 40).round()
        : 0;
    final attendanceScore = attendanceDays > 0
        ? (onTime / attendanceDays * 30).round()
        : 0;
    final progressScore = (avgProgress * 0.3).round();
    final totalScore = (taskScore + attendanceScore + progressScore).clamp(0, 100);

    results.add({
      'id': empId,
      'name': emp['full_name'] ?? 'N/A',
      'role': emp['role'] ?? '',
      'department': emp['department'] ?? '',
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'avg_progress': avgProgress,
      'attendance_days': attendanceDays,
      'on_time': onTime,
      'score': totalScore,
    });
  }

  results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  return results;
});

class PerformanceScorecardPage extends ConsumerWidget {
  const PerformanceScorecardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_performanceDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hiệu suất nhân viên'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: dataAsync.when(
        data: (data) => data.isEmpty
            ? const Center(child: Text('Chưa có dữ liệu nhân viên'))
            : _buildBody(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Map<String, dynamic>> data) {
    final topPerformers = data.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topPerformers.isNotEmpty) ...[
              const Text('Top nhân viên tháng này',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...topPerformers.asMap().entries.map(
                    (e) => _buildTopPerformerCard(e.key + 1, e.value),
                  ),
              const SizedBox(height: 20),
            ],
            const Text('Bảng xếp hạng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...data.asMap().entries.map(
                  (e) => _buildEmployeeRow(e.key + 1, e.value),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerCard(int rank, Map<String, dynamic> emp) {
    final score = emp['score'] as int;
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : '🥉';
    final color = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.blueGrey.shade300
            : Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${emp['role']} ${emp['department'] != '' ? '- ${emp['department']}' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text('điểm',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(int rank, Map<String, dynamic> emp) {
    final score = emp['score'] as int;
    final totalTasks = emp['total_tasks'] as int;
    final completedTasks = emp['completed_tasks'] as int;
    final attendanceDays = emp['attendance_days'] as int;

    final scoreColor = score >= 70
        ? Colors.green
        : score >= 40
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rank',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(emp['role'] as String,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          _miniStat('Task', '$completedTasks/$totalTasks', Colors.blue),
          const SizedBox(width: 8),
          _miniStat('Chấm công', '$attendanceDays', Colors.green),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text('$score',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: scoreColor)),
                SizedBox(
                  width: 44,
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}
