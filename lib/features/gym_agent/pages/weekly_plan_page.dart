import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_plan.dart';
import '../viewmodels/gym_coach_view_model.dart';
import 'today_plan_page.dart';
import 'workout_tracker_page.dart';

// ── Weekly Plan Provider ───────────────────────────────────────

final weeklyPlansProvider =
    AsyncNotifierProvider<WeeklyPlansNotifier, Map<String, DailyPlan?>>(
  WeeklyPlansNotifier.new,
);

class WeeklyPlansNotifier extends AsyncNotifier<Map<String, DailyPlan?>> {
  @override
  Future<Map<String, DailyPlan?>> build() async {
    final planner = ref.read(gymPlannerServiceProvider);
    final plans = await planner.getRecentPlans(limit: 7);

    // Index by date string
    final map = <String, DailyPlan?>{};
    for (final p in plans) {
      map[_dateKey(p.planDate)] = p;
    }
    return map;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── WeeklyPlanPage ─────────────────────────────────────────────

class WeeklyPlanPage extends ConsumerStatefulWidget {
  const WeeklyPlanPage({super.key});

  @override
  ConsumerState<WeeklyPlanPage> createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends ConsumerState<WeeklyPlanPage> {
  static const _gymColor = Color(0xFF10B981);

  // Show Mon of selected week (default = current week)
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final thisStart = DateTime(thisMonday.year, thisMonday.month, thisMonday.day);
    return _weekStart == thisStart;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(weeklyPlansProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(weeklyPlansProvider.notifier).refresh(),
      color: _gymColor,
      child: CustomScrollView(
        slivers: [
          // ── Week Navigation ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _weekStart =
                          _weekStart.subtract(const Duration(days: 7));
                    }),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isCurrentWeek
                            ? 'Tuần này'
                            : '${_weekStart.day}/${_weekStart.month} – ${_weekDays.last.day}/${_weekDays.last.month}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isCurrentWeek
                        ? null
                        : () => setState(() {
                              _weekStart =
                                  _weekStart.add(const Duration(days: 7));
                            }),
                  ),
                ],
              ),
            ),
          ),

          // ── Day Chips ──
          SliverToBoxAdapter(
            child: _buildDayChips(),
          ),

          // ── Plan Cards ──
          plansAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _gymColor),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Lỗi: $e')),
            ),
            data: (plans) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _DayPlanCard(
                    date: _weekDays[i],
                    plan: plans[_dateKey(_weekDays[i])],
                    gymColor: _gymColor,
                    onGeneratePlan: () => _generateForDay(_weekDays[i]),
                  ),
                  childCount: 7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChips() {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final plansData =
        ref.watch(weeklyPlansProvider).asData?.value ?? {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(7, (i) {
          final day = _weekDays[i];
          final key = _dateKey(day);
          final isToday = key == todayKey;
          final hasPlan = plansData.containsKey(key);
          final plan = plansData[key];
          final isRest = plan?.isRestDay ?? false;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _scrollToDay(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday
                      ? _gymColor
                      : hasPlan
                          ? (isRest
                              ? Colors.purple.withValues(alpha: 0.12)
                              : _gymColor.withValues(alpha: 0.1))
                          : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday
                        ? _gymColor
                        : hasPlan
                            ? (isRest
                                ? Colors.purple.withValues(alpha: 0.4)
                                : _gymColor.withValues(alpha: 0.4))
                            : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayNames[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : null,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasPlan
                            ? (isRest ? Colors.purple : _gymColor)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _scrollToDay(int index) {
    // Future: scroll list to that day card
  }

  Future<void> _generateForDay(DateTime date) async {
    final coachState = ref.read(gymCoachViewModelProvider).asData?.value;
    final profile = coachState?.userProfile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Chưa có Profile. Vào tab Chat và cho AI biết thông tin của bạn.'),
        ),
      );
      return;
    }

    final planner = ref.read(gymPlannerServiceProvider);
    final dayNames = [
      '', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '🤖 Đang tạo kế hoạch ${dayNames[date.weekday]}...'),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      await planner.generatePlan(profile, forDate: date);
      await ref.read(weeklyPlansProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tạo kế hoạch: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Day Plan Card ─────────────────────────────────────────────

class _DayPlanCard extends ConsumerWidget {
  final DateTime date;
  final DailyPlan? plan;
  final Color gymColor;
  final VoidCallback onGeneratePlan;

  const _DayPlanCard({
    required this.date,
    required this.plan,
    required this.gymColor,
    required this.onGeneratePlan,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get _isPast {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayNames = [
      '', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'
    ];
    final dayName = dayNames[date.weekday];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: _isToday ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isToday ? gymColor.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isToday
                        ? gymColor.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$dayName ${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isToday ? gymColor : null,
                    ),
                  ),
                ),
                if (_isToday)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: gymColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HÔM NAY',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                const Spacer(),
                if (plan == null && !_isPast)
                  TextButton.icon(
                    icon: Icon(Icons.auto_awesome, size: 14, color: gymColor),
                    label: Text('Tạo', style: TextStyle(fontSize: 12, color: gymColor)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: onGeneratePlan,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (plan == null)
              // No plan
              Text(
                _isPast ? 'Không có kế hoạch' : 'Chưa lên kế hoạch',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              )
            else if (plan!.isRestDay)
              // Rest day
              Row(
                children: [
                  const Text('🧘', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REST DAY', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'Nghỉ ngơi & phục hồi',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              )
            else ...[
              // Workout plan
              if (plan!.workout != null) ...[
                Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan!.workout!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      '~${plan!.workout!.estimatedMinutes}\'',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Exercise chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: plan!.workout!.exercises
                      .take(4)
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: gymColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e.name,
                              style: TextStyle(fontSize: 11, color: gymColor),
                            ),
                          ))
                      .toList()
                    ..addAll(
                      plan!.workout!.exercises.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${plan!.workout!.exercises.length - 4} more',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              )
                            ]
                          : [],
                    ),
                ),
              ],

              const SizedBox(height: 8),
              // Macro summary
              Row(
                children: [
                  _macroTag('🔥', '${plan!.targetCalories}kcal', Colors.red),
                  const SizedBox(width: 6),
                  _macroTag(
                      '🥩', '${plan!.targetMacros['protein'] ?? 0}g P', Colors.blue),
                  const SizedBox(width: 6),
                  _macroTag(
                      '🍚', '${plan!.targetMacros['carbs'] ?? 0}g C', Colors.orange),
                  const Spacer(),
                  if (_isToday && plan!.workout != null)
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Bắt đầu', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: gymColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutTrackerPage(
                            workout: plan!.workout!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroTag(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$emoji $label',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
