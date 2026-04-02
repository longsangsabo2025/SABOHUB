import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_logger.dart';
import '../models/daily_plan.dart';
import '../viewmodels/gym_coach_view_model.dart';

/// GymPlannerService — AI-powered daily plan generation via Travis API.
///
/// All Gemini calls go through Travis API (/api/gym/plan).
/// API key stays server-side. mem0 provides long-term memory.
/// Plans are stored in Supabase `gym_daily_plans` table.
class GymPlannerService {
  static final GymPlannerService _instance = GymPlannerService._();
  factory GymPlannerService() => _instance;
  GymPlannerService._();

  static String get _apiUrl =>
      dotenv.env['TRAVIS_API_URL'] ?? 'http://localhost:8300';

  static String get _apiKey =>
      dotenv.env['TRAVIS_API_KEY'] ?? '';

  final _supabase = Supabase.instance.client;

  // ─── Get or Generate Today's Plan ──────────────────────────────

  /// Get today's plan. If none exists, generate one via AI.
  Future<DailyPlan?> getTodayPlan(GymUserProfile profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final today = _todayStr();

    // Check if plan exists in Supabase
    try {
      final existing = await _supabase
          .from('gym_daily_plans')
          .select()
          .eq('user_id', userId)
          .eq('plan_date', today)
          .maybeSingle();

      if (existing != null) {
        return DailyPlan.fromJson(existing);
      }
    } catch (e) {
      AppLogger.warn('GymPlanner: Error fetching plan: $e');
    }

    // No plan → generate via AI
    return generatePlan(profile);
  }

  /// Force generate a new plan for today (or specific date).
  Future<DailyPlan?> generatePlan(
    GymUserProfile profile, {
    DateTime? forDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final date = forDate ?? DateTime.now();
    final dayOfWeek = _vietnameseDayOfWeek(date.weekday);

    AppLogger.api('GymPlanner: Generating plan for $dayOfWeek');

    try {
      final jsonPlan = await _callBackendPlan(profile, dayOfWeek);
      if (jsonPlan == null) return null;

      final plan = DailyPlan.fromJson({
        ...jsonPlan,
        'plan_date': _dateStr(date),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save to Supabase (upsert by date)
      await _savePlan(userId, plan);

      return plan;
    } catch (e) {
      AppLogger.error('GymPlanner: Error generating plan: $e');
      return null;
    }
  }

  // ─── Travis API Call ────────────────────────────────────────────

  Future<Map<String, dynamic>?> _callBackendPlan(
    GymUserProfile profile,
    String dayOfWeek,
  ) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final url = Uri.parse('$_apiUrl/api/gym/plan');

    final body = jsonEncode({
      'user_id': userId,
      'profile': {
        'level': profile.level,
        'goal': profile.goal,
        'weight': profile.weight ?? 70,
        'height': profile.height ?? 170,
        'age': profile.age ?? 25,
        'training_days_per_week': profile.trainingDaysPerWeek,
        'injuries': profile.injuries,
      },
      'day_of_week': dayOfWeek,
    });

    final response = await http
        .post(url, headers: _headers, body: body)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      AppLogger.error(
          'GymPlanner API error: ${response.statusCode} ${response.body}');
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['plan'] as Map<String, dynamic>?;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      };

  // ─── Helpers ───────────────────────────────────────────────────

  String _vietnameseDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ nhật';
      default: return 'Thứ 2';
    }
  }

  String _todayStr() => _dateStr(DateTime.now());

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Supabase Persistence ──────────────────────────────────────

  Future<void> _savePlan(String userId, DailyPlan plan) async {
    try {
      await _supabase.from('gym_daily_plans').upsert(
        plan.toSupabaseRow(userId),
        onConflict: 'user_id,plan_date',
      );
      AppLogger.info('GymPlanner: Plan saved for ${_dateStr(plan.planDate)}');
    } catch (e) {
      AppLogger.error('GymPlanner: Failed to save plan: $e');
    }
  }

  /// Get recent plans (for history/progress view).
  Future<List<DailyPlan>> getRecentPlans({int limit = 7}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _supabase
          .from('gym_daily_plans')
          .select()
          .eq('user_id', userId)
          .order('plan_date', ascending: false)
          .limit(limit);

      return rows.map((r) => DailyPlan.fromJson(r)).toList();
    } catch (e) {
      AppLogger.error('GymPlanner: Error fetching plans: $e');
      return [];
    }
  }
}
