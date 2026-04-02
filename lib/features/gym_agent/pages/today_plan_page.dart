import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_plan.dart';
import '../services/gym_planner_service.dart';
import '../viewmodels/gym_coach_view_model.dart';
import 'workout_tracker_page.dart';
import '../viewmodels/gym_stats_viewmodel.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final gymPlannerServiceProvider = Provider<GymPlannerService>((ref) {
  return GymPlannerService();
});

final todayPlanProvider =
    AsyncNotifierProvider<TodayPlanNotifier, DailyPlan?>(TodayPlanNotifier.new);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TODAY'S PLAN PAGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class TodayPlanNotifier extends AsyncNotifier<DailyPlan?> {
  @override
  Future<DailyPlan?> build() async {
    final coachState = ref.read(gymCoachViewModelProvider).asData?.value;
    final profile = coachState?.userProfile;
    if (profile == null) return null;

    final planner = ref.read(gymPlannerServiceProvider);
    return planner.getTodayPlan(profile);
  }

  Future<void> regenerate() async {
    state = const AsyncLoading();
    final coachState = ref.read(gymCoachViewModelProvider).asData?.value;
    final profile = coachState?.userProfile;
    if (profile == null) {
      state = const AsyncData(null);
      return;
    }
    final planner = ref.read(gymPlannerServiceProvider);
    state = await AsyncValue.guard(() => planner.generatePlan(profile));
  }

  void toggleExercise(int index) {
    final plan = state.asData?.value;
    if (plan?.workout == null) return;
    plan!.workout!.exercises[index].isCompleted =
        !plan.workout!.exercises[index].isCompleted;
    state = AsyncData(plan);
  }

  void toggleMeal(int index) {
    final plan = state.asData?.value;
    if (plan == null || index >= plan.meals.length) return;
    plan.meals[index].isCompleted = !plan.meals[index].isCompleted;
    state = AsyncData(plan);
  }
}

class TodayPlanPage extends ConsumerWidget {
  const TodayPlanPage({super.key});

  static const _green = Color(0xFF10B981);
  static const _orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(todayPlanProvider);

    return planAsync.when(
      data: (plan) {
        if (plan == null) return _buildNoProfile(context, ref);
        return _buildPlanView(context, ref, plan);
      },
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, ref, e),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: _green),
          ),
          SizedBox(height: 16),
          Text(
            '🤖 AI đang lên kế hoạch cho bạn...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Phân tích profile → Chọn bài tập → Lên thực đơn',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfile(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Chưa có Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vào tab Chat và cho AI biết thông tin của bạn:\n'
              'level, mục tiêu, cân nặng, chiều cao, tuổi, số ngày tập/tuần',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(todayPlanProvider.notifier).regenerate(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: _green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(todayPlanProvider.notifier).regenerate(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: _green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView(BuildContext context, WidgetRef ref, DailyPlan plan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => ref.read(todayPlanProvider.notifier).regenerate(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header Card ──
          _buildHeaderCard(context, plan, isDark),
          const SizedBox(height: 16),

          // ── Daily Tip ──
          if (plan.dailyTip != null && plan.dailyTip!.isNotEmpty)
            _buildTipCard(plan.dailyTip!, isDark),

          if (plan.dailyTip != null) const SizedBox(height: 16),

          // ── Macro Summary ──
          _buildMacroSummary(plan, isDark),
          const SizedBox(height: 16),

          // ── Workout Section ──
          if (!plan.isRestDay && plan.workout != null) ...[
            _buildSectionTitle('🏋️ WORKOUT', plan.workout!.name,
                '~${plan.workout!.estimatedMinutes} phút'),
            const SizedBox(height: 8),
            _buildWorkoutCard(context, ref, plan.workout!, isDark),
            const SizedBox(height: 16),
          ],

          if (plan.isRestDay) ...[
            _buildRestDayCard(isDark),
            const SizedBox(height: 16),
          ],

          // ── Meal Plan Section ──
          _buildSectionTitle('🍽️ DINH DƯỠNG', '${plan.meals.length} bữa',
              '${plan.targetCalories} kcal'),
          const SizedBox(height: 8),
          ...plan.meals.asMap().entries.map(
                (entry) =>
                    _buildMealCard(context, ref, entry.key, entry.value, isDark),
              ),

          const SizedBox(height: 24),

          // ── Regenerate Button ──
                    // ── Start Workout Button ──
                    if (!plan.isRestDay && plan.workout != null) ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('🏃 Bắt đầu tập ngay'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutTrackerPage(workout: plan.workout!),
                            ),
                          );
                          if (result == true && context.mounted) {
                            ref.read(gymStatsProvider.notifier).refresh();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Regenerate Button ──
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(todayPlanProvider.notifier).regenerate(),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Tạo lại kế hoạch mới'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, DailyPlan plan, bool isDark) {
    final now = DateTime.now();
    final dayNames = [
      '', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'
    ];
    final dayName = dayNames[now.weekday];
    final dateStr =
        '$dayName, ${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plan.isRestDay
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [_green, const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                plan.isRestDay ? Icons.self_improvement : Icons.fitness_center,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isRestDay ? 'REST DAY 🧘' : 'KẾ HOẠCH HÔM NAY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!plan.isRestDay && plan.workout != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${plan.workout!.name} • ${plan.workout!.exercises.length} bài • ~${plan.workout!.estimatedMinutes}\'',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(DailyPlan plan, bool isDark) {
    final protein = plan.targetMacros['protein'] ?? 0;
    final carbs = plan.targetMacros['carbs'] ?? 0;
    final fat = plan.targetMacros['fat'] ?? 0;

    return Row(
      children: [
        _macroChip('🔥', '${plan.targetCalories}', 'kcal', Colors.red, isDark),
        const SizedBox(width: 8),
        _macroChip('🥩', '$protein', 'g P', Colors.blue, isDark),
        const SizedBox(width: 8),
        _macroChip('🍚', '$carbs', 'g C', _orange, isDark),
        const SizedBox(width: 8),
        _macroChip('🥑', '$fat', 'g F', _green, isDark),
      ],
    );
  }

  Widget _macroChip(
      String emoji, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String icon, String title, String subtitle) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Spacer(),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WidgetRef ref,
      PlannedWorkout workout, bool isDark) {
    final completedCount =
        workout.exercises.where((e) => e.isCompleted).length;
    final total = workout.exercises.length;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              color: _green,
            ),
          ),

          // Warmup
          if (workout.warmup != null && workout.warmup!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.whatshot, size: 16, color: Colors.orange[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Warmup: ${workout.warmup}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

          // Exercises
          ...workout.exercises.asMap().entries.map(
                (entry) => _buildExerciseTile(
                    context, ref, entry.key, entry.value, isDark),
              ),

          // Cooldown
          if (workout.cooldown != null && workout.cooldown!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.ac_unit, size: 16, color: Colors.blue[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cooldown: ${workout.cooldown}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

          // Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '$completedCount / $total bài hoàn thành',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: completedCount == total && total > 0
                    ? _green
                    : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(BuildContext context, WidgetRef ref, int index,
      PlannedExercise exercise, bool isDark) {
    return InkWell(
      onTap: () => ref.read(todayPlanProvider.notifier).toggleExercise(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: exercise.isCompleted
                    ? _green
                    : Colors.transparent,
                border: Border.all(
                  color: exercise.isCompleted ? _green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: exercise.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: exercise.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: exercise.isCompleted
                          ? Colors.grey
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.sets} sets × ${exercise.reps}'
                    '${exercise.weight != null ? " • ${exercise.weight}" : ""}'
                    ' • Rest ${exercise.restSeconds}s',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (exercise.notes != null && exercise.notes!.isNotEmpty)
                    Text(
                      exercise.notes!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayCard(bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🧘', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Hôm nay là ngày nghỉ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cơ bắp cần thời gian phục hồi.\n'
              'Hãy stretching nhẹ, đi bộ, và ngủ đủ giấc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, int index,
      PlannedMeal meal, bool isDark) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(todayPlanProvider.notifier).toggleMeal(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: meal.isCompleted ? _green : Colors.transparent,
                  border: Border.all(
                    color: meal.isCompleted ? _green : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: meal.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),

              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          meal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: meal.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          meal.time,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...meal.foods.map(
                      (food) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Text('  •  ',
                                style: TextStyle(color: Colors.grey[400])),
                            Expanded(
                              child: Text(
                                food,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _mealMacroTag(
                            '${meal.calories} kcal', Colors.red[400]!),
                        const SizedBox(width: 6),
                        _mealMacroTag(
                            'P:${meal.macros['protein'] ?? 0}g',
                            Colors.blue[400]!),
                        const SizedBox(width: 6),
                        _mealMacroTag(
                            'C:${meal.macros['carbs'] ?? 0}g', _orange),
                        const SizedBox(width: 6),
                        _mealMacroTag(
                            'F:${meal.macros['fat'] ?? 0}g', _green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealMacroTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
