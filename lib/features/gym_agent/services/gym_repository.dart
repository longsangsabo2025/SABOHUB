import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gym_session.dart';
import '../viewmodels/gym_coach_view_model.dart';

/// GymRepository — Supabase CRUD for gym data.
///
/// Handles gym_profiles, gym_sessions, gym_exercise_logs, gym_set_logs,
/// gym_chat_messages tables.
class GymRepository {
  GymRepository._();
  static final instance = GymRepository._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  // ═══════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════

  Future<GymUserProfile?> getProfile() async {
    if (_userId == null) return null;
    final data = await _db
        .from('gym_profiles')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();
    if (data == null) return null;
    return GymUserProfile(
      level: data['level'] as String? ?? 'intermediate',
      goal: data['goal'] as String? ?? 'muscle_gain',
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      age: data['age'] as int?,
      trainingDaysPerWeek: data['training_days_per_week'] as int? ?? 4,
      injuries: (data['injuries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Future<void> upsertProfile(GymUserProfile profile) async {
    if (_userId == null) return;
    await _db.from('gym_profiles').upsert({
      'user_id': _userId,
      'level': profile.level,
      'goal': profile.goal,
      'weight': profile.weight,
      'height': profile.height,
      'age': profile.age,
      'training_days_per_week': profile.trainingDaysPerWeek,
      'injuries': profile.injuries,
    }, onConflict: 'user_id');
  }

  // ═══════════════════════════════════════════════
  // SESSIONS
  // ═══════════════════════════════════════════════

  Future<List<GymSession>> getRecentSessions({int limit = 20}) async {
    if (_userId == null) return [];
    final data = await _db
        .from('gym_sessions')
        .select('*, gym_exercise_logs(*, gym_set_logs(*))')
        .eq('user_id', _userId!)
        .order('started_at', ascending: false)
        .limit(limit);

    return (data as List).map((row) => _sessionFromRow(row)).toList();
  }

  Future<String> createSession(GymSession session) async {
    final row = await _db.from('gym_sessions').insert({
      'user_id': _userId,
      'workout_name': session.workoutName,
      'workout_type': 'custom',
      'started_at': session.startedAt.toIso8601String(),
      'ended_at': session.endedAt?.toIso8601String(),
      'notes': session.notes,
      'mood_rating': session.moodRating,
      'energy_level': session.energyLevel,
      'body_weight': session.bodyWeight,
      'is_ai_generated': false,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> completeSession(String sessionId, {
    DateTime? endedAt,
    int? moodRating,
    int? energyLevel,
    String? notes,
  }) async {
    await _db.from('gym_sessions').update({
      'ended_at': (endedAt ?? DateTime.now()).toIso8601String(),
      if (moodRating != null) 'mood_rating': moodRating,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (notes != null) 'notes': notes,
    }).eq('id', sessionId);
  }

  // ═══════════════════════════════════════════════
  // EXERCISE LOGS
  // ═══════════════════════════════════════════════

  Future<String> addExerciseLog({
    required String sessionId,
    required String exerciseId,
    required String exerciseName,
    required int sortOrder,
    String? notes,
  }) async {
    final row = await _db.from('gym_exercise_logs').insert({
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sort_order': sortOrder,
      'notes': notes,
    }).select('id').single();
    return row['id'] as String;
  }

  // ═══════════════════════════════════════════════
  // SET LOGS
  // ═══════════════════════════════════════════════

  Future<void> addSetLog({
    required String exerciseLogId,
    required int setNumber,
    required int reps,
    double? weight,
    String setType = 'working',
  }) async {
    await _db.from('gym_set_logs').insert({
      'exercise_log_id': exerciseLogId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'set_type': setType,
    });
  }

  // ═══════════════════════════════════════════════
  // CHAT MESSAGES
  // ═══════════════════════════════════════════════

  Future<void> saveChatMessage({
    required String role,
    required String content,
    String messageType = 'text',
    String? sessionId,
    int? tokensUsed,
  }) async {
    if (_userId == null) return;
    await _db.from('gym_chat_messages').insert({
      'user_id': _userId,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'message_type': messageType,
      'tokens_used': tokensUsed,
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    if (_userId == null) return [];
    return await _db
        .from('gym_chat_messages')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  // ═══════════════════════════════════════════════
  // STATS / AGGREGATION
  // ═══════════════════════════════════════════════

  /// Get total volume for a date range
  Future<double> getTotalVolume({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_userId == null) return 0;
    final data = await _db
        .from('gym_sessions')
        .select('gym_exercise_logs(gym_set_logs(reps, weight))')
        .eq('user_id', _userId!)
        .gte('started_at', from.toIso8601String())
        .lte('started_at', to.toIso8601String());

    double total = 0;
    for (final session in data) {
      final logs = session['gym_exercise_logs'] as List? ?? [];
      for (final log in logs) {
        final sets = log['gym_set_logs'] as List? ?? [];
        for (final set in sets) {
          final reps = (set['reps'] as num?)?.toDouble() ?? 0;
          final weight = (set['weight'] as num?)?.toDouble() ?? 0;
          total += reps * weight;
        }
      }
    }
    return total;
  }

  /// Get session count for a date range
  Future<int> getSessionCount({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_userId == null) return 0;
    final data = await _db
        .from('gym_sessions')
        .select('id')
        .eq('user_id', _userId!)
        .gte('started_at', from.toIso8601String())
        .lte('started_at', to.toIso8601String());
    return (data as List).length;
  }

  // ─── HELPERS ──────────────────────────────────

  GymSession _sessionFromRow(Map<String, dynamic> row) {
    final exerciseLogsRaw = row['gym_exercise_logs'] as List? ?? [];
    final exerciseLogs = exerciseLogsRaw.map((el) {
      final setsRaw = el['gym_set_logs'] as List? ?? [];
      final sets = setsRaw
          .map((s) => SetLog(
                setNumber: s['set_number'] as int? ?? 1,
                reps: s['reps'] as int? ?? 0,
                weight: (s['weight'] as num?)?.toDouble(),
                type: SetType.fromString(s['set_type'] as String? ?? 'working'),
              ))
          .toList();
      return ExerciseLog(
        exerciseId: el['exercise_id'] as String,
        exerciseName: el['exercise_name'] as String,
        sets: sets,
        notes: el['notes'] as String?,
      );
    }).toList();

    return GymSession(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      workoutName: row['workout_name'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      endedAt: row['ended_at'] != null
          ? DateTime.parse(row['ended_at'] as String)
          : null,
      exerciseLogs: exerciseLogs,
      notes: row['notes'] as String?,
      moodRating: row['mood_rating'] as int?,
      energyLevel: row['energy_level'] as int?,
      bodyWeight: (row['body_weight'] as num?)?.toDouble(),
    );
  }
}
