import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/gym_coach_view_model.dart';
import '../viewmodels/gym_stats_viewmodel.dart';

/// Gym Dashboard — Shows workout stats, streaks, and progress overview.
class GymDashboardPage extends ConsumerWidget {
  const GymDashboardPage({super.key});

  static const _gymColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gymStatsProvider).asData?.value ?? GymStats.empty();

    return RefreshIndicator(
      onRefresh: () => ref.read(gymStatsProvider.notifier).refresh(),
      color: _gymColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context, ref),
            const SizedBox(height: 16),
            _buildWeeklyOverview(context, stats),
            const SizedBox(height: 16),
            _buildStatsGrid(context, stats),
            const SizedBox(height: 16),
            _buildRecentWorkouts(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymCoachViewModelProvider);
    final profile = gymState.value?.userProfile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _gymColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.fitness_center, color: _gymColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gym Profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (profile != null) ...[
                    _buildProfileRow(
                        '💪', 'Level: ${profile.level}'),
                    _buildProfileRow(
                        '🎯', 'Mục tiêu: ${profile.goal}'),
                    if (profile.weight != null)
                      _buildProfileRow(
                          '⚖️', 'Cân nặng: ${profile.weight}kg'),
                    _buildProfileRow(
                        '📅', '${profile.trainingDaysPerWeek} ngày/tuần'),
                  ] else
                    Text(
                      'Chưa thiết lập profile. Chat với Coach AI để bắt đầu!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showProfileDialog(context, ref, profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('$emoji $text', style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context, GymStats gymStats) {
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final trainedDays = gymStats.trainedWeekdays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: _gymColor),
                const SizedBox(width: 8),
                Text(
                  'Tuần này',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gymColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gymStats.sessionsThisWeek} buổi tuần này',
                    style: const TextStyle(
                      color: _gymColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isTrained = trainedDays.contains(dayNum);
                final isToday = dayNum == today;

                return Column(
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? _gymColor : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isTrained
                            ? _gymColor
                            : isToday
                                ? _gymColor.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: _gymColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isTrained
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isToday ? _gymColor : Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, GymStats gymStats) {
    final stats = [
      _StatItem('🔥', 'Streak', '${gymStats.streak} ngày', _gymColor),
      _StatItem('🏋️', 'Tổng buổi', '${gymStats.totalSessions}', Colors.blue),
      _StatItem('⚡', 'Volume/tuần', gymStats.volumeText, Colors.orange),
      _StatItem('📅', 'Tuần này', '${gymStats.sessionsThisWeek} buổi', Colors.purple),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats.map((stat) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(stat.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      stat.label,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: stat.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentWorkouts(BuildContext context, GymStats gymStats) {
    final sessions = gymStats.recentSessions;
    if (sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.history, size: 20, color: _gymColor),
              const SizedBox(width: 8),
              Text(
                'Gần đây',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    // Build workout tiles from real sessions
    final workouts = sessions.map((s) {
      final when = _relativeDate(s.startedAt);
      return _RecentWorkout(
        s.workoutName,
        '${s.exerciseLogs.length} bài tập',
        s.durationText,
        when,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: _gymColor),
                const SizedBox(width: 8),
                Text(
                  'Gần đây',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...workouts.map((w) => _buildWorkoutTile(w)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTile(_RecentWorkout w) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _gymColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.fitness_center, size: 20, color: _gymColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(w.muscles,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(w.duration,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(w.when,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '$diff ngày trước';
  }

  void _showProfileDialog(
      BuildContext context, WidgetRef ref, GymUserProfile? current) {
    final weightCtrl =
        TextEditingController(text: current?.weight?.toString() ?? '');
    final heightCtrl =
        TextEditingController(text: current?.height?.toString() ?? '');
    final ageCtrl = TextEditingController(text: current?.age?.toString() ?? '');
    var level = current?.level ?? 'intermediate';
    var goal = current?.goal ?? 'muscle_gain';
    var days = current?.trainingDaysPerWeek ?? 4;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('🏋️ Gym Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: const [
                    DropdownMenuItem(
                        value: 'beginner', child: Text('🟢 Người mới')),
                    DropdownMenuItem(
                        value: 'intermediate', child: Text('🟡 Trung bình')),
                    DropdownMenuItem(
                        value: 'advanced', child: Text('🔴 Nâng cao')),
                  ],
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: goal,
                  decoration: const InputDecoration(labelText: 'Mục tiêu'),
                  items: const [
                    DropdownMenuItem(
                        value: 'muscle_gain', child: Text('💪 Tăng cơ')),
                    DropdownMenuItem(
                        value: 'fat_loss', child: Text('🔥 Giảm mỡ')),
                    DropdownMenuItem(
                        value: 'strength', child: Text('🏋️ Sức mạnh')),
                    DropdownMenuItem(
                        value: 'health', child: Text('❤️ Sức khỏe')),
                  ],
                  onChanged: (v) => setDialogState(() => goal = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Cân nặng (kg)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Chiều cao (cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tuổi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: days,
                        decoration:
                            const InputDecoration(labelText: 'Ngày/tuần'),
                        items: List.generate(
                          7,
                          (i) => DropdownMenuItem(
                              value: i + 1, child: Text('${i + 1} ngày')),
                        ),
                        onChanged: (v) => setDialogState(() => days = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final profile = GymUserProfile(
                  level: level,
                  goal: goal,
                  weight: double.tryParse(weightCtrl.text),
                  height: double.tryParse(heightCtrl.text),
                  age: int.tryParse(ageCtrl.text),
                  trainingDaysPerWeek: days,
                );
                ref
                    .read(gymCoachViewModelProvider.notifier)
                    .updateProfile(profile);
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: _gymColor),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  _StatItem(this.emoji, this.label, this.value, this.color);
}

class _RecentWorkout {
  final String name;
  final String muscles;
  final String duration;
  final String when;

  _RecentWorkout(this.name, this.muscles, this.duration, this.when);
}
