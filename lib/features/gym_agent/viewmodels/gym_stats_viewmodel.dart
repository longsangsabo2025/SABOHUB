import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_session.dart';
import '../services/gym_repository.dart';

// ── GymStats Model ─────────────────────────────────────────────

class GymStats {
  final int totalSessions;
  final int sessionsThisWeek;
  final double volumeThisWeek;
  final int streak; // consecutive training days ending today
  final List<GymSession> recentSessions;
  final List<double> weeklyVolumeByDay; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final Set<int> trainedWeekdays; // 1=Mon … 7=Sun (current week)

  const GymStats({
    required this.totalSessions,
    required this.sessionsThisWeek,
    required this.volumeThisWeek,
    required this.streak,
    required this.recentSessions,
    required this.weeklyVolumeByDay,
    required this.trainedWeekdays,
  });

  static GymStats empty() => const GymStats(
        totalSessions: 0,
        sessionsThisWeek: 0,
        volumeThisWeek: 0,
        streak: 0,
        recentSessions: [],
        weeklyVolumeByDay: [0, 0, 0, 0, 0, 0, 0],
        trainedWeekdays: {},
      );

  String get volumeText {
    if (volumeThisWeek >= 1000) {
      return '${(volumeThisWeek / 1000).toStringAsFixed(1)}K kg';
    }
    return '${volumeThisWeek.toStringAsFixed(0)} kg';
  }
}

// ── GymStatsNotifier ───────────────────────────────────────────

final gymStatsProvider =
    AsyncNotifierProvider<GymStatsNotifier, GymStats>(GymStatsNotifier.new);

class GymStatsNotifier extends AsyncNotifier<GymStats> {
  @override
  Future<GymStats> build() async => _fetchStats();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStats);
  }

  Future<GymStats> _fetchStats() async {
    final repo = GymRepository.instance;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Current week boundaries (Mon → Sun)
    final weekday = now.weekday; // 1=Mon
    final weekStart = today.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Fetch all sessions in parallel
    final results = await Future.wait([
      repo.getRecentSessions(limit: 60), // enough for streak + totals
      repo.getTotalVolume(from: weekStart, to: weekEnd),
      repo.getSessionCount(from: weekStart, to: weekEnd),
    ]);

    final sessions = results[0] as List<GymSession>;
    final volumeThisWeek = results[1] as double;
    final sessionsThisWeek = results[2] as int;

    // ── Per-day volume this week ──
    final weeklyVolumeByDay = List<double>.filled(7, 0.0);
    final trainedWeekdays = <int>{};

    for (final session in sessions) {
      final d = session.startedAt;
      final sessionDay = DateTime(d.year, d.month, d.day);
      if (!sessionDay.isBefore(weekStart) && sessionDay.isBefore(weekEnd)) {
        // weekday: 1=Mon → index 0
        final dayIndex = d.weekday - 1;
        // Volume = sum of (reps * weight) across all exercise logs
        double vol = 0;
        for (final log in session.exerciseLogs) {
          for (final set in log.sets) {
            vol += (set.reps) * (set.weight ?? 0);
          }
        }
        weeklyVolumeByDay[dayIndex] += vol;
        trainedWeekdays.add(d.weekday);
      }
    }

    // ── Streak calculation ──
    int streak = 0;
    DateTime checkDay = today;
    // Build a set of distinct dates that have at least one session
    final sessionDates = sessions
        .map((s) {
          final d = s.startedAt;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();

    while (sessionDates.contains(checkDay)) {
      streak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    return GymStats(
      totalSessions: sessions.length,
      sessionsThisWeek: sessionsThisWeek,
      volumeThisWeek: volumeThisWeek,
      streak: streak,
      recentSessions: sessions.take(10).toList(),
      weeklyVolumeByDay: weeklyVolumeByDay,
      trainedWeekdays: trainedWeekdays,
    );
  }
}
