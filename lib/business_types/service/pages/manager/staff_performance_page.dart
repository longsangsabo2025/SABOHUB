import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../providers/auth_provider.dart';

class StaffPerformancePage extends ConsumerStatefulWidget {
  const StaffPerformancePage({super.key});

  @override
  ConsumerState<StaffPerformancePage> createState() =>
      _StaffPerformancePageState();
}

class _StaffPerformancePageState extends ConsumerState<StaffPerformancePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic> _checkinStats = {};
  Map<String, int> _moodCounts = {'great': 0, 'okay': 0, 'tired': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final client = Supabase.instance.client;
    final companyId = user.companyId ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      // Load employees
      final empResponse = await client
          .from('employees')
          .select('id, full_name, role, is_active')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('full_name');

      // Load today's checkins
      final checkinResponse = await client
          .from('checkins')
          .select('employee_id, check_in_time, check_out_time')
          .eq('company_id', companyId)
          .gte('check_in_time', '${today}T00:00:00')
          .lte('check_in_time', '${today}T23:59:59');

      // Load mood logs (might not exist yet — wrap in try/catch)
      Map<String, int> moodCounts = {'great': 0, 'okay': 0, 'tired': 0};
      try {
        final moodResponse = await client
            .from('mood_logs')
            .select('mood')
            .eq('company_id', companyId)
            .eq('date', today);
        for (final row in (moodResponse as List)) {
          final mood = row['mood'] as String?;
          if (mood != null && moodCounts.containsKey(mood)) {
            moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
          }
        }
      } catch (_) {
        // mood_logs table may not exist yet — silent fail
      }

      final checkins = List<Map<String, dynamic>>.from(checkinResponse);
      final checkedInIds = checkins.map((c) => c['employee_id']).toSet();

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(empResponse);
          _checkinStats = {
            'total': _employees.length,
            'checkedIn': checkedInIds.length,
            'absent': _employees.length - checkedInIds.length,
          };
          _moodCounts = moodCounts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _loadData();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCheckinSummary(),
                  const SizedBox(height: 16),
                  _buildMoodSummary(),
                  const SizedBox(height: 16),
                  const Text(
                    'Danh sách nhân viên',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildEmployeeCard(_employees[i]),
              childCount: _employees.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCheckinSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Check-in hôm nay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${_checkinStats['checkedIn'] ?? 0}/${_checkinStats['total'] ?? 0}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_checkinStats['total'] ?? 0) > 0
                  ? (_checkinStats['checkedIn'] ?? 0) /
                      (_checkinStats['total'] ?? 1)
                  : 0,
              minHeight: 6,
              backgroundColor: Colors.grey.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.info,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_checkinStats['absent'] ?? 0} nhân viên chưa check-in',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSummary() {
    final total = _moodCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('😊', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Mood team hôm nay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodCount(
                '😊', 'Tuyệt', _moodCounts['great'] ?? 0, AppColors.success),
              _buildMoodCount(
                '😐', 'Bình thường', _moodCounts['okay'] ?? 0, AppColors.warning),
              _buildMoodCount(
                '😩', 'Mệt', _moodCounts['tired'] ?? 0, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCount(String emoji, String label, int count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.info.withAlpha(30),
            child: Text(
              (emp['full_name'] as String? ?? '?')
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            emp['full_name'] ?? 'Không tên',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            emp['role'] ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
